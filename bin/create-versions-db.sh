#! /bin/bash

source $DGL_CONF_HOME/crawl-build/crawl-git.conf

if [[ -f "$VERSIONS_DB" ]]; then
    echo -e "Crawl version db $VERSIONS_DB already exists, aborting."
    exit 1
fi

if [[ "$UID" != "0" ]]; then
    echo -e "This script must be run as root"
    exit 1
fi

set -e
cat $CRAWL_BUILD_DIR/version-db-schema.sql | sqlite3 $VERSIONS_DB