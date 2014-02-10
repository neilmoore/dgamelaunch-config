#!/bin/bash

VERSION=${1}

# Quoting for =~ changed from bash 3.0 to 3.2; using a variable for the
# regexp works with both.
#VERS_RE='^[0-9]+.[0-9]+$'
#if [[ ! $VERSION =~ $VERS_RE ]]; then
#    echo "Bad crawl version $VERSION"
#    exit 1
#fi

set -e
lock-or-die crawl-update "someone is already updating the crawl build"

source $DGL_CONF_HOME/crawl-git.conf
GAME=crawl-$VERSION

export DESTDIR=$CRAWL_BASEDIR
BRANCH=$VERSION
#if [[ $VERSION != [0-9]* ]]; then
#    BRANCH=$VERSION
#fi

check-crawl-basedir-exists
enable-prompts $*

TODAY="$(dgl-today)"

# Second argument can be a revision (SHA) to build
# for dev, keep repo updated manually
#REVISION="$2"
#./update-public-repository.sh $BRANCH "$REVISION"

#REVISION="$(git-do rev-parse HEAD | cut -c 1-7)"
#REVISION_FULL="$(git-do describe --long HEAD)"
#VER_STR="$(git-do describe HEAD)"
#VER_STR_OLD="$(($CRAWL_BINARY_PATH/$GAME -version 2>/dev/null || true) | sed -ne 's/Crawl version //p')"
#REVISION_OLD="${VER_STR_OLD##*-g}"

#[[ "$REVISION" == "$REVISION_OLD" || "$VER_STR" = "$VER_STR_OLD" ]] && \
#    abort-saying "Nothing new to install at the moment: you asked for $REVISION_FULL and it's already installed"
# ALWAYS TRY TO REBUILD

prompt "start update build"

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
    dgl-git-log ${REVISION_OLD:+$REVISION_OLD..}${REVISION} | less
fi

prompt "compile ${GAME} (${REVISION})"

# REMEMBER to adjust /var/lib/dgamelaunch/sbin/install-stable.sh as well if make parameters change!
##################################################################################################

say-do crawl-do nice make -C source \
    GAME=${GAME} \
    GAME_MAIN=${GAME} MCHMOD=0755 MCHMOD_SAVEDIR=755 \
    INSTALL_UGRP=$CRAWL_UGRP \
    WEBTILES=YesPlease USE_DGAMELAUNCH=YesPlease WIZARD=YesPlease \
    STRIP=true DESTDIR=${DESTDIR} prefix= bin_prefix=/bin \
    SAVEDIR=$CHROOT_CRAWL_BASEDIR/${GAME}/saves \
    DATADIR=$CHROOT_CRAWL_BASEDIR/${GAME}/data \
    WEBDIR=$CHROOT_CRAWL_BASEDIR/${GAME}/data/web \
    EXTERNAL_FLAGS_L="-g"

prompt "install ${GAME} (${REVISION})"

say-do sudo -H $DGL_CHROOT/sbin/install-stable.sh "$VERSION"

SUPER_VER="Dev"

#if [[ $VERSION = [0-9]* ]]; then
#    SUPER_VER="Stable"
#else
#    SUPER_VER="Experimental"
#fi

arr[0]=" to Version: Awesome!"
arr[1]=" to Version: Outstanding!"
arr[2]=" to Version: RevA_Final_Final2"
arr[3]=". Removed: gods, species, backgrounds, and monsters."
arr[4]=" to Version: Oh So Nice!"
arr[5]=" to Version: I really hope this works!"
arr[6]=" to Version: OMG THIS WILL BE SO GREAT!"
arr[7]="... you should check it out now..."
arr[8]=". YAY NEW STUFF!"


rand=$[ $RANDOM % 9 ]
themessage=${arr[$rand]}

announce "$SUPER_VER ($VERSION) branch on $DGL_SERVER updated${themessage}"

echo "All done."
echo
