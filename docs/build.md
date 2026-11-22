# ساخت ( Build)

> **وضعیت: اسکلت.** اسکریپتها تا زمان پین شدن ورودیها (SHA256) با پیام
> `INPUTS_NOT_PINNED` متوقف میشوند. این عمدی است: هیچ بیلدی نباید با فایل
> تأییدنشده ساخته شود.

## محل ساخت

روی هاست x86_64 لینوکس (Ubuntu 26.04) یا GitHub Actions. اجرا روی گوشی پشتیبانی
نمیشود. فضای لازم: حدود ۲۵–۳۰ گیگ.

## ورودیها

همهٔ ورودیها توسط `tools/fetch-inputs.sh` بر اساس `inputs.sha256` دانلود و
بررسی میشوند:

| ورودی | منبع | وضعیت |
|---|---|---|
| کرنل استوک / Halium | منبع ۶٫۶٫۱۱۸ سامسونگ — **در جستجو** | ❓ |
| Halium GSI arm64 | UBports CI (متناظر با Android 15) | ❓ پین نشده |
| rootfs Ubuntu Touch 24.04-x | UBports CI | ❓ پین نشده |
| UBports recovery ramdisk | UBports CI | ❓ پین نشده |
| busybox-static | Alpine repo | ❓ پین نشده |
| DTB/DTBO/ماژولها/فریمور تاچ | TWRP tree @ `eb19a1d` | ✅ قابل استخراج |

## مراحل

```sh
sh tools/fetch-inputs.sh      # دانلود + بررسی SHA256
sh build.sh kernel            # behi kernel 6.6 + halium.config + kmi_check
sh build.sh rootfs            # rootfs + overlay دستگاه
sh build.sh boot              # boot.img هدر v4 + AVB + initramfs
sh build.sh release build-NN  # بستهٔ Release + SHA256SUMS
```

خروجیها در `out/build-NN/`:

- `boot-ut.img` — کرنل + initramfs + overlay، هدر v4 + AVB (الگوی behi kernel)؛
- `userdata-ut.img` یا `system-ut.img` — بسته به تصمیم M0؛
- `SHA256SUMS` و `build-info.txt` (شماره بیلد، commit، نسخهٔ ورودیها).

## قواعد بیلد

- هر بیلد یک تگ `build-NN` میگیرد؛ تگها بازنویسی نمیشوند.
- UBports CI فایلهای قدیمی را حذف میکند، بنابراین ورودیها باید در Release
  همآینه شوند (الگوی stone-ut).
- `build.sh` قبل از اعمال پچها، تمیزی درخت کرنل را چک میکند و در صورت وجود
  تغییرات محلی متوقف میشود.
- هر بیلد موفق Artifact + Release میسازد؛ CI فقط با `workflow_dispatch` یا تگ
  اجرا میشود تا quota هدر نرود.

## چکلیست قبل از فلش

- [ ] `sha256sum -c SHA256SUMS` روی هاست OK است
- [ ] شماره بیلد و commit در `build-info.txt` ثبت شده
- [ ] بیلد مبنا Android `A145PXXUEDZJ2` است (نه GSI ۱۷ فعلی)
- [ ] بکاپ کامل از `/data` و پارتیشنهای `super` گرفته شده
- [ ] issue مربوط به تست بیلد باز شده است
