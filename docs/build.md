# ساخت (Build)

> **وضعیت: اسکلت قابلاجرا.** `build.sh` و `tools/fetch-inputs.sh` وجود دارند،
> ولی تا زمان پین شدن تمام ورودیها (`inputs.sha256`) با پیام
> `INPUTS_NOT_PINNED` متوقف میشوند. این عمدی است: هیچ بیلدی نباید با فایل
> تأییدنشده ساخته شود.

## محل ساخت

روی هاست x86_64 لینوکس (Ubuntu 24.04/26.04) یا GitHub Actions. اجرا روی گوشی
پشتیبانی نمیشود. فضای لازم: حدود ۲۵–۳۰ گیگ.

## ورودیها

همهٔ ورودیها توسط `tools/fetch-inputs.sh` بر اساس `inputs.sha256` دانلود و
بررسی میشوند. آدرس دانلود هر فایل در `inputs.urls` است؛ با تنظیم
`INPUTS_MIRROR` میشود همه را از آینهٔ Release خودمان گرفت.

| ورودی | منبع | وضعیت |
|---|---|---|
| `kernel-ut-boot.img` | [`behi v1.6.1`](https://github.com/Behrooz140/behi-kernel-sm-a145p/releases/tag/v1.6.1) — همان بوت ایمیجی که KMI gate کرنل را-pass کرده | ✅ پین شد |
| `kmi-baseline-v1.6.1.txt`, `kmi_check.py` | منبع کرنل @ `fbdd52d` | ✅ پین شد |
| Halium GSI arm64 | UBports CI (متناظر با Android 15/16) | ❓ پین نشده |
| rootfs Ubuntu Touch 24.04-x | UBports CI | ❓ پین نشده |
| `initrd.img-touch-arm64` | `halium/initramfs-tools-halium` release `dynparts` | ❓ پین نشده |
| UBports recovery ramdisk | UBports CI | ❓ پین نشده |
| busybox-static | Alpine repo | ❓ پین نشده |
| DTB/DTBO/ماژولها/فریمور تاچ | TWRP tree @ `eb19a1d` | ✅ قابل استخراج |

**نکتهٔ KMI:** گزینههای Halium در برنچ
`bump/ubuntu-touch-halium-6.6` فقط تکرار تنظیمات موجود v1.6.1اند؛ بنابراین
KMI همان baseline باقی میماند. کرنل نهایی در CI همان ریپو با
`scripts/kmi_check.py verify` و چک ورماجیک استوک بررسی میشود و ما تنها بوت
ایمیج منتشرشدهٔ آنرا با SHA256 مصرف میکنیم، نه اینکه KMI را دوباره در این ریپو
بسازیم.

## مراحل

```sh
sh tools/fetch-inputs.sh      # دانلود + بررسی SHA256
sh build.sh kernel            # unpack/verify بوت ایمیج کرنل + ثبت پارامترهای هدر
sh build.sh rootfs            # rootfs + overlay → ubuntu.img
sh build.sh boot              # boot-ut.img (کرنل + initramfs) + AVB
sh build.sh release build-NN  # بستهٔ Release + SHA256SUMS
# یا یکباره:
sh build.sh all build-NN
```

خروجیها در `out/build-NN/`:

- `boot-ut.img` — کرنل behi + راندیمس Halium، هدر v4 + AVB (الگوی behi kernel)،
  اندازهٔ ۳۲MiB؛
- `rootfs/ubuntu.img` — rootfs ext4 حاوی overlay دستگاه؛
- `SHA256SUMS` و `build-info.txt` (شماره بیلد، commit، هش کرنل، نسخهٔ ابزارها).

تصویر GSI و `ubuntu.img` هر دو باید در مرحلهٔ نصب روی دستگاه قرار بگیرند؛
`build.sh release` فعلاً بستهٔ بوت/rootfs را میسازد و GSI را بهعنوان ورودی جدا
نگه میدارد تا مسیر DSU روی microSD هم باز بماند (نگاه کنید به `docs/dsu.md`).

## قواعد بیلد

- هر بیلد یک تگ `build-NN` میگیرد؛ تگها بازنویسی نمیشوند.
- UBports CI فایلهای قدیمی را حذف میکند، بنابراین ورودیها باید در Release
  همآینه شوند (الگوی stone-ut).
- `build.sh kernel` قبل از هر کاری SHA256 بوت ایمیج کرنل و رشتهٔ ورماجیک استوک
  را چک میکند.
- هر بیلد موفق Artifact + Release میسازد؛ CI فقط با `workflow_dispatch` یا تگ
  اجرا میشود تا quota هدر نرود.

## چکلیست قبل از فلش

- [ ] `sha256sum -c SHA256SUMS` روی هاست OK است
- [ ] شماره بیلد و commit در `build-info.txt` ثبت شده
- [ ] بیلد مبنا Android `A145PXXUEDZJ2` است (نه GSI ۱۷ فعلی)
- [ ] بکاپ کامل از `/data` و پارتیشنهای `super` گرفته شده
- [ ] issue مربوط به تست بیلد باز شده است
