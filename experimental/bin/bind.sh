#!/bin/sh

set -e

if [ "$#" -lt 2 ]; then
    echo "$0 [src] [dst] [args...]"
    exit 1
fi

src="$1"; shift
dst="$1"; shift

mount --bind "$src" "$dst"

env --chdir="$PWD" "$@"
