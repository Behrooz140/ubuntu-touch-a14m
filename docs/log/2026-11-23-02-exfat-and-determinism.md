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

| فایل | پیشفرض (`build-10`) | با `datapart=` (`build-sd`) |
|---|---|---|
| `boot-ut.img` | `9fa215434860e178172a4150b7c3bf39150155473ed6c484d17b9f2b25717af5` | `f0c4c1a8355faf534aa96326d958620a042879c92b3ef04d0049b0707b91eda3` |
| `init_boot-ut.img` | `80fe1affea7a002c23e8e290c446c8dc930c5facc8a1f702d901e6f4b2c6e9cc` | همان |
| `ubuntu.img` | `47aea5aabce50f53efc5b7b126ad72ab4283e1422bcad152db07df1b0b6e7f43` | همان |

`overlay/README.md` از rootfs حذف شد تا مستندات توسعهدهنده وارد تصویر نشود.
همچنین mount اکستFAT بدون گزینهٔ `discard` انجام میشود و استیج قدیمی قبل از
هر بیلد پاک میشود تا هشها در بیلد مجدد ثابت بمانند. `build-10` و
`build-10-verify` سه تصویر بایتبهبایت یکسان تولید کردند.

## وضعیت

هیچ فلش یا تغییری روی دستگاه انجام نشد. بکاپ پارتیشنهای حساس در
`/root/.cache/ut-device/backup/` ذخیره و هش شد. گام بعدی: restored استوک،
کپی تصاویر به کارت، و بوت موقت `fastboot boot`.

[#5]: https://github.com/Behrooz140/ubuntu-touch-a14m/issues/5
