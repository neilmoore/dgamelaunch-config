#!/bin/bash
#
# This script needs a sudo entry for user crawl to run as root:
# For obvious reasons, this script should not source any other scripts that
# are not owned by root.
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

set -e
set -u
shopt -s extglob

# These are not overrideable:
CHROOT="%%DGL_CHROOT%%"
CHROOT_CRAWL_BASEDIR="%%CHROOT_CRAWL_BASEDIR%%"
CRAWL_UGRP="%%CRAWL_UGRP%%"

# Safe path:
PATH=/bin:/sbin:/usr/bin:/usr/sbin

if [[ "$UID" != "0" ]]; then
    echo "$0 must be run as root"
    exit 1
fi

install-webserver() {
    echo "Copying web server files to $WEBDIR"
    cp -r source/webserver/!(config.py|config.toml|game_data|templates|games.conf.d) "$WEBDIR"
    cp source/webserver/templates/!(banner.html) "$WEBDIR"/templates/
    chown -R "$CRAWL_UGRP" "$WEBDIR"
}

assert-not-evil() {
    local file=$1
    if [[ "$file" != "$(echo "$file" |
                        perl -lpe 's{[.]{2}|[^.a-zA-Z0-9_/-]+}{}g')" ]]
    then
        echo -e "Path $file contains characters I don't like, aborting."
        exit 1
    fi
}

assert-all-variables-exist() {
    local -a broken_variables=()
    for variable_name in "$@"; do
        eval "value=\"\$$variable_name\""
        if [[ -z "$value" ]]; then
            broken_variables=(${broken_variables[@]} $variable_name)
        fi
    done
    if (( ${#broken_variables[@]} > 0 )); then
        echo -e "These variables are required, but are unset:" \
            "${broken_variables[@]}"
        exit 1
    fi
}

if [[ ! ( "$CRAWL_UGRP" =~ ^[a-z0-9]+:[a-z0-9]+$ ) ]]; then
    echo -e "Expected CRAWL_UGRP to be user:group, but got $CRAWL_UGRP"
    exit 1
fi

WEBDIR=$CHROOT$CHROOT_CRAWL_BASEDIR/webserver
assert-not-evil "$WEBDIR"

echo "Installing webserver"
install-webserver
