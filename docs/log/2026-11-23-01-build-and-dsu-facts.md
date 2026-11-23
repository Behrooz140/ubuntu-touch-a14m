# 2026-11-23 — بیلد مرجع و حقایق تازهٔ DSU/GKI

منبع: بیلد محلی در هاست، خواندن مستقیم پارتیشنها از دستگاه، و کد منبع
AOSP `system/gsid`.

## بیلد

- تمام ورودیها پین شدند؛ `sh tools/fetch-inputs.sh` → `all inputs verified`.
- GSI ۱۴۱ هالیم ۱۶: `d2d93e08948b7d795211b838bb99df2f7b6ff5649f28662a8c98ca7ad95f4c36`
  (۱۴۲٬۸۵۳٬۳۲۰ بایت)؛ rootfs ۱۶۸:
  `da1314acd0895fbfb8fbb8517aa4975224a0bf6f225f36567e9f664b56402acd`
  (۹۷۱٬۵۳۱٬۳۶۹ بایت). هر دو آرشیو با `xz -t` / `gzip -t` سالم ماند.
- `BUILD_ID=build-01 sh build.sh all` و `BUILD_ID=build-02 sh build.sh all`
  موفقیتآمیز. `boot-ut.img`، `init_boot-ut.img` و `ubuntu.img` بایتبهبایت
  یکساناند؛ تنها `build-info.txt` متفاوت است.
- هش تصاویر در `docs/build.md` ثبت شد.

## GKI

| پارتیشن | نتیجهٔ `unpack_bootimg.py` | اندازه |
|---|---|---|
| `boot` | header v4، کرنل ۱۵٬۵۱۳٬۳۶۵ بایت، راندیمسک ۰ | ۳۲MiB |
| `init_boot` | header v4، کرنل ۰، راندیمسک ۳٬۰۸۶٬۴۲۸ بایت | ۸MiB |
| `vendor_boot` | `VNDRBOOT` | ۶۴MiB |

`build.sh` اکنون علاوه بر `boot-ut.img`، `init_boot-ut.img` هم میسازد.
`vendor_boot` دستنخورده میماند.

## DSU

- `gsi_tool install` گزینهٔ مخفی و اجباری `--install-dir` دارد؛ تصویر GSI را
  از stdin میخواند. `--no-reboot` و `--partition-name` هم در کد منبع وجود دارند.
- مسیر مجاز نصب فقط `/data/gsi/dsu/` یا `/mnt/media_rw/<VOL>/` است.
- رسانهٔ خارجی فقط زمانی پذیرفته میشود که `statfs` مقدار
  `MSDOS_SUPER_MAGIC` (FAT32) بدهد؛ کارت فعلی exFAT است.
- فضای `super`: ۷٬۸۴۳٬۳۴۸٬۴۸۰ بایت کل، ۳۵۱MiB آزاد) → DSU در `super` غیرممکن.
- فstab `/system` دارای سه کلید GSI است و `check_at_most_once` ندارد.
- `android-rootfs.img` داخل تار Halium، ext2 بدون AVB footer است؛ مشکل امضا
  مربوط به first-stage AVB است نه `gsid`.

## وضعیت

هیچ فلش یا تغییری روی دستگاه انجام نشد. گام بعدی حل [#2] و [#3]، سپس بوت
موقت با `fastboot boot` بعد از restore استوک و بکاپ کامل.

[#2]: https://github.com/Behrooz140/ubuntu-touch-a14m/issues/2
[#3]: https://github.com/Behrooz140/ubuntu-touch-a14m/issues/3
