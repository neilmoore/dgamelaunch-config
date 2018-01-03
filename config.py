import logging
try:
    from collections import OrderedDict
except ImportError:
    from ordereddict import OrderedDict

dgl_mode = True

bind_nonsecure = True # Set to false to only use SSL
bind_address = "192.73.239.18"

bind_port = 8080

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
server_id = "cbro"

# Disable caching of game data files
game_data_no_cache = False

# Watch socket dirs for games not started by the server
watch_socket_dirs = True

# Game configs
# %n in paths is replaced by the current username
games = OrderedDict([
    ("dcss-git", dict(
        name = "DCSS trunk",
        crawl_binary = "/bin/crawl-git-launcher.sh",
        send_json_options = True,
        rcfile_path = "%%CHROOT_RCFILESDIR%%/crawl-git/",
        macro_path = "%%CHROOT_RCFILESDIR%%/crawl-git/",
        morgue_path = "%%CHROOT_MORGUEDIR%%/%n/",
        morgue_url = "%%CHROOT_MORGUE_URL%%/%n/",
	inprogress_path = "%%CHROOT_INPROGRESSDIR%%/crawl-git/",
        ttyrec_path = "%%CHROOT_TTYRECDIR%%/%n/",
        socket_path = "%%CHROOT_WEBDIR%%/sockets")),
    ("spr-git", dict(
        name = "Sprint trunk",
        crawl_binary = "/bin/crawl-git-launcher.sh",
        send_json_options = True,
        rcfile_path = "%%CHROOT_RCFILESDIR%%/crawl-git/",
        macro_path = "%%CHROOT_RCFILESDIR%%/crawl-git/",
        morgue_path = "%%CHROOT_MORGUEDIR%%/%n/",
        morgue_url = "%%CHROOT_MORGUE_URL%%/%n/",
        inprogress_path = "%%CHROOT_INPROGRESSDIR%%/crawl-git-sprint/",
        ttyrec_path = "%%CHROOT_TTYRECDIR%%/%n/",
        socket_path = "%%CHROOT_WEBDIR%%/sockets",
        options = ["-sprint"])),
    ("tut-git", dict(
        name = "Tutorial trunk",
        crawl_binary = "/bin/crawl-git-launcher.sh",
        send_json_options = True,
        rcfile_path = "%%CHROOT_RCFILESDIR%%/crawl-git/",
        macro_path = "%%CHROOT_RCFILESDIR%%/crawl-git/",
        morgue_path = "%%CHROOT_MORGUEDIR%%/%n/",
        morgue_url = "%%CHROOT_MORGUE_URL%%/%n/",
        inprogress_path = "%%CHROOT_INPROGRESSDIR%%/crawl-git-tut/",
        ttyrec_path = "%%CHROOT_TTYRECDIR%%/%n/",
        socket_path = "%%CHROOT_WEBDIR%%/sockets",
        options = ["-tutorial"])),
 
    ("dcss-0.21", dict(
        name = "DCSS 0.21 (Tournament Version!)",
        crawl_binary = "/bin/crawl-stable-launcher.sh",
        pre_options  = [ "0.21" ],
        rcfile_path = "%%CHROOT_RCFILESDIR%%/crawl-0.21/",
        macro_path = "%%CHROOT_RCFILESDIR%%/crawl-0.21/",
        morgue_path = "%%CHROOT_MORGUEDIR%%/%n/",
        morgue_url = "%%CHROOT_MORGUE_URL%%/%n/",
        inprogress_path = "%%CHROOT_INPROGRESSDIR%%/crawl-21/",
        ttyrec_path = "%%CHROOT_TTYRECDIR%%/%n/",
        socket_path = "%%CHROOT_WEBDIR%%/sockets")),
    ("spr-0.21", dict(
        name = "Sprint 0.21",
        crawl_binary = "/bin/crawl-stable-launcher.sh",
        pre_options  = [ "0.21" ],
        rcfile_path = "%%CHROOT_RCFILESDIR%%/crawl-0.21/",
        macro_path = "%%CHROOT_RCFILESDIR%%/crawl-0.21/",
        morgue_path = "%%CHROOT_MORGUEDIR%%/%n/",
        morgue_url = "%%CHROOT_MORGUE_URL%%/%n/",
        inprogress_path = "%%CHROOT_INPROGRESSDIR%%/crawl-21-sprint/",
        ttyrec_path = "%%CHROOT_TTYRECDIR%%/%n/",
        socket_path = "%%CHROOT_WEBDIR%%/sockets",
        options = ["-sprint"])),
    ("tut-0.21", dict(
        name = "Tutorial 0.21",
        crawl_binary = "/bin/crawl-stable-launcher.sh",
        pre_options  = [ "0.21" ],
        rcfile_path = "%%CHROOT_RCFILESDIR%%/crawl-0.21/",
        macro_path = "%%CHROOT_RCFILESDIR%%/crawl-0.21/",
        morgue_path = "%%CHROOT_MORGUEDIR%%/%n/",
        morgue_url = "%%CHROOT_MORGUE_URL%%/%n/",
        inprogress_path = "%%CHROOT_INPROGRESSDIR%%/crawl-21-tut/",
        ttyrec_path = "%%CHROOT_TTYRECDIR%%/%n/",
        socket_path = "%%CHROOT_WEBDIR%%/sockets",
        options = ["-tutorial"])),
 
    ("dcss-0.20", dict(
        name = "DCSS 0.20",
        crawl_binary = "/bin/crawl-stable-launcher.sh",
        pre_options  = [ "0.20" ],
        rcfile_path = "%%CHROOT_RCFILESDIR%%/crawl-0.20/",
        macro_path = "%%CHROOT_RCFILESDIR%%/crawl-0.20/",
        morgue_path = "%%CHROOT_MORGUEDIR%%/%n/",
        morgue_url = "%%CHROOT_MORGUE_URL%%/%n/",
        inprogress_path = "%%CHROOT_INPROGRESSDIR%%/crawl-20/",
        ttyrec_path = "%%CHROOT_TTYRECDIR%%/%n/",
        socket_path = "%%CHROOT_WEBDIR%%/sockets")),
    ("spr-0.20", dict(
        name = "Sprint 0.20",
        crawl_binary = "/bin/crawl-stable-launcher.sh",
        pre_options  = [ "0.20" ],
        rcfile_path = "%%CHROOT_RCFILESDIR%%/crawl-0.20/",
        macro_path = "%%CHROOT_RCFILESDIR%%/crawl-0.20/",
        morgue_path = "%%CHROOT_MORGUEDIR%%/%n/",
        morgue_url = "%%CHROOT_MORGUE_URL%%/%n/",
        inprogress_path = "%%CHROOT_INPROGRESSDIR%%/crawl-20-sprint/",
        ttyrec_path = "%%CHROOT_TTYRECDIR%%/%n/",
        socket_path = "%%CHROOT_WEBDIR%%/sockets",
        options = ["-sprint"])),
    ("tut-0.20", dict(
        name = "Tutorial 0.20",
        crawl_binary = "/bin/crawl-stable-launcher.sh",
        pre_options  = [ "0.20" ],
        rcfile_path = "%%CHROOT_RCFILESDIR%%/crawl-0.20/",
        macro_path = "%%CHROOT_RCFILESDIR%%/crawl-0.20/",
        morgue_path = "%%CHROOT_MORGUEDIR%%/%n/",
        morgue_url = "%%CHROOT_MORGUE_URL%%/%n/",
        inprogress_path = "%%CHROOT_INPROGRESSDIR%%/crawl-20-tut/",
        ttyrec_path = "%%CHROOT_TTYRECDIR%%/%n/",
        socket_path = "%%CHROOT_WEBDIR%%/sockets",
        options = ["-tutorial"])),
 
    ("dcss-0.19", dict(
        name = "DCSS 0.19",
        crawl_binary = "/bin/crawl-stable-launcher.sh",
        pre_options  = [ "0.19" ],
        rcfile_path = "%%CHROOT_RCFILESDIR%%/crawl-0.19/",
        macro_path = "%%CHROOT_RCFILESDIR%%/crawl-0.19/",
        morgue_path = "%%CHROOT_MORGUEDIR%%/%n/",
        morgue_url = "%%CHROOT_MORGUE_URL%%/%n/",
        inprogress_path = "%%CHROOT_INPROGRESSDIR%%/crawl-19/",
        ttyrec_path = "%%CHROOT_TTYRECDIR%%/%n/",
        socket_path = "%%CHROOT_WEBDIR%%/sockets")),
    ("spr-0.19", dict(
        name = "Sprint 0.19",
        crawl_binary = "/bin/crawl-stable-launcher.sh",
        pre_options  = [ "0.19" ],
        rcfile_path = "%%CHROOT_RCFILESDIR%%/crawl-0.19/",
        macro_path = "%%CHROOT_RCFILESDIR%%/crawl-0.19/",
        morgue_path = "%%CHROOT_MORGUEDIR%%/%n/",
        morgue_url = "%%CHROOT_MORGUE_URL%%/%n/",
        inprogress_path = "%%CHROOT_INPROGRESSDIR%%/crawl-19-sprint/",
        ttyrec_path = "%%CHROOT_TTYRECDIR%%/%n/",
        socket_path = "%%CHROOT_WEBDIR%%/sockets",
        options = ["-sprint"])),
    ("tut-0.19", dict(
        name = "Tutorial 0.19",
        crawl_binary = "/bin/crawl-stable-launcher.sh",
        pre_options  = [ "0.19" ],
        rcfile_path = "%%CHROOT_RCFILESDIR%%/crawl-0.19/",
        macro_path = "%%CHROOT_RCFILESDIR%%/crawl-0.19/",
        morgue_path = "%%CHROOT_MORGUEDIR%%/%n/",
        morgue_url = "%%CHROOT_MORGUE_URL%%/%n/",
        inprogress_path = "%%CHROOT_INPROGRESSDIR%%/crawl-19-tut/",
        ttyrec_path = "%%CHROOT_TTYRECDIR%%/%n/",
        socket_path = "%%CHROOT_WEBDIR%%/sockets",
        options = ["-tutorial"])),
 
    ("dcss-0.18", dict(
        name = "DCSS 0.18 ",
        crawl_binary = "/bin/crawl-stable-launcher.sh",
        pre_options  = [ "0.18" ],
        rcfile_path = "%%CHROOT_RCFILESDIR%%/crawl-0.18/",
        macro_path = "%%CHROOT_RCFILESDIR%%/crawl-0.18/",
        morgue_path = "%%CHROOT_MORGUEDIR%%/%n/",
        morgue_url = "%%CHROOT_MORGUE_URL%%/%n/",
        inprogress_path = "%%CHROOT_INPROGRESSDIR%%/crawl-18/",
        ttyrec_path = "%%CHROOT_TTYRECDIR%%/%n/",
        socket_path = "%%CHROOT_WEBDIR%%/sockets")),
    ("spr-0.18", dict(
        name = "Sprint 0.18",
        crawl_binary = "/bin/crawl-stable-launcher.sh",
        pre_options  = [ "0.18" ],
        rcfile_path = "%%CHROOT_RCFILESDIR%%/crawl-0.18/",
        macro_path = "%%CHROOT_RCFILESDIR%%/crawl-0.18/",
        morgue_path = "%%CHROOT_MORGUEDIR%%/%n/",
        morgue_url = "%%CHROOT_MORGUE_URL%%/%n/",
        inprogress_path = "%%CHROOT_INPROGRESSDIR%%/crawl-18-sprint/",
        ttyrec_path = "%%CHROOT_TTYRECDIR%%/%n/",
        socket_path = "%%CHROOT_WEBDIR%%/sockets",
        options = ["-sprint"])),
    ("tut-0.18", dict(
        name = "Tutorial 0.18",
        crawl_binary = "/bin/crawl-stable-launcher.sh",
        pre_options  = [ "0.18" ],
        rcfile_path = "%%CHROOT_RCFILESDIR%%/crawl-0.18/",
        macro_path = "%%CHROOT_RCFILESDIR%%/crawl-0.18/",
        morgue_path = "%%CHROOT_MORGUEDIR%%/%n/",
        morgue_url = "%%CHROOT_MORGUE_URL%%/%n/",
        inprogress_path = "%%CHROOT_INPROGRESSDIR%%/crawl-18-tut/",
        ttyrec_path = "%%CHROOT_TTYRECDIR%%/%n/",
        socket_path = "%%CHROOT_WEBDIR%%/sockets",
        options = ["-tutorial"])),
 
    ("dcss-0.17", dict(
        name = "DCSS 0.17",
        crawl_binary = "/bin/crawl-stable-launcher.sh",
        pre_options  = [ "0.17" ],
        rcfile_path = "%%CHROOT_RCFILESDIR%%/crawl-0.17/",
        macro_path = "%%CHROOT_RCFILESDIR%%/crawl-0.17/",
        morgue_path = "%%CHROOT_MORGUEDIR%%/%n/",
        morgue_url = "%%CHROOT_MORGUE_URL%%/%n/",
        inprogress_path = "%%CHROOT_INPROGRESSDIR%%/crawl-17/",
        ttyrec_path = "%%CHROOT_TTYRECDIR%%/%n/",
        socket_path = "%%CHROOT_WEBDIR%%/sockets")),
    ("spr-0.17", dict(
        name = "Sprint 0.17",
        crawl_binary = "/bin/crawl-stable-launcher.sh",
        pre_options  = [ "0.17" ],
        rcfile_path = "%%CHROOT_RCFILESDIR%%/crawl-0.17/",
        macro_path = "%%CHROOT_RCFILESDIR%%/crawl-0.17/",
        morgue_path = "%%CHROOT_MORGUEDIR%%/%n/",
        morgue_url = "%%CHROOT_MORGUE_URL%%/%n/",
        inprogress_path = "%%CHROOT_INPROGRESSDIR%%/crawl-17-sprint/",
        ttyrec_path = "%%CHROOT_TTYRECDIR%%/%n/",
        socket_path = "%%CHROOT_WEBDIR%%/sockets",
        options = ["-sprint"])),
    ("tut-0.17", dict(
        name = "Tutorial 0.17",
        crawl_binary = "/bin/crawl-stable-launcher.sh",
        pre_options  = [ "0.17" ],
        rcfile_path = "%%CHROOT_RCFILESDIR%%/crawl-0.17/",
        macro_path = "%%CHROOT_RCFILESDIR%%/crawl-0.17/",
        morgue_path = "%%CHROOT_MORGUEDIR%%/%n/",
        morgue_url = "%%CHROOT_MORGUE_URL%%/%n/",
        inprogress_path = "%%CHROOT_INPROGRESSDIR%%/crawl-17-tut/",
        ttyrec_path = "%%CHROOT_TTYRECDIR%%/%n/",
        socket_path = "%%CHROOT_WEBDIR%%/sockets",
        options = ["-tutorial"])),

    ("dcss-0.16", dict(
        name = "DCSS 0.16",
        crawl_binary = "/bin/crawl-stable-launcher.sh",
        pre_options  = [ "0.16" ],
        rcfile_path = "%%CHROOT_RCFILESDIR%%/crawl-0.16/",
        macro_path = "%%CHROOT_RCFILESDIR%%/crawl-0.16/",
        morgue_path = "%%CHROOT_MORGUEDIR%%/%n/",
        morgue_url = "%%CHROOT_MORGUE_URL%%/%n/",
        inprogress_path = "%%CHROOT_INPROGRESSDIR%%/crawl-16/",
        ttyrec_path = "%%CHROOT_TTYRECDIR%%/%n/",
        socket_path = "%%CHROOT_WEBDIR%%/sockets")),
    ("spr-0.16", dict(
        name = "Sprint 0.16",
        crawl_binary = "/bin/crawl-stable-launcher.sh",
        pre_options  = [ "0.16" ],
        rcfile_path = "%%CHROOT_RCFILESDIR%%/crawl-0.16/",
        macro_path = "%%CHROOT_RCFILESDIR%%/crawl-0.16/",
        morgue_path = "%%CHROOT_MORGUEDIR%%/%n/",
        morgue_url = "%%CHROOT_MORGUE_URL%%/%n/",
        inprogress_path = "%%CHROOT_INPROGRESSDIR%%/crawl-16-sprint/",
        ttyrec_path = "%%CHROOT_TTYRECDIR%%/%n/",
        socket_path = "%%CHROOT_WEBDIR%%/sockets",
        options = ["-sprint"])),
    ("tut-0.16", dict(
        name = "Tutorial 0.16",
        crawl_binary = "/bin/crawl-stable-launcher.sh",
        pre_options  = [ "0.16" ],
        rcfile_path = "%%CHROOT_RCFILESDIR%%/crawl-0.16/",
        macro_path = "%%CHROOT_RCFILESDIR%%/crawl-0.16/",
        morgue_path = "%%CHROOT_MORGUEDIR%%/%n/",
        morgue_url = "%%CHROOT_MORGUE_URL%%/%n/",
        inprogress_path = "%%CHROOT_INPROGRESSDIR%%/crawl-16-tut/",
        ttyrec_path = "%%CHROOT_TTYRECDIR%%/%n/",
        socket_path = "%%CHROOT_WEBDIR%%/sockets",
        options = ["-tutorial"])),

    ("dcss-0.15", dict(
        name = "DCSS 0.15",
        crawl_binary = "/bin/crawl-stable-launcher.sh",
        pre_options  = [ "0.15" ],
        rcfile_path = "%%CHROOT_RCFILESDIR%%/crawl-0.15/",
        macro_path = "%%CHROOT_RCFILESDIR%%/crawl-0.15/",
        morgue_path = "%%CHROOT_MORGUEDIR%%/%n/",
        morgue_url = "%%CHROOT_MORGUE_URL%%/%n/",
        inprogress_path = "%%CHROOT_INPROGRESSDIR%%/crawl-15/",
        ttyrec_path = "%%CHROOT_TTYRECDIR%%/%n/",
        socket_path = "%%CHROOT_WEBDIR%%/sockets")),
    ("spr-0.15", dict(
        name = "Sprint 0.15",
        crawl_binary = "/bin/crawl-stable-launcher.sh",
        pre_options  = [ "0.15" ],
        rcfile_path = "%%CHROOT_RCFILESDIR%%/crawl-0.15/",
        macro_path = "%%CHROOT_RCFILESDIR%%/crawl-0.15/",
        morgue_path = "%%CHROOT_MORGUEDIR%%/%n/",
        morgue_url = "%%CHROOT_MORGUE_URL%%/%n/",
        inprogress_path = "%%CHROOT_INPROGRESSDIR%%/crawl-15-sprint/",
        ttyrec_path = "%%CHROOT_TTYRECDIR%%/%n/",
        socket_path = "%%CHROOT_WEBDIR%%/sockets",
        options = ["-sprint"])),
    ("zd-0.15", dict(
        name = "Zot Defence 0.15",
        crawl_binary = "/bin/crawl-stable-launcher.sh",
        pre_options  = [ "0.15" ],
        rcfile_path = "%%CHROOT_RCFILESDIR%%/crawl-0.15/",
        macro_path = "%%CHROOT_RCFILESDIR%%/crawl-0.15/",
        morgue_path = "%%CHROOT_MORGUEDIR%%/%n/",
        morgue_url = "%%CHROOT_MORGUE_URL%%/%n/",
        inprogress_path = "%%CHROOT_INPROGRESSDIR%%/crawl-15-zotdef/",
        ttyrec_path = "%%CHROOT_TTYRECDIR%%/%n/",
        socket_path = "%%CHROOT_WEBDIR%%/sockets",
        options = ["-zotdef"])),
    ("tut-0.15", dict(
        name = "Tutorial 0.15",
        crawl_binary = "/bin/crawl-stable-launcher.sh",
        pre_options  = [ "0.15" ],
        rcfile_path = "%%CHROOT_RCFILESDIR%%/crawl-0.15/",
        macro_path = "%%CHROOT_RCFILESDIR%%/crawl-0.15/",
        morgue_path = "%%CHROOT_MORGUEDIR%%/%n/",
        morgue_url = "%%CHROOT_MORGUE_URL%%/%n/",
        inprogress_path = "%%CHROOT_INPROGRESSDIR%%/crawl-15-tut/",
        ttyrec_path = "%%CHROOT_TTYRECDIR%%/%n/",
        socket_path = "%%CHROOT_WEBDIR%%/sockets",
        options = ["-tutorial"])),

    ("dcss-0.14", dict(
        name = "DCSS 0.14",
        crawl_binary = "/bin/crawl-stable-launcher.sh",
        pre_options  = [ "0.14" ],
        rcfile_path = "%%CHROOT_RCFILESDIR%%/crawl-0.14/",
        macro_path = "%%CHROOT_RCFILESDIR%%/crawl-0.14/",
        morgue_path = "%%CHROOT_MORGUEDIR%%/%n/",
        morgue_url = "%%CHROOT_MORGUE_URL%%/%n/",
        inprogress_path = "%%CHROOT_INPROGRESSDIR%%/crawl-14/",
        ttyrec_path = "%%CHROOT_TTYRECDIR%%/%n/",
        socket_path = "%%CHROOT_WEBDIR%%/sockets")),
    ("spr-0.14", dict(
        name = "Sprint 0.14",
        crawl_binary = "/bin/crawl-stable-launcher.sh",
        pre_options  = [ "0.14" ],
        rcfile_path = "%%CHROOT_RCFILESDIR%%/crawl-0.14/",
        macro_path = "%%CHROOT_RCFILESDIR%%/crawl-0.14/",
        morgue_path = "%%CHROOT_MORGUEDIR%%/%n/",
        morgue_url = "%%CHROOT_MORGUE_URL%%/%n/",
        inprogress_path = "%%CHROOT_INPROGRESSDIR%%/crawl-14-sprint/",
        ttyrec_path = "%%CHROOT_TTYRECDIR%%/%n/",
        socket_path = "%%CHROOT_WEBDIR%%/sockets",
        options = ["-sprint"])),
    ("zd-0.14", dict(
        name = "Zot Defence 0.14",
        crawl_binary = "/bin/crawl-stable-launcher.sh",
        pre_options  = [ "0.14" ],
        rcfile_path = "%%CHROOT_RCFILESDIR%%/crawl-0.14/",
        macro_path = "%%CHROOT_RCFILESDIR%%/crawl-0.14/",
        morgue_path = "%%CHROOT_MORGUEDIR%%/%n/",
        morgue_url = "%%CHROOT_MORGUE_URL%%/%n/",
        inprogress_path = "%%CHROOT_INPROGRESSDIR%%/crawl-14-zotdef/",
        ttyrec_path = "%%CHROOT_TTYRECDIR%%/%n/",
        socket_path = "%%CHROOT_WEBDIR%%/sockets",
        options = ["-zotdef"])),
    ("tut-0.14", dict(
        name = "Tutorial 0.14",
        crawl_binary = "/bin/crawl-stable-launcher.sh",
        pre_options  = [ "0.14" ],
        rcfile_path = "%%CHROOT_RCFILESDIR%%/crawl-0.14/",
        macro_path = "%%CHROOT_RCFILESDIR%%/crawl-0.14/",
        morgue_path = "%%CHROOT_MORGUEDIR%%/%n/",
        morgue_url = "%%CHROOT_MORGUE_URL%%/%n/",
        inprogress_path = "%%CHROOT_INPROGRESSDIR%%/crawl-14-tut/",
        ttyrec_path = "%%CHROOT_TTYRECDIR%%/%n/",
        socket_path = "%%CHROOT_WEBDIR%%/sockets",
        options = ["-tutorial"])),


    ("dcss-0.13", dict(
        name = "DCSS 0.13",
        crawl_binary = "/bin/crawl-stable-launcher.sh",
        pre_options  = [ "0.13" ],
        rcfile_path = "%%CHROOT_RCFILESDIR%%/crawl-0.13/",
        macro_path = "%%CHROOT_RCFILESDIR%%/crawl-0.13/",
        morgue_path = "%%CHROOT_MORGUEDIR%%/%n/",
        morgue_url = "%%CHROOT_MORGUE_URL%%/%n/",
        inprogress_path = "%%CHROOT_INPROGRESSDIR%%/crawl-13/",
        ttyrec_path = "%%CHROOT_TTYRECDIR%%/%n/",
        socket_path = "%%CHROOT_WEBDIR%%/sockets")),
    ("spr-0.13", dict(
        name = "Sprint 0.13",
        crawl_binary = "/bin/crawl-stable-launcher.sh",
        pre_options  = [ "0.13" ],
        rcfile_path = "%%CHROOT_RCFILESDIR%%/crawl-0.13/",
        macro_path = "%%CHROOT_RCFILESDIR%%/crawl-0.13/",
        morgue_path = "%%CHROOT_MORGUEDIR%%/%n/",
        morgue_url = "%%CHROOT_MORGUE_URL%%/%n/",
        inprogress_path = "%%CHROOT_INPROGRESSDIR%%/crawl-13-sprint/",
        ttyrec_path = "%%CHROOT_TTYRECDIR%%/%n/",
        socket_path = "%%CHROOT_WEBDIR%%/sockets",
        options = ["-sprint"])),
    ("zd-0.13", dict(
        name = "Zot Defence 0.13",
        crawl_binary = "/bin/crawl-stable-launcher.sh",
        pre_options  = [ "0.13" ],
        rcfile_path = "%%CHROOT_RCFILESDIR%%/crawl-0.13/",
        macro_path = "%%CHROOT_RCFILESDIR%%/crawl-0.13/",
        morgue_path = "%%CHROOT_MORGUEDIR%%/%n/",
        morgue_url = "%%CHROOT_MORGUE_URL%%/%n/",
        inprogress_path = "%%CHROOT_INPROGRESSDIR%%/crawl-13-zotdef/",
        ttyrec_path = "%%CHROOT_TTYRECDIR%%/%n/",
        socket_path = "%%CHROOT_WEBDIR%%/sockets",
        options = ["-zotdef"])),
    ("tut-0.13", dict(
        name = "Tutorial 0.13",
        crawl_binary = "/bin/crawl-stable-launcher.sh",
        pre_options  = [ "0.13" ],
        rcfile_path = "%%CHROOT_RCFILESDIR%%/crawl-0.13/",
        macro_path = "%%CHROOT_RCFILESDIR%%/crawl-0.13/",
        morgue_path = "%%CHROOT_MORGUEDIR%%/%n/",
        morgue_url = "%%CHROOT_MORGUE_URL%%/%n/",
        inprogress_path = "%%CHROOT_INPROGRESSDIR%%/crawl-13-tut/",
        ttyrec_path = "%%CHROOT_TTYRECDIR%%/%n/",
        socket_path = "%%CHROOT_WEBDIR%%/sockets",
        options = ["-tutorial"])),


])

