# نصب و تست از طریق DSU

## حکم کلی

**DSU یک مسیر عالی برای تست ایمن لایهٔ Halium است، ولی بهتنهایی Ubuntu Touch
را بوت نمیکند.** دلیل:

1. دستور `gsi_tool install` روی همین گوشی فقط دو تصویر میپذیرد: `system` و
   `userdata` (طبق متن کمک خود باینری: `--gsi-size`، `--userdata-size`،
   `--wipe`). گزینهای برای `boot.img` ندارد.
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
- متن کمک دقیق `gsi_tool` روی دستگاه:
  `install [--gsi-size ...] [--userdata-size ...] [--wipe]`،
  `enable [-s|--single-boot] [-d|--dsuslot SLOT]`، `disable`، `wipe`، `status`.
  **هیچ گزینه برای boot/init_boot/vendor_boot ندارد.**
- فضای آزاد `super` کم است (~۳۵۰MiB)، پس نصب GSI معمولی در `super` ممکن است با
  کمبود فضا روبرو شود. گزینهٔ بهتر، نصب بر روی **microSD** است (باینری رشتهٔ
  `install-dir` و پشتیبانی AOSP از DSU on external media). ابتدا گنجایش و فایلسیستم
  کارت را چک میکنیم.
- چون `veritymode=enforcing` است، GSI امضانشده UBports توسط `gsid` رد میشود؛
  باید از `gsid` سفارشی (DSU Sideloader / ماژول KernelSU) یا کلید عمومی اضافهشده
  استفاده کرد.
- وجود `init_boot` و `vendor_boot` یعنی معماری GKI استاندارد است: راندیمسک عمومی
  در `init_boot` و راندیمسک vendor (ماژولهای `.ko`) در `vendor_boot` قرار دارد.
  بوت ایمیج UT باید این را در نظر بگیرد (حداقل `init_boot` با initramfs ما جایگزین
  شود یا راندیمسک داخل `boot` قرار گیرد).

> دستورهای بالا را از طریق `chroot /proc/1/root /system/bin/sh` در محیط فعلی
> اجرا کردیم؛ ریشهٔ اندروید در `/proc/1/root` قابل دسترس است.

> دستورهای `getprop` داخل chroot اوبونتو به دلیل شکستن لینکر APEX اجرا نمیشوند؛
> این بررسیها را باید از `adb shell` اندروید انجام داد، نه از داخل chroot.

## فاز A — تست لایهٔ Halium داخل DSU (غیرمخرب)

```sh
# ۱) تصویر GSI را روی گوشی بریز
adb push halium-gsi-arm64.img /sdcard/Download/system.img

# ۲) اندازهٔ تصویر را به مضرب ۵۱۲ گرد کن (gsid سختگیر است)
adb shell 'stat -c %s /sdcard/Download/system.img'

# ۳) نصب DSU (از shell اندروید با روت)
adb shell 'su -c "gsi_tool install --gsi-size <ROUND_UP_BYTES> \
  --userdata-size 3221225472 --wipe < /sdcard/Download/system.img"'

# ۴) وضعیت
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
- [ ] بکاپ از `persist`، `metadata`، `vbmeta` و بوت فعلی behi گرفته شده
- [ ] تصویر GSI دقیقاً با نسخهٔ Halium پینشده در `inputs.sha256` همخوان است
- [ ] فضای آزاد کافی (GSI + حداقل ۳GiB userdata)
- [ ] مسیر دور زدن امضای GSI (ماژول KernelSU یا DSU Sideloader) مشخص است

## باگها

لبل `area:dsu` برای مشکلات مربوط به نصب/امضا/gsid و `area:boot` برای مشکلات
بوت ایمیج UT. هر دو با شماره بیلد و خروجی `gsi_tool status` ثبت شوند.
