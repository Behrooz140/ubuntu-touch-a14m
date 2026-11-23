# نصب و تست از طریق DSU

## حکم کلی

**DSU یک مسیر عالی برای تست ایمن لایهٔ Halium است، ولی بهتنهایی Ubuntu Touch
را بوت نمیکند.** دلیل:

1. دستور `gsi_tool install` روی همین گوشی تصویر GSI را از **stdin** میخواند و
   هیچ گزینهای برای `boot`/`init_boot`/`vendor_boot` ندارد. متن کمک کوتاه باینری
   گزینهٔ اجباری `--install-dir` را نشان نمیدهد، ولی کد منبع AOSP
   (`system/gsid/gsi_tool.cpp`) آن را required علامت زده است.
2. Ubuntu Touch برای بالا آمدن به یک **boot/initramfs سفارشی** نیاز دارد تا
   `ubuntu.img` را loop-mount کند و Lomiri + libhybris را start دهد. بوت استوک/
   behi چنین راندیمسکی ندارد.
3. DSU طبق طراحی Android فقط GSIهای امضا شده با کلید مورد اعتماد Google/OEM
   را میپذیرد. GSI عمومی UBports چنین امضایی ندارد؛ با روت و DSU Sideloader
   (gsid سفارشی) یا اضافه کردن کلید عمومی به لیست کلیدهای مورد اعتماد DSU
   میشود رد شدن امضا را دور زد.

پس برنامهٔ عملی: **DSU بهعنوان محیط آزمایش سامانه + بوت سفارشی موقت**
(قابل برگشت)، نه فلش دائمی system/data.

## آنچه روی دستگاه تأیید شد (زنده، از داخل روتاندروید)

```
gsi_tool status                     -> normal        # هیچ DSU نصب نشده
getprop ro.boot.dynamic_partitions  -> true
getprop ro.boot.slot_suffix         -> (خالی)       # دستگاه A-only است
getprop ro.boot.verifiedbootstate   -> green
getprop ro.boot.veritymode          -> enforcing     # امضای GSI بررسی میشود
getprop ro.system.build.version.release -> 17       # GSI فعلی اندروید ۱۷
lpdump                              -> super ~7.31 GiB، آزاد حدود ۳۵۰MiB
ls /dev/block/by-name               -> boot, init_boot, vendor_boot, vbmeta, ...
```

- `/system/bin/gsi_tool` و `/system/bin/gsid` وجود دارند → قابلیت DSU در روم هست.
- متن کمک کوتاه `gsi_tool` روی دستگاه:
  `install [--gsi-size ...] [--userdata-size ...] [--wipe]`،
  `enable [-s|--single-boot] [-d|--dsuslot SLOT]`، `disable`، `wipe`، `status`.
  کد منبع همان نسخه نشان میدهد که `install` گزینههای
  `--install-dir` (اجباری)، `--no-reboot` و `--partition-name` هم دارد.
- **فضای `super` دقیقاً اندازهگیری شد:** کل پارتیشن ۷٬۸۴۳٬۳۴۸٬۴۸۰ بایت،
  حداکثر گروه `main` ۷٬۸۳۹٬۱۵۴٬۱۷۶ بایت، و آخرین extent مصرفشده تا سکتور
  ۱۴٬۶۲۴٬۱۵۲ (~۷٫۴۹GB)؛ یعنی حدود **۳۵۱MiB آزاد**. یک GSI ۳GiB در `super`
  جا نمیشود. تنها مسیر DSU، نصب روی رسانهٔ خارجی است.
- AOSP `gsi_service.cpp` مسیر نصب را فقط به `/data/gsi/dsu/` یا
  `/mnt/media_rw/<VOL>/` محدود میکند. برای رسانهٔ خارجی، `statfs` باید
  `MSDOS_SUPER_MAGIC` (FAT32) بدهد. کارت فعلی **exFAT** است
  (`/mnt/media_rw/6EEC-F18E` با نوع `exfat`)، پس بدون فرمت شدن به FAT32 توسط
  `gsid` بهعنوان رسانهٔ خارجی پذیرفته نمیشود. فرمت کردن مخرب است و فقط بعد از
  بکاپ کامل و با تأیید کاربر مجاز است.
- نصب DSU نیاز به پرچم `check_at_most_once` ندارد: فstab استوک `/system` دارای
  `avb_keys=/avb/q-gsi.avbpubkey:/avb/r-gsi.avbpubkey:/avb/s-gsi.avbpubkey`
  است و پرچم مذکور در آن دیده نمیشود.
