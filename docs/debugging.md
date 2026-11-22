# عیب یابی و لاگها

## سطوح دسترسی

- **ADB**: وقتی developer mode / adb در UT فعال است.
- **SSH**: کلید عمومی در زمان ساخت rootfs به `phablet` اضافه میشود
  (پیرو الگوی stone-ut)؛ مسیر: `SSH_PUBKEY`.
- **سریال USB**: برخی بیلدهای debug ارسال لاگ از طریق USB serial دارند.
- **pstore**: تنها راه دیدن علت ریبوتهایی که قبل از بالا آمدن لاگ رخ میدهند.

## جمعآوری self-contained

```sh
sh tools/collect-logs.sh build-NN-touch-2026-11-23
# خروجی: /sdcard/ut-logs/build-NN-touch-2026-11-23.tar.gz
adb pull /sdcard/ut-logs/build-NN-touch-2026-11-23.tar.gz .
```

اسکریپت فقط میخواند، چیزی پاک نمیکند و در صورت نبودن دستورها با `|| true`
ادامه میدهد.

## نشانههای مهم در dmesg

| الگو | معنی |
|---|---|
| `init: ... Failed to mount` | مشکل decrypt یا فstab |
| `binder: ...` | مشکل ABI کرنل/ماژولها |
| `mt6768 ... probe failed` | ماژول استوک لود نشده |
| `tee` / `sec_os` | TEE بالا نیامده (در ریکاوری طبیعی است) |
| `panel` / `lcm` | پنل اشتباه انتخاب شده |

## لاگ بوت ناموفق

1. گوشی را خاموش کن، کابل را وصل کن و `adb shell cat /sys/fs/pstore/*` بگیر
   (اگر UT بوت شد)؛
2. از TWRP، مسیر `/sys/fs/pstore/` و `/cache/recovery/` را کپی کن؛
3. نام فایلها را با شماره بیلد و تاریخ بزن.

## ابزارهای کمکی

- `tools/patch_touch_bootmode.py` و `tools/twrp-diag.sh` از درخت TWRP قابل
 استفادهاند (تاچ و تشخیص در ریکاوری).
- `lshal`، `dumpsys`، `ofonoctl`، `pulseaudio`، `journalctl -b` منابع اصلیاند.
