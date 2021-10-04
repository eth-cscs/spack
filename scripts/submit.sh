#!/bin/sh
#SBATCH --cpus-per-task=16

root="$(dirname "$(dirname "$(readlink -f "$0")")")"

bold_cyan='\e[1;36m'
no_color='\e[0m'

if [ "$1" ]; then
    store_dir="$1"
    mkdir -p "$store_dir"
else
    store_dir="$root/installs"
fi

environment="$root/environments/cscs"

if [ "$GITHUB_TOKEN" ]; then
    report="yes"
else
    report="no"
fi

# This is a terrible hack until https://github.com/spack/spack/pull/26735 lands.
export HOME="$root/home"
rm -rf "$HOME"

export PATH="$root/scripts/:$PATH"
export SPACK_SYSTEM_CONFIG_PATH="$root/config/dom"

printf "Install dir:      %b\n" "${bold_cyan}${store_dir}${no_color}"
printf "Home dir:         %b\n" "${bold_cyan}${HOME}${no_color}"
printf "Environment:      %b\n" "${bold_cyan}${environment}${no_color}"
printf "Config:           %b\n" "${bold_cyan}${SPACK_SYSTEM_CONFIG_PATH}${no_color}"
printf "Report to Github: %b\n" "${bold_cyan}${report}${no_color}"

# Find the working spack
find_the_latest_working_spack.sh "$environment" "$store_dir"

result="$?"

# Compute the diff if we have a new working version
if [ -f "good_sha" ]; then
    fork_sha="$(git -C ./fork-spack rev-parse HEAD)"
    good_sha="$(cat good_sha)"
    diff_concrete_env.sh "$root/upstream-spack" "$environment" "$fork_sha" "$good_sha"
fi

# Report to github if a token is provided
if [ "$GITHUB_TOKEN" ]; then
    report.sh
fi

exit "$result"