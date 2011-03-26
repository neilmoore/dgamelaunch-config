#!/bin/bash

set -u

CHROOT="%%DGL_CHROOT%%"
BASE_DIR="%%CHROOT_CRAWL_BASEDIR%%"
GAME="%%GAME%%"

BINPATH="%%CHROOT_CRAWL_BINARY_PATH%%"
VERSIONS_DB="%%VERSIONS_DB%%"
USER_ID="%%DGL_UID%%"
DGL_USER="%%DGL_USER%%"

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

hash-version-detail() {
    local hash="$1"
    sqlite3 -separator \. "$VERSIONS_DB" <<EOF
SELECT description,major,minor
FROM versions
WHERE hash='$hash';
EOF
}

saves-in-dir() {
    local folder="$1"
    local -a globs
    globs=(${folder}/saves/{,sprint/,zotdef/}*.{sav,chr,cs})
    if (( $# == 2 )); then
        local suffix="/$2"
        globs=($folder/saves$suffix/*.{sav,chr,cs})
    fi
    /bin/ls -1 ${globs[@]} 2>/dev/null
}

count-saves-in-dir() {
    saves-in-dir "$@" | wc -l
}

strip-save-uid-extension() {
    sed 's/-'${USER_ID}'//g;s/\.\(sav\|chr\|cs\)//g;'
}

savegame-dirs() {
    /bin/ls -1td $GAME_GLOB
}
    
list_hashes()
{
    cd $CHROOT/$BASE_DIR
    
    if verbose; then
	echo "Date              Hash       Version  Amount  Players"
	echo "********************************************************"
        
	for folder in $(savegame-dirs); do
            local hash=${folder/$GAME_BASE/}
	    /bin/ls -1tdl ${folder} 2>/dev/null | \
		sed "s/$GAME_BASE//g;" | \
		awk '{ printf "%3s %2s  %s    %-9s  %6s %6s    ",
                    $6, $7, $8, $9,
                    "'$(hash-version-detail $hash)'",
                    "'$(count-saves-in-dir "$folder")'" }'
            
	    for char in $(saves-in-dir "$folder" | strip-save-uid-extension)
	    do
		echo -n "$(basename ${char}) "
	    done
            
	    echo
	done
    else
	echo "Date              Hash       Version   Players in Games"
	echo "*******************************************************************"
        
	for folder in $(savegame-dirs)
	do
            local hash=${folder/$GAME_BASE/}
	    /bin/ls -1tdl ${folder} 2>/dev/null | \
		sed "s/$GAME_BASE//g;" | \
		awk '{ printf "%3s %2s  %s    %-9s  %6s %6s in trunk, %3s in sprint, %3s in zotdef", $6, $7, $8, $9,
                    "'$(hash-version-detail $hash)'",
                    "'$(count-saves-in-dir "$folder" '')'",
                    "'$(count-saves-in-dir "$folder" 'sprint')'",
                    "'$(count-saves-in-dir "$folder" 'zotdef')'"
                     }'
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
	    while { ps -fC $GAME_VER | awk '{ print $1" "$2"\t "$5" "$7"\t "$8" "$9" "$10 }' | grep ^"$DGL_USER"; }
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
	    if { ps -fC $GAME_VER | awk '{ print $1" "$2"\t "$5" "$7"\t "$8" "$9" "$10 }' | grep ^"$DGL_USER" >/dev/null; }
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