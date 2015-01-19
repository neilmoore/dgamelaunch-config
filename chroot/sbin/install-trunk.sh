#!/bin/bash
#
# This script needs a sudo entry for user crawl to run as root:
# For obvious reasons, this script should not source any other scripts that
# are not owned by root.
#
# ===========================================================================
# Copyright (C) 2008, 2009, 2010, 2011 Marc H. Thoben
# Copyright (C) 2011 Darshan Shaligram
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# ===========================================================================
#

set -e
set -u
shopt -s extglob

# These are not overrideable:
CHROOT="%%DGL_CHROOT%%"
CHROOT_BINARIES="%%CHROOT_CRAWL_BINARY_PATH%%"
GAME="%%GAME%%"
CHROOT_CRAWL_BASEDIR="%%CHROOT_CRAWL_BASEDIR%%"
DESTDIR="%%CRAWL_BASEDIR%%"
VERSIONS_DB="%%VERSIONS_DB%%"
CRAWL_UGRP="%%CRAWL_UGRP%%"
DGL_SETTINGS_DIR="%%DGL_SETTINGS_DIR%%"

REVISION="$1"
DESCRIPTION="$2"
SGV_MAJOR="$3"
SGV_MINOR="$4"

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
    ln -sf $GAME_BINARY $BINARIES_DIR/crawl-latest
}

copy-data-files() {
    echo "Copying game data files to $DATADIR"
    cp -r source/dat docs settings $DATADIR
    cp -r settings/. $DGL_SETTINGS_DIR/$GAME-settings
    cp -r source/webserver/game_data/. $DATADIR/web
# remove these lines to prevent trunk recompile to obliterate webserver 
# can uncomment once webtiles-changes merges with trunk

#    cp -r source/webserver/!(config.py|game_data|templates) $WEBDIR
#    cp source/webserver/templates/client.html $WEBDIR/templates/
#    cp source/webserver/templates/game_links.html $WEBDIR/templates/

    mkdir -p "$ABS_COMMON_DIR/data/docs"
    cp docs/crawl_changelog.txt "$ABS_COMMON_DIR/data/docs"
    # Enable something like this when we merge webtiles-changes into trunk.
    #cp source/dat/des/sprint/sprint.toml "$ABS_COMMON_DIR/data/"
}

link-logfiles() {
    for file in logfile milestones scores; do
        ln -sf $COMMON_DIR/saves/$file $SAVEDIR
        ln -sf $COMMON_DIR/saves/$file-sprint $SAVEDIR
        ln -sf $COMMON_DIR/saves/$file-zotdef $SAVEDIR
    done
}

install-game() {
    mkdir -p $SAVEDIR/{,sprint,zotdef}
    mkdir -p $DATADIR

    copy-game-binary
    copy-data-files
    link-logfiles
    
    chown -R $CRAWL_UGRP $SAVEDIR
    ln -snf $GAME_BINARY $CHROOT$CHROOT_CRAWL_BASEDIR/crawl-latest
}

register-game-version() {
    echo
    echo "Adding version (${SGV_MAJOR}.${SGV_MINOR}) to database..."
    sqlite3 ${VERSIONS_DB} <<SQL
INSERT INTO VERSIONS VALUES ('${REVISION}', '$DESCRIPTION', $(date +%s),
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
    
    WEBDIR=$CHROOT$CHROOT_CRAWL_BASEDIR/webserver
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
