#!/bin/bash
#
# This script needs a sudo entry for user crawl to run as root:
# For obvious reasons, this script should not source any other scripts that
# are not owned by root.

set -e

# This is not overrideable:
CHROOT=/var/lib/dgamelaunch

if [[ "$UID" != "0" ]]; then
    echo "$0 must be run as root"
    exit 1
fi

install-game() {
    rmdir $SAVEDIR/morgue || true
    rm -f $SAVEDIR/saves/logfile || true
    rm -f $SAVEDIR/saves/scores || true
    rmdir $SAVEDIR/saves || true
    mkdir -p $ABS_COMMON_DIR/morgue
    chown $CRAWL_UGRP $ABS_COMMON_DIR/morgue || true
    mkdir -p $ABS_COMMON_DIR/saves
    test -f $ABS_COMMON_DIR/saves/logfile || \
	touch $ABS_COMMON_DIR/saves/logfile
    chown $CRAWL_UGRP $ABS_COMMON_DIR/saves/logfile
    test -f $ABS_COMMON_DIR/saves/milestones || \
	touch $ABS_COMMON_DIR/saves/milestones
    chown $CRAWL_UGRP $ABS_COMMON_DIR/saves/milestones
    test -f $ABS_COMMON_DIR/saves/scores || \
	touch $ABS_COMMON_DIR/saves/scores
    chown $CRAWL_UGRP $ABS_COMMON_DIR/saves/scores
    test -f $ABS_COMMON_DIR/saves/logfile-sprint || \
	touch $ABS_COMMON_DIR/saves/logfile-sprint
    chown $CRAWL_UGRP $ABS_COMMON_DIR/saves/logfile-sprint
    test -f $ABS_COMMON_DIR/saves/milestones-sprint || \
	touch $ABS_COMMON_DIR/saves/milestones-sprint
    chown $CRAWL_UGRP $ABS_COMMON_DIR/saves/milestones-sprint
    test -f $ABS_COMMON_DIR/saves/scores-sprint || \
	touch $ABS_COMMON_DIR/saves/scores-sprint
    chown $CRAWL_UGRP $ABS_COMMON_DIR/saves/scores-sprint
    test -f $ABS_COMMON_DIR/saves/logfile-zotdef || \
	touch $ABS_COMMON_DIR/saves/logfile-zotdef
    chown $CRAWL_UGRP $ABS_COMMON_DIR/saves/logfile-zotdef
    test -f $ABS_COMMON_DIR/saves/milestones-zotdef || \
	touch $ABS_COMMON_DIR/saves/milestones-zotdef
    chown $CRAWL_UGRP $ABS_COMMON_DIR/saves/milestones-zotdef
    test -f $ABS_COMMON_DIR/saves/scores-zotdef || \
	touch $ABS_COMMON_DIR/saves/scores-zotdef
    chown $CRAWL_UGRP $ABS_COMMON_DIR/saves/scores-zotdef
    cp ../README.txt $ABS_COMMON_DIR/
    test -h $DATADIR/docs || \
	rm -f -r $ABS_COMMON_DIR/docs && \
	mv $DATADIR/docs $ABS_COMMON_DIR/
    test -h $DATADIR/settings || \
	rm -f -r $ABS_COMMON_DIR/settings && \
	mv $DATADIR/settings $ABS_COMMON_DIR/
    ln -sf $ABS_COMMON_DIR/data/README.txt $DATADIR/
    ln -sf $ABS_COMMON_DIR/data/docs $DATADIR/
    ln -sf $ABS_COMMON_DIR/data/morgue $DATADIR/
    ln -sf $ABS_COMMON_DIR/data/settings $DATADIR/
    mkdir -p $SAVEDIR
    chown $CRAWL_UGRP $SAVEDIR || true
    chmod 755 $SAVEDIR || true
    mkdir -p $SAVEDIR/sprint
    chown $CRAWL_UGRP $SAVEDIR/sprint || true
    chmod 755 $SAVEDIR/sprint || true
    mkdir -p $SAVEDIR/zotdef
    chown $CRAWL_UGRP $SAVEDIR/zotdef || true
    chmod 755 $SAVEDIR/zotdef || true

    ln -sf $COMMON_DIR/saves/logfile $DATADIR/saves/
    ln -sf $COMMON_DIR/saves/milestones $DATADIR/saves/
    ln -sf $COMMON_DIR/saves/scores $DATADIR/saves/
    ln -sf $COMMON_DIR/saves/logfile-sprint $DATADIR/saves/
    ln -sf $COMMON_DIR/saves/milestones-sprint $DATADIR/saves/
    ln -sf $COMMON_DIR/saves/scores-sprint $DATADIR/saves/
    ln -sf $COMMON_DIR/saves/logfile-zotdef $DATADIR/saves/
    ln -sf $COMMON_DIR/saves/milestones-zotdef $DATADIR/saves/
    ln -sf $COMMON_DIR/saves/scores-zotdef $DATADIR/saves/
}

register-game-version() {
    echo
    echo "Adding version (${SGV_MAJOR}.${SGV_MINOR}) to database..."
    sqlite3 ${VERSIONS_DB} <<SQL
INSERT INTO VERSIONS VALUES ('${REVISION}', $(date +%s),
                             ${SGV_MAJOR}, ${SGV_MINOR}, 1);
SQL
}

assert-not-evil() {
    local path=$1
    if [[ "$path" =~ ([.]{2}|[^a-z0-9_/-]) ]]; then
        echo -e "Path $path contains characters I don't like, aborting."
        exit 1
    fi
}

if test -n "${GAME}" -a -n "${REVISION}" -a -n "${DESTDIR}" -a -n "${PRIMARY_BRANCH_REMOTE}" -a -n "${VERSIONS_DB}" -a -n "$CRAWL_UGRP"; then
    if [[ -n "${SGV_MAJOR}" && -n "${SGV_MINOR}" ]]; then
        COMMON_DIR=$CHROOT_CRAWL_BASEDIR/$GAME
        assert-not-evil "$COMMON_DIR"
        ABS_COMMON_DIR=$CHROOT$CHROOT_CRAWL_BASEDIR/$GAME

        if [[ ! -d "$CHROOT$COMMON_DIR" ]]; then
            echo -e "Expected to find common game dir $ABS_COMMON_DIR but did not find it"
            exit 1
        fi
        
        SAVEDIR=$CHROOT/$CHROOT_CRAWL_BASEDIR/${GAME}-${REVISION}/saves
        DATADIR=$CHROOT/$CHROOT_CRAWL_BASEDIR/${GAME}-${REVISION}/data
        assert-not-evil "$SAVEDIR"
        assert-not-evil "$DATADIR"
        install-game
        register-game-version
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