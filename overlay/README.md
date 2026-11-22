# Device overlay

Files in this directory are copied over the Ubuntu Touch rootfs **after** the
pinned rootfs tarball is extracted (`build.sh rootfs`), and before `ubuntu.img`
is created.

Everything here must be tracked, reviewed and reproducible. Never put generated
or host-specific files in this directory.

Subdirectory `ramdisk/` is copied into the Halium initramfs instead (used by
`build.sh boot`) — that is the place for early-boot scripts, `fstab` snippets
and any `init` hooks that must run before the rootfs is mounted.

Planned a14m-specific items:

- audio routing / PulseAudio droid policy overrides,
- sensor and GPS configuration for MT6769V,
- camera HAL configuration,
- udev rules for the touchscreen and fingerprint sensor,
- initramfs cmdline helpers for the GKI `init_boot` / `vendor_boot` layout.

Each fix should be added together with a GitHub issue reference in its filename
or comment, e.g. `# Issue #12: ...` inside the file.
