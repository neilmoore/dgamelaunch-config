#! /bin/bash

source $DGL_CONF_HOME/crawl-git.conf

set -e
GAME_DIR=$CRAWL_GAMEDIR
echo "Crawl basedir to create: $GAME_DIR"

[[ -d "$GAME_DIR" ]] && abort-saying "Crawl base directory already exists"
assert-chroot-exists
[[ "$UID" != "0" ]] && abort-saying "This script must be run as root"

mkdir -p $DGL_CHROOT/cores

mkdir -p $GAME_DIR/saves/{sprint,zotdef}
( cd $GAME_DIR/saves &&
    touch logfile{,-sprint,-zotdef} \
        milestones{,-sprint,-zotdef} \
        scores{,-sprint,-zotdef} )

# Only the saves dir is chowned games: data dir is not supposed to be
# games writable.
chown -R $CRAWL_UGRP $GAME_DIR/saves

echo "Created $GAME_DIR"