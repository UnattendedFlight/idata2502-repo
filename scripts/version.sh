#!/usr/bin/env bash
set -eu
# defaults to current branch if no refs passed
ref="${1:-$(git rev-parse --abbrev-ref HEAD)}"
case "$ref" in
  # release branches use the branch name as the version, like release/1.4.0 -> 1.4.0
  release/*) echo "${ref#release/}"; exit ;; # release breanch produce "pure" versions as theyre validated releases,
                                             # allows main to continue to grow, and a release to diverge if security patches are added retroactively
  main)  channel=b ;;  # main branch produces betas and "latest"
  rc/*)  channel=rc ;; # rc bnranches are release candidates, so own channel
  *)     channel=a ;;  # every other branch
esac
# no tags yet, so start from 0.0.0
last=$(git describe --tags --abbrev=0 2>/dev/null || echo 0.0.0)
# commits since last tag with a falback to all commits when 0.0.0 is not really a tag
n=$(git rev-list --count "$last"..HEAD 2>/dev/null || git rev-list --count HEAD)
# strip leading v and any prerelease suffix (1.2.3rc4 -> 1.2.3), then bump patch
base=$(echo "${last#v}" | sed 's/[a-z].*//' | awk -F. '{print $1"."$2"."$3+1}')
# e.g. 1.2.3b17
echo "$base$channel$n"
