#!/bin/sh
# Download a candidate build input, print its SHA256 and register its URL.
#
# Usage:
#   sh tools/pin-input.sh <filename> <url>
#
# This does NOT edit inputs.sha256 automatically: copy the printed line into
# the manifest after reviewing the source and the checksum. It does update
# inputs.urls because the URL is not a trust decision, only a location.
set -eu

die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
INPUTS="$ROOT/inputs"
URLS="$ROOT/inputs.urls"
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

[ $# -eq 2 ] || die "usage: $0 <filename> <url>"
FILE=$1
URL=$2
mkdir -p "$INPUTS"

printf 'downloading %s\n' "$FILE" >&2
curl -fL --retry 3 -o "$TMP" "$URL"
SUM=$(sha256sum "$TMP" | cut -d' ' -f1)
SIZE=$(stat -c '%s' "$TMP")
mv "$TMP" "$INPUTS/$FILE"
trap - EXIT

if ! grep -q "^${FILE}[[:space:]]" "$URLS"; then
    printf '%s  %s\n' "$FILE" "$URL" >> "$URLS"
    printf 'added URL to inputs.urls\n' >&2
else
    printf 'URL for %s already present in inputs.urls\n' "$FILE" >&2
fi

printf '\nCopy this line into inputs.sha256 (replace any TBD line):\n\n'
printf '%s  %s\n' "$SUM" "$FILE"
printf '\nsize: %s bytes\n' "$SIZE" >&2
