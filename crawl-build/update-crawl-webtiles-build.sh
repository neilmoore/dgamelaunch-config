#!/bin/bash

set -e
lock-or-die crawl-update "someone is already updating the crawl build"

source $DGL_CONF_HOME/crawl-git.conf
check-versions-db-exists

export DESTDIR=$CRAWL_BASEDIR

check-crawl-basedir-exists
enable-prompts $*

TODAY="$(dgl-today)"

# First argument can be a revision (SHA) to build
REVISION="$1"
./update-public-repository.sh $WEBTILES_BRANCH "$REVISION"

REVISION="$(git-do rev-parse HEAD | cut -c 1-10)"
REVISION_FULL="$(git-do describe --long HEAD)"
REVISION_OLD="$(echo "select hash from versions order by time desc limit 1;" | sqlite3 ${VERSIONS_DB})"

[[ "$REVISION" == "$REVISION_OLD" ]] && \
    abort-saying "Nothing new to install at the moment: you asked for $REVISION_FULL and it's already installed"

prompt "start update build"

cd $CRAWL_REPOSITORY_DIR/crawl-ref


if prompts-enabled; then
    echo "Changes to $WEBTILES_BRANCH from $REVISION_OLD .. $REVISION"
    dgl-git-log ${REVISION_OLD}..${REVISION} | less
fi

prompt "compile ${WEBTILES_BRANCH}-${REVISION}"

##################################################################################################

say-do crawl-do nice make -C source webserver-client \
    GAME=${GAME}-${REVISION} \
    GAME_MAIN=${GAME} MCHMOD=0755 MCHMOD_SAVEDIR=755 \
    INSTALL_UGRP=$CRAWL_UGRP \
    WEBTILES=YesPlease USE_DGAMELAUNCH=YesPlease WIZARD=YesPlease \
    STRIP=true DESTDIR=${DESTDIR} prefix= bin_prefix=/bin \
    SAVEDIR=$CHROOT_CRAWL_BASEDIR/${GAME}-${REVISION}/saves \
    DATADIR=$CHROOT_CRAWL_BASEDIR/${GAME}-${REVISION}/data \
    WEBDIR=$CHROOT_CRAWL_BASEDIR/${GAME}-${REVISION}/data/web \
    SHAREDDIR=$CHROOT_CRAWL_BASEDIR/${GAME}/saves \
    USE_PCRE=y \
    EXTERNAL_FLAGS_L="-g"

prompt "install ${WEBTILES_BRANCH}-${REVISION}"

say-do sudo -H $DGL_CHROOT/sbin/install-webserver.sh

echo "All done."
echo
