#!/usr/bin/env bash
# Checks that the version of the addon is the same in its TOC and in its code, and, when a
# tag is given, that the tag names this version ("v0.25.1-beta" for version 0.25.1-beta).
#
# Usage: tools/check_version.sh [tag]
# Prints the version on success.

set -euo pipefail

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
toc="$repo_dir/ChroniquesAzeroth/ChroniquesAzeroth.toc"
code="$repo_dir/ChroniquesAzeroth/Core.lua"

toc_version="$(sed -n 's/^## Version:[[:space:]]*\([^[:space:]]*\).*/\1/p' "$toc" | tr -d '\r')"
code_version="$(sed -n 's/^CA\.VERSION = "\([^"]*\)".*/\1/p' "$code")"

if [ -z "$toc_version" ] || [ -z "$code_version" ]; then
    echo "Version not found: TOC '$toc_version', code '$code_version'" >&2
    exit 1
fi
if [ "$toc_version" != "$code_version" ]; then
    echo "The TOC carries version $toc_version but CA.VERSION is $code_version" >&2
    exit 1
fi
if [ $# -ge 1 ] && [ "$1" != "v$toc_version" ]; then
    echo "The tag $1 does not match version $toc_version (expected v$toc_version)" >&2
    exit 1
fi

echo "$toc_version"
