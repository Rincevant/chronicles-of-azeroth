#!/usr/bin/env bash
# Prints the version of the addon, read from its TOC ("1.0" for "## Version: 1.0"). The addon
# reads its version from the TOC at runtime and the release workflow publishes it, so the TOC
# is the only place that carries it.
#
# Usage: tools/check_version.sh

set -euo pipefail

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
toc="$repo_dir/ChroniquesAzeroth/ChroniquesAzeroth.toc"

version="$(sed -n 's/^## Version:[[:space:]]*\([^[:space:]]*\).*/\1/p' "$toc" | tr -d '\r')"

if [ -z "$version" ]; then
    echo "No version in $toc" >&2
    exit 1
fi

echo "$version"
