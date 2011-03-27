#! /usr/bin/perl
#
# Monitors dgamelaunch inprogress-dirs to detect active games, and then
# monitors those active games to find .where updates and converts them to
# .dglwhere files that dgamelaunch can consume.
#
# Assumption: inprogress dirs are directly under DGLDIR/inprogress*
# Assumption: player .where files are under TTYRECDIR/<playername>/
# Assumption: the script runs with permissions to create .dglwhere alongside
#             the player .where

use strict;
use warnings;
use Linux::Inotify2;
use POSIX;
use Fcntl qw/:flock/;

use Getopt::Long;

my $DAEMON = 1;
GetOptions("daemon" => \$DAEMON)
  or die "Bad command line: @ARGV\n";

my $DGLDIR = $ARGV[0];
my $TTYRECDIR = $ARGV[1];

$ENV{DGLDIR} = $DGLDIR;
$ENV{TTYRECDIR} = $TTYRECDIR;

my $LOCKFILE = "$DGLDIR/.crawl-inotify.lock";
my $LOGFILE = "$DGLDIR/crawl-inotify-where.log";

my $inotify;
my %MONITORED_PLAYERS;

sub say($) {
  print STDERR "@_\n";
}

sub assert_dir_exists($) {
  my $dir = shift;
  die "$dir not set in environment\n" unless $ENV{$dir};
  die "Can't find $dir ($ENV{$dir})\n" unless -d $ENV{$dir};
}

sub assert_environment_exists() {
  assert_dir_exists('DGLDIR');
  assert_dir_exists('TTYRECDIR');
}

sub player_where_dir($) {
  my $player = shift;
  "$TTYRECDIR/$player"
}

sub player_where_file($) {
  my $player = shift;
  player_where_dir($player) . "/$player.where"
}

sub player_dglwhere_file($) {
  my $player = shift;
  player_where_dir($player) . "/$player.dglwhere"
}

sub whereis_read($) {
  my $whereis_file = shift;
  open my $inf, '<', $whereis_file or do {
    warn "Could not read whereis file: $whereis_file: $!\n";
    return;
  };
  chomp(my $text = <$inf>);
  close $inf;
  $text =~ s/::/\n/g;
  my %hash = map {
    my ($key, $value) = /(\w+)=(.*)/s;
    $value =~ s/\n/:/gs;
    ($key, $value)
  } split(/:/s, $text);
  \%hash
}

sub whereis_human_readable($) {
  my $w = shift;
  # No more than 18 characters, empty string for saved/dead characters:
  return '' if $$w{status} ne 'active';
  my $weight = $$w{xl} * 100 + $$w{lvl};
  sprintf("$weight|%-3s $$w{char}, $$w{place}",
          "L$$w{xl}")
}

sub write_dglwhere_file($) {
  my $player = shift;
  my $where_dict = whereis_read(player_where_file($player));

  if ($where_dict) {
    my $human_readable_where = whereis_human_readable($where_dict);
    my $dglwhere_file = player_dglwhere_file($player);
    open my $outf, '>', $dglwhere_file or do {
      say "Could not write $dglwhere_file: $!";
      return;
    };
    print $outf "$human_readable_where\n";
    close $outf;
    say "Wrote $dglwhere_file: $human_readable_where";
  }
}

sub inprog_player($) {
  my $ttyrec = shift;
  ($ttyrec) = $ttyrec =~ m{.*/(.*)} if $ttyrec =~ m{/};
  my ($player) = $ttyrec =~ /(.+?):/;
  $player
}

## BEGIN inotify callbacks ##

sub inotify_player_where_file_changed {
  my ($player, $event) = @_;
  return unless $$event{name} =~ /$player\.where$/;
  write_dglwhere_file($player);
}

sub inotify_inprogress_change {
  my ($event) = @_;
  my $file = $$event{name};
  return unless $file;

  my $player = inprog_player($file);
  my $gone_away = $$event{mask} & IN_DELETE;
  if ($player) {
    if ($gone_away) {
      say "$player went away, unmonitoring.";
      unmonitor_player($player);
    }
    else {
      say "$player started game, monitoring";
      write_dglwhere_file($player);
      monitor_player($inotify, $player);
    }
  }
}

## END inotify callbacks ##

