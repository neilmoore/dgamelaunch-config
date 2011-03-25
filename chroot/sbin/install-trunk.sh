#!/bin/bash
#
# This script needs a sudo entry for user crawl to run as root:
# For obvious reasons, this script should not source any other scripts that
# are not owned by root.

set -e

# These are not overrideable:
CHROOT=/var/lib/dgamelaunch
CHROOT_BINARIES=/usr/games

# Safe path:
PATH=/usr/bin:/bin:/usr/sbin

if [[ "$UID" != "0" ]]; then
    echo "$0 must be run as root"
    exit 1
fi

copy-game-binary() {
    say "Installing game binary ($GAME_BINARY) in $BINARIES_DIR"
    mkdir -p $BINARIES_DIR
    cp source/$GAME_BINARY $BINARIES_DIR
}

copy-data-files() {
    say "Copying game data files to $DATADIR"
    cp -r source/dat docs settings $DATADIR
}

link-logfiles() {
    for file in logfile milestones scores; do
        ln -sf $COMMON_DIR/saves/$file $DATADIR/saves/
        ln -sf $COMMON_DIR/saves/$file-sprint $DATADIR/saves/
        ln -sf $COMMON_DIR/saves/$file-zotdef $DATADIR/saves/
    done
}

install-game() {
    mkdir -p $SAVEDIR
    mkdir -p $DATADIR

    copy-game-binary
    copy-data-files
    link-logfiles
    
    chown -R $CRAWL_UGRP $SAVEDIR
}

register-game-version() {
    echo
    echo "Adding version (${SGV_MAJOR}.${SGV_MINOR}) to database..."
    sqlite3 ${VERSIONS_DB} <<SQL
INSERT INTO VERSIONS VALUES ('${REVISION}', $(date +%s),
                             ${SGV_MAJOR}, ${SGV_MINOR}, 1);
SQL
}

assert-not-evil() {
    local path=$1
    if [[ "$path" =~ ([.]{2}|[^.a-zA-Z0-9_/-]) ]]; then
        echo -e "Path $path contains characters I don't like, aborting."
        exit 1
    fi
}

assert-all-variables-exist() {
    local -a broken_variables=()
    for variable_name in "$@"; do
        eval "value=\"\$$variable_name\""
        if [[ -z "$value" ]]; then
            broken_variables=(${broken_variables[@]} $variable_name)
        fi
    done
    if (( ${#broken_variables[@]} > 0 )); then
        echo -e "These variables are required, but are unset:" \
            "${broken_variables[@]}"
        exit 1
    fi
}

assert-all-variables-exist GAME REVISION DESTDIR VERSIONS_DB CRAWL_UGRP \
    CHROOT_CRAWL_BASEDIR

assert-not-evil "$GAME"
assert-not-evil "$REVISION"
assert-not-evil "$DESTDIR"
assert-not-evil "$VERSIONS_DB"
assert-not-evil "$CHROOT_CRAWL_BASEDIR"

if [[ ! ( "$CRAWL_UGRP" =~ ^[a-z0-9]+:[a-z0-9]+$ ) ]]; then
    echo -e "Expected CRAWL_UGRP to be user:group, but got $CRAWL_UGRP"
    exit 1
fi

if [[ -n "${SGV_MAJOR}" && -n "${SGV_MINOR}" ]]; then
    # COMMON_DIR is the absolute path *inside* the chroot jail of the
    # directory holding common data for all game versions, viz: saves.
    COMMON_DIR=$CHROOT_CRAWL_BASEDIR/$GAME
    assert-not-evil "$COMMON_DIR"

    # ABS_COMMON_DIR is the absolute path from outside the chroot
    # corresponding to COMMON_DIR
    ABS_COMMON_DIR=$CHROOT$CHROOT_CRAWL_BASEDIR/$GAME

    if [[ ! -d "$CHROOT$COMMON_DIR" ]]; then
        echo -e "Expected to find common game dir $ABS_COMMON_DIR but did not find it"
        exit 1
    fi

    GAME_BINARY=$GAME-$REVISION
    BINARIES_DIR=$CHROOT$CHROOT_BINARIES
    
    GAMEDIR=$CHROOT/$CHROOT_CRAWL_BASEDIR/$GAME_BINARY
    # Absolute path to save game directory
    SAVEDIR=$GAMEDIR/saves
    DATADIR=$GAMEDIR/data
    assert-not-evil "$SAVEDIR"
    assert-not-evil "$DATADIR"

    echo "Installing game"
    install-game
    register-game-version
else
    echo "Could not figure out version tags. Installation cancelled."
    echo "Aborting installation!"
    echo
    exit 1
fi
