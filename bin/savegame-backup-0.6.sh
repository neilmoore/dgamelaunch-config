#!/bin/bash

clear

TODAY="$(date +%y%m%d-%H%M)"

TARGET_DIR="/dumps"
HTTP_LINK="http://crawl.akrasiac.org/saves/dumps"

USER_ID="5"
PREFIX="/var/games"

BINARY_SAVE_NAME="crawl06"
BINARY_SAVE_DIR="$PREFIX/$BINARY_SAVE_NAME/saves"
BINARY_MAIN_NAME="crawl-0.6"

SAVE_QUALIFIER=""
SAVE_SUBDIR=""

CHAR=Character

C_NORMAL="\033[0m"
C_YELLOW="\033[1;33m"
C_GREEN="\033[1;32m"
C_RED="\033[1;31m"

PARAMS="$(echo "$*" | sed 's/[$*\/();.|+-]//g')"

CHAR_NAME="${PARAMS}"
    
SAVE_FOUND="$(echo ${BINARY_SAVE_DIR}/${CHAR_NAME}-${USER_ID}.sav* ${BINARY_SAVE_DIR}/${CHAR_NAME}-${USER_ID}.chr* | head -n 1)"

if test ${#SAVE_FOUND} -ne 0
then
    OUR_GAME_HASH="$(echo ${SAVE_FOUND} | sed "s|${BINARY_SAVE_DIR}/${CHAR_NAME}-${USER_ID}.*|\1|")"
    OUR_GAME_DIR="$(dirname ${SAVE_FOUND})"

    echo
    echo -n "$CHAR \"${CHAR_NAME}\" in ${OUR_GAME_HASH}. "

    echo -n "Backing up:"

    cd ${OUR_GAME_DIR}

    tar -cjf ${TARGET_DIR}/${CHAR_NAME}${SAVE_QUALIFIER}-${OUR_GAME_HASH}-${TODAY}.tar.bz2 ${CHAR_NAME}-${USER_ID}.*

    if test $? -ne 0
    then
	echo -e " ${C_RED}failed!${C_NORMAL}"
    else
	echo -e " ${C_GREEN}successful.${C_NORMAL}"
	echo "- ${HTTP_LINK}/${CHAR_NAME}${SAVE_QUALIFIER}-${OUR_GAME_HASH}-${TODAY}.tar.bz2"
	echo
	echo "Please provide this link in your bug-report or give it to a developer."
    fi
else
    echo "Your character ($CHAR_NAME) was not found."
fi

echo
read -n 1 -s -p "--- Press any key to continue ---"
exit 0