sub monitor_player($$) {
  my ($inotify, $player) = @_;
  return if $MONITORED_PLAYERS{$player};
  say "++ MONITOR: $player";
  my $watch = $inotify->watch(player_where_dir($player), IN_CLOSE_WRITE,
                              sub {
                                inotify_player_where_file_changed($player, @_)
                              });
  die "Failed to watch $player: $!\n" unless $watch;
  $MONITORED_PLAYERS{$player} = $watch;
  say "[ERR] Watch object is false for $player" unless $watch;
}

sub unmonitor_player($) {
  my $player = shift;
  my $watch = $MONITORED_PLAYERS{$player};
  if (defined $watch) {
    say "-- MONITOR: $player";
    $watch->cancel;
    delete $MONITORED_PLAYERS{$player};
  }
  else {
    say "$player was not being monitored, ignoring unmonitor request"
  }
}

sub monitor_players($@) {
  my ($inotify, @players) = @_;
  for my $player (@players) {
    write_dglwhere_file($player);
    monitor_player($inotify, $player);
  }
}

sub inprogress_dirs() {
  my @dirs = grep(-d, glob("$DGLDIR/inprogress*"));
  die "No inprogress dirs under $DGLDIR!\n" unless @dirs;
  @dirs
}

sub monitor_active_player_where($) {
  my $inotify = shift;

  my %monitorees;
  my @inprog_dirs = inprogress_dirs();
  for my $dir (@inprog_dirs) {
    my @ttyrecs = glob("$dir/*.ttyrec");

    for my $ttyrec (@ttyrecs) {
      my ($player) = inprog_player($ttyrec);
      $monitorees{$player} = 1 if $player =~ /^\w+/;
    }
  }
  monitor_players($inotify, keys %monitorees);
}

sub monitor_inprogress_dirs($) {
  my $inotify = shift;
  my @inprog_dirs = inprogress_dirs();
  for my $inprog (@inprog_dirs) {
    $inotify->watch($inprog, IN_CREATE | IN_DELETE,
                    \&inotify_inprogress_change);
  }
}

sub lock_or_exit {
  my ($exitcode, $lockf) = @_;
  $exitcode ||= 0;
  open LOCKFILE, '>', $lockf or die "Couldn't open $lockf: $!\n";
  flock(LOCKFILE, LOCK_EX | LOCK_NB)
    or do {
      warn "Cannot start: $lockf is held by another process\n";
      exit($exitcode);
    };
}

sub daemonify {
  my $log = shift;
  umask 0;
  defined(my $pid = fork) or die "Unable to fork: $!";
  exit if $pid;
  setsid or die "Unable to start a new session: $!";
  print "Started daemon.\n";

  open STDOUT, '>', $log or die "Can't write $log: $!\n";
  open STDERR, '>&', \*STDOUT;
  # Done daemonifying.
}

sub ps_list($) {
  my $process_name = shift;
  my @processes = map([split],
                      qx/ps -ef | grep \Q$process_name\E | grep -v grep/);
  grep($_->[1] != $$, @processes);
}

sub ps_pid($) {
  my $process_name = shift;
  my @processes = ps_list($process_name);
  return unless @processes == 1;
  return $processes[0][1];
}

sub pid_describe($) {
  my $pid = shift;
  my @lines = qx/ps -f -p \Q$pid\E/;
  join('', @lines)
}

sub supersede_existing_daemon() {
  my $name = $0;
  ($name) = $name =~ m{.*/(.*)} if $name =~ m{/};
  my $existing_daemon_pid = ps_pid($name);
  if ($existing_daemon_pid) {
    print "Killing existing daemon ($existing_daemon_pid):\n",
      pid_describe($existing_daemon_pid);
    kill TERM => $existing_daemon_pid;
    sleep 1;
  }
}

sub main() {
  assert_environment_exists();

  supersede_existing_daemon();
  lock_or_exit(1, $LOCKFILE);
  daemonify($LOGFILE) if $DAEMON;

  $inotify = Linux::Inotify2->new;
  monitor_active_player_where($inotify);
  monitor_inprogress_dirs($inotify);

  say "Monitoring and updating where info";
  $inotify->poll while 1;
  warn "Exiting, WTF?\n";
}

main();
