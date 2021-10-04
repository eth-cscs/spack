#!/bin/sh

# shellcheck disable=SC2016

set -e

# Download the github cli tool
tmpdir=$(mktemp -d)
(
    cd "$tmpdir"
    gh="https://github.com/cli/cli/releases/download/v2.1.0/gh_2.1.0_linux_amd64.tar.gz"
    curl -Lfso gh.tar.gz "$gh"
    echo "eddadd0cf7ecf340614dd5914eaad1543d8491c966a3a3a41f8a03832dfac184  gh.tar.gz" | sha256sum --quiet -c
    tar -xf gh.tar.gz --strip-components=1
)

# Clean up our secret tokens in the fake home folder.
cleanup() {
  echo "Removing $tmpdir"
  rm -rf "$tmpdir"
}

trap cleanup EXIT

# Put it in the PATH
export PATH="$tmpdir/bin:$PATH"
export HOME="$tmpdir"

# Report about the first breaking commit
if [ -f "bad_sha" ]; then
    title="💥 spack is broken"
    bad_sha="$(cat bad_sha)"
    body="$(printf 'https://github.com/spack/spack/commit/%s is breaking our builds. ```%s```' "$bad_sha" "$bad_sha")"
    # Link to CI
    if [ "$BUILD_URL" ]; then
        body="$(printf '%s\n\n%s' "$body" "$BUILD_URL")"
    fi
    gh issue create --repo eth-cscs/spack --title "$title" --body "$body"
fi

# Report about the last working commit
if [ -f "good_sha" ]; then
    title="✅ spack can be bumped"
    good_sha="$(cat good_sha)"
    body="$(printf 'Please bump to https://github.com/spack/spack/commit/%s. ```%s```' "$good_sha" "$good_sha")"
    # Maybe also show some environment diff
    if [ -f "env.diff" ]; then
        diff="$(cat env.diff)"
        body="$(printf '%s\n\nEnvironment diff:\n```diff\n%s\n```' "$body" "$diff")"
    fi
    # Link to CI
    if [ "$BUILD_URL" ]; then
        body="$(printf '%s\n\n%s' "$body" "$BUILD_URL")"
    fi
    gh issue create --repo eth-cscs/spack --title "$title" --body "$body"
fi
