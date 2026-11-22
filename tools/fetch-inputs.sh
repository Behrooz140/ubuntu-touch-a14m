#!/bin/sh
# Download and verify every build input against inputs.sha256.
# Refuse to build anything from unverified inputs.
set -eu

die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
MANIFEST="$ROOT/inputs.sha256"
OUT="$ROOT/inputs"

[ -f "$MANIFEST" ] || die "missing inputs.sha256"

if grep -q 'TBD' "$MANIFEST"; then
    die "INPUTS_NOT_PINNED: fill every SHA256 in inputs.sha256 first"
fi

[ -n "${INPUTS_MIRROR:-}" ] || die "set INPUTS_MIRROR to the Release URL holding the pinned inputs"

mkdir -p "$OUT"
cd "$OUT"

while read -r sum file; do
    case "$sum" in ''|\#*) continue ;; esac
    [ -n "${file:-}" ] || die "bad line in inputs.sha256: $sum"

    if [ ! -f "$file" ]; then
        printf 'fetching %s\n' "$file"
        curl -fL --retry 3 -o "$file" "${INPUTS_MIRROR%/}/$file"
    fi

    actual=$(sha256sum "$file" | cut -d' ' -f1)
    [ "$actual" = "$sum" ] || die "checksum mismatch for $file: expected $sum, got $actual"
done < "$MANIFEST"

printf 'all inputs verified\n'
