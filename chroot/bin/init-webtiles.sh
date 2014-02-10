#! /bin/sh

ifnxcp() {
    [ -e "$2" ] || cp "$1" "$2";
}

NAME=$1

ifnxcp %%CHROOT_DGLDIR%%/data/crawl-farmer-settings/init.txt %%CHROOT_RCFILESDIR%%/crawl-farmer/"$NAME".rc
ifnxcp %%CHROOT_DGLDIR%%/data/crawl-farmer.macro %%CHROOT_RCFILESDIR%%/crawl-farmer/"$NAME".macro
ifnxcp %%CHROOT_DGLDIR%%/data/crawl-helen-settings/init.txt %%CHROOT_RCFILESDIR%%/crawl-helen/"$NAME".rc
ifnxcp %%CHROOT_DGLDIR%%/data/crawl-farmer.macro %%CHROOT_RCFILESDIR%%/crawl-helen/"$NAME".macro

mkdir -p %%CHROOT_MORGUEDIR%%/"$NAME"
mkdir -p %%CHROOT_TTYRECDIR%%/"$NAME"
