#!/bin/bash

echo "select username from dglusers where flags=1;" | sqlite3 /var/lib/dgamelaunch/dgldir/data/passwd.db3 | sort -f

