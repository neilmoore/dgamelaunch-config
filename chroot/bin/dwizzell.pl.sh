#!/usr/bin/perl

#
# ===========================================================================
# Copyright (C) 2007 Marc H. Thoben
# Copyright (C) 2008 Darshan Shaligram
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# ===========================================================================
#
#to use this, create folders dwizzell and run under /DGL/

use strict;
use warnings;

use POSIX qw(setsid); # For daemonization.
use File::Find;
use File::Glob qw/:globally :nocase/;

my $username       = 'XXXXXX';
my $nickname       = '|df_XXXXXX';
my $ircname        = '|df_XXXXXX, the MFC Dwarf Fortress Bot';
# my $ircserver      = 'barjavel.freenode.net';
# my $ircserver      = 'kornbluth.freenode.net';
# my $ircserver      = 'bartol.freenode.net';
# my $ircserver      = 'pratchett.freenode.net';
my $ircserver      = 'chat.freenode.net';
my $port           = 8001;
my @CHANNELS       = ('#octolog', '##crawl-df');
my $ANNOUNCE_CHAN  = ('##crawl-df');
my $DEV_CHAN       = '#octolog';
my @badusers;

my @stonefiles     = ('/dfdir/df_XXXXXX/gamelog.txt');

my @logfiles       = ('/dfdir/df_XXXXXX/blank.txt');

my @announcefiles  = ('/logs/df_XXXXXX.log');
my $pidfile        = '/dfdir/df_XXXXXX/dwizzell.pid';
my $baduserfile    = '/dwizzell/.badusers';

my $DGL_INPROGRESS_DIR    = '/dgldir/inprogress/';
my $DGL_TTYREC_DIR        = '/dgldir/ttyrec/';
my $DGL_BINARY_DIR        = '/usr/games/';
my $INACTIVE_IDLE_CEILING_SECONDS = 300;

my $MAX_LENGTH = 420;
# The largest message to paginate in PM.
my $MAX_PAGINATE_LENGTH = 2000;
my $SERVER_BASE_URL = 'http://crawl.beRotato.org/crawl/dev';
my $MORGUE_BASE_URL = "$SERVER_BASE_URL/morgue";
my $WEBTILES_BASE_URL = 'http://dev.berotato.org:8081/#watch-';

# Uniques that generate in D and/or Lair, excluding Sigmund and Rupert
my @BORING_UNIQUES = qw/Ijyb Jessica Terence Yiuf Blork Eustachio
                        Edmund Dowan Duvessa Pikel Grinder
                        Menkaure Ribbit Joseph Grum Psyche
                        Maurice Erica Fannar Harold Erolcha
                        Nergalle Urug Josephine Gastronok Sonja
                        Nessos Maud Purgy Snorg/;

my %GAME_TYPE_NAMES = (zot => 'ZotDef',
                       spr => 'Sprint');

my %COMMANDS = (
  '|whereis' => \&cmd_whereis,
  '|dump' => \&cmd_dump,
  '!dbro'     => \&cmd_players,
  '|players' => \&cmd_players,
  '|version' => \&cmd_version,
  '|watch' => \&cmd_watch,

#  '%??' => \&cmd_trunk_monsterinfo,
#  '%?' => \&cmd_monsterinfo,
);

if (defined $_[0] and $_[0] eq '-t') {
  shift;
} else {
  # Daemonify. http://www.webreference.com/perl/tutorial/9/3.html
  umask 0;
  defined(my $pid = fork) or die "Unable to fork: $!";
  exit if $pid;
  setsid or die "Unable to start a new session: $!";
  # Done daemonifying.
  if (open my $pf, '>', $pidfile) {
    print $pf "$$\n";
    close $pf;
  } else {
    warn "Unable to open $pidfile: $!";
  }
}

my @stonehandles = open_handles(@stonefiles);
my @loghandles = open_handles(@logfiles);
my @announcehandles = open_handles(@announcefiles);

if (open my $baduserhandle, "<", $baduserfile) {
  while (<$baduserhandle>) {
    chomp;
    push @badusers, qr/$_/i;
  }
  close $baduserhandle;
} else {
  warn "Cannot open $baduserfile: $!";
}

