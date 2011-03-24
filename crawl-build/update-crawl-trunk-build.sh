#!/bin/bash

set -e
source $DGL_CONF_HOME/sh-utils

lock-or-die crawl-update "someone is already updating the trunk build"

. crawl-git.conf
check-versions-db-exists

export GAME="crawl-svn"
export DESTDIR=$DGL_CHROOT

ANNOUNCEMENTS_FILE="$DGL_CONF_LOGS/announcements.log"

TODAY="$(dgl-today)"

./update-public-repository.sh

export REVISION="$(git rev-parse $BRANCH)"
REVISION_FULL="$(git describe --long $BRANCH)"
REVISION_OLD="$(echo "select hash from versions order by time desc limit 1;" | sqlite3 ${VERSIONS_DB})"

if test "${REVISION}" = "${REVISION_OLD}"
then
	echo "Nothing new to install at the moment."
	echo "Aborting..."
	echo
	exit 1
fi

echo "-- Press RETURN to start installation --"
test ${WAIT_KEY} -eq 1 && read || echo

cd crawl-ref

echo "Copying CREDITS to docs/crawl_credits.txt..."
cp CREDITS.txt docs/crawl_credits.txt

echo "Creating changelog in docs/crawl_changelog.txt..."
git log --pretty=tformat:"--------------------------------------------------------------------------------%n%h | %an | %ci%n%n%s%n%b" ${PRIMARY_BRANCH_REMOTE} | grep -v "git-svn-id" | awk 1 RS= ORS="\n\n" | fold -s > docs/crawl_changelog.txt

if test ${WAIT_KEY} -eq 1
then
	echo "Displaying changes since ${REVISION_OLD}..."
	git log --pretty=tformat:"--------------------------------------------------------------------------------%n%h | %an | %ci%n%n%s%n%b" ${REVISION_OLD}..${REVISION} | grep -v "git-svn-id" | awk 1 RS= ORS="\n\n" | fold -s | less
fi

echo "-- Press RETURN to compile ${GAME}-${REVISION} --"
test ${WAIT_KEY} -eq 1 && read || echo

# REMEMBER to adjust /var/lib/dgamelaunch/sbin/install-trunk.sh as well if make parameters change!
##################################################################################################

nice make -j2 -C source GAME=${GAME}-${REVISION} GAME_MAIN=${GAME} MCHMOD=0755 MCHMOD_SAVEDIR=755 INSTALL_UGRP=dgl:crawl BUILD_PCRE=YesPlease USE_DGAMELAUNCH=YesPlease WIZARD=YesPlease STRIP=true DESTDIR=${DESTDIR} prefix= bin_prefix=/bin SAVEDIR=/${GAME}-${REVISION}/saves DATADIR=/${GAME}-${REVISION} USE_MERGE_BASE="${PRIMARY_BRANCH_REMOTE}" EXTERNAL_FLAGS_L="-g"

echo "-- Press RETURN to install ${GAME}-${REVISION} --"
test ${WAIT_KEY} -eq 1 && read || echo

if { ps -fC ${GAME}-${REVISION} | awk '{ print $1" "$2"\t "$5" "$7"\t "$8" "$9" "$10 }' | grep ^dgl; }
then
	echo "There are already active instances of this version (${REVISION_FULL}) running."
	echo "Aborting..."
	echo
	exit 1
fi

echo "Searching for version tags..."
export SGV_MAJOR="$(grep "#define TAG_MAJOR_VERSION[[:space:]]*[[:digit:]]*" source/tag-version.h | sed 's/.*TAG_MAJOR_VERSION[[:space:]]*\([[:digit:]]*\)/\1/')"
export SGV_MINOR="0"
echo

sudo -H -E -u root /var/lib/dgamelaunch/sbin/install-trunk.sh

echo "-- Press RETURN to clean source --"
test ${WAIT_KEY} -eq 1 && read || echo

make -C source GAME=${GAME}-${REVISION} distclean

rm -vf docs/crawl_changelog.txt
rm -vf docs/crawl_credits.txt
rm -vf /var/www/crawl.develz.org/htdocs/trunk/rss/feeds/cdo.xml

cd ..

echo
echo "---------------------------------------------------------------------"
echo "Unstable branch on CDO updated to: ${REVISION_FULL} (${SGV_MAJOR})"
echo "Unstable branch on CDO updated to: ${REVISION_FULL} (${SGV_MAJOR})" >> ${ANNOUNCEMENTS}
echo "All done."
echo

