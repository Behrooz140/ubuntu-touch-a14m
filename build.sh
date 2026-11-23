#!/bin/sh
# Build reproducible Ubuntu Touch artifacts for Samsung Galaxy A14 4G (a14m).
#
# Stages:
#   build.sh kernel   unpack/verify the pinned behi kernel boot image
#   build.sh rootfs   build ubuntu.img from the pinned rootfs tarball + overlay
#   build.sh boot     build boot-ut.img (kernel + Halium initramfs, AVB signed)
#   build.sh release  bundle a numbered build directory with SHA256SUMS
#   build.sh all      kernel -> rootfs -> boot -> release
#
# Every input is verified by tools/fetch-inputs.sh before any stage runs.
set -eu

die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
say() { printf '==> %s\n' "$*"; }

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
OUT="$ROOT/out"
INPUTS="$ROOT/inputs"
OVERLAY="$ROOT/overlay"
TOOLS="$ROOT/.build-tools"
BUILD=${BUILD_ID:-$(date -u +build-%Y%m%d-%H%M%S)}
BUILD_DIR="$OUT/$BUILD"

MBOOTIMG_COMMIT=d2bb0af5ba6d3198a3e99529c97eda1be0b5a093
AVB_COMMIT=3328b7b60ae384e1a92f44d7e6f3ac021c2b05be
AVB_ALGORITHM=${AVB_ALGORITHM:-SHA256_RSA4096}
# avbtool uses /dev/urandom for the hash descriptor salt unless told otherwise.
AVB_SALT=${AVB_SALT:-6131346d2d75742d6176622d73616c742d76310000000000000000000000}
BOOT_PARTITION_SIZE=${BOOT_PARTITION_SIZE:-33554432}
INIT_BOOT_PARTITION_SIZE=${INIT_BOOT_PARTITION_SIZE:-8388608}
# Optional: point Halium initramfs at a non-encrypted data partition, e.g.
# /dev/block/mmcblk1p1 (an ext4 partition on the microSD card).
UT_DATAPART=${UT_DATAPART:-}
OS_VERSION=${OS_VERSION:-15.0.0}
OS_PATCH_LEVEL=${OS_PATCH_LEVEL:-2026-07}

# Reproducible-build anchors. Changing any of these produces a new build ID.
SOURCE_DATE_EPOCH=${SOURCE_DATE_EPOCH:-1767225600}   # 2026-01-01T00:00:00Z
EXT4_HASH_SEED=${EXT4_HASH_SEED:-6a14d000-0000-4000-8000-000000000002}
export SOURCE_DATE_EPOCH

STAGE=${1:-all}

case "$STAGE" in
    all|kernel|rootfs|boot|release) ;;
    *) die "unknown stage: $STAGE (expected all|kernel|rootfs|boot|release)" ;;
esac

require_inputs() {
    [ -d "$INPUTS" ] || die "inputs/ missing; run sh tools/fetch-inputs.sh"
    # A second verification is cheap and catches manual edits after fetch.
    (cd "$ROOT" && sh tools/fetch-inputs.sh >/dev/null)
}

setup_tools() {
    mkdir -p "$TOOLS"
    if [ ! -f "$TOOLS/mkbootimg/mkbootimg.py" ] || [ ! -f "$TOOLS/avb/avbtool.py" ]; then
        say "fetching pinned AOSP image tools"
    fi
    fetch_git() {
        repo=$1 commit=$2 dir=$3
        [ -d "$dir/.git" ] || git clone -q "$repo" "$dir"
        if [ "$(git -C "$dir" rev-parse HEAD)" != "$commit" ]; then
            git -C "$dir" fetch -q origin "$commit"
            git -C "$dir" checkout -q "$commit"
        fi
        [ "$(git -C "$dir" rev-parse HEAD)" = "$commit" ] || die "wrong tool commit in $dir"
    }
    fetch_git https://android.googlesource.com/platform/system/tools/mkbootimg \
        "$MBOOTIMG_COMMIT" "$TOOLS/mkbootimg"
    fetch_git https://android.googlesource.com/platform/external/avb \
        "$AVB_COMMIT" "$TOOLS/avb"
    MBOOTIMG="$TOOLS/mkbootimg/mkbootimg.py"
    UNPACK="$TOOLS/mkbootimg/unpack_bootimg.py"
    AVBTOOL="$TOOLS/avb/avbtool.py"
    AVB_KEY="$TOOLS/avb/test/data/testkey_rsa4096.pem"
    [ -f "$MBOOTIMG" ] && [ -f "$UNPACK" ] && [ -f "$AVBTOOL" ] && [ -f "$AVB_KEY" ] \
        || die "incomplete AOSP image tools"
}

