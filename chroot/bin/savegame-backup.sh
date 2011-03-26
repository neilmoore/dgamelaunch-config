#!/bin/bash

set -u

ARGUMENTS=($@)
CHAR_NAME="$(echo ${ARGUMENTS[0]} | sed 's/[$*\/();.|+-]//g')"
BINARY_MAIN_NAME=${ARGUMENTS[1]}
BINARY_SAVE_NAME=$BINARY_MAIN_NAME
PREFIX="${ARGUMENTS[2]}"

trap "read -n 1 -s -p '-- Hit a key to exit --'; exit 0" EXIT

clear

TODAY="$(date +%y%m%d-%H%M)"

TARGET_DIR="%%CHROOT_SAVE_DUMPDIR%%"
HTTP_LINK="%%WEB_SAVEDUMP_URL%%"

USER_ID="%%DGL_UID%%"

existing-files() {
    for file in "$@"; do
        if [[ -f "$file" ]]; then
            printf "%s " "$file"
        fi
    done
}

first-existing-file() {
    for file in "$@"; do
        if [[ -f "$file" ]]; then
            echo "$file"
        fi
    done
}

savedir-containing() {
    local char="$1"
    local -a saves
    saves=($PREFIX/$BINARY_SAVE_NAME{,-*}/saves/$char{,-$USER_ID}.{cs,chr,sav})
    local savefile="$(first-existing-file "${saves[@]}")"
    [[ -n "$savefile" ]] && dirname "$savefile"
    return 0
}

SAVES="$(savedir-containing $CHAR_NAME)"
SPRINT_SAVES="$(savedir-containing sprint/$CHAR_NAME)"
ZOTDEF_SAVES="$(savedir-containing zotdef/$CHAR_NAME)"

if [[ -z "$SAVES" && -z "$SPRINT_SAVES" && -z "$ZOTDEF_SAVES" ]]; then
    echo "No saves to backup for $CHAR_NAME"
fi

SAVE_QUALIFIER=""

CHAR=Character

C_NORMAL="\033[0m"
C_YELLOW="\033[1;33m"
C_GREEN="\033[1;32m"
C_RED="\033[1;31m"

PROMPT="Backup"
[[ -n "$SAVES" ]] && PROMPT="$PROMPT [n]ormal save"
[[ -n "$SPRINT_SAVES" ]] && PROMPT="$PROMPT [s]print"
[[ -n "$ZOTDEF_SAVES" ]] && PROMPT="$PROMPT [z]otdef"
PROMPT="$PROMPT character?"

read -n 1 -s -p "$PROMPT" REPLY
echo

REPLY="$(echo "$REPLY" | sed 's/\([A-Z]\)/\L\1/g')"

if [[ -n "$SPRINT_SAVES" && ( "$REPLY" = "s" ) ]]; then
    SAVE_QUALIFIER="-sprint"
    SAVES="$SPRINT_SAVES"
    CHAR="Sprint character"
elif [[ -n "$ZOTDEF_SAVES" && ( "$REPLY" = "z" ) ]]; then
    SAVE_QUALIFIER="-zotdef"
    SAVES="$ZOTDEF_SAVES"
    CHAR="Zot Defense character"
elif [[ "$REPLY" != "n" ]]; then
    echo -e "Bad choice, aborting."
    exit 1
fi

declare -a SAVE_MATCHES
SAVE_MATCHES=(${SAVES}/${CHAR_NAME}{,-${USER_ID}}.{sav,cs,chr}*)

# Get rid of glob patterns that failed to match anything:
SAVE_MATCHES=(${SAVE_MATCHES[@]##*\*})

# And the first remaining entry is the matched save.
SAVE_FOUND=${SAVE_MATCHES[0]}

if [[ -n "$SAVE_FOUND" && -f "$SAVE_FOUND" ]]; then
    GAME_NAME=${SAVES%/zotdef}
    GAME_NAME=${GAME_NAME%/sprint}
    GAME_NAME="$(dirname $GAME_NAME)"
    GAME_NAME="${GAME_NAME##*/}"

    echo
    echo "$CHAR \"${CHAR_NAME}\" in $GAME_NAME. "

    echo -n "Backing up:"
    cd $SAVES

    TARNAME=${CHAR_NAME}${SAVE_QUALIFIER}-$GAME_NAME-${TODAY}.tar.bz2
    tar -cjf ${TARGET_DIR}/$TARNAME \
        $(existing-files ${CHAR_NAME}{,-${USER_ID}}.*)

    if test $? -ne 0
    then
	echo -e " ${C_RED}failed!${C_NORMAL}"
    else
	echo -e " ${C_GREEN}successful.${C_NORMAL}"
	echo "- ${HTTP_LINK}/$TARNAME"
	echo
	echo "Please provide this link in your bug-report or give it to a developer."
    fi
else
    echo "Your character ($CHAR_NAME) was not found in $SAVES."
fi