my $BOT = Gretell->new(nick     => $nickname,
                       server   => $ircserver,
                       port     => $port,
                       ircname  => $ircname,
                       channels => [ @CHANNELS ])
  or die "Unable to instantiate $nickname\n";

eval {
  $BOT->run();
};
unlink $pidfile or warn "Unable to delete pidfile: $!";
die $@ if $@;
exit 0;

sub open_handles
{
  my (@files) = @_;
  my @handles;

  for my $file (@files) {
    open my $handle, '<', $file or do {
      warn "Unable to open $file for reading: $!";
      next;
    };
    seek($handle, 0, 2); # EOF
    push @handles, [ $file, $handle, tell($handle) ];
  }
  return @handles;
}

sub game_place_branch($)
{
  my $g = shift;
  my $place = $$g{place};
  if ($place =~ /:/) {
    ($place) = $place =~ /(.*):/;
  }
  $place
}

sub milestone_is_uniq($) {
  my $g = shift;
  my $type = $$g{type} || '';
  return grep($type, qw/uniq unique/);
}

sub game_type($) {
  my $g = shift;
  my ($type) = ($$g{lv} || '') =~ /-(.*)/;
  $type = lc(substr($type, 0, 3)) if $type;
  $type
}

sub game_type_name($) {
  my $type = game_type(shift);
  $type && $GAME_TYPE_NAMES{$type}
}

sub game_is_sprint($) {
  (game_type(shift) || '') eq 'spr'
}

sub game_is_zotdef($) {
  (game_type(shift) || '') eq 'zot'
}

sub user_is_bad($) {
  my $name = shift;
  scalar grep { $name =~ /^$_$/ } @badusers;
}

sub newsworthy
{
  my $g = shift;

  return 0 if user_is_bad($g->{name});

  return 1;

  # Milestone type, empty if this is not a milestone.
  my $type = $$g{type} || '';
  my $br_enter = $type eq 'enter' || $type eq 'br.enter';
  my $place_branch = game_place_branch($g);

  return 0 if grep($_ eq $type, 'crash', 'monstrous', 'death', 'br.mid', 'br.exit', 'begin');

  return 0
    if $br_enter
      && grep($place_branch eq $_, qw/Temple Lair D Orc/);

  return 0
    if ($type eq 'br.end')
      && grep($place_branch eq $_, qw/Lair Orc/);

  if ($type eq 'zig') {
    my ($depth) = ($$g{milestone} || '') =~ /reached level (\d+)/;
    return 0 if $depth < 18 && $$g{xl} >= 27;
  }

  return 0
    if milestone_is_uniq($g) && grep(index($$g{milestone}, $_) != -1,
                                     @BORING_UNIQUES);

  # Suppress all Sprint/ZotDef events other than wins.
  return 0 if (game_type($g) && ($$g{ktyp} || '') ne 'winning');

  return 0
    if (!$$g{milestone}
        && ($g->{sc} <= 0
            && ($g->{ktyp} eq 'quitting'
                || $g->{ktyp} eq 'leaving'
                || $g->{turn} <= 1)));

  return 0;
}

sub devworthy
{
  my $g = shift;
  my $type = $$g{type} || '';
  return $type eq 'crash';
}

# Given an xlogfile hash, returns the place where the event occurred.
sub xlog_place
{
  my $g = shift;

  my $game_type_place_qualifier = game_type_name($g);
  my $place = $$g{oplace} || $$g{place};
  if ($game_type_place_qualifier) {
    $place = "$place ($game_type_place_qualifier)";
  }
  return $place;
}

sub raw_message_post {
  my ($m, $output) = @_;
  # Handle emotes (/me does foo)
  if ($output =~ m{^/me }) {
    $output =~ s{^/me }{};
    $BOT->emote(channel => $$m{channel},
                who => $$m{who},
                body => $output);
    return;
  }

  $BOT->say(channel => $$m{channel},
            who => $$m{who},
            body => $output);
}

