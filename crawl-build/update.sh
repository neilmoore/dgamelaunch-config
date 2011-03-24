#!/bin/bash

set -e

LOCK_FILE="${HOME}/.crawl_cdo_update.lock"

if test -f ${LOCK_FILE}
then
	echo
	echo "Someone is currently updating CDO already. Try again later."
	echo "Aborting..."
	echo
	exit 0
else
	touch ${LOCK_FILE}
fi

force_exit()
{
	exit 1
}

normal_exit()
{
	rm -f ${LOCK_FILE}
}

trap force_exit INT TERM
trap normal_exit EXIT

if test "${CONFIG_READ}" != "true"
then
	. update.conf
fi

export GAME="crawl-0.6"
export PRIMARY_BRANCH_REMOTE="${BRANCH_REMOTE/ */}"
export DESTDIR=/var/lib/dgamelaunch
export VERSIONS_DB="${DESTDIR}/versions-0.6.db3"

WAIT_KEY=1
if test -n "$1"
then
	WAIT_KEY=0
fi

TODAY="$(date +%y%m%d-%H%M)"

./update-public-repository.sh

./merge.sh

export REVISION="$(git log --abbrev-commit --pretty=oneline -1 ${PRIMARY_BRANCH_REMOTE} | cut -d' ' -f1)"
REVISION_FULL="$(git describe --long ${PRIMARY_BRANCH_REMOTE})"
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

# REMEMBER to adjust /var/lib/dgamelaunch/sbin/install-0.6.sh as well if make parameters change!
################################################################################################

nice make -j2 -C source GAME=${GAME}-${REVISION} GAME_MAIN=${GAME} MCHMOD=0755 MCHMOD_SAVEDIR=755 INSTALL_UGRP=dgl:crawl BUILD_PCRE=YesPlease USE_DGAMELAUNCH=YesPlease DESTDIR=${DESTDIR} prefix= bin_prefix=/bin SAVEDIR=/${GAME}-${REVISION}/saves DATADIR=/${GAME}-${REVISION} USE_MERGE_BASE="${PRIMARY_BRANCH_REMOTE}" EXTERNAL_FLAGS_L=-DSAVE_PACKAGE_NONE

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
export SGV_MAJOR="$(grep "#define TAG_MAJOR_VERSION[[:space:]]*[[:digit:]]*" source/tags.h | sed 's/.*TAG_MAJOR_VERSION[[:space:]]*\([[:digit:]]*\)/\1/')"
export SGV_MINOR="$(grep "TAG_MINOR_VERSION[[:space:]]*=" source/tags.h | sed 's/.*=[[:space:]]*\([[:digit:]]*\).*/\1/')"
echo

sudo -H -E -u root /var/lib/dgamelaunch/sbin/install-0.6.sh

echo "-- Press RETURN to clean source --"
test ${WAIT_KEY} -eq 1 && read || echo

make -C source GAME=${GAME}-${REVISION} distclean

rm -vf docs/crawl_changelog.txt
rm -vf docs/crawl_credits.txt

cd ..

echo
echo "---------------------------------------------------------------------"
echo "Stable branch on CDO updated to: ${REVISION_FULL} (${SGV_MAJOR}.${SGV_MINOR})"
echo "All done."
echo

