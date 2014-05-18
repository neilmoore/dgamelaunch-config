#! /bin/sh

ifnxcp() {
    [ -e "$2" ] || cp "$1" "$2";
}

NAME=$1

ifnxcp %%CHROOT_DGLDIR%%/data/crawl-git-settings/init.txt %%CHROOT_RCFILESDIR%%/crawl-git/"$NAME".rc
ifnxcp %%CHROOT_DGLDIR%%/data/crawl-git.macro %%CHROOT_RCFILESDIR%%/crawl-git/"$NAME".macro

mkdir -p %%CHROOT_MORGUEDIR%%/"$NAME"
mkdir -p %%CHROOT_TTYRECDIR%%/"$NAME"