sub report_milestone
{
  my $game_ref = shift;
  my $channel  = shift;

  my $place = xlog_place($game_ref);
  my $placestring = "";
  my $milestone = $$game_ref{milestone} || '';
  if ($milestone eq "reached level 27 of the Dungeon.")
  {
    $placestring = "";
  }

  post_message({ channel => $channel },
               sprintf("%s %s%s",
                       $game_ref->{name},
                       $milestone,
                       $placestring));
}

sub parse_milestone_file
{
  my $href = shift;
  my $stonehandle = $href->[1];
  $href->[2] = tell($stonehandle);

  my $line = <$stonehandle>;
  # If the line isn't complete, seek back to where we were and wait for it
  # to be done.
  if (!defined($line) || $line !~ /\n$/) {
    seek($stonehandle, $href->[2], 0);
    return;
  }
  $href->[2] = tell($stonehandle);
  return unless defined($line) && $line =~ /\S/;

  my $game_ref = demunge_xlogline($line);
  if ($game_ref) {
    report_milestone($game_ref, $ANNOUNCE_CHAN) if newsworthy($game_ref);
    report_milestone($game_ref, $DEV_CHAN) if devworthy($game_ref);
  }

  seek($stonehandle, $href->[2], 0);
}

sub parse_log_file
{
  my $href = shift;
  my $loghandle = $href->[1];

  $href->[2] = tell($loghandle);
  my $line = <$loghandle>;
  if (!defined($line) || $line !~ /\n$/) {
    seek($loghandle, $href->[2], 0);
    return;
  }
  $href->[2] = tell($loghandle);
  return unless defined($line) && $line =~ /\S/;

  my $game_ref = demunge_xlogline($line);
  if ($game_ref && newsworthy($game_ref)) {
    my $output = pretty_print($game_ref);
    $output =~ s/ on \d{4}-\d{2}-\d{2}//;
    post_message({ channel => $ANNOUNCE_CHAN }, $output);
  }
  seek($loghandle, $href->[2], 0);
}

sub parse_announce_file
{
  my $href = shift;
  my $announcehandle = $href->[1];

  $href->[2] = tell($announcehandle);
  my $line = <$announcehandle>;

  if (!defined($line) || $line !~ /\n$/) {
    seek($announcehandle, $href->[2], 0);
    return;
  }

  $href->[2] = tell($announcehandle);
  return unless defined($line) && $line =~ /\S/;

  post_message({ channel => $ANNOUNCE_CHAN }, $line);
  post_message({ channel => $DEV_CHAN }, $line);

  seek($announcehandle, $href->[2], 0);
}

sub check_stonefiles
{
  for my $stoneh (@stonehandles) {
    parse_milestone_file($stoneh);
  }
}

sub check_logfiles
{
  for my $logh (@loghandles) {
    parse_log_file($logh);
  }
}

sub check_announcefiles
{
  for my $announceh (@announcehandles) {
    parse_announce_file($announceh);
  }
}

sub check_files
{
  check_stonefiles();
  check_logfiles();
  check_announcefiles();
}

sub process_message {
  my $m = shift;
  my ($who, $channel, $verbatim) = @$m{qw/who channel body/};
  return unless $who && $channel && $verbatim;

  my $nick = get_nick($who) or return;
  my $command = get_command($verbatim) or return;

  process_command($m, $command, $nick, $verbatim);

  undef;
}

sub sanitise_nick {
  my $nick = shift;
  return unless $nick;
  $nick =~ tr/a-zA-Z_0-9-//cd;
  return $nick;
}

sub get_nick {
  my $nick = shift;
  return $nick? sanitise_nick($nick) : undef;
}

sub get_command {
  my $verbatim_input = shift;
  my ($command) = $verbatim_input =~ /^(\S+)/;
  return $command;
}

