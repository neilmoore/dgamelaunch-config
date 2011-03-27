#! /bin/bash

set -e

DGAMELAUNCH="$(which dgamelaunch 2>/dev/null || true)"
[[ -n "$DGAMELAUNCH" ]] || DGAMELAUNCH=/usr/local/sbin/dgamelaunch
if [[ -z "$DGAMELAUNCH" || ! -x "$DGAMELAUNCH" ]]; then
    abort-saying "Cannot find dgamelaunch binary"
fi

STRACE_OUT=strace.out

if not-running-as-root; then
    cat-error <<EOF
$SCRIPT_NAME: runs dgamelaunch with the current (testing) configuration

Run this command as root to test your dgamelaunch.conf

Options:
    --strace: Run dgamelaunch with strace and dump strace output to $STRACE_OUT

EOF
    exit 1
fi

[[ "$1" == "--strace" ]] && STRACE=1 || STRACE=

TEST_FILE=dgamelaunch.conf
TMP_DIR=.tmp

trap "rm $TMP_DIR/$TEST_FILE && rmdir $TMP_DIR" EXIT

mkdir -p $TMP_DIR
dgl-run publish-conf --target /$PWD/$TMP_DIR

if [[ -z "$STRACE" ]]; then
    "$DGAMELAUNCH" -f "$TMP_DIR/$TEST_FILE"
else
    strace -f "$DGAMELAUNCH" -f "$TMP_DIR/$TEST_FILE" 2>$STRACE_OUT
fi