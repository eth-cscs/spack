#!/bin/sh

bold_cyan='\e[1;36m'
no_color='\e[0m'

# By default, show stdout from process 0, and stderr from all, and color output.
export SPACK_COLOR="${SPACK_COLOR:-always}"

# Allow the user to avoid using srun altogether through `SRUN= ./install_spack_env.sh`
srun="${SRUN:-srun --pty}"

set -e

if [ ! -d "$1" ] || [ ! -d "$2" ]; then
    echo "Usage: $0 [path/to/env/dir] [path/to/store]"
    exit 1
fi

# Make sure that the user sets a path to the system config:
if [ ! -d "$SPACK_SYSTEM_CONFIG_PATH" ]; then
    echo "Make sure to point SPACK_SYSTEM_CONFIG_PATH to a directory containing Spack config files"
    exit 1
fi

env_dir="$1"
install_dir="$2"
spack_sha="$(git -C "$(dirname "$(command -v spack)")" rev-parse --short HEAD)"
store_dir="$install_dir/$spack_sha"

mkdir -p "$store_dir"

printf "⏳ Going to install %b in %b\n" "${bold_cyan}$env_dir${no_color}" "${bold_cyan}$store_dir${no_color}"

if [ -d "$SPACK_USER_CONFIG_DIR" ]; then
    printf '👉 Removing %s\n' "$SPACK_USER_CONFIG_DIR"
    rm -rf "$SPACK_USER_CONFIG_DIR"
fi

if [ -d "$SPACK_USER_CACHE_DIR" ]; then
    printf '👉 Removing %s\n' "$SPACK_USER_CACHE_DIR"
    rm -rf "$SPACK_USER_CACHE_DIR"
fi

printf '👉 Cleaning: spack -e "%s" clean -sfmpb\n' "$env_dir"
spack -e "$env_dir" clean -sfmpb

printf '👉 Bootstrapping: spack -e "%s" spec zlib > /dev/null\n' "$env_dir"
spack -e "$env_dir" spec zlib > /dev/null

printf '👉 Concretizing: spack -e "%s" concretize -f\n' "$env_dir"
spack -e "$env_dir" concretize -f

# printf '👉 Fetching sources: spack -e "%s" fetch\n' "$env_dir"
# spack -e "$env_dir" fetch

printf '👉 Installing: %s spack -e "%s" -c "config:install_tree:root:%s" install --no-cache -j16"\n' "$srun" "$env_dir" "$store_dir"
$srun spack -e "$env_dir" -c "config:install_tree:root:$store_dir" install --no-cache -j16