sub post_message($$) {
  my ($m, $output) = @_;

  my $private = $$m{channel} eq 'msg';

  # Hard limit on output size, regardless of whether this is PM or
  # public:
  $output = substr($output, 0, $MAX_PAGINATE_LENGTH) . "..."
    if length($output) > $MAX_PAGINATE_LENGTH;

  # On PM, send multiple lines of output instead of truncating.
  if ($private) {
    my $length = length($output);
    my $PAGE = $MAX_LENGTH;
    for (my $start = 0; $start < $length; $start += $PAGE) {
      if ($length - $start > $PAGE) {
        my $spcpos = rindex($output, ' ', $start + $PAGE - 1);
        if ($spcpos != -1 && $spcpos > $start) {
          raw_message_post($m, substr($output, $start, $spcpos - $start));
          $start = $spcpos + 1 - $PAGE;
          next;
        }
      }
      raw_message_post($m, substr($output, $start, $PAGE));
    }
  }
  else {
    $output = substr($output, 0, $MAX_LENGTH) . "..."
      if length($output) > $MAX_LENGTH;
    raw_message_post($m, $output);
  }
}

#######################################################################
# Commands

sub process_command($$$$) {
  my ($m, $command, $nick, $verbatim) = @_;

  if (substr($command, 0, 3) eq '@??') {
    $command = "@??";
  }
  elsif (substr($command, 0, 2) eq '@?') {
    $command = "@?";
  }

  my $proc = $COMMANDS{$command} or return;
  &$proc($m, $nick, $verbatim);
}

sub find_named_nick {
  my ($default, $command) = @_;
  $default = sanitise_nick($default);
  my $named = (split ' ', $command)[1] or return $default;
  return sanitise_nick($named) || $default;
}

sub make_shellsafe($) {
  my $thing = shift;
  # Toss out everything that might confuse the shell. Spaces are ok,
  # quotes are not.
  $thing =~ tr/a-zA-Z0-9_+ -//cd;
  return $thing;
}

sub cmd_trunk_monsterinfo {
  my ($m, $nick, $verbatim) = @_;
  my $monster_name = substr($verbatim, 3);
  my $monster_info = qx/monster-trunk \Q$monster_name\E/;
  post_message($m, $monster_info);
}

sub cmd_monsterinfo {
  my ($m, $nick, $verbatim) = @_;

  my $monster_name = substr($verbatim, 2);
  my $monster_info = `monster \Q$monster_name\E`;
  post_message($m, $monster_info);
}

sub get_crawl_version($) {
  my $branch = shift;
  $branch = "latest" if !defined($branch) or $branch =~ /^(?:git|trunk)$/;
  $branch =~ /^(?:0.[0-9]+|latest)$/ or return "bad branch";

  open my $vercmd, "-|", "$DGL_BINARY_DIR/crawl-$branch", "-version";
  while (<$vercmd>) {
    chomp;
    if (/Crawl version (.*)/) {
      close $vercmd;
      return $1;
    }
  }
  close $vercmd;
  return "not found"
}

sub cmd_version {
  my ($m, $nick, $verbatim) = @_;
  my @answers = ();

  for my $branch (qw(trunk 0.13)) {
    my $version = get_crawl_version($branch);
    push @answers, "$branch: $version";
  }

  post_message($m, join(";  ", @answers));
}

sub ttyrec_idle_time_seconds($) {
  my $filename = shift;
  my ($player, $ttyrec) = $filename =~ m{.*/([^:]+):(.*)$};
  $filename = "$DGL_TTYREC_DIR/$player/$ttyrec" if $player && $ttyrec;
  my $modtime = (stat $filename)[9];
  return time() - $modtime;
}

sub active_player_hash($$) {
  my ($player_name, $ttyrec_filename) = @_;
  return { player_name => $player_name,
           idle_seconds => ttyrec_idle_time_seconds($ttyrec_filename)
         };
}

sub find_active_players {
  my @player_where_list;
  find(sub {
         my $filename = $File::Find::name;
         if (-f $filename && $filename =~ /\.ttyrec$/) {
           my ($game_version, $player_name) =
             $filename =~ m{.*/([^/]+)/(.*?):};
           if ($game_version && $player_name) {
             push @player_where_list,
               active_player_hash($player_name, $filename);
           }
         }
       },
       $DGL_INPROGRESS_DIR);

  return @player_where_list;
}