- تصویر پینشدهٔ Halium (`android-rootfs.img`) یک ext2 ساده **بدون AVB footer**
  است (`avbtool info_image` میگوید «does not look like a vbmeta image»). بنابراین
  رد امضا در مرحلهٔ `gsid` نیست، بلکه در first-stage AVB هنگام بوت است؛ راه حل
  یا vbmeta غیرفعال، یا اضافه کردن کلید، یا `gsid` سفارشی است ([#2]).
- وجود `init_boot` و `vendor_boot` یعنی معماری GKI استاندارد است. خواندن مستقیم
  پارتیشنها نشان داد: `boot` فقط کرنل (ramdisk=0)، `init_boot` راندیمسک ۳٬۰۸۶٬۴۲۸
  بایت، `vendor_boot` با ماژولهای vendor. `build.sh` اکنون هر دو
  `boot-ut.img` و `init_boot-ut.img` را میسازد ([#4]).

> دستورهای بالا را از طریق `chroot /proc/1/root /system/bin/sh` در محیط فعلی
> اجرا کردیم؛ ریشهٔ اندروید در `/proc/1/root` قابل دسترس است.

> دستورهای `getprop` داخل chroot اوبونتو به دلیل شکستن لینکر APEX اجرا نمیشوند؛
> این بررسیها را باید از `adb shell` اندروید انجام داد، نه از داخل chroot.

## فاز A — تست لایهٔ Halium داخل DSU (غیرمخرب)

> **اجرا نشده است.** این دستورها قبل از restore استوک، بکاپ کامل، و حل [#2]
> و [#3] فقط الگواند. `--install-dir` در نسخهٔ نصبشده اجباری است؛ مسیر FAT32
> باید از نوع `/mnt/media_rw/<VOL>/` باشد.

```sh
# ۱) تصویر GSI را استخراج و به گوشی بفرست
tar -xJf inputs/halium-gsi-arm64.tar.xz \
  system/var/lib/lxc/android/android-rootfs.img
adb push system/var/lib/lxc/android/android-rootfs.img /data/local/tmp/system.img

# ۲) اندازهٔ دقیق بایت را بگیر و به مضرب ۵۱۲ گرد کن
adb shell 'su -c "stat -c %s /data/local/tmp/system.img"'

# ۳) نصب DSU بر روی کارت FAT32 (GSI از stdin خوانده میشود)
adb shell 'su -c "gsi_tool install \
  --install-dir /mnt/media_rw/<VOL>/ \
  --gsi-size <ROUND_UP_BYTES> --userdata-size 0 \
  --no-reboot < /data/local/tmp/system.img"'

# ۴) وضعیت و کلید AVB
adb shell 'su -c "gsi_tool status"'

# ۵) بوت به سیستم پویا: از نوتیفیکیشن DSU یا:
adb shell 'su -c "gsi_tool enable -s"'   # فقط یک بار
adb reboot
```

بازگشت: ساده است — reboot معمولی به سیستم اصلی برمیگردد (مگر sticky). برای
حذف کامل:

```sh
adb shell 'su -c "gsi_tool wipe"'
```

در این فاز فقط میخواهیم ببینیم کرنل behi + vendor استوک، سرویسهای Halium
(`hwbinder`, `vndbinder`, HALها) را بالا میآورند و `lshal` سالم است. موفقیت آن
یعنی مسیر GSI درست است و مشکل بعدی فقط rootfs/initramfs است.

## فاز B — اضافه کردن بوت سفارشی (همچنان قابل برگشت)

1. بوت ایمیج UT را میسازیم: کرنل behi + `halium.config` + initramfs busybox +
   overlay + AVB (الگوی `scripts/build_boot_image.sh`).
2. `ubuntu.img` (rootfs) را داخل **DSU userdata** قرار میدهیم (یا روی microSD
   اگر decrypt مشکل شد).
3. بوت ایمیج را **ابتدا موقتاً** میزنیم، بدون فلش شدن پارتیشن:

```sh
fastboot boot out/build-NN/boot-ut.img
```

   `fastboot boot` تصویر را تنها برای همان بوت استفاده میکند؛ با یک ریبوت ساده
   به بوت قبلی برمیگردیم. این از فلش `boot` هم ایمنتر است.

4. اگر بوت ایمیج موقت پایدار بود و خواستیم دائمیش کنیم:

```sh
fastboot flash boot out/build-NN/boot-ut.img
fastboot reboot
```

5. اگر بوت نشد: کافی است ریبوت کنیم (در حالت موقت) یا همان بوت استوک/behi قبلی
   را دوباره فلش کنیم؛ `system` و `/data` دستنخوردهاند و DSU هنوز نصب است.

## فاز C — تصمیم نهایی

پس از پایداری M0–M2 مشخص میکنیم که آیا همان ترکیب DSU + بوت سفارشی بماند یا
به فلش معمولی (system/rootfs) مهاجرت کنیم. مزیت ماندن: بکاپ و بازگشت خیلی
ساده است. معایب: وابستگی به گسید سفارشی/امضا و مصرف فضای `super`.

## چکلیست قبل از شروع DSU

- [ ] `adb shell gsi_tool status` بدون خطا اجرا میشود
- [ ] بیلد استوک `A145PXXUEDZJ2` (اندروید ۱۵) روی دستگاه است
- [ ] vbmeta غیرفعال است
- [ ] بکاپ از `persist`، `metadata`، `vbmeta`، `init_boot` و بوت فعلی behi گرفته شده
- [ ] تصویر GSI دقیقاً با نسخهٔ Halium پینشده در `inputs.sha256` همخوان است
- [ ] مسیر دور زدن امضای GSI (vbmeta غیرفعال / کلید / gsid سفارشی) مشخص است
- [ ] یک پارتیشن FAT32 (نه exFAT) با حداقل ۵GiB آزاد برای `--install-dir` آماده است
- [ ] فضای `super` بهعنوان مسیر نصب رد شده است ([#3])

[#2]: https://github.com/Behrooz140/ubuntu-touch-a14m/issues/2
[#3]: https://github.com/Behrooz140/ubuntu-touch-a14m/issues/3
[#4]: https://github.com/Behrooz140/ubuntu-touch-a14m/issues/4

## باگها

لبل `area:dsu` برای مشکلات مربوط به نصب/امضا/gsid و `area:boot` برای مشکلات
بوت ایمیج UT. هر دو با شماره بیلد و خروجی `gsi_tool status` ثبت شوند.