write_build_info() {
    mkdir -p "$BUILD_DIR"
    {
        echo "Build ID       : $BUILD"
        echo "Source date    : $(date -u -d "@$SOURCE_DATE_EPOCH" '+%Y-%m-%dT%H:%M:%SZ')"
        echo "Port commit    : $(git -C "$ROOT" rev-parse HEAD 2>/dev/null || echo unknown)"
        echo "Kernel input   : $(sha256sum "$INPUTS/kernel-ut-boot.img" | cut -d' ' -f1)"
        KIMAGE="$BUILD_DIR/kernel/Image"
        [ -f "$KIMAGE" ] || KIMAGE="$BUILD_DIR/kernel/Image.gz"
        echo "Kernel release : $(strings "$KIMAGE" 2>/dev/null | sed -n 's/^Linux version \([^ ]*\) .*/\1/p' | head -n1 || true)"
        echo "Tool commits   : mkbootimg=$MBOOTIMG_COMMIT avb=$AVB_COMMIT"
        echo "Cmdline        : ${UT_CMDLINE:-default (see deviceinfo/a14m)}"
        echo "AVB            : $AVB_ALGORITHM, partition $BOOT_PARTITION_SIZE bytes (AOSP test key), salt=$AVB_SALT"
        echo "Repro anchors  : SOURCE_DATE_EPOCH=$SOURCE_DATE_EPOCH EXT4_HASH_SEED=$EXT4_HASH_SEED"
    } > "$BUILD_DIR/build-info.txt"
}

stage_kernel() {
    require_inputs
    setup_tools
    mkdir -p "$BUILD_DIR/kernel"

    say "unpacking kernel from pinned boot image"
    python3 "$UNPACK" --boot_img "$INPUTS/kernel-ut-boot.img" --out "$BUILD_DIR/kernel/unpacked"
    [ -s "$BUILD_DIR/kernel/unpacked/kernel" ] || die "kernel payload not found"
    cp "$BUILD_DIR/kernel/unpacked/kernel" "$BUILD_DIR/kernel/Image.gz"
    gzip -dc "$BUILD_DIR/kernel/Image.gz" > "$BUILD_DIR/kernel/Image"

    say "verifying kernel release and stock module ABI stamp"
    strings "$BUILD_DIR/kernel/Image" | grep -qF '6.6.144-android15-8-abA145PXXUEDZJ2-4k-behi-v1.6.1' \
        || die "expected behi v1.6.1 kernel release missing"
    strings "$BUILD_DIR/kernel/Image" | grep -qF '6.6.118-android15-8-abA145PXXUEDZJ2-4k SMP preempt mod_unload modversions aarch64' \
        || die "stock 6.6.118 vermagic missing (vendor modules would not load)"

    # The KMI guard runs in the kernel repository CI (config check, kmi_check.py
    # verify against configs/kmi-baseline-v1.6.1.txt, vermagic check). Pinning the
    # SHA256 of that exact released boot.img here binds this build to that gate.
    python3 "$UNPACK" --boot_img "$INPUTS/kernel-ut-boot.img" --format mkbootimg --null \
        > "$BUILD_DIR/kernel/mkbootimg-args.bin"

    write_build_info
    say "kernel stage OK"
}