sub compare_player_where_infos($$) {
  my ($wa, $wb) = @_;
  my $axl = $$wa{where}{xl} || 0;
  my $bxl = $$wb{where}{xl} || 0;
  return $axl != $bxl? $bxl - $axl :
         ($$wa{player_name} cmp $$wb{player_name});
}

sub sort_active_player_where_infos(@) {
  return sort { compare_player_where_infos($a, $b) } @_;
}

sub player_where_stats($) {
  my $wr = shift;
  return '' unless $wr;
  my $place = xlog_place($wr) || '';
  my $xl = $$wr{xl} || '';
  my $turn = $$wr{turn} || '';
  return "L$xl @ $place, T:$turn";
}

sub player_where_brief($) {
  my $wref = shift;
  my $extended = player_where_stats($$wref{where}) || '';
  $extended = " ($extended)" if $extended;
  return "$$wref{player_name}$extended";
}

sub get_active_players_line($) {
  my $check_not_idle = shift;
  my @active_players = find_active_players();
  # If the command wanted active players, toss the idle layabouts.
  if ($check_not_idle) {
    @active_players =
      grep($$_{idle_seconds} < $INACTIVE_IDLE_CEILING_SECONDS,
           @active_players);
  }
  for my $r_player_info_hash (@active_players) {
    player_whereis_add_info($r_player_info_hash);
  }
  my @sorted_players = sort_active_player_where_infos(@active_players);
  my $message = join(", ", map(player_where_brief($_), @sorted_players));
  unless ($message) {
    my $qualifier = $check_not_idle? "active " : "";
    $message = "No ${qualifier}players.";
  }
  return $message;
}

sub cmd_players {
  my ($m, $nick, $verbatim) = @_;
  my $check_not_idle = $verbatim =~ /-a/;
  my $message = get_active_players_line($check_not_idle);
  post_message($m, $message);
}

sub player_whereis_file($) {
  my $realnick = shift;
  my @crawldirs      = glob('/home/crawl-dev/crawl-dev/DGL/dgldir/');
  my @whereis_path   = map { "$_/morgue" } @crawldirs;

  my $where_file;
  my $final_where;

  for my $where_path (@whereis_path) {
    my @where_dir = glob("$where_path/$realnick*");
    my @where_files;
    if (@where_dir) {
      @where_files = glob("$where_dir[0]/$realnick.where*");
    }
    if (@where_files) {
      $where_file = $where_files[0];
      if (defined($final_where) && length($final_where) > 0) {
        if ((stat($final_where))[9] < (stat($where_file))[9]) {
          $final_where = $where_file;
        }
      }
      else {
        $final_where = $where_file;
      }
    }
  }
  undef $final_where unless defined($final_where) && length($final_where) > 0;
  return $final_where;
}

sub player_whereis_line($) {
  my $realnick = shift;
  my $where_file = player_whereis_file($realnick);

  return undef unless $where_file;

  open my $in, '<', $where_file or return undef;
  chomp( my $where = <$in> );
  close $in;

  return $where;
}

sub player_whereis_hash($) {
  my $nick = shift;
  my $line = player_whereis_line($nick);
  return $line ? demunge_xlogline($line) : undef;
}

sub player_whereis_add_info($) {
  my $phash = shift;
  $$phash{where} = player_whereis_hash($$phash{player_name});
}

sub cmd_whereis {
  my ($m, $nick, $verbatim) = @_;

  # Get the nick to act on.
  my $realnick = find_named_nick($nick, $verbatim);
  my $where = player_whereis_hash($realnick);
  unless ($where) {
    post_message($m, "No where information for $realnick.");
    return;
  }
  show_where_information($m, $where);
}

sub cmd_watch {
  my ($m, $nick, $verbatim) = @_;

  # Get the nick to act on.
  my $realnick = find_named_nick($nick, $verbatim);
  my $watch = player_active($realnick);

  unless ($watch) {
    post_message($m, "No current CBRO game for $realnick.");
    return;
  }
  post_message($m, "Watch $realnick at: " . $WEBTILES_BASE_URL . $realnick);
}

