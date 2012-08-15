#! /usr/bin/perl
#
# Allows DGL admin users to download saves from CSZO's save dump directory.
#

use CGI qw/:standard/;
use MIME::Base64;

use DBI;

my $DB = "%%LOGIN_DB%%";
my $CONTENT_DIR = '%%SAVE_DUMPDIR%%/';

my $AUTH_REALM = 'CSZO save dump directory';

sub request_auth() {
  print(header(-type => 'text/html',
               -status => '401 Authorization Required',
               -WWW_Authenticate => "Basic realm=\"$AUTH_REALM\""),
        start_html('CSZO save dumps'),
        p('Must authenticate to access saves'),
        end_html);
  return undef;
}

sub match_password($$) {
  my ($plain, $crypt) = @_;
  my $cc = crypt($plain, $crypt);
  return crypt($plain, $crypt) eq $crypt;
}

sub valid_user($$) {
  my ($user, $password) = @_;
  my $db = DBI->connect("dbi:SQLite:dbname=$DB", '', '')
    or die "Can't open auth db: $DB\n";
  my $st = $db->prepare(<<QUERY);
SELECT username, password FROM dglusers
WHERE username=? AND (flags & 1) = 1;
QUERY
  $st->execute($user);
  my $row = $st->fetchrow_arrayref;

  # Should have at least one row.
  return defined($row) && match_password($password, $row->[1]);
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
  my ($file) = param('file');

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
