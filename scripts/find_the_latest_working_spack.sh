#!/bin/sh

# Test whether we can bump Spack to a new version without breaking our environment
# Output: on failure, writes the first bad commit sha to ./bad_sha, exits with 1.
#         on success, writes the working commit sha to ./good_sha, exits with 0.

bold_cyan='\e[1;36m'
bold_green='\e[1;32m'
bold_red='\e[1;31m'
no_color='\e[0m'

set -e

if [ ! -d "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 path/to/env/dir path/to/install/dir"
    exit 1
fi

# Make sure that the user sets a path to the system config:
if [ ! -d "$SPACK_SYSTEM_CONFIG_PATH" ]; then
    echo "Make sure to point SPACK_SYSTEM_CONFIG_PATH to a directory containing Spack config files"
    exit 1
fi

# Make sure we can run install_spack_env.sh
if ! [ -x "$(command -v install_spack_env.sh)" ]; then
    echo "Make sure install_spack_env.sh in your PATH"
    exit 1
fi

env_dir="$1"
install_dir="$2"

mkdir -p "$install_dir"

# Clone the fork; don't need a deep clone.
git clone --quiet --branch develop --depth=5 -c feature.manyFiles=true https://github.com/eth-cscs/spack.git fork-spack

# Clone upstream
git clone --quiet --branch develop -c feature.manyFiles=true https://github.com/spack/spack.git upstream-spack

# Get the full commit SHA's.
fork_commit="$(git -C ./fork-spack rev-parse HEAD)"
upstream_commit="$(git -C ./upstream-spack rev-parse HEAD)"

printf "✨ Spack bump: %b ↑ %b.\n" "${bold_cyan}${fork_commit}${no_color}" "${bold_green}${upstream_commit}${no_color}"

# Build with upstream Spack
set +e
export PATH="$PWD/upstream-spack/bin:$PATH"

# Try to install on the latest develop version
if install_spack_env.sh "$env_dir" "$install_dir"; then
    printf "🎉 Spack can be upgraded to %b\n" "${bold_green}${upstream_commit}${no_color}"
    echo "$upstream_commit" > good_sha
    exit 0
fi

# Otherwise, bisect!
set -e

# upstream_commit is bad, fork_commit is good
git -c color.ui=always -C ./upstream-spack bisect start "$upstream_commit" "$fork_commit" --
git -c color.ui=always -C ./upstream-spack bisect run install_spack_env.sh "$env_dir" "$install_dir"

# Get the first bad SHA
bad_sha="$(git -C ./upstream-spack rev-parse refs/bisect/bad)"

printf "💀 %b is breaking our builds\n" "${bold_red}${bad_sha}${no_color}"

echo "$bad_sha" > bad_sha

# Maybe there is a good SHA too?
good_sha="$(git -C ./upstream-spack rev-parse "$bad_sha^1")"

if [ "$good_sha" != "$fork_commit" ]; then
    printf "🎉 Spack can be upgraded to %b\n" "${bold_green}${upstream_commit}${no_color}"
    echo "$good_sha" > good_sha
fi

# Stop bisecting
git -c color.ui=always -C ./upstream-spack bisect reset

exit 1