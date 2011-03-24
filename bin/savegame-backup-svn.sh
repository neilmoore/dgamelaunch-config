#!/usr/bin/bash-static

clear

TODAY="$(date +%y%m%d-%H%M)"

TARGET_DIR="/dumps"
HTTP_LINK="http://crawl.develz.org/saves/dumps"

USER_ID="2002"
PREFIX=""
BINARY_MAIN_NAME="crawl-svn"

C_NORMAL="\033[0m"
C_YELLOW="\033[1;33m"
C_GREEN="\033[1;32m"
C_RED="\033[1;31m"

PARAMS="$(echo "$*" | sed 's/[$*\/();.|+-]//g')"

CHAR_NAME="${PARAMS}"

read -n 1 -s -p "Backup [n]ormal or [s]print or [z]otdef char?" REPLY
echo

if test "$REPLY" = "z" -o "$REPLY" = "Z"
then
	SAVE_FOUND="$(/usr/bin/ls -1rt ${PREFIX}/${BINARY_MAIN_NAME}-*/saves/zotdef/${CHAR_NAME}{-${USER_ID},}.cs 2>/dev/null | head -n 1)"

	if test ${#SAVE_FOUND} -ne 0
	then
		OUR_GAME_HASH="$(echo ${SAVE_FOUND} | sed "s|${PREFIX}/${BINARY_MAIN_NAME}-\(.*\)/saves/zotdef/${CHAR_NAME}.*|\1|")"
		OUR_GAME_DIR="$(dirname ${SAVE_FOUND})"

		echo
		echo -n "Char \"${CHAR_NAME}\" in ${OUR_GAME_HASH}. "

		echo -n "Backing up:"

		cd ${OUR_GAME_DIR}

		if test -r ${CHAR_NAME}-${USER_ID}.cs
		then
			cp ${CHAR_NAME}-${USER_ID}.cs ${TARGET_DIR}/${CHAR_NAME}-zotdef-${OUR_GAME_HASH}-${TODAY}.cs
		elif test -r ${CHAR_NAME}.cs
		then
			cp ${CHAR_NAME}.cs ${TARGET_DIR}/${CHAR_NAME}-zotdef-${OUR_GAME_HASH}-${TODAY}.cs
		fi

		if test $? -ne 0
		then
			echo -e " ${C_RED}failed!${C_NORMAL}"
		else
			echo -e " ${C_GREEN}successful.${C_NORMAL}"
			echo "- ${HTTP_LINK}/${CHAR_NAME}-zotdef-${OUR_GAME_HASH}-${TODAY}.cs"
			echo
			echo "Please provide this link in your bug-report or give it to a developer."
		fi
	else
		echo "Your character was not found."
	fi
elif test "$REPLY" = "s" -o "$REPLY" = "S"
then
	SAVE_FOUND="$(/usr/bin/ls -1rt ${PREFIX}/${BINARY_MAIN_NAME}-*/saves/sprint/${CHAR_NAME}{-${USER_ID},}.cs 2>/dev/null | head -n 1)"

	if test ${#SAVE_FOUND} -ne 0
	then
		OUR_GAME_HASH="$(echo ${SAVE_FOUND} | sed "s|${PREFIX}/${BINARY_MAIN_NAME}-\(.*\)/saves/sprint/${CHAR_NAME}.*|\1|")"
		OUR_GAME_DIR="$(dirname ${SAVE_FOUND})"

		echo
		echo -n "Char \"${CHAR_NAME}\" in ${OUR_GAME_HASH}. "

		echo -n "Backing up:"

		cd ${OUR_GAME_DIR}

		if test -r ${CHAR_NAME}-${USER_ID}.cs
		then
			cp ${CHAR_NAME}-${USER_ID}.cs ${TARGET_DIR}/${CHAR_NAME}-sprint-${OUR_GAME_HASH}-${TODAY}.cs
		elif test -r ${CHAR_NAME}.cs
		then
			cp ${CHAR_NAME}.cs ${TARGET_DIR}/${CHAR_NAME}-sprint-${OUR_GAME_HASH}-${TODAY}.cs
		fi

		if test $? -ne 0
		then
			echo -e " ${C_RED}failed!${C_NORMAL}"
		else
			echo -e " ${C_GREEN}successful.${C_NORMAL}"
			echo "- ${HTTP_LINK}/${CHAR_NAME}-sprint-${OUR_GAME_HASH}-${TODAY}.cs"
			echo
			echo "Please provide this link in your bug-report or give it to a developer."
		fi
	else
		echo "Your character was not found."
	fi
elif test "$REPLY" = "n" -o "$REPLY" = "N"
then
	SAVE_FOUND="$(/usr/bin/ls -1rt ${PREFIX}/${BINARY_MAIN_NAME}-*/saves/${CHAR_NAME}-${USER_ID}.chr ${PREFIX}/${BINARY_MAIN_NAME}-*/saves/${CHAR_NAME}{-${USER_ID},}.cs 2>/dev/null | head -n 1)"

	if test ${#SAVE_FOUND} -ne 0
	then
		OUR_GAME_HASH="$(echo ${SAVE_FOUND} | sed "s|${PREFIX}/${BINARY_MAIN_NAME}-\(.*\)/saves/${CHAR_NAME}.*|\1|")"
		OUR_GAME_DIR="$(dirname ${SAVE_FOUND})"

		echo
		echo -n "Char \"${CHAR_NAME}\" in ${OUR_GAME_HASH}. "

		echo -n "Backing up:"

		cd ${OUR_GAME_DIR}

		if test -r ${CHAR_NAME}-${USER_ID}.cs -o -r ${CHAR_NAME}-${USER_ID}.chr
		then
			tar -cjf ${TARGET_DIR}/${CHAR_NAME}-${OUR_GAME_HASH}-${TODAY}.tar.bz2 ${CHAR_NAME}-${USER_ID}.*
		elif test -r ${CHAR_NAME}.cs
		then
			tar -cjf ${TARGET_DIR}/${CHAR_NAME}-${OUR_GAME_HASH}-${TODAY}.tar.bz2 ${CHAR_NAME}.*
		fi

		if test $? -ne 0
		then
			echo -e " ${C_RED}failed!${C_NORMAL}"
		else
			echo -e " ${C_GREEN}successful.${C_NORMAL}"
			echo "- ${HTTP_LINK}/${CHAR_NAME}-${OUR_GAME_HASH}-${TODAY}.tar.bz2"
			echo
			echo "Please provide this link in your bug-report or give it to a developer."
		fi
	else
		echo "Your character was not found."
	fi
else
	echo "Backup aborted."
fi

echo
read -n 1 -s -p "--- any key to continue ---"
exit 0

