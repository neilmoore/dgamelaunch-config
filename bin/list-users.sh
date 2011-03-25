#!/bin/bash

sqlite3 %%LOGIN_DB%% <<EOF | sort -f
SELECT username FROM dglusers ORDER BY username;
EOF
