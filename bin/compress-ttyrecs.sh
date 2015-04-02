#! /bin/bash

source $DGL_CONF_HOME/crawl-git.conf

if [[ $UID != 0 ]]; then
    echo "$0 must be run as root!"
    exit 1
fi

if [[ $1 == -v || $1 == --verbose ]]; then
    verbose=1
else
    verbose=0
fi

verbiate() {
    ((verbose)) && echo "$@" >&2
}

quietly() {
    "$@" >/dev/null 2>&1
}

failures=()
skip=0 succ=0 fail=0
shopt -s nullglob
for ttyrec in "$TTYRECDIR"/*/*.ttyrec; do
    # If anyone has it open, skip it.
    if quietly lsof "$ttyrec"; then
        verbiate -n "."
        let ++skip
        continue
    fi
    if bzip2 "$ttyrec"; then
        let ++succ
        verbiate -n "+"
    else
        let ++fail
        verbiate -n "X"
        failures+=( "$ttyrec" )
    fi
done
verbiate

if (( failed || verbose )); then
    printf "%d succeeded\t%d failed\t%d skipped\n" "$succ" "$fail" "$skip"
    if (( failed )); then
        printf "\nFailing files:\n"
        printf "  %s\n" "${failures[@]}"
        exit 1
    fi
fi

exit 0
