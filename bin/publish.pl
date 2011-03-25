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

sub overwrite_summary($@) {
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

  my @report;
  push @report, "$new new: @new" if $new;
  push @report, "$changed changed: @changed" if $changed;
  @report? join(', ', @report) : 'no change'
}

sub publishee_summary($) {
  my ($src, $dst) = @{$_[0]};

  my @files = glob($src);
  $dst = qualify_directory($dst);
  if (@files == 1 && $files[0] eq $src) {
    "$src -> $dst (" . overwrite_summary($dst, $src) . ")";
  } else {
    "$src (" . scalar(@files) . " files) -> $dst (" .
      overwrite_summary($dst, @files) . ")";
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

sub substitute_variable($$) {
  my ($file, $var) = @_;
  die "$file refers to unknown variable $var.\n" unless $ENV{$var};
  $ENV{$var}
}

sub substitute_variables($$) {
  my ($filename, $text) = @_;
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
    print(" [OK]\n");
  };
  if ($@) {
    print(" [ERR]\n\n");
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
summarize_publishees();
print "\n";

if ($< != 0) {
  warn "This script must be run as root\n";
  exit 1;
}

copy_targets(@COPY_TARGETS);
print "\nAll done.\n";
