#! /bin/bash

check-chroot-exists
export DGL_CONF_HOME DGL_CHROOT
exec perl $DGL_CONF_HOME/bin/publish.pl "$@"
