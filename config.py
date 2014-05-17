import logging
try:
    from collections import OrderedDict
except ImportError:
    from ordereddict import OrderedDict

dgl_mode = True

bind_nonsecure = True # Set to false to only use SSL
bind_address = "192.73.239.18"

bind_port = 8081

#bind_pairs = (
#    ("192.73.239.18", 8080),
#    ("192.73.239.18", 8080),
#)

logging_config = {
    "filename": "%%CHROOT_WEBDIR%%/run/webtiles.log",
    "level": logging.INFO,
    "format": "%(asctime)s %(levelname)s: %(message)s"
}

password_db = "%%CHROOT_LOGIN_DB%%"

static_path = "%%CHROOT_WEBDIR%%/static"
template_path = "%%CHROOT_WEBDIR%%/templates/"

# Path for server-side unix sockets (to be used to communicate with crawl)
server_socket_path = None # Uses global temp dir

# Server name, so far only used in the ttyrec metadata
server_id = "dbro"

# Disable caching of game data files
game_data_no_cache = False

# Watch socket dirs for games not started by the server
watch_socket_dirs = True

# Game configs
# %n in paths and urls is replaced by the current username
# morgue_url is for a publicly available URL to access morgue_path
games = OrderedDict([

    ("dcss-farmer", dict(
        name = "DCSS farmer",
        crawl_binary = "/bin/crawl-stable-launcher.sh",
        pre_options  = [ "farmer" ],
        rcfile_path = "%%CHROOT_RCFILESDIR%%/crawl-farmer/",
        macro_path = "%%CHROOT_RCFILESDIR%%/crawl-farmer/",
        morgue_path = "%%CHROOT_MORGUEDIR%%/%n/",
        morgue_url = "http://crawl.berotato.org/crawl/dev/morgue/%n",
        inprogress_path = "%%CHROOT_INPROGRESSDIR%%/crawl-farmer/",
        ttyrec_path = "%%CHROOT_TTYRECDIR%%/%n/",
        socket_path = "%%CHROOT_WEBDIR%%/sockets")),

    ("dcss-helen", dict(
        name = "DCSS helen",
        crawl_binary = "/bin/crawl-stable-launcher.sh",
        pre_options  = [ "helen" ],
        rcfile_path = "%%CHROOT_RCFILESDIR%%/crawl-helen/",
        macro_path = "%%CHROOT_RCFILESDIR%%/crawl-helen/",
        morgue_path = "%%CHROOT_MORGUEDIR%%/%n/",
        morgue_url = "http://crawl.berotato.org/crawl/dev/morgue/%n",
        inprogress_path = "%%CHROOT_INPROGRESSDIR%%/crawl-helen/",
        ttyrec_path = "%%CHROOT_TTYRECDIR%%/%n/",
        socket_path = "%%CHROOT_WEBDIR%%/sockets")),

    ("dcss-potion_fun", dict(
        name = "DCSS potion_fun",
        crawl_binary = "/bin/crawl-stable-launcher.sh",
        pre_options  = [ "potion_fun" ],
        rcfile_path = "%%CHROOT_RCFILESDIR%%/crawl-potion_fun/",
        macro_path = "%%CHROOT_RCFILESDIR%%/crawl-potion_fun/",
        morgue_path = "%%CHROOT_MORGUEDIR%%/%n/",
        morgue_url = "http://crawl.berotato.org/crawl/dev/morgue/%n",
        inprogress_path = "%%CHROOT_INPROGRESSDIR%%/crawl-potion_fun/",
        ttyrec_path = "%%CHROOT_TTYRECDIR%%/%n/",
        socket_path = "%%CHROOT_WEBDIR%%/sockets")),
    
])

dgl_status_file = "%%CHROOT_WEBDIR%%/run/status"

# Set to None not to read milestones
milestone_file = "%%CHROOT_CRAWL_GAMEDIR%%/saves/milestones"

status_file_update_rate = 5

recording_term_size = (80, 24)

max_connections = 200

# Script to initialize a user, e.g. make sure the paths
# and the rc file exist. This is not done by the server
# at the moment.
init_player_program = "/bin/init-webtiles.sh"

ssl_options = None # No SSL
#ssl_options = {
#    "certfile": "/etc/ssl/private/s-z.org.crt",
#    "keyfile": "/etc/ssl/private/s-z.org.key",
#    "ca_certs": "/etc/ssl/private/cas.pem"
#}
#ssl_address = "192.73.239.18"
#ssl_port = 443

#ssl_bind_pairs = (
#    ("192.73.239.18", 443),
#    ("192.73.239.18", 443),
#)

connection_timeout = 600
max_idle_time = 5 * 60 * 60

# Seconds until stale HTTP connections are closed
# This needs a patch currently not in mainline tornado.
http_connection_timeout = 600

kill_timeout = 10 # Seconds until crawl is killed after HUP is sent

nick_regex = r"^[a-zA-Z0-9]{3,20}$"
max_passwd_length = 20

# crypt() algorithm, e.g. "1" for MD5 or "6" for SHA-512; see crypt(3).
# If false, use traditional DES (but then only the first eight characters
# are significant).
crypt_algorithm = "6"
# If crypt_algorithm is true, the length of the salt string to use.  If
# crypt_algorithm is false, a two-character salt is used.
crypt_salt_length = 16

login_token_lifetime = 7 # Days

uid = 1010  # If this is not None, the server will setuid to that (numeric) id
gid = 1011  # after binding its sockets.

umask = None # e.g. 0077

chroot = "%%DGL_CHROOT%%"

pidfile = "%%CHROOT_WEBDIR%%/run/webtiles.pid"
daemon = True # If true, the server will detach from the session after startup

player_url = "http://crawl.akrasiac.org/scoring/players/%s.html"

# Only for development:
# Automatically log in all users with the username given here.
autologin = None

