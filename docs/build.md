# ساخت (Build)

> **وضعیت: ورودیها کاملاً پین شدند.** `sh tools/fetch-inputs.sh` با پیام
> `all inputs verified` تمام میشود و `build.sh all` قابل اجرا است. نگهبان
> `INPUTS_NOT_PINNED` همچنان سر راه هر بیلدی میماند که ورودی تأییدنشده داشته باشد.

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
| Halium GSI arm64 | UBports CI `halium-16.0` بیلد ۱۴۱ (نزدیکترین GSI موجود به vendor اندروید ۱۵) | ✅ `d2d93e08…` |
| rootfs Ubuntu Touch 24.04-x | UBports CI `24.04-2.x` بیلد ۱۶۸ | ✅ `da1314ac…` |
| `initrd.img-touch-arm64` | `halium/initramfs-tools-halium` release `dynparts` | ✅ پین شد |
| UBports recovery ramdisk | همان بیلد Halium 16 (شماره ۱۴۱) | ✅ پین شد |
| busybox-static | آینهٔ stone-ut، نسخهٔ `1.37.0-r31-aarch64-static` | ✅ پین شد |
| DTB/DTBO | TWRP tree @ `eb19a1d` | ✅ پین شد |
| ماژولها/فریمور تاچ | TWRP tree @ `eb19a1d` | ✅ قابل استخراج |

**چرا Halium 16؟** UBports CI هیچ jobای به نام `halium-15.0` ندارد. گزینهها
Halium 14 (قدیمیتر از vendor اندروید ۱۵) یا Halium 16 (جدیدتر از آن)اند؛ چون
در Treble معمولاً system باید حداقل به اندازهٔ vendor جدید باشد، Halium 16 را
انتخاب میکنیم. ابزارهای مربوطه (`halium-generic-adaptation-build-tools` @
`7dd99e0…` یا نسخهٔ جدیدتر `262bf2c…`) پشتیبانی `android15-6.6` را دارند. این
انتخاب تا اولین بوت روی دستگاه تأییدنشده است؛ پین کردن ورودیها در
[issue #1](https://github.com/Behrooz140/ubuntu-touch-a14m/issues/1) بسته شد و
سازگاری واقعی در [#2](https://github.com/Behrooz140/ubuntu-touch-a14m/issues/2)
پیگیری میشود.

**نکتهٔ KMI:** گزینههای Halium در برنچ
`bump/ubuntu-touch-halium-6.6` فقط تکرار تنظیمات موجود v1.6.1اند؛ بنابراین
KMI همان baseline باقی میماند. کرنل نهایی در CI همان ریپو با
`scripts/kmi_check.py verify` و چک ورماجیک استوک بررسی میشود و ما تنها بوت
ایمیج منتشرشدهٔ آنرا با SHA256 مصرف میکنیم، نه اینکه KMI را دوباره در این ریپو
بسازیم.

## پین کردن ورودی جدید

```sh
sh tools/pin-input.sh <filename> <url>
```

اسکریپت فایل را دانلود میکند، SHA256 و اندازهٔ آنرا چاپ میکند و آدرس را در
`inputs.urls` ثبت مینماید. خط مربوطه را باید دستی و بعد از بررسی منبع، جایگزین
خط `TBD` در `inputs.sha256` کرد.

## مراحل

```sh
sh tools/fetch-inputs.sh              # دانلود + بررسی SHA256
BUILD_ID=build-01 sh build.sh kernel   # unpack/verify بوت ایمیج کرنل + ثبت هدر
BUILD_ID=build-01 sh build.sh rootfs   # rootfs + overlay → ubuntu.img
BUILD_ID=build-01 sh build.sh boot     # boot-ut.img (کرنل + initramfs) + AVB
BUILD_ID=build-01 sh build.sh release  # SHA256SUMS نهایی
# یا یکباره:
BUILD_ID=build-01 sh build.sh all
```

`BUILD_ID` از طریق متغیر محیطی داده میشود؛ آرگومان positionals پشتیبانی نمیشود.
اگر تنظیم نشود، یک شناسهٔ مبتنی بر زمان ساخته میشود (برای بیلدهای محلی).

خروجیها در `out/build-01/`:

- `boot-ut.img` — کرنل behi + راندیمس Halium، هدر v4 + AVB (الگوی behi kernel)،
  اندازهٔ ۳۲MiB؛
- `init_boot-ut.img` — همان راندیمس Halium بدون کرنل، هدر v4 + AVB، اندازهٔ
  ۸MiB. دلیلش این است که پارتیشنهای استوک این دستگاه GKIاند: `boot` فقط کرنل
  دارد و راندیمس عمومی در `init_boot` قرار دارد ([#4](https://github.com/Behrooz140/ubuntu-touch-a14m/issues/4))؛
- `ubuntu.img` — rootfs ext4 حاوی overlay دستگاه؛
- `SHA256SUMS` — فقط همین چهار فایل released؛
- `build-info.txt` — شناسه بیلد، commit، هش کرنل، نسخهٔ ابزارها و لنگرهای
  قابلتولید مجدد.

درختهای میانی (`kernel/`, `ramdisk/`, `rootfs/tree/`) داخل پوشهٔ بیلد میمانند ولی
در `SHA256SUMS` نیستند، چون شامل مسیرهای مطلقاند. `vendor_boot` استوک دستنخورده
میماند.

تصویر GSI و `ubuntu.img` هر دو باید در مرحلهٔ نصب روی دستگاه قرار بگیرند؛
`build.sh release` فعلاً بستهٔ بوت/rootfs را میسازد و GSI را بهعنوان ورودی جدا
نگه میدارد تا مسیر DSU روی microSD هم باز بماند (نگاه کنید به `docs/dsu.md`).

## قابلتولید مجدد

دو بیلد با همان ورودیها، حتی با `BUILD_ID` متفاوت، `boot-ut.img`،
`init_boot-ut.img` و `ubuntu.img` یکسانی تولید میکنند. لنگرهای ثابت (`build.sh`):

| لنگر | مقدار پیشفرض | دلیل |
|---|---|---|
| `SOURCE_DATE_EPOCH` | `1767225600` (۲۰۲۶-۰۱-۰۱) | زمان ساخت superblock ext4 و مtimeها |
| `EXT4_HASH_SEED` | `6a14d000-…-0002` | جلوگیری از hash seed تصادفی mke2fs |
| UUID ext4 | `6a14d000-…-0001` | ثبات superblock |
| AVB salt | `6131346d…0000` | جلوگیری از salt تصادفی avbtool |
| cpio | `--reproducible` | حذف inode/uid/devnumberهای وابسته به چکاوت |

تفاوت تنها در `build-info.txt` است که شماره بیلد را ثبت میکند. بررسی محلی:

```sh
BUILD_ID=a sh build.sh all
BUILD_ID=b sh build.sh all
cmp out/a/boot-ut.img out/b/boot-ut.img
cmp out/a/init_boot-ut.img out/b/init_boot-ut.img
cmp out/a/ubuntu.img out/b/ubuntu.img
```

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
