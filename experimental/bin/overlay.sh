#!/bin/sh

set -e

# Print usage when input is incorrect
if [ "$#" -lt 5 ] || ! command -v "$1" > /dev/null 2>&1 ; then
    echo "$0 [overlayfs command] [lower] [upper] [work] [merge] [args...]"
    exit 1
fi

# Swallow required args
overlayfscmd="$1"; shift
lower="$1";        shift
upper="$1";        shift
work="$1";         shift
merge="$1";        shift

# Defensively unmount
fusermount -u "$merge" > /dev/null 2>&1 || true

# First process runs the overlay mount
if [ "$SLURM_LOCALID" = 0 ] || [ -z "${SLURM_LOCALID+x}" ]; then
    "$overlayfscmd" -o "auto_unmount,big_writes,max_write=1048576,threaded=0,lowerdir=$lower,upperdir=$upper,workdir=$work" "$merge"
fi

# Other processes wait for it to come into existence
while ! mountpoint -q "$merge"; do
    sleep 1
done

# Execute the actual command

env --chdir="$PWD" "$@"

fusermount -u "$merge" > /dev/null 2>&1 || true
