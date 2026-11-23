# Ubuntu Touch برای Samsung Galaxy A14 4G (`a14m`)

پورت اجتماعی، متنباز و مرحلهای **Ubuntu Touch 24.04-x** روی
**Samsung Galaxy A14 4G — SM-A145P** (کدنام `a14m`)، چیپست MediaTek
**MT6768 / Helio G80**، معماری `arm64-v8a`.

> **وضعیت: بیلد قابلتولید مجدد آماده / قبل از اولین بوت.** هنوز هیچ ایمیجی
> فلش نشده است. ورودیها پین و سه تصویر بایتبهبایت قابلتولیداند؛ تصاویر لازم
> روی کارت exFAT فعلی گوشی کپی شدهاند. دستور بوت موقت در
> [اولین تست بوت](docs/first-boot-test.md) و وضعیت تکتک سختافزارها در
> [ماتریس سختافزار](docs/hardware-matrix.md) است.

🌐 [English](README.md) · **فارسی**

---

## چرا ریپازیتوری جداگانه؟

درخت TWRP تو (`Behrooz140/android_device_samsung_a14m`) یک دارایی
ارزشمند برای این پورت است: کرنل و ماژولهای استخراجشده از ریکاوری استوک،
DTB/DTBO، فریمور تاچ، فstab، هدر بوت و ۲۱ پچ. ولی Ubuntu Touch به چیزهای
دیگهای هم نیاز دارد: Halium GSI، rootfs، Lomiri، لایه libhybris، تنظیمات
ofono/pulseaudio/Wi-Fi و چرخهٔ «بیلد → تست → ثبت باگ → فیکس». مخلوط کردن
آنها با درخت TWRP، هر دوتا پروژه را سختگیر میکرد؛ بنابراین این ریپازیتوری
جداگانه است و به عنوان **consumer** از خروجیهای TWRP استفاده میکند.

## مسیر فنی انتخابشده

| گزینه | توضیح | تصمیم |
|---|---|---|
| Halium قدیمی (standalone 9/10) | ساخت android/system کامل + rootfs جداگانه، جداسازی vendor سخت | ❌ رد شد |
| **Halium GSI روی vendor استوک** | کرنل Halium + GSI عمومی UBports در LXC،vendor/modem/firmware دستکاری نشده | ✅ مسیر ما |
| postmarketOS / mainline | آزادی بیشتر ولی تقریباً هیچ درایوری برای MT6768 کار نمیکند | ❌ فعلاً |

الگوی معتبر این مسیر در سال ۲۰۲۶:
[stone-ut](https://github.com/alpha-liu-01/stone-ut) (Halium 14) و
[ubuntu-touch-bluejay](https://github.com/logicalangel/ubuntu-touch-bluejay)
(Halium 16). جزئیات و دلیل انتخاب در [یادداشتهای پورت](docs/porting-notes.md).

## نکتهٔ مهم در مورد نسخهٔ اندروید

GSI Halium باید با **vendor استوک** همخوانی داشته باشد. گوشی فعلاً یک GSI
اندروید ۱۷ (`infinity_gsi`) اجرا میکند؛ قبل از فلش UT باید به بیلد استوک
`A145PXXUEDZJ2` (اندروید ۱۵ / One UI 7) برگردیم و vendor را همانجا نگه داریم.
پارتیشنهای modem، vbmeta و `super` دستکاری نمیشوند.

## وضعیت فعلی (خلاصه)

| پیشنیاز | وضعیت |
|---|---|
| بوتلودر باز / Knox | ✅ انجامشده (TWRP و KernelSU روی گوشی هستند) |
| غیرفعالسازی AVB (`vbmeta`) | ✅ روی TWRP امتحانشده |
| هدر بوت GKI v4 + AVB (و ریکاوری v2 در TWRP) | ✅ الگوی کارآمد در [`behi-kernel-sm-a145p`](https://github.com/Behrooz140/behi-kernel-sm-a145p) |
| کرنل ۶٫۶ دارای binder/hwbinder/vndbinder/ashmem و User NS | ✅ از `/proc/config.gz` تأیید شد |
| منبع کرنل ۶٫۶٫۱۴۴ + نگهبان KMI | ✅ [`behi-kernel-sm-a145p`](https://github.com/Behrooz140/behi-kernel-sm-a145p) — برنچ UT: `bump/ubuntu-touch-halium-6.6` @ `1a3814092` |
| مسیر تست DSU | ⚠️ امضا و فضا محدوداند ([[#2]](https://github.com/Behrooz140/ubuntu-touch-a14m/issues/2)، [[#3]](https://github.com/Behrooz140/ubuntu-touch-a14m/issues/3))؛ ولی بوت M0 از DSU نمیکند، تصویر اندروید از کارت خوانده میشود |
| ورودیهای قابلتولید مجدد | ✅ تمام ورودیها پین شدند؛ `build-09` و `build-sd` تصاویر یکسان دادند — [#1](https://github.com/Behrooz140/ubuntu-touch-a14m/issues/1) |
| اسکریپت بیلد | ✅ `build.sh` + `tools/fetch-inputs.sh` + staging اکست۴ قطعی ([ساخت](docs/build.md)) |
| اولین بوت تا Lomiri | ❓ تصاویر روی کارت آمادهاند؛ فرمان بوت نیاز به هاست بیرونی دارد — [#5](https://github.com/Behrooz140/ubuntu-touch-a14m/issues/5) |
| تکتک سختافزارها | ❓ — [ماتریس](docs/hardware-matrix.md) |

## چرخهٔ کار

1. هر بیلد یک تگ `build-NN` و یک Release با `SHA256SUMS` دارد.
2. هر مشکل **یک issue** با لبل `area:*` و شمارهٔ بیلد دارد
   ([قواعد ثبت باگ](docs/bug-triage.md)).
3. فیکس + بهروزرسانی `docs/hardware-matrix.md` در **همان PR** میآید.
4. وقتی تست با موفقیت تکرار شد، وضعیت جدول به ✅ تغییر میکند و لینک لاگ/تست هم اضافه میشود.

## ساخت و نصب

- [ساخت](docs/build.md) — روی هاست x86_64 / GitHub Actions، **روی گوشی نه**.
- [نصب](docs/install.md) — شامل بازگشت به اندروید.
- [اولین تست بوت](docs/first-boot-test.md) — بوت موقت با `fastboot boot`، بدون فلش.
- [تست از طریق DSU](docs/dsu.md) — مسیر جایگزین برای تست لایهٔ Halium.
- [عیب یابی](docs/debugging.md) — لاگ، pstore، adb/ssh.

## مجوز

کدهای مالک این ریپازیتوری `GPL-3.0-or-later`اند. کرنل، rootfs، GSI و
فایلهای فرموار استوک هرکدام مجوز خود را دارند؛ فهرست کامل در
[SOURCES.md](SOURCES.md) و [NOTICE](NOTICE).

> پروژهای غیررسمی است و به UBports، سامسونگ یا MediaTek مربوط نیست.
> فلش کردن دادهها را پاک میکند و warranty bit را برای همیشه ۱ میکند.
