#!/bin/bash

set -e
lock-or-die crawl-update "someone is already updating the trunk build"

source $DGL_CONF_HOME/crawl-git.conf
check-versions-db-exists

export GAME="crawl-git"
export DESTDIR=$CRAWL_BASEDIR

check-crawl-basedir-exists

TODAY="$(dgl-today)"

./update-public-repository.sh $BRANCH

export REVISION="$(git-do rev-parse $BRANCH)"
REVISION_FULL="$(git-do describe --long $BRANCH)"
REVISION_OLD="$(echo "select hash from versions order by time desc limit 1;" | sqlite3 ${VERSIONS_DB})"

[[ "$REVISION" == "$REVISION_OLD" ]] && \
    abort-saying "Nothing new to install at the moment."

prompt "start install"

cd $CRAWL_REPOSITORY_DIR/crawl-ref

echo "Copying CREDITS to docs/crawl_credits.txt..."
cp CREDITS.txt docs/crawl_credits.txt

dgl-git-log() {
    git-do log --pretty=tformat:"--------------------------------------------------------------------------------%n%h | %an | %ci%n%n%s%n%b" "$@" | grep -v "git-svn-id" | awk 1 RS= ORS="\n\n" | fold -s
}

echo "Creating changelog in docs/crawl_changelog.txt..."
dgl-git-log $BRANCH > docs/crawl_changelog.txt

if prompts-enabled; then
    echo "Changes to $BRANCH from $REVISION_OLD .. $REVISION"
    dgl-git-log ${REVISION_OLD}..${REVISION} | less
fi

prompt "compile ${GAME}-${REVISION}"

# REMEMBER to adjust /var/lib/dgamelaunch/sbin/install-trunk.sh as well if make parameters change!
##################################################################################################

say-do crawl-do nice make -j2 -C source GAME=${GAME}-${REVISION} \
    GAME_MAIN=${GAME} MCHMOD=0755 MCHMOD_SAVEDIR=755 \
    INSTALL_UGRP=$CRAWL_UGRP \
    BUILD_PCRE=YesPlease USE_DGAMELAUNCH=YesPlease WIZARD=YesPlease \
    STRIP=true DESTDIR=${DESTDIR} prefix= bin_prefix=/bin \
    SAVEDIR=$CHROOT_CRAWL_BASEDIR/${GAME}-${REVISION}/saves \
    DATADIR=$CHROOT_CRAWL_BASEDIR/${GAME}-${REVISION}/data \
    EXTERNAL_FLAGS_L="-g"

prompt "install ${GAME}-${REVISION}"

if { ps -fC ${GAME}-${REVISION} | awk '{ print $1" "$2"\t "$5" "$7"\t "$8" "$9" "$10 }' | grep ^dgl; }
then
    abort-saying "There are already active instances of this version (${REVISION_FULL}) running."
fi

echo "Searching for version tags..."

export SGV_MAJOR=$(crawl-tag-major-version.sh)
export SGV_MINOR="0"
echo

DGL_CONF_HOME=$DGL_CONF_HOME \
    CRAWL_UGRP=$CRAWL_UGRP \
    CHROOT_CRAWL_BASEDIR=$CHROOT_CRAWL_BASEDIR \
    sudo -H -E $DGL_CHROOT/sbin/install-trunk.sh

prompt "clean source"
make -C source GAME=${GAME}-${REVISION} distclean
rm -vf docs/crawl_changelog.txt
rm -vf docs/crawl_credits.txt
#rm -vf /var/www/crawl.develz.org/htdocs/trunk/rss/feeds/cdo.xml

announce "Unstable branch on CDO updated to: ${REVISION_FULL} (${SGV_MAJOR})"

echo "All done."
echo
