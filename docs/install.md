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
adb shell dd if=/dev/block/by-name/init_boot of=/sdcard/backup/init_boot.img
adb pull /sdcard/backup .
```

پارتیشنهای منطقی `super` را طبق مستندات TWRP (بخش ۸٫۱) بکاپ بگیر.

## نصب (پس از M0)

پس از تأیید بیلد، دستورهای دقیق در Release مربوطه قرار میگیرند و همین فایل
با شماره بیلد بهروزرسانی میشود. الگو:

```sh
# مرحلهٔ ۱: بوت موقت — مسیر A (پیشفرض، بدون فلش هیچ پارتیشنی)
fastboot boot out/build-NN/boot-ut.img
```

چون پارتیشنهای استوک GKIاند، ممکن است بوتلودر راندیمس را از `init_boot`
بخواند و راندیمس داخل `boot-ut.img` را نادیده بگیرد. در آن صورت مسیر B:

```sh
# فقط بعد از بکاپ کامل از init_boot:
fastboot flash init_boot out/build-NN/init_boot-ut.img
fastboot boot out/build-NN/boot-ut.img     # یا fastboot reboot
# بازگشت: fastboot flash init_boot <بکاپ استوک>
```

`vendor_boot` و `vbmeta` در هر دو مسیر دستنخورده میمانند. فلش دائمی `boot`
فقط بعد از اینکه بوت موقت پایدار بود:

```sh
fastboot flash boot out/build-NN/boot-ut.img
fastboot reboot
```

`ubuntu.img` و GSI را طبق [مسیر DSU](dsu.md) روی دستگاه میگذاریم؛ تصمیم نهایی
محل آنها بعد از M0 گرفته میشود
([#2](https://github.com/Behrooz140/ubuntu-touch-a14m/issues/2)،
[#4](https://github.com/Behrooz140/ubuntu-touch-a14m/issues/4)).

## مسیر پیشنهادی برای اولین بوت: microSD اکست۴

دو مانع مستقل، مسیر DSU و مسیر `/data` داخلی را سخت میکنند:

1. `super` فقط ~۳۵۱MiB آزاد دارد، پس DSU در پارتیشنهای پویا جا نمیشود
   ([#3](https://github.com/Behrooz140/ubuntu-touch-a14m/issues/3)).
2. initramfs هالیم انتظار یک پارتیشن **ext4 بدون رمزگذاری FBE** را دارد، ولی
   `/data` دستگاه f2fs با `fileencryption=aes-256-xts:aes-256-cts:v2` است. تنها
   `mount` کردن آن در initramfs کافی نیست: نام فایلها رمز میماند و `ubuntu.img`
   پیدا نمیشود.

پس برای اولین بوت از یک پارتیشن ext4 جداگانه روی microSD استفاده میکنیم:

```sh
# ۱) فقط بعد از بکاپ کامل کارت (تمام محتوا پاک میشود)
#    روی هاست: card=/dev/sdX  <- حتماً با lsblk تأیید کن
sudo sgdisk --zap-all "$card"
sudo sgdisk -n 1:0:0 -t 1:8300 "$card"
sudo mkfs.ext4 -L ut-data "${card}1"

# ۲) کپی تصاویر (GSI داخل تار Halium، بدون AVB footer)
sudo mount "${card}1" /mnt/ut-data
cp out/build-NN/ubuntu.img /mnt/ut-data/
tar -xJf inputs/halium-gsi-arm64.tar.xz -C /tmp \
  system/var/lib/lxc/android/android-rootfs.img
cp /tmp/system/var/lib/lxc/android/android-rootfs.img /mnt/ut-data/system.img
sync && sudo umount /mnt/ut-data

# ۳) بیلد با cmdline اضافی datapart (هیچ پارتیشن داخلی فلش نمیشود)
UT_DATAPART=/dev/block/mmcblk1p1 BUILD_ID=build-sd sh build.sh all

# ۴) بوت موقت
fastboot boot out/build-sd/boot-ut.img
```

بازگشت کامل: ریبوت ساده (چون فلش نشده) و در صورت تمایل خارج کردن کارت.
پارتیشن internal `/data`، `super` و `vbmeta` دستنخورده میمانند. درخت ext4
روی کارت هر بار توسط initramfs `e2fsck` و در صورت لزوم resize میشود.

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
