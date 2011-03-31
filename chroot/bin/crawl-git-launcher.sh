#! /bin/bash
#
# Must be called as crawl-git -name <playername> [...]; character name
# must always be the second argument.
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

set -o nounset

CRAWL_GIT_DIR="%%CHROOT_CRAWL_BASEDIR%%"
USER_DB="%%CHROOT_LOGIN_DB%%"
CRAWL_BINARY_PATH="%%CHROOT_CRAWL_BINARY_PATH%%"
BINARY_BASE_NAME="%%GAME%%"
USER_ID="%%DGL_UID%%"
VERSIONS_DB="%%CHROOT_VERSIONS_DB%%"

export HOME="%%CHROOT_COREDIR%%"

# If set, this script will not event report the existence of newer versions.
TRANSFER_BYPASSED=
TRANSFER_ENABLED="1"
CHAR_NAME="$2"

# Clear screen
printf "\e[2J\e[H"

export LANG="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"

SAVES="saves"

[[ "$@" =~ --print-charset\\b ]] && TRANSFER_BYPASSED=1

[[ "$@" =~ -sprint\\b ]] && SAVES="$SAVES/sprint"
[[ "$@" =~ -zotdef\\b ]] && SAVES="$SAVES/zotdef"

if [[ $# == 0 || -z "$CHAR_NAME" ]]; then
    echo "Parameters missing. Aborting..."
    read -n 1 -s -p "--- any key to continue ---"
    echo
    exit 1
fi

ulimit -S -c 153600 2>/dev/null
ulimit -S -v 102400 2>/dev/null

first-real-file() {
    for file in "$@"; do
        if [[ -f "$file" ]]; then
            printf "%s\n" "$file"
            return 0
        fi
    done
}

query() {
    sqlite3 "$VERSIONS_DB"
}

hash-description() {
    local hash=$1
    query <<EOF
SELECT description FROM versions WHERE hash='$hash' LIMIT 1;
EOF
}

latest-game-hash() {
    query <<EOF
SELECT hash FROM versions ORDER BY time DESC LIMIT 1;
EOF
}

major-version-for-game() {
    local game=$1
    query <<EOF
SELECT major FROM versions WHERE hash='$game' LIMIT 1;
EOF
}

newest-version-with-major-version() {
    local major_version=$1
    query <<EOF
SELECT hash FROM versions WHERE major=$major_version
ORDER BY time DESC
LIMIT 1;
EOF
}

transfer-save() {
    local save=$1
    local game_hash=$2
    local target="$CRAWL_GIT_DIR/$BINARY_BASE_NAME-$game_hash/$SAVES"
    local src_save_dir=$(dirname $save)
    if [[ -d "$target" ]]; then
        mv "$src_save_dir/$CHAR_NAME"* \
            "$src_save_dir/start-$CHAR_NAME-ns.prf" \
            "$target"

	if test $? -eq 0
	then
	    echo ": successful!"
	    echo
	    OUR_GAME_HASH="${game_hash}"
	    read -n 1 -t 5 -s -p "--- any key to continue ---"
	    echo
	else
	    echo ": failed!"
	    echo
	    echo "Transferring your save failed! Continuing with former version."
	    read -n 1 -s -p "--- any key to continue ---"
	    echo
	fi
    else
	echo ": failed!"
	echo
	echo "Target version is corrupt! Continuing with former version."
	read -n 1 -s -p "--- any key to continue ---"
	echo
    fi
}

SAVEGLOB="$CRAWL_GIT_DIR/$BINARY_BASE_NAME-*/$SAVES"

declare -a SAVE_CANDIDATES
SAVE_CANDIDATES=($SAVEGLOB/$CHAR_NAME.cs \
    $SAVEGLOB/$CHAR_NAME-$USER_ID.sav \
    $SAVEGLOB/$CHAR_NAME-$USER_ID.chr)

SAVE="$(first-real-file "${SAVE_CANDIDATES[@]}")"
LATEST_GAME_HASH="$(latest-game-hash)"

if [[ -n "$SAVE" ]]; then
    OUR_GAME_HASH=${SAVE#$CRAWL_GIT_DIR/$BINARY_BASE_NAME-}
    OUR_GAME_HASH=${OUR_GAME_HASH%%/*}

    if [[ -z "$TRANSFER_BYPASSED" && \
        "$OUR_GAME_HASH" != "$LATEST_GAME_HASH" ]]
    then
        current_ver="$(hash-description $OUR_GAME_HASH)"
        echo "Hi, you have a $current_ver save game:"
	echo

	OUR_SGV_MAJOR="$(major-version-for-game $OUR_GAME_HASH)"
	NEW_GAME_HASH="$(newest-version-with-major-version $OUR_SGV_MAJOR)"
        new_ver="$(hash-description $NEW_GAME_HASH)"

        if [[ "$OUR_GAME_HASH" != "$NEW_GAME_HASH" &&
                    "$TRANSFER_ENABLED" == "1" ]]; then
	    if [[ "${NEW_GAME_HASH}" != "${LATEST_GAME_HASH}" ]]; then
		echo "There's a newer version ($new_ver) that can load your save."
                read -n 1 -s -p "[T]ransfer your save to this version?" REPLY
		echo
	    else
		read -n 1 -s -p "[T]ransfer your save to the latest version ($new_ver)?" REPLY
		echo
	    fi

	    if test "$REPLY" = "t" -o "$REPLY" = "T" -o "$REPLY" = "y"
	    then
		echo -n "Transferring..."
                transfer-save "$SAVE" "$NEW_GAME_HASH"
	    fi
	else
	    if test "${TRANSFER_ENABLED}" != "1"
	    then
		echo "Transfering of saves is currently disabled."
		echo "Finish your game or end your character to play in latest version."
	    else
		echo "Your save cannot be tranferred though because of incompatibility."
		echo "Finish your game or end your character to play in latest version."
	    fi
            
	    read -n 1 -t 5 -s -p "--- any key to continue ---"
	    echo
	fi
    fi
else
    OUR_GAME_HASH="${LATEST_GAME_HASH}"
fi

if test ${#OUR_GAME_HASH} -eq 0
then
    echo "Could not figure out the right game version. Aborting..."
    read -n 1 -s -p "--- any key to continue ---"
    echo
    exit 1
fi

BINARY_NAME="$CRAWL_BINARY_PATH/$BINARY_BASE_NAME-$OUR_GAME_HASH"
GAME_FOLDER="$CRAWL_GIT_DIR/$BINARY_BASE_NAME-$OUR_GAME_HASH"

if test -x "${BINARY_NAME}" -a -d "${GAME_FOLDER}"
then
    cd ${HOME}

    echo
    echo "Starting Dungeon Crawl Stone Soup ${OUR_GAME_HASH}..."
    exec ${BINARY_NAME} "$@"
fi

echo "Failed starting: ${BINARY_NAME} not found!"
read -n 1 -s -p "--- any key to continue ---"
echo
exit 1