#!/bin/bash

set -e

REPO_DIR=$PWD/$CRAWL_REPOSITORY_DIR

clone-crawl-ref() {
    if [[ -d "$CRAWL_REPOSITORY_DIR" && -d "$CRAWL_REPOSITORY_DIR/.git" ]]; then
        return 0
    fi
    announce "Cloning $CRAWL_GIT_URL into $REPO_DIR"
    git clone $CRAWL_GIT_URL $CRAWL_REPOSITORY_DIR
}

update-crawl-ref() {
    announce "Updating git repository $REPO_DIR"
    ( cd $REPO_DIR && git pull )
}

update-submodules() {
    announce "Updating git submodules in $REPO_DIR"
    ( cd $REPO_DIR && git submodule update --init )
}

clone-crawl-ref
update-crawl-ref
update-submodules
