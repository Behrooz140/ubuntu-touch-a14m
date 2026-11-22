# قواعد ثبت و بستن باگ

## اصول

1. **یک سختافزار = یک issue.** دو مشکل متفاوت را در یک issue مخلوط نکن.
2. هر issue حتماً شمارهٔ بیلد (`build-NN`) و hash فایلها را دارد.
3. قبل از باز کردن issue، جدول [ماتریس سختافزار](hardware-matrix.md) را چک کن؛
   شاید همان سطر از قبل issue داشته باشد.
4. لاگها را به issue پیوست کن، نه اینکه متن خیلی طولانی را paste کنی.
5. اطلاعات شخصی (شماره تلفن، IMSI، ICCID، ایمیل، موقعیت GPS) را قبل از
   انتشار پاک کن.

## فیلدهای اجباری

| فیلد | مثال |
|---|---|
| بیلد | `build-01` |
| بیلد Android/vendor مبنا | `A145PXXUEDZJ2` (اندروید ۱۵) |
| Halium / UT | `halium-15` / `24.04-2.x` |
| سختافزار | `area:wifi` |
| مراحل تولید | ۱) Wi-Fi را روشن کن ۲) به شبکهٔ WPA2 وصل شو … |
| نتیجهٔ مورد انتظار / واقعی | … |
| لاگ | `build-01-wifi-2026-11-23.tar.gz` |

## لبلها

`area:boot` · `area:display` · `area:touch` · `area:gpu` · `area:wifi` ·
`area:bluetooth` · `area:audio` · `area:modem` · `area:camera` · `area:gps` ·
`area:sensors` · `area:fingerprint` · `area:usb` · `area:sdcard` · `area:battery`
· `needs-log` · `needs-build` · `regression` · `bootloader-limitation` ·
`upstream` · `wontfix`.

## جمعآوری لاگ

روی گوشی (از طریق `adb shell` یا SSH):

```sh
TAG=build-NN-area-YYYY-MM-DD
mkdir -p /sdcard/ut-logs/$TAG
dmesg > /sdcard/ut-logs/$TAG/dmesg.txt 2>&1 || true
journalctl -b --no-pager > /sdcard/ut-logs/$TAG/journal.txt 2>&1 || true
journalctl -b -1 --no-pager > /sdcard/ut-logs/$TAG/journal-prev.txt 2>&1 || true
lshal > /sdcard/ut-logs/$TAG/lshal.txt 2>&1 || true
getprop > /sdcard/ut-logs/$TAG/getprop.txt 2>&1 || true
systemctl --failed --no-pager > /sdcard/ut-logs/$TAG/failed-units.txt 2>&1 || true
cat /proc/config.gz | gzip -dc > /sdcard/ut-logs/$TAG/kernel-config 2>&1 || true
ls -l /sys/fs/pstore > /sdcard/ut-logs/$TAG/pstore-list.txt 2>&1 || true
cp /sys/fs/pstore/* /sdcard/ut-logs/$TAG/ 2>/dev/null || true
```

سپس:

```sh
adb pull /sdcard/ut-logs/$TAG .
tar -czf $TAG.tar.gz $TAG
sha256sum $TAG.tar.gz
```

برای بوتهای ناموفق، اسکریپت [<CODE>tools/collect-logs.sh</CODE>](../tools/collect-logs.sh)
را از ریکاوری/TWRP هم میشود اجرا کرد. لاگ دورهٔ قبل را حتماً بگیر؛ خیلی از
ریبوتها فقط در pstore دیده میشوند.

## بستن issue

فیکس باید شامل سه چیز باشد:

1. کد/پچ مربوطه؛
2. بهروزرسانی سطر مربوطه در `docs/hardware-matrix.md` (وضعیت + شماره بیلد + لینک تست)؛
3. یادداشت در `docs/log/` اگر تصمیم غیربدیهیایی گرفته شد.

سپس issue با لینک به PR بسته میشود، نه با «احتمالاً درست شد».
