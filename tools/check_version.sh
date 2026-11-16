#!/usr/bin/env bash
# Prints the version of the addon, read from its TOC, and, when a tag is given, checks that
# the tag names this version ("v0.25.1-beta" for version 0.25.1-beta). The addon reads its
# version from the TOC at runtime, so the TOC is the only place that carries it.
#
# Usage: tools/check_version.sh [tag]

set -euo pipefail

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
toc="$repo_dir/ChroniquesAzeroth/ChroniquesAzeroth.toc"

version="$(sed -n 's/^## Version:[[:space:]]*\([^[:space:]]*\).*/\1/p' "$toc" | tr -d '\r')"

if [ -z "$version" ]; then
    echo "No version in $toc" >&2
    exit 1
fi
if [ $# -ge 1 ] && [ "$1" != "v$version" ]; then
    echo "The tag $1 does not match version $version (expected v$version)" >&2
    exit 1
fi

echo "$version"
