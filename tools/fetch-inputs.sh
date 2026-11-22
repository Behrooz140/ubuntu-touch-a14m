#!/bin/sh
# Download and verify every build input against inputs.sha256.
# Refuse to build anything from unverified inputs.
set -eu

die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
MANIFEST="$ROOT/inputs.sha256"
URLS="$ROOT/inputs.urls"
OUT="$ROOT/inputs"

[ -f "$MANIFEST" ] || die "missing inputs.sha256"
[ -f "$URLS" ] || die "missing inputs.urls"

if grep -q 'TBD' "$MANIFEST"; then
    die "INPUTS_NOT_PINNED: fill every SHA256 in inputs.sha256 first"
fi

mkdir -p "$OUT"
cd "$OUT"

url_for() {
    file=$1
    url=$(awk -v f="$file" '
        /^[[:space:]]*#/ { next }
        NF >= 2 && $1 == f { print $2; found=1; exit }
        END { if (!found) exit 1 }
    ' "$URLS") || die "no URL for $file in inputs.urls"
    printf '%s\n' "$url"
}

while read -r sum file; do
    case "$sum" in ''|\#*) continue ;; esac
    [ -n "${file:-}" ] || die "bad line in inputs.sha256: $sum"

    if [ -n "${INPUTS_MIRROR:-}" ]; then
        url="${INPUTS_MIRROR%/}/$file"
    else
        url=$(url_for "$file")
    fi

    if [ ! -f "$file" ]; then
        printf 'fetching %s from %s\n' "$file" "$url"
        curl -fL --retry 3 -o "$file.part" "$url" || die "download failed: $file"
        mv "$file.part" "$file"
    fi

    actual=$(sha256sum "$file" | cut -d' ' -f1)
    [ "$actual" = "$sum" ] || die "checksum mismatch for $file: expected $sum, got $actual"
done < "$MANIFEST"

printf 'all inputs verified\n'
