#!/bin/sh
# Read-only diagnostic collector. Run on the device via adb shell / SSH.
# Usage: sh collect-logs.sh [TAG]
set -eu

TAG=${1:-ut-logs-$(date -u +%Y%m%dT%H%M%SZ)}
BASE=/sdcard/ut-logs/$TAG
mkdir -p "$BASE"

grab() {
    name=$1
    shift
    if command -v "$1" >/dev/null 2>&1 || [ -e "$1" ]; then
        "$@" >"$BASE/$name" 2>&1 || true
    else
        printf 'missing: %s\n' "$1" >"$BASE/$name"
    fi
}

grab dmesg.txt dmesg
grab journal.txt journalctl -b --no-pager
grab journal-prev.txt journalctl -b -1 --no-pager
grab lshal.txt lshal
grab getprop.txt getprop
grab failed-units.txt systemctl --failed --no-pager
grab ip-addr.txt ip addr
grab ip-route.txt ip route
grab block-devices.txt ls -l /dev/block/by-name
grab mounts.txt mount
grab pstore-list.txt ls -l /sys/fs/pstore

if [ -r /proc/config.gz ]; then
    gzip -dc /proc/config.gz >"$BASE/kernel-config" 2>&1 || true
fi

for f in /sys/fs/pstore/*; do
    [ -f "$f" ] && cp "$f" "$BASE/" 2>/dev/null || true
done

(cd /sdcard/ut-logs && tar -czf "$TAG.tar.gz" "$TAG")
printf 'saved: /sdcard/ut-logs/%s.tar.gz\n' "$TAG"
