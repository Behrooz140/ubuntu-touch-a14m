# نقشه راه (Milestoneها)

قاعده: هر milestone فقط وقتی بسته میشود که **معیار خروج** آن روی گوشی واقعی
تکرار شده و لاگش در issue مربوطه موجود باشد. چیزی از مرحلهٔ بعدی عقب
 نمیشود مگر اینکه از همان مرحله باشد.

## M0 — بوت و لاگ

**هدف:** بالا آمدن کرنل + initramfs + rootfs و رسیدن به Lomiri greeter یا حداقل
یک shell قابل دسترس از طریق adb/SSH.

| کار | معیار خروج |
|---|---|
| اعمال `halium_ut.config` روی behi kernel 6.6 و عبور از KMI | `Image.gz` با همان ABI ماژولهای استوک ساخته شود (در حال اجرا: [بیلد تست](https://github.com/Behrooz140/behi-kernel-sm-a145p/actions/runs/45077953406)) |
| حداقل `halium.config` + cmdline (`console=tty0`) | `dmesg` تا marque اصلی بدون panic |
| ساخت boot image هدر v4 + AVB طبق اسکریپت behi | بوتلودر تصویر را رد نکند (جلوگیری از لوگوی سامسونگ + ریبوت) |
| تست لایهٔ Halium داخل DSU (فاز A) | `gsi_tool status` سالم و `lshal` بدون خطا [docs/dsu.md](dsu.md) |
| تأیید decrypt `/data` در بوت عادی (TEE بالاست) | rootfs قابل مانت باشد |
| اولین rootfs + GSI در LXC | `systemctl` داخل کانتینر Halium سالم باشد |

** بلوکرها:** نتیجهٔ بیلد تست KMI، [پین کردن GSI/rootfs/initramfs (#1)](https://github.com/Behrooz140/ubuntu-touch-a14m/issues/1)،
[دور زدن امضای DSU (#2)](https://github.com/Behrooz140/ubuntu-touch-a14m/issues/2)،
[کمبود فضای `super` (#3)](https://github.com/Behrooz140/ubuntu-touch-a14m/issues/3)،
[تعیین محل راندیمس در GKI (#4)](https://github.com/Behrooz140/ubuntu-touch-a14m/issues/4).

## M1 — نمایش و ورودی

**هدف:** Lomiri قابل استفاده باشد.

نمایشگر (۴ پنل)، backlight، GPU، تاچ (۴ کنترلر + فریمور)، چرخش، وضعیت خواب/بیداری.
معیار خروج: قفلگشایی، کشیدن صفحه و اجرای یک اپ با ۳ بیلد پشت سر هم.

## M2 — ارتباطات

**هدف:** تماس، پیام و اینترنت.

Wi-Fi، Bluetooth (صدا)، مودم: تماس/SMS/داده، VoLTE و APN. معیار خروج: تماس
ورودی و خروجی + SMS + data روی سیم کارت واقعی.

## M3 — چندرسانهای و حسگرها

دوربین جلو/عقب + فلش، صدا (اسپیکر/هدفن/میکروفون)، GPS، سنسورها، اثر انگشت،
ویبره، USB (MTP/ADB/OTG)، MicroSD، باتری و deep sleep.

## M4 — توزیع و نگهداری

installer/OTA، Release با `SHA256SUMS`، مستندات نصب/بازگشت، ثبت دستگاه در
Community ports UBports (پس از پایداری)، جذب تسترهای دیگر.

---

## قوانین جابجایی باگ بین milestoneها

- باگ جدید با لبل `area:*` وارد همان milestone میشود که سختافزار مربوطه در آن است.
- اگر فیکسی باعث رگرسیون در milestone بستهشده شد، لبل `regression` میخورد و
  milestone قدیمی دوباره باز میشود.
- وضعیتها فقط در `docs/hardware-matrix.md` منبع حقیقتاند، نه در متن issue.
