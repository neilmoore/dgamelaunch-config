USER_ID="2002"
BASE_DIR="/var/lib/dgamelaunch"
VERSIONS_DB="${BASE_DIR}/versions.db3"
VERBOSE=0

set -e

verbose() {
    [[ "$VERBOSE" == "1" ]]
}

say() {
    if [[ "$VERBOSE" == "1" ]]; then
        echo "$@"
    fi
}