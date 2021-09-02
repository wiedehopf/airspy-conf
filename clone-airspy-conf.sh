#!/bin/bash

if ! command -v git &>/dev/null || ! command -v airspy_rx &>/dev/null || ! command -v curl &>/dev/null; then
    apt update
    apt install -y --no-install-suggests --no-install-recommends git airspy curl
fi

function getGIT() {
    # getGIT $REPO $BRANCH $TARGET-DIR
    if [[ -z "$1" ]] || [[ -z "$2" ]] || [[ -z "$3" ]]; then
        echo "getGIT wrong usage, check your script or tell the author!" 1>&2
        return 1
    fi
    if ! cd "$3" &>/dev/null || ! git fetch --depth 1 origin "$2" || ! git reset --hard FETCH_HEAD; then
        if ! rm -rf "$3" || ! git clone --depth 1 --single-branch --branch "$2" "$1" "$3"; then
            return 1
        fi
    fi
    return 0
}
target=/usr/local/share/airspy-conf
repo=https://github.com/wiedehopf/airspy-conf.git

getGIT "$repo" "master" "$target" || { echo "Failed to load the repository!"; exit 1; }

echo ----------
echo Done.
