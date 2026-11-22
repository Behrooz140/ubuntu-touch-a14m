# نصب و بازگشت به استوک

> **هشدار: فعلاً هیچ دستور فلش قابل اجرایی در اینجا وجود ندارد.** تا زمانی که
> M0 بیلد تأییدشده تولید نکند، لطفاً چیزی فلش نکن. برای تست غیرمخرب لایهٔ
> Halium از [مسیر DSU](dsu.md) استفاده کن.

## پیشنیازها

- گوشی SM-A145P با بوتلودر باز (warranty bit = 1)؛
- بیلد استوک `A145PXXUEDZJ2` (اندروید ۱۵) — **نه GSI اندروید ۱۷ فعلی**؛
- TWRPbuild 31 از
  [`android_device_samsung_a14m`](https://github.com/Behrooz140/android_device_samsung_a14m)
  روی گوشی کار کند؛
- AVB طبق بخش ۷٫۲ مستندات TWRP غیرفعال باشد؛
- بکاپ کامل: `/data`، `super`، `persist`، `metadata`، `vbmeta`؛
- کابل USB و ابزار fastboot روی هاست.

## بکاپ (قبل از هر کاری)

```sh
# از داخل TWRP، یا از هاست:
adb shell dd if=/dev/block/by-name/persist of=/sdcard/backup/persist.img
adb shell dd if=/dev/block/by-name/metadata of=/sdcard/backup/metadata.img
adb shell dd if=/dev/block/by-name/vbmeta of=/sdcard/backup/vbmeta.img
adb pull /sdcard/backup .
```

پارتیشنهای منطقی `super` را طبق مستندات TWRP (بخش ۸٫۱) بکاپ بگیر.

## نصب (پس از M0)

پس از تأیید بیلد، دستورهای دقیق در Release مربوطه قرار میگیرند و همین فایل
با شماره بیلد بهروزرسانی میشود. الگو:

```sh
# مرحلهٔ ۱: بوت موقت (هیچ پارتیشنی فلش نمیشود؛ با یک ریبوت برمیگردد)
fastboot boot out/build-NN/boot-ut.img

# مرحلهٔ ۲: فقط در صورتی که بوت موقت پایدار بود
fastboot flash boot out/build-NN/boot-ut.img
fastboot reboot
```

`ubuntu.img` و GSI را طبق [مسیر DSU](dsu.md) روی دستگاه میگذاریم؛ تصمیم نهایی
محل آنها بعد از M0 گرفته میشود ([#1](https://github.com/Behrooz140/ubuntu-touch-a14m/issues/1)،
[#4](https://github.com/Behrooz140/ubuntu-touch-a14m/issues/4)).

## بازگشت به اندروید

1. بوت به TWRP؛
2. Restore بکاپ `/data` و `super`؛
3. فلش `boot.img` و `vbmeta` استوک بیلد `A145PXXUEDZJ2`؛
4. ریبوت و تأیید One UI.

## مشکلات رایج

| علامت | دلیل محتمل | مرجع |
|---|---|---|
| لوگوی سامسونگ و ریبوت | vbmeta استوک / هدر بوت اشتباه | TWRP docs §7.2 |
| تاچ کار نمیکند | فریمور تاچ در rootfs/ramdisk نیست | `area:touch` |
| لوپ بوت بدون dmesg | cmdline فاقد `console=tty0` | `deviceinfo` |

همیشه قبل از ایجاد issue، [قواعد ثبت باگ](bug-triage.md) را بخوان.
