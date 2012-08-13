#! /bin/sh

ifnxcp() {
    [ -e "$2" ] || cp "$1" "$2";
}

NAME=$1

ifnxcp /dgldir/data/crawl-git-settings/init.txt /dgldir/rcfiles/crawl-git/"$NAME".rc
ifnxcp /dgldir/data/crawl-git.macro /dgldir/rcfiles/crawl-git/"$NAME".macro
ifnxcp /dgldir/data/crawl-0.11-settings/init.txt /dgldir/rcfiles/crawl-0.11/"$NAME".rc
ifnxcp /dgldir/data/crawl-git.macro /dgldir/rcfiles/crawl-0.11/"$NAME".macro
ifnxcp /dgldir/data/crawl-0.10-settings/init.txt /dgldir/rcfiles/crawl-0.10/"$NAME".rc
ifnxcp /dgldir/data/crawl-git.macro /dgldir/rcfiles/crawl-0.10/"$NAME".macro

mkdir -p /dgldir/morgue/"$NAME"
