#! /bin/bash

source $DGL_CONF_HOME/sh-utils
source $DGL_CONF_HOME/crawl-git.conf

crawl-do perl -lne 'print $1 if /#define\s+TAG_MAJOR_VERSION\s+(\d+)/' \
           source/tag-version.h
