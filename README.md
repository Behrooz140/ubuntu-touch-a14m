# Ubuntu Touch for Samsung Galaxy A14 4G (`a14m`)

Community, open-source, incremental **Ubuntu Touch 24.04-x** port for the
**Samsung Galaxy A14 4G / SM-A145P** (MediaTek MT6768 / Helio G80, arm64).

> **Status: reproducible build ready / pre-first-boot.** No image has been
> flashed. Inputs are pinned, three images are byte-for-byte reproducible,
> and the first-boot artifacts are staged on the device's existing exFAT
> microSD. See [first-boot-test](docs/first-boot-test.md) for the exact
> temporary-boot procedure, and the
> [hardware matrix](docs/hardware-matrix.md) for per-subsystem issues.
>
> **Open M0 items:** [userdata FBE / initramfs data source (#5)](https://github.com/Behrooz140/ubuntu-touch-a14m/issues/5)
> (workaround staged, device test pending) and
> [restore stock Android 15 vendor (#22)](https://github.com/Behrooz140/ubuntu-touch-a14m/issues/22).
> DSU concerns (#2, #3) are no longer on the M0 critical path: our boot path
> loop-mounts the Android image from microSD instead of using DSU.

🌐 **English** · [فارسی](README.fa.md)

## Approach

A Halium GSI port on top of the **untouched stock Android 15 vendor**
(build `A145PXXUEDZJ2`), following the 2026 community pattern used by
[stone-ut](https://github.com/alpha-liu-01/stone-ut) and
[ubuntu-touch-bluejay](https://github.com/logicalangel/ubuntu-touch-bluejay).

This repository is separate from
[`android_device_samsung_a14m`](https://github.com/Behrooz140/android_device_samsung_a14m)
(TWRP tree), but reuses its prebuilt kernel, DTB/DTBO, touch firmware,
partition layout and boot header details.

## Docs

- [Porting notes](docs/porting-notes.md) — why this route, discovered facts
- [Hardware matrix](docs/hardware-matrix.md) — one row per bug area
- [Roadmap](docs/roadmap.md) — milestones M0–M4 with exit criteria
- [Bug triage](docs/bug-triage.md) — how to report and close a bug
- [Build](docs/build.md) · [Install](docs/install.md) · [First boot test](docs/first-boot-test.md) · [DSU testing](docs/dsu.md) · [Debugging](docs/debugging.md)

## License

Project files: GPL-3.0-or-later. Third-party components keep their own
licences; see [SOURCES.md](SOURCES.md) and [NOTICE](NOTICE).

Unofficial project, not affiliated with UBports, Samsung or MediaTek.
Flashing erases the device and trips the Knox warranty bit.
