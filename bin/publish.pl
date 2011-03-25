#! /usr/bin/env perl

use strict;
use warnings;

use File::Copy;
use File::Path;

my $CHROOT = $ENV{DGL_CHROOT};
die "DGL chroot not specified in environment\n" unless $CHROOT;

my @COPY_TARGETS = ([ 'dgamelaunch.conf', '//etc' ],
                    [ 'chroot/data/menus/*.txt', "/dgldir/data/menus" ],
                    [ 'chroot/bin/*.sh', '/bin' ],
                    [ 'chroot/sbin/*.sh', '/sbin' ]);

sub publishee_summary($) {
  my ($src, $dst) = @{$_[0]};

  my @files = glob($src);
  $dst = qualify_directory($dst);
  if (@files == 1 && $files[0] eq $src) {
    "$src -> $CHROOT$dst";
  } else {
    "$src (" . scalar(@files) . " files) -> $CHROOT$dst";
  }
}

sub summarize_publishees() {
  my $index = 0;
  print "These are the publish copy targets:\n";
  for my $copy_target (@COPY_TARGETS) {
    ++$index;
    print("$index) " . publishee_summary($copy_target) . "\n");
  }
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
  system("cp @quoted_files \Q$dst")
    and die "Failed to copy @files -> $dst\n";
  print(" [OK]\n");
}

sub copy_targets(@) {
  print "Copying files:\n";
  for my $copy_target (@_) {
    copy_files($copy_target->[0], $copy_target->[1]);
  }
}

print "Publishing DGL config files:\n\n";
summarize_publishees();
print "\n";

if ($< != 0) {
  warn "This script must be run as root\n";
  exit 1;
}

copy_targets(@COPY_TARGETS);
print "\nAll done.\n";
