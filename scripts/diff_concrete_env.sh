#!/bin/sh

# usage: diff_concrete_env.sh path/to/spack/root path/to/env abcdef 123456
# output: env.diff, the diff of the concrete environment concretized with Spack commit
#         abcdef -> 123456.

set -e

bold_cyan='\e[1;36m'
bold_green='\e[1;32m'
no_color='\e[0m'

if [ ! -d "$1" ] || [ ! -d "$2" ] || [ ! "$3" ] || [ ! "$4" ]; then
    echo "Usage: $0 [spack root] [env dir] [old sha] [new sha]"
    exit 1
fi

# Make sure that the user sets a path to the system config:
if [ ! -d "$SPACK_SYSTEM_CONFIG_PATH" ]; then
    echo "Make sure to point SPACK_SYSTEM_CONFIG_PATH to a directory containing Spack config files"
    exit 1
fi

root="$(dirname "$(dirname "$(readlink -f "$0")")")"
spack_dir="$1"
env_dir="$2"
old_sha="$3"
new_sha="$4"

printf "👉 Diffing environment %b → %b.\n" "${bold_cyan}${old_sha}${no_color}" "${bold_green}${new_sha}${no_color}"

# Put spack in the PATH
export PATH="$spack_dir/bin:$PATH"

# Concretize with old Spack
git -C "$spack_dir" reset --hard "$old_sha"
spack -e "$env_dir" concretize -f
mv "$env_dir/spack.lock" "$env_dir/spack.$old_sha.lock"

# Concretize with new Spack
git -C "$spack_dir" reset --hard "$new_sha"
spack -e "$env_dir" concretize -f
mv "$env_dir/spack.lock" "$env_dir/spack.$new_sha.lock"

# Apply the patch that allows diffing environment files
(cd "$spack_dir" && git apply "$root/patches/26469.patch")

# Save the diff in env.diff
spack --color=never diff "$env_dir/spack.$old_sha.lock" "$env_dir/spack.$new_sha.lock" > env.diff
