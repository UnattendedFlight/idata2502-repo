#!/usr/bin/env bash
set -eu

ref="${1:-$(git rev-parse --abbrev-ref HEAD)}"
# resolve version.sh relative to this scriptso it works from any cwd
version=$(dirname "$0")/version.sh
version=$("$version" "$ref")
# the order matters, as rc takes precedence before a and b
case "$version" in
  *rc*) type=rc ;;
  *a*)  type=alpha ;;
  *b*)  type=beta ;;
  *)    type=release ;;
esac
# only tracked changes for the dirty flag, untracked files do not count for dirty
git diff --quiet HEAD 2>/dev/null && dirty=false || dirty=true
cat <<VARS
BUILD_VERSION=$version
BUILD_TYPE=$type
BUILD_TIME=$(date -u +%Y-%m-%dT%H:%M:%SZ)
BUILD_COMMIT=$(git rev-parse --short HEAD)
BUILD_BRANCH=$ref
BUILD_DIRTY=$dirty
VARS
