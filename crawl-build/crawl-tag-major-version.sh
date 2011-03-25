#! /bin/bash

perl -lne 'print $1 if /#define\s+TAG_MAJOR_VERSION\s+(\d+)/' \
    source/tag-version.h
