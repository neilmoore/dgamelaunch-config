#! /bin/sh

ifnxcp() {
    [ -e "$2" ] || cp "$1" "$2";
}

NAME=$1

ifnxcp %%CHROOT_DGLDIR%%/data/crawl-git-settings/init.txt %%CHROOT_RCFILESDIR%%/crawl-git/"$NAME".rc
ifnxcp %%CHROOT_DGLDIR%%/data/crawl-git.macro %%CHROOT_RCFILESDIR%%/crawl-git/"$NAME".macro
ifnxcp %%CHROOT_DGLDIR%%/data/crawl-0.24-settings/init.txt %%CHROOT_RCFILESDIR%%/crawl-0.23/"$NAME".rc
ifnxcp %%CHROOT_DGLDIR%%/data/crawl-git.macro %%CHROOT_RCFILESDIR%%/crawl-0.24/"$NAME".macro
ifnxcp %%CHROOT_DGLDIR%%/data/crawl-0.23-settings/init.txt %%CHROOT_RCFILESDIR%%/crawl-0.23/"$NAME".rc
ifnxcp %%CHROOT_DGLDIR%%/data/crawl-git.macro %%CHROOT_RCFILESDIR%%/crawl-0.23/"$NAME".macro
ifnxcp %%CHROOT_DGLDIR%%/data/crawl-0.22-settings/init.txt %%CHROOT_RCFILESDIR%%/crawl-0.22/"$NAME".rc
ifnxcp %%CHROOT_DGLDIR%%/data/crawl-git.macro %%CHROOT_RCFILESDIR%%/crawl-0.22/"$NAME".macro
ifnxcp %%CHROOT_DGLDIR%%/data/crawl-0.21-settings/init.txt %%CHROOT_RCFILESDIR%%/crawl-0.21/"$NAME".rc
ifnxcp %%CHROOT_DGLDIR%%/data/crawl-git.macro %%CHROOT_RCFILESDIR%%/crawl-0.21/"$NAME".macro
ifnxcp %%CHROOT_DGLDIR%%/data/crawl-0.20-settings/init.txt %%CHROOT_RCFILESDIR%%/crawl-0.20/"$NAME".rc
ifnxcp %%CHROOT_DGLDIR%%/data/crawl-git.macro %%CHROOT_RCFILESDIR%%/crawl-0.20/"$NAME".macro
ifnxcp %%CHROOT_DGLDIR%%/data/crawl-0.19-settings/init.txt %%CHROOT_RCFILESDIR%%/crawl-0.19/"$NAME".rc
ifnxcp %%CHROOT_DGLDIR%%/data/crawl-git.macro %%CHROOT_RCFILESDIR%%/crawl-0.19/"$NAME".macro
ifnxcp %%CHROOT_DGLDIR%%/data/crawl-0.18-settings/init.txt %%CHROOT_RCFILESDIR%%/crawl-0.18/"$NAME".rc
ifnxcp %%CHROOT_DGLDIR%%/data/crawl-git.macro %%CHROOT_RCFILESDIR%%/crawl-0.18/"$NAME".macro
ifnxcp %%CHROOT_DGLDIR%%/data/crawl-0.17-settings/init.txt %%CHROOT_RCFILESDIR%%/crawl-0.17/"$NAME".rc
ifnxcp %%CHROOT_DGLDIR%%/data/crawl-git.macro %%CHROOT_RCFILESDIR%%/crawl-0.17/"$NAME".macro
ifnxcp %%CHROOT_DGLDIR%%/data/crawl-0.16-settings/init.txt %%CHROOT_RCFILESDIR%%/crawl-0.16/"$NAME".rc
ifnxcp %%CHROOT_DGLDIR%%/data/crawl-git.macro %%CHROOT_RCFILESDIR%%/crawl-0.16/"$NAME".macro
ifnxcp %%CHROOT_DGLDIR%%/data/crawl-0.15-settings/init.txt %%CHROOT_RCFILESDIR%%/crawl-0.15/"$NAME".rc
ifnxcp %%CHROOT_DGLDIR%%/data/crawl-git.macro %%CHROOT_RCFILESDIR%%/crawl-0.15/"$NAME".macro
ifnxcp %%CHROOT_DGLDIR%%/data/crawl-0.14-settings/init.txt %%CHROOT_RCFILESDIR%%/crawl-0.14/"$NAME".rc
ifnxcp %%CHROOT_DGLDIR%%/data/crawl-git.macro %%CHROOT_RCFILESDIR%%/crawl-0.14/"$NAME".macro
ifnxcp %%CHROOT_DGLDIR%%/data/crawl-0.13-settings/init.txt %%CHROOT_RCFILESDIR%%/crawl-0.13/"$NAME".rc
ifnxcp %%CHROOT_DGLDIR%%/data/crawl-git.macro %%CHROOT_RCFILESDIR%%/crawl-0.13/"$NAME".macro

mkdir -p %%CHROOT_MORGUEDIR%%/"$NAME"
mkdir -p %%CHROOT_TTYRECDIR%%/"$NAME"
