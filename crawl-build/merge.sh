#!/bin/bash

set -e

if test "${CONFIG_READ}" != "true"
then
	. update.conf
fi

echo "Fetching remote branches:"
echo "-------------------------"
for remote in ${BRANCH_REMOTE}
do
	remote="${remote/\/*/}"

	if ! [[ "${fetched}" =~ "${remote}" ]]
	then
		echo "${remote}:"
		echo ${#remote} | awk '{ for (i = 0; i <= $1; i++) printf "-"; printf "\n" }'
		git fetch ${remote}
		echo
		fetched+="${remote} "
	fi
done

echo "Merging local with remote branches:"
echo "-----------------------------------"
for branch in ${BRANCH_REMOTE}
do
	echo "${branch}:"
	echo ${#branch} | awk '{ for (i = 0; i <= $1; i++) printf "-"; printf "\n" }'
	git rebase ${branch}
	echo
done

echo "Updating submodules:"
echo "--------------------"
git submodule update --init
echo

for sub in $(git submodule | awk '{ print $2 }')
do
	echo -n "${sub} "
	(cd $sub && git checkout . && git clean -f >/dev/null )
done
echo

git submodule update --init
echo

