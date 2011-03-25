#!/bin/bash

CHROOT="%%DGL_CHROOT%%"
BASEDIR="$CHROOT%%CHROOT_CRAWL_BASEDIR%%"
GAME="%%GAME%%"

list_hashes()
{
    cd ${BASE_DIR}
    
    if verbose; then
	echo "Date              Hash       Version  Amount  Players"
	echo "********************************************************"
        
	for folder in $(/bin/ls -1td $GAME-*)
	do
	    /bin/ls -1tdl ${folder} 2>/dev/null | \
		sed 's/%%GAME%%-//g;' | \
		awk '{ printf "%3s %2s  %s    %-9s  %6s %6s    ", $6, $7, $8, $9, "'$(echo select major,minor from versions where hash=\"${folder/%%GAME%%-/}\"\; | sqlite3 -separator \. ${VERSIONS_DB})'", "'$(/bin/ls -1 ${folder}/saves/*.sav ${folder}/saves/*.chr ${folder}/saves/*.cs ${folder}/saves/sprint/*.cs ${folder}/saves/zotdef/*.cs 2>/dev/null | wc -l)'" }'
            
	    for char in $(/bin/ls -1 ${folder}/saves/*.sav ${folder}/saves/*.chr ${folder}/saves/*.cs 2>/dev/null | sed 's/-'${USER_ID}'//g;s/\.\(sav\|chr\|cs\)//g;')
	    do
		echo -n "$(basename ${char}) "
	    done
            
	    for char in $(/bin/ls -1 ${folder}/saves/sprint/*.cs 2>/dev/null | sed 's/-'${USER_ID}'//g;s/\.cs$//g;')
	    do
		echo -n "sprint/$(basename ${char}) "
	    done
            
	    for char in $(/bin/ls -1 ${folder}/saves/zotdef/*.cs 2>/dev/null | sed 's/-'${USER_ID}'//g;s/\.cs$//g;')
	    do
		echo -n "zotdef/$(basename ${char}) "
	    done
            
	    echo
	done
    else
	echo "Date              Hash       Version   Players in Games"
	echo "*******************************************************************"
        
	for folder in $(/bin/ls -1td $GAME-*)
	do
	    /bin/ls -1tdl ${folder} 2>/dev/null | \
		sed 's/%%GAME%%-//g;' | \
		awk '{ printf "%3s %2s  %s    %-9s  %6s %6s in trunk, %3s in sprint, %3s in zotdef", $6, $7, $8, $9, "'$(echo select major,minor from versions where hash=\"${folder/%%GAME%%-/}\"\; | sqlite3 -separator \. ${VERSIONS_DB})'", "'$(/bin/ls -1 ${folder}/saves/*.sav ${folder}/saves/*.chr ${folder}/saves/*.cs 2>/dev/null | wc -l)'", "'$(/bin/ls -1 ${folder}/saves/sprint/*.cs 2>/dev/null | wc -l)'", "'$(/bin/ls -1 ${folder}/saves/zotdef/*.cs 2>/dev/null | wc -l)'"}'
            
	    echo
	done
    fi
}

WAIT_KEY=1
if test "$1" = "-q"
then
    WAIT_KEY=0
    shift
fi

if test "$1" = "-v"
then
    VERBOSE=1
    shift
fi

PARAMS="$(echo "$*" | sed 's/[$*\/();.|+-]//g')"

if test $# -eq 0
then
    if test ${WAIT_KEY} -eq 1
    then
	echo "Usage: $(basename $0) [-q] [-v] [hash] [hash] ..." 
	echo
    fi
    list_hashes
    echo
    exit 0
fi

cd ${BASE_DIR}

for version in ${PARAMS}
do
    if test -f bin/%%GAME%%-${version} -a -d %%GAME%%-${version}
	then
	if test ${WAIT_KEY} -eq 1
	then		
	    while { ps -fC %%GAME%%-${version} | awk '{ print $1" "$2"\t "$5" "$7"\t "$8" "$9" "$10 }' | grep ^dgl; }
	    do
		echo "There are still active crawl processes running..."
		echo "-- Press RETURN to try again --"
		read
	    done
            
	    echo "Removing ${version} from repository..."
	    echo "delete from versions where hash=\"${version}\";"| sqlite3 ${VERSIONS_DB}
	    rm bin/%%GAME%%-${version}
	    rm -r %%GAME%%-${version}
	else
	    if { ps -fC %%GAME%%-${version} | awk '{ print $1" "$2"\t "$5" "$7"\t "$8" "$9" "$10 }' | grep ^dgl >/dev/null; }
	    then
		echo "Revision ${version} is being played..."
	    else
		echo "Removing ${version} from repository..."
		echo "delete from versions where hash=\"${version}\";"| sqlite3 ${VERSIONS_DB}
		rm bin/%%GAME%%-${version}
		rm -r %%GAME%%-${version}
	    fi
	fi
    else
	echo "Revision ${version} not found..."
    fi
done

echo
exit 0