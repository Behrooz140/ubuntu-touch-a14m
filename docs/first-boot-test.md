# نحوهٔ اولین تست بوت (ایمن، بدون فلش دائمی)

## وضعیت فعلی

> اجرای بوت و تست زنده برعهدهٔ شماست؛ در محیط بیلد فقط تصاویر ساخته و هشها
> تأیید شدند. هیچ فلش دائمی در این مرحله لازم نیست.

- چهار تصویر لازم **روی کارت exFAT دستگاه** کپی شدهاند (فقط اضافه شدند، هیچ چیز
  پاک یا فرمت نشد):

  | فایل روی کارت | SHA256 |
  |---|---|
  | `/mnt/media_rw/6EEC-F18E/ubuntu.img` | `47aea5aabce50f53efc5b7b126ad72ab4283e1422bcad152db07df1b0b6e7f43` |
  | `/mnt/media_rw/6EEC-F18E/system.img` | `afb89075a6abe2a0b2729aab76093304727868e87a8a45f4287ad4ecc4495978` |
  | `/mnt/media_rw/6EEC-F18E/boot-ut.img` | `f0c4c1a8355faf534aa96326d958620a042879c92b3ef04d0049b0707b91eda3` |
  | `/mnt/media_rw/6EEC-F18E/init_boot-ut.img` | `80fe1affea7a002c23e8e290c446c8dc930c5facc8a1f702d901e6f4b2c6e9cc` |

- بوت ایمیج دارای `datapart=/dev/block/mmcblk1p1` است، پس initiatorramfs کارت
  exFAT را mount میکند و دو تصویر بالا را loop-mount مینماید.
- پارتیشنهای داخلی `boot`، `init_boot`، `vendor_boot`، `super`، `vbmeta` و
  `/data` **تغییری نکردهاند**. بکاپ حساس partitions در
  `/root/.cache/ut-device/backup/` موجود و هش شده است.

## کاری که باید از یک هاست بیرونی انجام شود

> `fastboot boot` تصویر را فقط برای **یکبار بوت** بارگذاری میکند و هیچ چیز را
> فلش نمیکند. بعد از ریبوت، دستگاه به اندروید فعلی خود برمیگردد.

1. فایل `boot-ut.img` را از کارت بگیر (یکی از راهها):

   ```sh
   # اگر adb در دسترس است
   adb pull /mnt/media_rw/6EEC-F18E/boot-ut.img .
   # یا کارت را به هاست وصل کن و از ریشهٔ آن بردار
   ```

2. هش را روی هاست چک کن:

   ```sh
   sha256sum boot-ut.img
   # باید برابر باشد با:
   # f0c4c1a8355faf534aa96326d958620a042879c92b3ef04d0049b0707b91eda3
   ```

3. دستگاه را وارد bootloader کن:

   ```sh
   adb reboot bootloader
   # یا از داخل اندروید: reboot bootloader
   ```

4. بوت موقت:

   ```sh
   fastboot boot boot-ut.img
   ```

5. بعد از بالا آمدن (یا گیر کردن)، لاگها را جمع کن:

   ```sh
   sh tools/collect-logs.sh first-boot
   adb pull /sdcard/ut-logs/first-boot.tar.gz .
   ```

   اگر لومیری بالا نیامد و adb کار نکرد، از طریق TWRP یا `/dev/kmsg`\
   ذخیرهشده در pstore لاگ بگیر.

6. نتیجه را در [issue #5](https://github.com/Behrooz140/ubuntu-touch-a14m/issues/5)
   ثبت کن: شماره بیلد، آخرین خطوط `/dev/kmsg`، وضعیت بوت تا Lomiri، و هر
   سختافزاری که کار نکرد (هر کدام issue مربوطه در `docs/hardware-matrix.md`).

## بازگشت

ریبوت ساده کافی است. در صورت نیاز به اندروید استوک، طبق `docs/install.md` و
بکاپهای ذخیرهشده عمل کن.

## نکتهٔ مهم

دستگاه فعلاً Android 17 GSI است. چون تصویر اندروید موردنیاز UT روی **کارت**
قرار دارد و نه در `super`، این بوت موقت نباید به GSI فعلی وابسته باشد. با وجود
آن، مسیر نهایی باید بعداً به استوک `A145PXXUEDZJ2` برگردد
([issue #22](https://github.com/Behrooz140/ubuntu-touch-a14m/issues/22)).
