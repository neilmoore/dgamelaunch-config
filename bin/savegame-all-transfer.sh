#!/bin/bash

USER_ID="2002"

PREFIX="/var/lib/dgamelaunch"
VERSIONS_DB="${PREFIX}/versions.db3"

BINARY_MAIN_NAME="crawl-svn"

LATEST_GAME_HASH="$(echo "select hash from versions order by time desc limit 1;" | sqlite3 ${VERSIONS_DB})"

ALL_CHARS="$(/bin/ls -1rt ${PREFIX}/${BINARY_MAIN_NAME}-*/saves/*-${USER_ID}.sav ${PREFIX}/${BINARY_MAIN_NAME}-*/saves/*-${USER_ID}.chr ${PREFIX}/${BINARY_MAIN_NAME}-*/saves/*.cs ${PREFIX}/${BINARY_MAIN_NAME}-*/saves/sprint/*-${USER_ID}.chr ${PREFIX}/${BINARY_MAIN_NAME}-*/saves/sprint/*.cs ${PREFIX}/${BINARY_MAIN_NAME}-*/saves/zotdef/*.cs 2>/dev/null | grep -v ${LATEST_GAME_HASH} | sed "s|${PREFIX}/${BINARY_MAIN_NAME}-.*/saves/\(.*\)\..*|\1|;s|-${USER_ID}||" | sort -f)"

echo "Trying to transfer these chars to a newer version:"
echo ${ALL_CHARS}
echo

echo "-- Press RETURN to start installation --"
read

for char in ${ALL_CHARS}
do
	savegame-transfer.sh ${char}
done

