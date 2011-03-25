#!/bin/bash

set -u

CHROOT="%%DGL_CHROOT%%"
BASE_DIR="%%CHROOT_CRAWL_BASEDIR%%"
GAME="%%GAME%%"

BINPATH="%%CHROOT_CRAWL_BINARY_PATH%%"
VERSIONS_DB="%%VERSIONS_DB%%"
USER_ID="%%DGL_UID%%"

GAME_BASE="$GAME-"
GAME_GLOB="$GAME_BASE*"

VERBOSE=
PROMPTS_ENABLED=1

# Toss the leading slash:
BASE_DIR=${BASE_DIR#/}
BINPATH=${BINPATH#/}

while getopts vq opt; do
    case $opt in
        v) VERBOSE=1 ;;
        q) PROMPTS_ENABLED= ;;
    esac
done
shift $((OPTIND - 1))

verbose() {
    [[ -n "$VERBOSE" ]]
}

prompts-enabled() {
    [[ -n "$PROMPTS_ENABLED" ]]
}
    
list_hashes()
{
    cd $CHROOT/$BASE_DIR
    
    if verbose; then
	echo "Date              Hash       Version  Amount  Players"
	echo "********************************************************"
        
	for folder in $(/bin/ls -1td $GAME_GLOB)
	do
	    /bin/ls -1tdl ${folder} 2>/dev/null | \
		sed "s/$GAME_BASE//g;" | \
		awk '{ printf "%3s %2s  %s    %-9s  %6s %6s    ", $6, $7, $8, $9, "'$(echo select major,minor from versions where hash=\"${folder/$GAME_BASE/}\"\; | sqlite3 -separator \. ${VERSIONS_DB})'", "'$(/bin/ls -1 ${folder}/saves/*.sav ${folder}/saves/*.chr ${folder}/saves/*.cs ${folder}/saves/sprint/*.cs ${folder}/saves/zotdef/*.cs 2>/dev/null | wc -l)'" }'
            
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
        
	for folder in $(/bin/ls -1td $GAME_GLOB)
	do
	    /bin/ls -1tdl ${folder} 2>/dev/null | \
		sed "s/$GAME_BASE//g;" | \
		awk '{ printf "%3s %2s  %s    %-9s  %6s %6s in trunk, %3s in sprint, %3s in zotdef", $6, $7, $8, $9, "'$(echo select major,minor from versions where hash=\"${folder/$GAME_BASE/}\"\; | sqlite3 -separator \. ${VERSIONS_DB})'", "'$(/bin/ls -1 ${folder}/saves/*.sav ${folder}/saves/*.chr ${folder}/saves/*.cs 2>/dev/null | wc -l)'", "'$(/bin/ls -1 ${folder}/saves/sprint/*.cs 2>/dev/null | wc -l)'", "'$(/bin/ls -1 ${folder}/saves/zotdef/*.cs 2>/dev/null | wc -l)'"}'
            
	    echo
	done
    fi
}

PARAMS="$(echo "$*" | sed 's/[$*\/();.|+-]//g')"

if test $# -eq 0
then
    if prompts-enabled; then
	echo "Usage: $(basename $0) [-q] [-v] [hash] [hash] ..." 
	echo
    fi
    list_hashes
    echo
    exit 0
fi

cd $CHROOT


for version in ${PARAMS}
do
    GAME_VER="$GAME-$version"
    if test -f $BINPATH/$GAME_VER -a -d $BASE_DIR/$GAME_VER
	then
	if prompts-enabled; then
	    while { ps -fC $GAME_VER | awk '{ print $1" "$2"\t "$5" "$7"\t "$8" "$9" "$10 }' | grep ^dgl; }
	    do
		echo "There are still active crawl processes running..."
		echo "-- Press RETURN to try again --"
		read
	    done
            
	    echo "Removing ${version} from repository..."
	    echo "delete from versions where hash=\"${version}\";"| sqlite3 ${VERSIONS_DB}
	    rm $BINPATH/$GAME_VER
	    rm -r $BASE_DIR/$GAME_VER
	else
	    if { ps -fC $GAME_VER | awk '{ print $1" "$2"\t "$5" "$7"\t "$8" "$9" "$10 }' | grep ^dgl >/dev/null; }
	    then
		echo "Revision ${version} is being played..."
	    else
		echo "Removing ${version} from repository..."
		echo "delete from versions where hash=\"${version}\";"| sqlite3 ${VERSIONS_DB}
		rm $BINPATH/$GAME_VER
		rm -r $BASE_DIR/$GAME_VER
	    fi
	fi
    else
	echo "Revision ${version} not found..."
    fi
done

echo
exit 0