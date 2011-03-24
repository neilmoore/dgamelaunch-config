#!/bin/bash

set -e
LOCK_FILE="${HOME}/.crawl_update.lock"

if test -f ${LOCK_FILE}
then
	echo
	echo "Someone is currently updating CDO already. Try again later."
	echo "Aborting..."
	echo
	exit 0
fi

cd ${HOME}/source/crawl-git

git checkout master
echo

exec ./update.sh $*