stage_rootfs() {
    require_inputs
    command -v mkfs.ext4 >/dev/null || die "mkfs.ext4 (e2fsprogs) is required"
    [ -f "$INPUTS/ubuntu-touch-24.04-2.x-arm64.tar.gz" ] \
        || die "rootfs tarball not pinned yet"
    [ -d "$OVERLAY" ] || die "missing $OVERLAY"

    # mke2fs -d walks the source tree in readdir() order. On the host's f2fs
    # that order is not stable across extraction runs, so the same inputs used
    # to produce different inode layouts. Stage the tree on a loop-mounted
    # ext4 with a fixed hash seed: ext4 readdir order is then deterministic.
    STAGE_MNT="$BUILD_DIR/rootfs/stage"
    STAGE_IMG="$BUILD_DIR/rootfs/stage.img"
    STAGE_LOOP=""
    cleanup_stage() {
        [ -n "$STAGE_LOOP" ] && losetup -d "$STAGE_LOOP" 2>/dev/null || true
        rm -f "$STAGE_IMG"
    }
    trap cleanup_stage EXIT HUP INT TERM

    mkdir -p "$STAGE_MNT"
    truncate -s 7G "$STAGE_IMG"
    mkfs.ext4 -q -F -L ut-stage \
        -U 6a14d000-0000-4000-8000-000000000003 \
        -E root_owner=0:0,hash_seed="$EXT4_HASH_SEED" \
        "$STAGE_IMG"
    STAGE_LOOP=$(losetup --find --show "$STAGE_IMG")
    mount -t ext4 "$STAGE_LOOP" "$STAGE_MNT"

    say "extracting rootfs tarball"
    tar -xf "$INPUTS/ubuntu-touch-24.04-2.x-arm64.tar.gz" -C "$STAGE_MNT"

    say "applying device overlay"
    # overlay/ramdisk/ belongs to the initramfs (stage_ramdisk), not to
    # the Ubuntu rootfs. Excluding it keeps the two stages independent.
    tar -C "$OVERLAY" --exclude=./ramdisk -cf - . \
        | tar -C "$STAGE_MNT" -xf -

    # Git does not preserve mtimes, so overlay files would otherwise make the
    # image depend on checkout time. Normalize everything before mkfs.
    chown -R 0:0 "$STAGE_MNT"
    find "$STAGE_MNT" -exec touch -h -d "@$SOURCE_DATE_EPOCH" {} +

    size_kb=$(du -sk "$STAGE_MNT" | cut -f1)
    size_mib=$(( (size_kb / 1024) + 512 ))
    say "creating ubuntu.img (${size_mib} MiB)"
    mkfs.ext4 -q -F -L ubuntu-rootfs \
        -U 6a14d000-0000-4000-8000-000000000001 \
        -E root_owner=0:0,hash_seed="$EXT4_HASH_SEED" \
        -d "$STAGE_MNT" \
        "$BUILD_DIR/ubuntu.img" "${size_mib}M"

    umount "$STAGE_MNT"
    cleanup_stage
    STAGE_LOOP=""
    trap - EXIT HUP INT TERM

    say "rootfs stage OK"
}

