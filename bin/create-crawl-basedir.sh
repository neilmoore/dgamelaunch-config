#! /bin/bash

source $DGL_CONF_HOME/crawl-git.conf

echo "Crawl basedir to create: $CRAWL_BASEDIR"

[[ -d "$CRAWL_BASEDIR" ]] && abort-saying "Crawl base directory already exists"
check-chroot-exists
[[ "$UID" != "0" ]] && abort-saying "This script must be run as root"

mkdir -p $CRAWL_BASEDIR/saves
( cd $CRAWL_BASEDIR/saves &&
    touch logfile{,-sprint,-zotdef} \
        milestones{,-sprint,-zotdef} \
        scores{,-sprint,-zotdef} )

echo "Created $CRAWL_BASEDIR"