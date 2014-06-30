#! /usr/bin/env perl

use strict;
use warnings;

use File::Copy;
use File::Path;
use Cwd qw/abs_path/;
use Term::ANSIColor;
use Getopt::Long;

use lib "$ENV{DGL_CONF_HOME}/lib";
use DGLMan;

my %OPT;
GetOptions(\%OPT, "match=s", "skip=s", "confirm", "target=s")
  or die "Bad command line: @ARGV\n";

my $CHROOT = $ENV{DGL_CHROOT};
die "DGL chroot not specified in environment\n" unless $CHROOT;

my @COPY_TARGETS = ([ 'dgamelaunch-dev.conf', '//etc' ],
                    [ 'utils/auth-save-downloader-dev.pl', '//usr/lib/cgi-bin' ],
                    [ 'utils/trigger-rebuild-dev.pl', '//usr/lib/cgi-bin' ],
                    [ 'utils/webtiles-dev', '//etc/init.d' ],
                    [ 'config.py', "/crawl-master/webserver" ],
                    [ 'config.json', "/crawl-master/webserver" ],
                    [ 'chroot/data/menus/*.txt', "/dgldir/data/menus" ],
                    [ 'chroot/data/*.{rc,macro}', "/dgldir/data" ],
                    [ 'chroot/bin/*.sh', '/bin' ],
                    [ 'dwizzell.pl', "/dfdir/" ],
                    [ 'chroot/sbin/*.sh', '/sbin' ]);

if ($OPT{match}) {
  @COPY_TARGETS = grep($$_[0] =~ /\Q$OPT{match}/, @COPY_TARGETS);
}
if ($OPT{skip}) {
  @COPY_TARGETS = grep($$_[0] !~ /\Q$OPT{skip}/, @COPY_TARGETS);
}
if ($OPT{target}) {
  die "--target specified, but more than one file to publish\n"
    if @COPY_TARGETS > 1;
  $COPY_TARGETS[0][1] = $OPT{target};
}

sub change_stat($@) {
  my ($dst, @src) = @_;

  my $changed = 0;
  my @changed;

  my $new = 0;
  my @new;

  for my $file (@src) {
    my $target = target_file($dst, $file);
    if (-l $target) {
      return "ERR: $target is a symlink";
    }

    my $src_text = source_file_text($file);

    if (-f $target) {
      my $dst_text = file_text($target);
      if ($src_text ne $dst_text) {
        ++$changed;
        push @changed, basename($target);
      }
    } else {
      ++$new;
      push @new, basename($file);
    }
  }

  return { new => \@new,
           changed => \@changed };
}

sub change_exists($) {
  my $stat = shift;
  return @{$$stat{new}} || @{$$stat{changed}};
}

sub change_summary($) {
  my $stat = shift;
  my @report;
  my @new = @{$$stat{new}};
  my @changed = @{$$stat{changed}};
  my $new = scalar(@new);
  my $changed = scalar(@changed);
  push @report, neutral_text("$new new: @new") if @new;
  push @report, neutral_text("$changed changed: @changed") if @changed;
  @report? join(', ', @report) : 'no change'
}

sub publishee_summary($) {
  my ($src, $dst) = @{$_[0]};

  my @files = glob($src);
  $dst = qualify_directory($dst);

  my $change_stat = change_stat($dst, @files);
  if (@files == 1 && $files[0] eq $src) {
    ("$src -> $dst (" . change_summary($change_stat) . ")",
     $change_stat)
  } else {
    ("$src (" . scalar(@files) . " files) -> $dst (" .
      change_summary($change_stat) . ")",
     $change_stat)
  }
}

sub summarize_publishees() {
  my $index = 0;
  print "These are the publish copy targets:\n";
  my $dirty;
  for my $copy_target (@COPY_TARGETS) {
    ++$index;
    my ($summary, $stat) = publishee_summary($copy_target);
    print("$index) $summary\n");
    $dirty = 1 if change_exists($stat);
  }
  $dirty
}

my $copy_count = 0;
sub nth_copy() {
  ++$copy_count . ") ";
}

