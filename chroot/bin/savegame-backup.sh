#!/bin/bash

ARGUMENTS=($@)
CHAR_NAME="$(echo ${ARGUMENTS[0]} | sed 's/[$*\/();.|+-]//g')"
BINARY_MAIN_NAME=${ARGUMENTS[1]}
BINARY_SAVE_NAME="$(echo $BINARY_MAIN_NAME | sed 's/[.-]//g')"

clear

TODAY="$(date +%y%m%d-%H%M)"

TARGET_DIR="/dumps"
HTTP_LINK="http://crawl.akrasiac.org/saves/dumps"

USER_ID="5"
PREFIX="/var/games"

BINARY_SAVE_DIR="$PREFIX/$BINARY_SAVE_NAME/saves"

SAVE_QUALIFIER=""
SAVE_SUBDIR=""

CHAR=Character

C_NORMAL="\033[0m"
C_YELLOW="\033[1;33m"
C_GREEN="\033[1;32m"
C_RED="\033[1;31m"

HAVE_SPRINT=$([ -d "$BINARY_SAVE_DIR/sprint" ] && echo 1)
HAVE_ZOTDEF=$([ -d "$BINARY_SAVE_DIR/zotdef" ] && echo 1)

if [[ -n $HAVE_SPRINT || -n $HAVE_ZOTDEF ]]; then
    PROMPT="Backup [n]ormal"
    if [ -n "$HAVE_SPRINT" ]; then
        PROMPT="$PROMPT or [s]print"
    fi
    if [ -n "$HAVE_ZOTDEF" ]; then
        PROMPT="$PROMPT or [z]otdef"
    fi
    PROMPT="$PROMPT character?"

    read -n 1 -s -p "$PROMPT" REPLY
    echo

    REPLY="$(echo "$REPLY" | sed 's/\([A-Z]\)/\L\1/g')"

    if [[ -n "$HAVE_SPRINT" && ( "$REPLY" = "s" ) ]]; then
        SAVE_QUALIFIER="-sprint"
        BINARY_SAVE_DIR="$BINARY_SAVE_DIR/sprint"
        CHAR="Sprint character"
    elif [[ -n "$HAVE_ZOTDEF" && ( "$REPLY" = "z" ) ]]; then
        SAVE_QUALIFIER="-zotdef"
        BINARY_SAVE_DIR="$BINARY_SAVE_DIR/zotdef"
        CHAR="Zot Defense character"
    elif [[ "$REPLY" != "n" ]]; then
        echo -e "Bad choice, aborting."
        exit 1
    fi
fi

SAVE_MATCHES=(${BINARY_SAVE_DIR}/${CHAR_NAME}-${USER_ID}.sav*
    ${BINARY_SAVE_DIR}/${CHAR_NAME}-${USER_ID}.chr*
    ${BINARY_SAVE_DIR}/${CHAR_NAME}.cs*
    ${BINARY_SAVE_DIR}/${CHAR_NAME}-$USER_ID.cs*)

# Get rid of glob patterns that failed to match anything:
SAVE_MATCHES=(${SAVE_MATCHES[@]##*\*})

# And the first remaining entry is the matched save.
SAVE_FOUND=${SAVE_MATCHES[0]}

if [[ -n "$SAVE_FOUND" && -f "$SAVE_FOUND" ]]; then
    OUR_GAME_DIR="$(dirname ${SAVE_FOUND})"

    echo
    echo -n "$CHAR \"${CHAR_NAME}\" in ${BINARY_MAIN_NAME}. "

    echo -n "Backing up:"

    cd ${OUR_GAME_DIR}

    TARNAME=${CHAR_NAME}${SAVE_QUALIFIER}-${BINARY_MAIN_NAME}-${TODAY}.tar.bz2
    tar -cjf ${TARGET_DIR}/$TARNAME ${CHAR_NAME}-${USER_ID}.*

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
    echo "Your character ($CHAR_NAME) was not found in $BINARY_SAVE_DIR."
fi

echo
read -n 1 -s -p "--- Press any key to continue ---"
exit 0