stage_boot() {
    require_inputs
    setup_tools
    [ -s "$BUILD_DIR/kernel/Image.gz" ] || die "run the kernel stage first"
    [ -f "$INPUTS/initrd.img-touch-arm64" ] || die "initramfs not pinned yet"

    mkdir -p "$BUILD_DIR/ramdisk/tree"
    say "unpacking Halium initramfs"
    gzip -dc "$INPUTS/initrd.img-touch-arm64" \
        | (cd "$BUILD_DIR/ramdisk/tree" && cpio -idm --quiet)

    if [ -d "$OVERLAY/ramdisk" ]; then
        say "applying ramdisk overlay"
        cp -a "$OVERLAY/ramdisk/." "$BUILD_DIR/ramdisk/tree/"
    fi
    chown -R 0:0 "$BUILD_DIR/ramdisk/tree"
    find "$BUILD_DIR/ramdisk/tree" -exec touch -h -d "@$SOURCE_DATE_EPOCH" {} +
    [ -x "$BUILD_DIR/ramdisk/tree/init" ] \
        || die "initramfs has no executable /init"

    say "repacking ramdisk"
    # --reproducible zeroes owner/device/inode numbers; without it GNU cpio
    # embeds the current checkout's inode numbers in the archive.
    (cd "$BUILD_DIR/ramdisk/tree" && find . -print0 | sort -z \
        | cpio --null --reproducible -o -H newc --quiet \
        | gzip -9 -n > "$BUILD_DIR/ramdisk/initramfs.cpio.gz")

    say "building boot-ut.img (header v4 + AVB)"
    python3 - "$BUILD_DIR/kernel/mkbootimg-args.bin" \
        "$BUILD_DIR/kernel/Image.gz" "$BUILD_DIR/ramdisk/initramfs.cpio.gz" \
        "$BUILD_DIR/boot-ut.unsigned" <<'PY'
import shlex, sys
args_file, kernel, ramdisk, output = sys.argv[1:5]
args = open(args_file, 'rb').read().split(b'\0')
args = [a.decode() for a in args if a]
out = []
skip = False
for i, a in enumerate(args):
    if skip:
        skip = False
        continue
    if a in ('--kernel', '--ramdisk', '--output', '--second', '--dtb'):
        skip = True
        continue
    out.append(a)
out += ['--kernel', kernel, '--ramdisk', ramdisk, '--output', output]
print('recorded mkbootimg args:', ' '.join(shlex.quote(x) for x in out))
PY
    # Reuse the exact header parameters recorded from the released kernel image.
    MBOOT_IMG="$BUILD_DIR/boot-ut.unsigned"
    UT_CMDLINE=${UT_CMDLINE:-"console=tty0 bootopt=64S3,32N2,64N2 loop.max_part=7"}
    if [ -n "$UT_DATAPART" ]; then
        UT_CMDLINE="$UT_CMDLINE datapart=$UT_DATAPART"
    fi
    python3 "$MBOOTIMG" \
        --header_version 4 \
        --os_version "$OS_VERSION" \
        --os_patch_level "$OS_PATCH_LEVEL" \
        --cmdline "$UT_CMDLINE" \
        --kernel "$BUILD_DIR/kernel/Image.gz" \
        --ramdisk "$BUILD_DIR/ramdisk/initramfs.cpio.gz" \
        --output "$MBOOT_IMG"

    say "adding SEANDROIDENFORCE marker"
    printf 'SEANDROIDENFORCE' >> "$MBOOT_IMG"

    say "signing with avbtool ($AVB_ALGORITHM)"
    python3 "$AVBTOOL" add_hash_footer \
        --image "$MBOOT_IMG" \
        --partition_size "$BOOT_PARTITION_SIZE" \
        --partition_name boot \
        --key "$AVB_KEY" \
        --algorithm "$AVB_ALGORITHM" \
        --salt "$AVB_SALT"

    [ "$(stat -c '%s' "$MBOOT_IMG")" = "$BOOT_PARTITION_SIZE" ] \
        || die "unexpected boot image size"
    mv "$MBOOT_IMG" "$BUILD_DIR/boot-ut.img"

    # This device is GKI: stock boot.img is kernel-only, while the generic
    # ramdisk lives in init_boot.img (verified by unpacking the live partitions).
    # Build both variants so either boot path can be tested without guessing.
    say "building init_boot-ut.img (ramdisk only, header v4 + AVB)"
    INIT_IMG="$BUILD_DIR/init_boot-ut.unsigned"
    python3 "$MBOOTIMG" \
        --header_version 4 \
        --os_version "$OS_VERSION" \
        --os_patch_level "$OS_PATCH_LEVEL" \
        --ramdisk "$BUILD_DIR/ramdisk/initramfs.cpio.gz" \
        --output "$INIT_IMG"
    python3 "$AVBTOOL" add_hash_footer \
        --image "$INIT_IMG" \
        --partition_size "$INIT_BOOT_PARTITION_SIZE" \
        --partition_name init_boot \
        --key "$AVB_KEY" \
        --algorithm "$AVB_ALGORITHM" \
        --salt "$AVB_SALT"
    [ "$(stat -c '%s' "$INIT_IMG")" = "$INIT_BOOT_PARTITION_SIZE" ] \
        || die "unexpected init_boot image size"
    mv "$INIT_IMG" "$BUILD_DIR/init_boot-ut.img"

    python3 "$AVBTOOL" info_image --image "$BUILD_DIR/boot-ut.img" | sed -n '1,8p'
    python3 "$AVBTOOL" info_image --image "$BUILD_DIR/init_boot-ut.img" | sed -n '1,8p'
    write_build_info
    say "boot stage OK"
}

stage_release() {
    [ -d "$BUILD_DIR" ] || die "no such build directory: $BUILD_DIR"
    [ -f "$BUILD_DIR/boot-ut.img" ] || die "boot-ut.img missing; run the boot stage first"
    [ -f "$BUILD_DIR/init_boot-ut.img" ] || die "init_boot-ut.img missing; run the boot stage first"
    [ -f "$BUILD_DIR/ubuntu.img" ] || die "ubuntu.img missing; run the rootfs stage first"

    # Only release artifacts are hashed. Intermediate unpacked trees contain
    # absolute paths and would make SHA256SUMS depend on the build directory.
    say "writing SHA256SUMS for $BUILD"
    (cd "$BUILD_DIR" && sha256sum build-info.txt boot-ut.img init_boot-ut.img ubuntu.img > SHA256SUMS)
    cat "$BUILD_DIR/SHA256SUMS"
    say "release stage OK: $BUILD_DIR"
}

case "$STAGE" in
    kernel)  stage_kernel ;;
    rootfs)  stage_rootfs ;;
    boot)    stage_boot ;;
    release) stage_release ;;
    all)     stage_kernel; stage_rootfs; stage_boot; stage_release ;;
esac
