# 2026-11-23 — بوت بدون فرمت کارت و رفع عدمتولیدپذیری

منبع: بررسی initiatorramfs و تنظیمات کرنل زنده، سپس بیلدهای مکرر در هاست.

## exFAT بدون فرمت

- initiatorramfs Halium بهطور شرطی `e2fsck` و `resize2fs` را اجرا میکند و فرض
  میکند userdataext4 است. در دستگاه `/data` فایلسیستم f2fs+FBE است و کارت
  microSD (`/dev/block/mmcblk1p1`) exFAT.
- کرنل بومی ما دارای `CONFIG_EXFAT_FS=y` است (از `/proc/config.gz` زنده تأیید شد).
- فایل `overlay/ramdisk/scripts/halium` اضافه شد تا:
  1. فایلسیستم را با `blkid` تشخیص دهد؛
  2. برای exFAT از `e2fsck`/`resize2fs` صرفنظر کند؛
  3. رشتهٔ گزینههای mount بدون کامای اضافی ساخته شود؛
  4. در صورت شکست mount، panic با پیام واضح ثبت شود.
- نتیجه: نیازی به فرمت مخرب کارت نیست. همان کارت ۵۸GiB فعلی (۲۳GiB آزاد)
  با `UT_DATAPART=/dev/block/mmcblk1p1` قابل استفاده است.

## رفع عدمتولیدپذیری rootfs

- `mke2fs -d` اینودها را به ترتیب `readdir()` پوشهٔ منبع تخصیص میدهد. ترتیب
  readdir در f2fs میزبان بین دو استخراج یکسان متفاوت بود → هش `ubuntu.img`
  عوض میشد (`build-05` در برابر `build-06`).
- `stage_rootfs` اکنون درخت را ابتدا روی یک اکست۴ حلقهای با
  `hash_seed=6a14d000-…-0002` استخراج میکند و سپس `mke2fs -d` از آن میخواند.
- `build-07` و `build-08` سه تصویر بایتبهبایت یکسان تولید کردند و
  `sha256sum -c SHA256SUMS` تأیید شد.

## بیلد مرجع جدید

| فایل | SHA256 |
|---|---|
| `boot-ut.img` | `cbcd98c571117db4785715b343ec379775136a82c5574768aaf8cf49d680c9e7` |
| `init_boot-ut.img` | `5313533bd9c232ea932a774065bc007aac3f5b26b391fed4bca6edb9a8b7a043` |
| `ubuntu.img` | `aa43f8196c23ec64275280722b19fd3281c777fd0c3a7ec22b616c27545bddb5` |

## وضعیت

هیچ فلش یا تغییری روی دستگاه انجام نشد. بکاپ پارتیشنهای حساس در
`/root/.cache/ut-device/backup/` ذخیره و هش شد. گام بعدی: restored استوک،
کپی تصاویر به کارت، و بوت موقت `fastboot boot`.

[#5]: https://github.com/Behrooz140/ubuntu-touch-a14m/issues/5
