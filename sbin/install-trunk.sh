#!/bin/bash

set -e

if test -n "${GAME}" -a -n "${REVISION}" -a -n "${DESTDIR}" -a -n "${PRIMARY_BRANCH_REMOTE}" -a -n "${VERSIONS_DB}"
then
	if test -n "${SGV_MAJOR}" -a -n "${SGV_MINOR}"
	then
		make -C source GAME=${GAME}-${REVISION} GAME_MAIN=${GAME} MCHMOD=0755 MCHMOD_SAVEDIR=755 INSTALL_UGRP=dgl:crawl BUILD_PCRE=YesPlease USE_DGAMELAUNCH=YesPlease WIZARD=YesPlease STRIP=true DESTDIR=${DESTDIR} prefix= bin_prefix=/bin SAVEDIR=/${GAME}-${REVISION}/saves DATADIR=/${GAME}-${REVISION} USE_MERGE_BASE="${PRIMARY_BRANCH_REMOTE}" EXTERNAL_FLAGS_L="-g" cdo-install

		echo
		echo "Adding version (${SGV_MAJOR}.${SGV_MINOR}) to database..."
		echo "insert into versions values('${REVISION}', $(date +%s), ${SGV_MAJOR}, ${SGV_MINOR}, 1);" | sqlite3 ${VERSIONS_DB}
	else
		echo "Could not figure out version tags. Installation cancelled."
		echo "Aborting installation!"
		echo
		exit 1
	fi

else
	echo "Could not figure out proper environment variables. Installation cancelled."
	echo "Aborting installation!"
	echo
	exit 1
fi

