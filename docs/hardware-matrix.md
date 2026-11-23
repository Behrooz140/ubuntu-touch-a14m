# ماتریس سختافزار و وضعیت باگها

**قاعدهٔ طلایی: هر سطر = یک سختافزار = حداکثر یک issue باز.** وقتی فیکسی
مرج، همان سطر در همان PR بهروزرسانی میشود و لینک لاگ و شماره بیلد اضافه
میشود. وضعیتها: ✅ کار میکند · ⚠️ کار میکند با محدودیت · ❌ کار نمیکند ·
❓ تست نشده · 🚫 محدودیت بوتلودر/سختافزار.

آخرین بهروزرسانی: ۲۰۲۶-۱۱-۲۳ (بیلد مرجع `build-08`، قبل از اولین بوت UT)

## پیشنیازها و بستر (پلتفرم)

| مورد | وضعیت | شواهد / یادداشت | Issue |
|---|---|---|---|
| بوتلودر باز + Knox tripped | ✅ | TWRP و KernelSU روی دستگاه کار میکنند | — |
| قابلیت DSU | ⚠️ | `gsi_tool status=normal`، `dynamic_partitions=true`، A-only؛ `veritymode=enforcing`، فاقد امضای GSI، و فقط ۳۵۱MiB آزاد در `super` | #2، #3 |
| پارتیشنهای بوت GKI | ✅ | خواندن مستقیم پارتیشنها: `boot` فقط کرنل، `init_boot` راندیمسک، `vendor_boot` ماژولها؛ `build.sh` هر دو ایمیج UT را میسازد | بسته شد #4 |
| غیرفعالسازی AVB (`vbmeta`) | ✅ | در TWRP tree، بخش ۷٫۲ مستندشده | — |
| هدر بوت | ✅ | TWRP/ریکاوری: v2، `kernel 0x40080000`، `ramdisk 0x47C80000`، `tags/dtb 0x4BC80000`، page 4096، board `SRPVJ12A014`. بوت GKI: v4 + `SEANDROIDENFORCE` + AVB، طبق اسکریپت behi kernel | — |
| DTB/DTBO استوک | ✅ | `prebuilt/dtb.img` + `prebuilt/dtbo.img` در TWRP tree، بایت به بایت مطابق استوک | — |
| کرنل: binder/hwbinder/vndbinder/ashmem/UserNS | ✅ | از `/proc/config.gz` زنده دستگاه استخراج شد | — |
| ABI/KMI ماژولهای vendor | ✅ | behi kernel ورماجیک استوک ۶٫۶٫۱۱۸ را پین میکند و `scripts/kmi_check.py` CRCها را در CI چک میکند | — |
| منبع کرنل ۶٫۶٫۱۴۴ (`behi`) | ✅ | [`Behrooz140/behi-kernel-sm-a145p`](https://github.com/Behrooz140/behi-kernel-sm-a145p) @ `fbdd52d` — GKI `android15-6.6`؛ برنچ UT: `bump/ubuntu-touch-halium-6.6` @ `1a3814092` | — |
| ورودیهای Halium/rootfs | ✅ | تمام ورودیها پین و تأیید شدند؛ `fetch-inputs.sh` → `all inputs verified`؛ بیلد مرجع `build-08` | بسته شد #1 |
| نسخهٔ vendor مبنا | ⚠️ | فعلاً GSI اندروید ۱۷ on-device است؛ باید به `A145PXXUEDZJ2` (اندروید ۱۵) برگردیم | #22 |
| محل rootfs UT | ⚠️ | مسیر `/data` داخلی f2fs+FBE است و توسط initramfs هالیم قابل خواندن نیست؛ initramfs ما اکنون exFAT را هم میپذیرد، پس همان کارت فعلی با `datapart=` کار میکند | #5 |
| TEE در ریکاوری بالا نمیآید | 🚫 | محدودیت بوتلودر؛ **برای بوت عادی بیاثر است** چون TEE در بوت معمولی بالا میآید | — |

## سختافزارها

| سختافزار | وضعیت | جزئیات / چکلیست | Issue |
|---|---|---|---|
| بوت تا Lomiri (shell) | ❓ | هدف M0؛ بوت ایمیج UT توسط `build.sh boot` ساخته شد، ولی هنوز روی دستگاه تست نشده | #5 |
| نمایشگر (پنلهای BOE/TXD/INX/JDI) | ❓ | ۴ پنل: hx83112f, jd9522t, nl9922c, td4375 | #6 |
| روشنایی / backlight | ❓ | مسیر backlight واقعی از TWRP tree | #7 |
| تاچ (Himax / Jadard / Chipone / Focaltech) | ❓ | فریمور تاچ باید در ramdisk/rootfs موجود باشد | #8 |
| GPU / Mali | ❓ | رندر Lomiri وابسته به آن است | #9 |
| Wi-Fi | ❓ | HAL + wpa_supplicant | #10 |
| Bluetooth (صدا + اتصال مجدد) | ❓ | | #11 |
| صدا: اسپیکر / هدفن / میکروفون | ❓ | pulseaudio-modules-droid | #12 |
| مودم: تماس / SMS / داده | ❓ | ofono + IMS/VoLTE | #13 |
| دوربین عقب / جلو + فلش | ❓ | droidmedia + تنظیمات camera | #14 |
| GPS / GNSS | ❓ | GNSS HAL استوک | #15 |
| سنسورها (چرخش، نور، ...) | ❓ | hybris sensors | #16 |
| اثر انگشت | ❓ | چیپ cdfinger/focaltech | #17 |
| ویبره / هپتیک | ❓ | در TWRP با پچ ۰۰۱۷ درست شد | #18 |
| باتری / شارژ / خواب عمیق | ❓ | | #19 |
| USB (MTP/ADB/شارژ/OTG) | ❓ | سوییچ نقش OTG در TWRP tree هست | #20 |
| MicroSD (exFAT / ext4) | ⚠️ | exFAT فعلی توسط `gsid` بهعنوان DSU external پذیرفته نمیشود، ولی initramfs پچشده ما آن را mount میکند؛ نیازی به فرمت کارت نیست | #3، #5 |
| رمزگشایی `/data` در بوت عادی | ❌ | initramfs هالیم با f2fs+FBE سازگار نیست؛ فعلاً از مسیر microSD (exFAT) دور میزنیم | #5 |
| OTA / installer | ❓ | M4 | #21 |

## چگونه یک سطر را به ✅ تغییر دهیم

1. بیلدی بساز و تگ `build-NN` بزن.
2. تست مشخص (مراحل + نتیجه + لاگ) را در issue مربوطه بگذار.
3. فیکس را همراه با بهروزرسانی همین جدول و لینک تست commit کن.