dgl_status_file = "%%CHROOT_WEBDIR%%/run/status"

# Set to None not to read milestones
milestone_file = [
 "%%CHROOT_CRAWL_BASEDIR%%/crawl-0.13/saves/milestones",
 "%%CHROOT_CRAWL_BASEDIR%%/crawl-0.13/saves/milestones-tutorial",
 "%%CHROOT_CRAWL_BASEDIR%%/crawl-0.13/saves/milestones-sprint",
 "%%CHROOT_CRAWL_BASEDIR%%/crawl-0.13/saves/milestones-zotdef",
 "%%CHROOT_CRAWL_BASEDIR%%/crawl-0.14/saves/milestones",
 "%%CHROOT_CRAWL_BASEDIR%%/crawl-0.14/saves/milestones-tutorial",
 "%%CHROOT_CRAWL_BASEDIR%%/crawl-0.14/saves/milestones-sprint",
 "%%CHROOT_CRAWL_BASEDIR%%/crawl-0.14/saves/milestones-zotdef",
 "%%CHROOT_CRAWL_BASEDIR%%/crawl-0.15/saves/milestones",
 "%%CHROOT_CRAWL_BASEDIR%%/crawl-0.15/saves/milestones-tutorial",
 "%%CHROOT_CRAWL_BASEDIR%%/crawl-0.15/saves/milestones-sprint",
 "%%CHROOT_CRAWL_BASEDIR%%/crawl-0.15/saves/milestones-zotdef",
 "%%CHROOT_CRAWL_BASEDIR%%/crawl-0.16/saves/milestones",
 "%%CHROOT_CRAWL_BASEDIR%%/crawl-0.16/saves/milestones-tutorial",
 "%%CHROOT_CRAWL_BASEDIR%%/crawl-0.16/saves/milestones-sprint",
 "%%CHROOT_CRAWL_BASEDIR%%/crawl-0.17/saves/milestones",
 "%%CHROOT_CRAWL_BASEDIR%%/crawl-0.17/saves/milestones-tutorial",
 "%%CHROOT_CRAWL_BASEDIR%%/crawl-0.17/saves/milestones-sprint",
 "%%CHROOT_CRAWL_BASEDIR%%/crawl-0.18/saves/milestones",
 "%%CHROOT_CRAWL_BASEDIR%%/crawl-0.18/saves/milestones-tutorial",
 "%%CHROOT_CRAWL_BASEDIR%%/crawl-0.18/saves/milestones-sprint",
 "%%CHROOT_CRAWL_BASEDIR%%/crawl-0.19/saves/milestones",
 "%%CHROOT_CRAWL_BASEDIR%%/crawl-0.19/saves/milestones-tutorial",
 "%%CHROOT_CRAWL_BASEDIR%%/crawl-0.19/saves/milestones-sprint",
 "%%CHROOT_CRAWL_BASEDIR%%/crawl-0.20/saves/milestones",
 "%%CHROOT_CRAWL_BASEDIR%%/crawl-0.20/saves/milestones-tutorial",
 "%%CHROOT_CRAWL_BASEDIR%%/crawl-0.20/saves/milestones-sprint",
 "%%CHROOT_CRAWL_BASEDIR%%/crawl-0.21/saves/milestones",
 "%%CHROOT_CRAWL_BASEDIR%%/crawl-0.21/saves/milestones-tutorial",
 "%%CHROOT_CRAWL_BASEDIR%%/crawl-0.21/saves/milestones-sprint",
 "%%CHROOT_CRAWL_BASEDIR%%/crawl-abyssrun/saves/milestones",
 "%%CHROOT_CRAWL_BASEDIR%%/crawl-basajaun/saves/milestones",
 "%%CHROOT_CRAWL_BASEDIR%%/crawl-thorn_god/saves/milestones",
 "%%CHROOT_CRAWL_BASEDIR%%/crawl-evoker-god-rebase/saves/milestones",
 "%%CHROOT_CRAWL_BASEDIR%%/crawl-orcs_and_elves/saves/milestones",
 "%%CHROOT_CRAWL_BASEDIR%%/crawl-adrenaline_rush/saves/milestones",
 "%%CHROOT_CRAWL_BASEDIR%%/crawl-councilgod-PR/saves/milestones",
 "%%CHROOT_CRAWL_BASEDIR%%/crawl-dpegs_dynamic_monsters/saves/milestones",
 "%%CHROOT_CRAWL_BASEDIR%%/crawl-cyno-PR/milestones",
 "%%CHROOT_CRAWL_BASEDIR%%/crawl-hellcrawl-cbro/saves/milestones",
 "%%CHROOT_CRAWL_BASEDIR%%/crawl-frogs/saves/milestones",
 "%%CHROOT_CRAWL_BASEDIR%%/crawl-faithful/saves/milestones",
 "%%CHROOT_CRAWL_GAMEDIR%%/saves/milestones",
 "%%CHROOT_CRAWL_GAMEDIR%%/saves/milestones-tutorial",
 "%%CHROOT_CRAWL_GAMEDIR%%/saves/milestones-sprint"
]

status_file_update_rate = 5

recording_term_size = (80, 24)

max_connections = 500

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

nick_regex = r"^[a-zA-Z0-9]{2,20}$"
max_passwd_length = 20

# crypt() algorithm, e.g. "1" for MD5 or "6" for SHA-512; see crypt(3).
# If false, use traditional DES (but then only the first eight characters
# are significant).
crypt_algorithm = "6"
# If crypt_algorithm is true, the length of the salt string to use.  If
# crypt_algorithm is false, a two-character salt is used.
crypt_salt_length = 16

login_token_lifetime = 7 # Days

uid = 1007  # If this is not None, the server will setuid to that (numeric) id
gid = 1008  # after binding its sockets.

umask = None # e.g. 0077

chroot = "%%DGL_CHROOT%%"

pidfile = "%%CHROOT_WEBDIR%%/run/webtiles.pid"
daemon = True # If true, the server will detach from the session after startup

player_url = "http://crawl.akrasiac.org/scoring/players/%s.html"
