#! /usr/bin/perl
#
# Allows DGL admin users to download saves from CAO's save dump directory.
#

use CGI qw/:standard/;
use MIME::Base64;

use DBI;

my $DB = "/var/lib/dgamelaunch/dgldir/dgamelaunch.db";
my $CONTENT_DIR = '/var/lib/dgamelaunch/dumps';

my $AUTH_REALM = 'CAO save dump directory';

sub request_auth() {
  print(header(-type => 'text/html',
               -status => '401 Authorization Required',
               -WWW_Authenticate => "Basic realm=\"$AUTH_REALM\""),
        start_html('CAO save dumps'),
        p('Must authenticate to access saves'),
        end_html);
  return undef;
}

sub hash_password($) {
  my $pw = shift;
  crypt($pw, substr($pw, 0, 2))
}

sub valid_user($$) {
  my ($user, $password) = @_;
  my $db = DBI->connect("dbi:SQLite:dbname=$DB", '', '')
    or die "Can't open auth db: $DB\n";
  my $st = $db->prepare(<<QUERY);
SELECT username FROM dglusers
WHERE username=? AND password=? AND (flags & 1) = 1;
QUERY
  $st->execute($user, hash_password($password));

  # Should have at least one row.
  $st->fetchrow_arrayref
}

sub valid_auth($) {
  my $header = shift;
  return unless $header =~ s/^Basic //;
  my $decoded = decode_base64($header);
  my ($user, $password) = $decoded =~ /(.*?):(.*)/;
  valid_user($user, $password)
}

sub authenticate() {
  my $auth_header = http('Authorization');
  return request_auth() unless $auth_header && valid_auth($auth_header);
  1
}

sub file_bytes($) {
  my $file = shift;
  open my $inf, '<', $file;
  binmode $inf;
  my $content = do { local $/; <$inf> };
  close $inf;
  $content
}

sub serve_file() {
  my $url = url(-path => 1);
  my ($file) = $url =~ m{.*/(.*)};

  my $absfile = "$CONTENT_DIR/$file";
  if ($file =~ /[.]{2}/ ||
      $file !~ /^[a-zA-Z0-9._-]+$/ ||
      $file !~ /\.(?:tar\.bz2|cs)$/ ||
      !-r $absfile)
  {
    print(header(-status => '404 Not Found'),
          start_html,
          p("Could not find $absfile"),
          end_html);
    return;
  }

  print(header(-type => 'application/octet-stream'),
        file_bytes($absfile));
}

sub main() {
  return unless authenticate();
  serve_file();
}

main();