sub qualify_directory($) {
  my $dir = shift;
  if ($dir =~ m{^//}) {
    $dir =~ s{^/}{};
    $dir
  } else {
    "$CHROOT$dir"
  }
}

sub substitute_variable($$) {
  my ($file, $var) = @_;
  die "$file refers to unknown variable $var.\n" unless $ENV{$var};
  $ENV{$var}
}

sub file_needs_banner($) {
  my $filename = shift;
  $filename =~ /(?:dgamelaunch-dev\.conf|\.sh|\.pl)$/
}

sub file_banner($) {
  my $filename = shift;
  my $basename = basename($filename);

  my $source_file = abs_path($filename);

  return <<BANNER;
#############################################################################
#
# WARNING!  AUTO-GENERATED FILE, DO NOT EDIT.
#
# This file ($basename) is automatically generated from $source_file.
#
# Do NOT edit this file; edit $source_file instead, and
# use `dgl publish` to publish your changes.
#
#############################################################################
BANNER
}

sub file_add_banner($$) {
  my ($filename, $text) = @_;
  if ($text =~ /^#!.*\n/) {
    $text =~ s/(^#!.*\n)/$1 . file_banner($filename)/e;
  } else {
    $text =~ s/^/file_banner($filename)/e;
  }
  $text
}

sub substitute_variables($$) {
  my ($filename, $text) = @_;

  $text = file_add_banner($filename, $text) if file_needs_banner($filename);
  $text =~ s/%%(\w+)%%/ substitute_variable($filename, $1) /ge;
  $text
}

sub basename($) {
  my $file = shift;
  my ($basename) = $file =~ m{.*/(.*)};
  $basename || $file
}

sub target_file($$) {
  my ($dst, $src) = @_;
  my $basename = basename($src);
  "$dst/$basename"
}

sub file_text($) {
  my $source_file = shift;

  open my $inf, '<', $source_file or die "Can't read $source_file: $!\n";
  binmode $inf;
  my $text = do { local $/; <$inf> };
  close $inf;

  $text
}

sub source_file_text($) {
  my $source_file = shift;
  substitute_variables($source_file, file_text($source_file))
}

sub copy_file($$) {
  my ($source_file, $dst) = @_;
  my $target_file = target_file($dst, $source_file);

  if (-l $target_file) {
    die "Can't copy $source_file -> $target_file: destination is a symlink\n";
  }

  my $text = source_file_text($source_file);

  my $target_tmp = "$target_file.tmp";
  open my $outf, '>', $target_tmp or die "Can't write $target_tmp: $!\n";
  print $outf $text;
  close $outf;

  if (-x $source_file) {
    chmod 0755, $target_tmp or
      die "Couldn't +x $target_tmp when copying $source_file -> $dst" ;
  }

  rename $target_tmp, $target_file or
    die "Couldn't copy $source_file -> $target_file\n";
}

sub copy_files($$) {
  my ($src, $dst) = @_;
  my @files = glob($src);
  if (!@files) {
    die "Can't find files to copy for $src\n";
  }
  $dst = qualify_directory($dst);
  if (!-d($dst)) {
    mkpath($dst) or die "Couldn't create $dst\n";
  }

  my @quoted_files = map("\Q$_", @files);
  print(nth_copy() . "@files -> $dst ");

  eval {
    for my $file (@files) {
      copy_file($file, $dst) or
        die "Failed to copy $file -> $dst: $!\n";
    }
    say_good(" [OK]\n");
  };
  if ($@) {
    say_bad(" [ERR]\n\n");
    die $@;
  }
}

sub copy_targets(@) {
  print "Copying files:\n";
  for my $copy_target (@_) {
    copy_files($copy_target->[0], $copy_target->[1]);
  }
}

print "Publishing DGL config files:\n\n";
my $dirty = summarize_publishees();
print "\n";

my $want_publish = $OPT{confirm};
if (!$want_publish) {
  if ($dirty) {
    warn <<PUBLISH_HOWTO;
To publish the new dgl config, run this command as root:

  @{ [ emphasized_text('dgl publish --confirm') ] }

PUBLISH_HOWTO
  }
  else {
    say_coloured('bold green', <<INSYNC);
DGL config is in sync.
INSYNC
  }
  exit 0;
}

if ($< != 0) {
  print STDERR "** This script must be run as root to publish changes **\n";
  exit 1;
}

copy_targets(@COPY_TARGETS);
print "\nAll done.\n";
