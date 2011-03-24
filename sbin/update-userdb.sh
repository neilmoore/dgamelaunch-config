#!/bin/bash

mysql --silent --skip-column-names -u dgl -e "select * from mantis_crawl.developers" | while read dev; do echo "update dglusers set flags=1 where username=\"$dev\";"; done | sqlite3 /var/lib/dgamelaunch/dgldir/data/passwd.db3

