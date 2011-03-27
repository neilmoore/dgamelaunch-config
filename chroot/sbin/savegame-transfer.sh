#!/bin/bash
#
# ===========================================================================
# Copyright (C) 2008, 2009, 2010, 2011 Marc H. Thoben
# Copyright (C) 2011 Darshan Shaligram
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# ===========================================================================
#

set -u

USER_ID="%%DGL_UID%%"
CHROOT="%%DGL_CHROOT%%"
PREFIX="$CHROOT%%CHROOT_CRAWL_BASEDIR%%"
VERSIONS_DB="%%VERSIONS_DB%%"

BINARY_MAIN_NAME="%%GAME%%"

C_NORMAL="\033[0m"
C_YELLOW="\033[1;33m"
C_GREEN="\033[1;32m"
C_RED="\033[1;31m"

PARAMS="$(echo "$*" | sed 's/[$*\();.|+-]//g')"

if test ${#PARAMS} -eq 0
then
	$(dirname $0)/remove-trunks.sh -v | grep -v "Usage:"
	echo "Usage: $(basename $0) <charname> [charname] ..." 
	exit 1
fi

LATEST_GAME_HASH="$(echo "select hash from versions order by time desc limit 1;" | sqlite3 ${VERSIONS_DB})"

for char in ${PARAMS}
do
    CHAR_NAME="${char}"
    GAME_MODE=""
    PS_MOD="rc"
    
    SAVE_FOUND="$(/bin/ls -1rt ${PREFIX}/${BINARY_MAIN_NAME}-*/saves/${CHAR_NAME}-${USER_ID}.sav ${PREFIX}/${BINARY_MAIN_NAME}-*/saves/${CHAR_NAME}-${USER_ID}.chr ${PREFIX}/${BINARY_MAIN_NAME}-*/saves/${CHAR_NAME}{-${USER_ID},}.cs 2>/dev/null | head -n 1)"

    if test ${#SAVE_FOUND} -ne 0
    then
	OUR_GAME_HASH="$(echo ${SAVE_FOUND} | sed "s|${PREFIX}/${BINARY_MAIN_NAME}-\(.*\)/saves/${CHAR_NAME}.*|\1|")"
	OUR_GAME_SV="$(echo select major,minor from versions where hash=\"${OUR_GAME_HASH}\"\; | sqlite3 -separator \. ${VERSIONS_DB})"
	echo -n "Char \"${CHAR_NAME}\" in ${OUR_GAME_HASH} (${OUR_GAME_SV}). "
        
	if test "${OUR_GAME_HASH}" != "${LATEST_GAME_HASH}"
	then
	    OUR_SGV_MAJOR="$(echo "select major from versions where hash=\"${OUR_GAME_HASH}\";" | sqlite3 ${VERSIONS_DB})"
	    POSSIBLE_GAME_HASH="$(echo "select hash from versions where major=${OUR_SGV_MAJOR} order by time desc limit 1;" | sqlite3 ${VERSIONS_DB})"
            
	    if test "${OUR_GAME_HASH}" != "${POSSIBLE_GAME_HASH}"
	    then
		POSSIBLE_GAME_SV="$(echo select major,minor from versions where hash=\"${POSSIBLE_GAME_HASH}\"\; | sqlite3 -separator \. ${VERSIONS_DB})"
		echo -n "Moving to ${POSSIBLE_GAME_HASH} (${POSSIBLE_GAME_SV}):"
                
		if test "$(basename ${CHAR_NAME})" != "${CHAR_NAME}"
		then
		    GAME_MODE="$(dirname ${CHAR_NAME})"
		    CHAR_NAME="$(basename ${CHAR_NAME})"
		    PS_MOD="${GAME_MODE}"
		fi
                
		if { ps -fC ${BINARY_MAIN_NAME}-${OUR_GAME_HASH} | awk '{ print $8, $9, $10, $11 }' | grep "\-name ${CHAR_NAME} \-${PS_MOD}" &>/dev/null; }
		then
		    echo -e " ${C_YELLOW}in use!${C_NORMAL}"
		    continue
		fi
                
		if test -d ${PREFIX}/${BINARY_MAIN_NAME}-${POSSIBLE_GAME_HASH}/saves/${GAME_MODE}
		then
		    mv ${PREFIX}/${BINARY_MAIN_NAME}-${OUR_GAME_HASH}/saves/${GAME_MODE}/${CHAR_NAME}* ${PREFIX}/${BINARY_MAIN_NAME}-${OUR_GAME_HASH}/saves/${GAME_MODE}/start-${CHAR_NAME}-ns.prf ${PREFIX}/${BINARY_MAIN_NAME}-${POSSIBLE_GAME_HASH}/saves/${GAME_MODE}/
		    if test $? -eq 0
		    then
			echo -e " ${C_GREEN}successful.${C_NORMAL}"
		    else
			echo -e " ${C_RED}failed1!${C_NORMAL}"
			continue
		    fi
                    
		else
		    echo -e " ${C_RED}failed2!${C_NORMAL}"
		    continue
		fi
	    else
		echo -e "${C_YELLOW}No transfer possible.${C_NORMAL}"
	    fi
	else
	    echo "No transfer necessary."
	fi
    else
	echo "Character \"${CHAR_NAME}\" not found."
    fi
done

exit 0