#!/bin/bash
#
# This script needs a sudo entry for user crawl to run as root:
# For obvious reasons, this script should not source any other scripts that
# are not owned by root.

set -e
set -u

# These are not overrideable:
CHROOT="%%DGL_CHROOT%%"
CHROOT_BINARIES="%%CHROOT_CRAWL_BINARY_PATH%%"
GAME="%%GAME%%"
CHROOT_CRAWL_BASEDIR="%%CHROOT_CRAWL_BASEDIR%%"
DESTDIR="%%CRAWL_BASEDIR%%"
VERSIONS_DB="%%VERSIONS_DB%%"
CRAWL_UGRP="%%CRAWL_UGRP%%"

# Safe path:
PATH=/bin:/sbin:/usr/bin:/usr/sbin

if [[ "$UID" != "0" ]]; then
    echo "$0 must be run as root"
    exit 1
fi

copy-game-binary() {
    echo "Installing game binary ($GAME_BINARY) in $BINARIES_DIR"
    mkdir -p $BINARIES_DIR
    cp source/$GAME_BINARY $BINARIES_DIR
}

copy-data-files() {
    echo "Copying game data files to $DATADIR"
    cp -r source/dat docs settings $DATADIR
}

link-logfiles() {
    for file in logfile milestones scores; do
        ln -sf $COMMON_DIR/saves/$file $SAVEDIR
        ln -sf $COMMON_DIR/saves/$file-sprint $SAVEDIR
        ln -sf $COMMON_DIR/saves/$file-zotdef $SAVEDIR
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
    local file=$1
    if [[ "$file" != "$(echo "$file" |
                        perl -lpe 's{[.]{2}|[^.a-zA-Z0-9_/-]+}{}g')" ]]
    then
        echo -e "Path $file contains characters I don't like, aborting."
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

if [[ -z "$REVISION" ]]; then
    echo -e "Missing revision argument"
    exit 1
fi

assert-not-evil "$REVISION"

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
    
    GAMEDIR=$CHROOT$CHROOT_CRAWL_BASEDIR/$GAME_BINARY
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