sub player_active($) {
  my $nick = shift;
  my $match = 0;

  find(sub {
         my $filename = $File::Find::name;
         if (-f $filename && $filename =~ /\/$nick.*ttyrec$/) {
           $match = 1;
         }
       },
       $DGL_INPROGRESS_DIR);

  return $match;
}

sub show_dump_file($$) {
  my ($m, $whereis_file) = @_;

  my ($player) =
    $whereis_file =~ m{/morgue/(\w+)/+\w+[.]where};

  my %GAME_WEB_MAPPINGS =
    ( 'crawl-0.10' => '0.10',
      'crawl-git' => 'trunk' );

  my $dump_file = "/home/crawl-dev/crawl-dev/DGL/dgldir/morgue/$player/$player.txt";

  unless (-f $dump_file) {
    post_message($m, "Can't find character dump for $player.");
    return;
  }

  post_message($m, "$MORGUE_BASE_URL/$player/$player.txt");
}

sub cmd_dump {
  my ($m, $nick, $verbatim) = @_;

  my $realnick = find_named_nick($nick, $verbatim);
  my $whereis_file = player_whereis_file($realnick);
  unless ($whereis_file) {
    post_message($m, "No where information for $realnick.");
    return;
  }
  show_dump_file($m, $whereis_file);
}

sub format_crawl_date {
  my $date = shift;
  return '' unless $date;
  my ($year, $mon, $day) = $date =~ /(.{4})(.{2})(.{2})/;
  return '' unless $year && $mon && $day;
  $mon++;
  return sprintf("%04d-%02d-%02d", $year, $mon, $day);
}

sub show_where_information($$) {
  my ($m, $wref) = @_;
  return unless $wref;

  my %wref = %$wref;

  my $place = xlog_place($wref);
  my $preposition = index($place, ':') != -1? " on" : " in";
  $place = "the $place" if $place =~ 'Abyss' || $place eq 'Temple';
  $place = " $place";

  my $punctuation = '.';
  my $date = ' on ' . format_crawl_date($wref{time});

  my $turn = " after $wref{turn} turns";
  chop $turn if $wref{turn} == 1;

  my $what = $wref{status};
  my $msg;
  if ($what eq 'active') {
    $what = 'is currently';
    $date = '';
  }
  elsif ($what eq 'won') {
    $punctuation = '!';
    $preposition = $place = '';
  }
  elsif ($what eq 'bailed out') {
    $what = 'got out of the dungeon alive';
    $preposition = $place = '';
  }
  $what = " $what";

  my $god = $wref{god}? ", a worshipper of $wref{god}," : "";
  unless ($msg) {
    $msg = "$wref{name} the $wref{title} (L$wref{xl} $wref{char})" .
           "$god$what$preposition$place$date$turn$punctuation";
  }
  post_message($m, $msg);
}

#######################################################################
# Imports

sub pretty_print
{
  my $game_ref = shift;

  my $loc_string = "";
  my $place = xlog_place($game_ref);
  if (exists $game_ref->{ltyp} && $game_ref->{ltyp} ne 'D' || $place !~ ':') {
    $loc_string = " in $place";
  }
  elsif ($game_ref->{br} eq 'blade' or $game_ref->{br} eq 'temple' or $game_ref->{br} eq 'hell') {
    $loc_string = " in $place";
  }
  else {
    $loc_string = " on $place";
  }
  $loc_string = "" # For escapes of the dungeon, so it doesn't print the loc
    if $game_ref->{ktyp} eq 'winning' or $game_ref->{ktyp} eq 'leaving';

  $game_ref->{end} =~ /^(\d{4})(\d{2})(\d{2})/;
  my $death_date = " on " . $1 . "-" . sprintf("%02d", $2 + 1) . "-" . $3;

  my $deathmsg = $game_ref->{vmsg} || $game_ref->{tmsg};
  $deathmsg =~ s/!$//;
  sprintf '%s the %s (L%d %s)%s, %s%s%s, with %d point%s after %d turn%s and %s.',
      $game_ref->{name},
      $game_ref->{title},
      $game_ref->{xl},
      $game_ref->{char},
      exists $game_ref->{god} ? ", worshipper of $game_ref->{god}" : '',
      $deathmsg,
      $loc_string,
      $death_date,
      $game_ref->{sc},
      $game_ref->{sc} == 1 ? '' : 's',
      $game_ref->{turn},
      $game_ref->{turn} == 1 ? '' : 's',
      serialize_time($game_ref->{dur})
}

