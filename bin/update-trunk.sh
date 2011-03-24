#!/bin/bash

set -e
cd $DGL_CONF_HOME/crawl-build
exec ./update-crawl-trunk-build.sh "$@"