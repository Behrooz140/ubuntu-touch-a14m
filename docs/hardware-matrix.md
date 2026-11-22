# ماتریس سختافزار و وضعیت باگها

**قاعدهٔ طلایی: هر سطر = یک سختافزار = حداکثر یک issue باز.** وقتی فیکسی
مرج، همان سطر در همان PR بهروزرسانی میشود و لینک لاگ و شماره بیلد اضافه
میشود. وضعیتها: ✅ کار میکند · ⚠️ کار میکند با محدودیت · ❌ کار نمیکند ·
❓ تست نشده · 🚫 محدودیت بوتلودر/سختافزار.

آخرین بهروزرسانی: ۲۰۲۶-۱۱-۲۲ (اسکویتینگ، قبل از اولین بیلد UT)

## پیشنیازها و بستر (پلتفرم)

| مورد | وضعیت | شواهد / یادداشت | Issue |
|---|---|---|---|
| بوتلودر باز + Knox tripped | ✅ | TWRP و KernelSU روی دستگاه کار میکنند | — |
| قابلیت DSU | ✅ | `gsi_tool status=normal`، `dynamic_partitions=true`، A-only، `super` ۷٫۳GiB (آزاد ~۳۵۰MiB)؛ `veritymode=enforcing` | — |
| پارتیشنهای بوت GKI | ✅ | `boot` + `init_boot` + `vendor_boot` + `vbmeta*` روی دستگاه موجوداند | — |
| غیرفعالسازی AVB (`vbmeta`) | ✅ | در TWRP tree، بخش ۷٫۲ مستندشده | — |
| هدر بوت | ✅ | TWRP/ریکاوری: v2، `kernel 0x40080000`، `ramdisk 0x47C80000`، `tags/dtb 0x4BC80000`، page 4096، board `SRPVJ12A014`. بوت GKI: v4 + `SEANDROIDENFORCE` + AVB، طبق اسکریپت behi kernel | — |
| DTB/DTBO استوک | ✅ | `prebuilt/dtb.img` + `prebuilt/dtbo.img` در TWRP tree، بایت به بایت مطابق استوک | — |
| کرنل: binder/hwbinder/vndbinder/ashmem/UserNS | ✅ | از `/proc/config.gz` زنده دستگاه استخراج شد | — |
| ABI/KMI ماژولهای vendor | ✅ | behi kernel ورماجیک استوک ۶٫۶٫۱۱۸ را پین میکند و `scripts/kmi_check.py` CRCها را در CI چک میکند | — |
| منبع کرنل ۶٫۶٫۱۴۴ (`behi`) | ✅ | [`Behrooz140/behi-kernel-sm-a145p`](https://github.com/Behrooz140/behi-kernel-sm-a145p) @ `fbdd52d` — GKI `android15-6.6` | — |
| نسخهٔ vendor مبنا | ⚠️ | فعلاً GSI اندروید ۱۷ on-device است؛ باید به `A145PXXUEDZJ2` (اندروید ۱۵) برگردیم | #TBD |
| محل rootfs UT (system در super در برابر userdata.img) | ❓ | تصمیم بعد از اولین بوت | #TBD |
| TEE در ریکاوری بالا نمیآید | 🚫 | محدودیت بوتلودر؛ **برای بوت عادی بیاثر است** چون TEE در بوت معمولی بالا میآید | — |

## سختافزارها

| سختافزار | وضعیت | جزئیات / چکلیست | Issue |
|---|---|---|---|
| بوت تا Lomiri (shell) | ❓ | هدف M0 | #TBD |
| نمایشگر (پنلهای BOE/TXD/INX/JDI) | ❓ | ۴ پنل: hx83112f, jd9522t, nl9922c, td4375 | #TBD |
| روشنایی / backlight | ❓ | مسیر backlight واقعی از TWRP tree | #TBD |
| تاچ (Himax / Jadard / Chipone / Focaltech) | ❓ | فریمور تاچ باید در ramdisk/rootfs موجود باشد | #TBD |
| GPU / Mali | ❓ | رندر Lomiri وابسته به آن است | #TBD |
| Wi-Fi | ❓ | HAL + wpa_supplicant | #TBD |
| Bluetooth (صدا + اتصال مجدد) | ❓ | | #TBD |
| صدا: اسپیکر / هدفن / میکروفون | ❓ | pulseaudio-modules-droid | #TBD |
| مودم: تماس / SMS / داده | ❓ | ofono + IMS/VoLTE | #TBD |
| دوربین عقب / جلو + فلش | ❓ | droidmedia + تنظیمات camera | #TBD |
| GPS / GNSS | ❓ | GNSS HAL استوک | #TBD |
| سنسورها (چرخش، نور، ...) | ❓ | hybris sensors | #TBD |
| اثر انگشت | ❓ | چیپ cdfinger/focaltech | #TBD |
| ویبره / هپتیک | ❓ | در TWRP با پچ ۰۰۱۷ درست شد | #TBD |
| باتری / شارژ / خواب عمیق | ❓ | | #TBD |
| USB (MTP/ADB/شارژ/OTG) | ❓ | سوییچ نقش OTG در TWRP tree هست | #TBD |
| MicroSD (exFAT) | ❓ | در TWRP کار میکند | #TBD |
| رمزگشایی `/data` در بوت عادی | ❓ | همان محدودیت ریکاوری نیست، ولی باید تست شود | #TBD |
| OTA / installer | ❓ | M4 | #TBD |

## چگونه یک سطر را به ✅ تغییر دهیم

1. بیلدی بساز و تگ `build-NN` بزن.
2. تست مشخص (مراحل + نتیجه + لاگ) را در issue مربوطه بگذار.
3. فیکس را همراه با بهروزرسانی همین جدول و لینک تست commit کن.