sub demunge_xlogline
{
  my $line = shift;
  return {} if $line eq '';
  my %game;

  chomp $line;
  die "Unable to handle internal newlines." if $line =~ y/\n//;
  $line =~ s/::/\n\n/g;

  $game{milestone} = $line;
  return \%game;

  while ($line =~ /\G(\w+)=([^:]*)(?::(?=[^:])|$)/cg) {
    my ($key, $value) = ($1, $2);
    $value =~ s/\n\n/:/g;
    $game{$key} = $value;
  }

  if (!defined(pos($line)) || pos($line) != length($line)) {
    my $pos = defined(pos($line)) ? "Problem started at position " . pos($line) . "." : "Regex doesn't match.";
    return undef;
  }

  return \%game;
}

sub serialize_time
{
  my $seconds = int shift;
  my $long = shift;

  if (not $long) {
    my $hours = int($seconds/3600);
    $seconds %= 3600;
    my $minutes = int($seconds/60);
    $seconds %= 60;

    return sprintf "%d:%02d:%02d", $hours, $minutes, $seconds;
  }

  my $minutes = int($seconds / 60);
  $seconds %= 60;
  my $hours = int($minutes / 60);
  $minutes %= 60;
  my $days = int($hours / 24);
  $hours %= 24;
  my $weeks = int($days / 7);
  $days %= 7;
  my $years = int($weeks / 52);
  $weeks %= 52;

  my @fields;
  push @fields, "about ${years}y" if $years;
  push @fields, "${weeks}w"       if $weeks;
  push @fields, "${days}d"        if $days;
  push @fields, "${hours}h"       if $hours;
  push @fields, "${minutes}m"     if $minutes;
  push @fields, "${seconds}s"     if $seconds;

  return join ' ', @fields if @fields;
  return '0s';
}

package Gretell;
use base 'Bot::BasicBot';

sub connected {
  my $self = shift;

  open(my $handle, '<', '.password') or warn "Unable to read .password: $!";
  my $password = <$handle>;
  chomp $password;

  $self->say(channel => 'msg',
             who     => 'nickserv',
             body    => "identify $password");

  return undef;
}

sub said {
  my ($self, $m) = @_;
  main::process_message($m);
  return undef;
}

sub tick {
  main::check_files();
  return 1;
}

# Override BasicBot say since it tries to get clever with linebreaks.
sub say {
  # If we're called without an object ref, then we're handling saying
  # stuff from inside a forked subroutine, so we'll freeze it, and toss
  # it out on STDOUT so that POE::Wheel::Run's handler can pick it up.
  if ( !ref( $_[0] ) ) {
    print $_[0] . "\n";
    return 1;
  }

  # Otherwise, this is a standard object method

  my $self = shift;
  my $args;
  if (ref($_[0])) {
    $args = shift;
  } else {
    my %args = @_;
    $args = \%args;
  }

  my $body = $args->{body};

  # add the "Foo: bar" at the start
  $body = "$args->{who}: $body"
    if ( $args->{channel} ne "msg" and $args->{address} );

  # work out who we're going to send the message to
  my $who = ( $args->{channel} eq "msg" ) ? $args->{who} : $args->{channel};

  unless ( $who && $body ) {
    print STDERR "Can't PRIVMSG without target and body\n";
    print STDERR " called from ".([caller]->[0])." line ".([caller]->[2])."\n";
    print STDERR " who = '$who'\n body = '$body'\n";
    return;
  }

  my ($ewho, $ebody) = $self->charset_encode($who, $body);
  $self->privmsg($ewho, $ebody);
}
