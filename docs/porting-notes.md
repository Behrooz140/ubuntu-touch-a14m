# یادداشتهای پورت — حقایق کشفشده و تصمیمها

## وضعیت فعلی دستگاه (اسکویتینگ ۲۰۲۶-۱۱-۲۲)

از خود دستگاه (Ubuntu chroot داخل KernelSU) و درخت TWRP موجود:

| مورد | مقدار |
|---|---|
| مدل / کدنام | SM-A145P / `a14m` (محصول سامسونگ `a14mnnxx`) |
| SoC | MediaTek MT6768 (`MT6769V/CT`)، Helio G80: 2×Cortex-A75 @2GHz + 6×Cortex-A55 @1.8GHz |
| RAM / ذخیره | ~3.6 GiB (2 GiB swap) / `/data` 50GiB f2fs، ~36GiB آزاد + MicroSD exFAT |
| کرنل زنده | `6.6.144-android15-8-abA145PXXUEDZJ2-4k-behi-v1.6.1` (Kleaf, clang 18) |
| کرنل ریکاوری استوک | `6.6.118-android15-8-abA145PXXUEDZJ2-4k` |
| بیلد استوک مبنا | `A145PXXUEDZJ2` / `AP3A.240905.015.A2`، اندروید ۱۵، پچ امنیتی 2026-10-05 |
| سیستم فعلاً بوتشده | GSI اندروید ۱۷ (`google/infinity_gsi/tdgsi_arm64_ab`) — **باید به استوک برگردیم** |
| ماژولهای KernelSU | `behi_uka`، `ubuntu-chroot`، `a145p_sms_pending_fix` |
| cmdline | `console=ttynull … console=tty0 root=/dev/ram bootopt=64S3,32N2,64N2 … lcm_panel=lcd_hx83112f_txd_boe_mipi_fhd_video_swid:0x13 … gpt=1` |
| هدر بوت | v2، page 4096، kernel `0x40080000`، ramdisk `0x47C80000`، tags/dtb `0x4BC80000`، board `SRPVJ12A014` |
| پارتیشنها | `recovery` 80,740,352 B (p40)، `super` 9,126,805,504 B (p46)، `/cache` ext4 rw، `/metadata` ext4 ro، `/persist` rw |
| پنلها | BOE/TXD/INX/JDI: `hx83112f`, `jd9522t`, `nl9922c`, `td4375` |
| تاچ | Himax HX83112، Jadard JD9522T، Chipone، Focaltech |

### کرنل از نگاه Halium

`/proc/config.gz` زنده دستگاه نشان میدهد:

```
CONFIG_DEVTMPFS=y
CONFIG_USER_NS=y
CONFIG_MODULES=y
CONFIG_ASHMEM=y
CONFIG_ANDROID_BINDER_IPC=y
CONFIG_ANDROID_BINDER_DEVICES="binder,hwbinder,vndbinder"
CONFIG_OVERLAY_FS=y
CONFIG_SECURITY_SELINUX=y
```

یعنی نیازی به پچهای قدیمی binder/ashmem نیست؛ کار عمدتاً به تنظیمات و
ساخت کرنل از منبع درست خلاصه میشود. کپی کامل کانفیگ در
[`kernel/config.a14m.stock`](../kernel/config.a14m.stock) است.

## تصمیم ۱: Halium GSI روی vendor استوک، نه Halium standalone قدیمی

دلیل: vendor و modem سامسونگ روی بیلد `A145PXXUEDZJ2` تستشدهاند و جداسازی
آنها در Halium 9/10 کاری پرریسک است. الگوی ما:

```
[stock Android 15 partitions: vendor, modem, firmware, super (دست نخورده)]
        ↑ HAL over hwbinder/vndbinder
[Halium 15 GSI in LXC container]
        ↑
[Ubuntu Touch 24.04 rootfs + libhybris + Lomiri]
        ↑
[boot.img: Halium-patched stock kernel + busybox initramfs + overlay]
```

## تصمیم ۲: GKI 6.6 بومی دستگاه، نه کرنل GKI عمومی UBports

برخلاف تصور اولیه، دستگاه **GKI است** (Linux 6.6، شاخهٔ `android15-6.6`) و
منبع آن هم موجود است:
[`Behrooz140/behi-kernel-sm-a145p`](https://github.com/Behrooz140/behi-kernel-sm-a145p)
@ `fbdd52d` (تگ `v1.6.1`). این کرنل KMI/ورماجیک استوک ۶٫۶٫۱۱۸ را حفظ میکند
تا ۱۹۸ ماژول `.ko` استوک لود شوند و در CI با `scripts/kmi_check.py` هر تغییری
در CRCهای صادرشده را رد میکند.

پس کرنل Halium ما **همین درخت** +fragment تنظیمات Halium است، نه کرنل
`android14-6.1-halium` عمومی UBports (KMI متفاوتی دارد و ماژولهای vendor را
رد میکند). الگوی stone-ut هم همین است: کرنل بومی دستگاه + پچهای Halium.

**چالش اصلی M0:** اضافه کردن گزینههای مورد نیاز Halium بدون شکستن KMI.
هر گزینهای که ساختارهای صادرشده را تغییر دهد توسط نگهبان KMI رد میشود؛ بنابراین
ابتدا فقط `halium.config` حداقلی را امتحان میکنیم و سپس در صورت لزوم پچ هدفمند
روی فراخوانیهای Halium میزنیم.

**ساخت بوت ایمیج:** از الگوی `scripts/build_boot_image.sh` همان ریپازیتوری
استفاده میکنیم: هدر v4، gzip kernel، `SEANDROIDENFORCE`، سپس AVB hash footer
برای پارتیشن ۳۲MiB با کلید تست عمومی AOSP (روی بوتلودر باز پذیرفته میشود).
آفستهای v2 درخت TWRP مربوط به ریکاوریاند و نباید برای بوت UT کپی شوند.

## تصمیم ۳: محل rootfs

دو گزینه:

| گزینه | مزیت | ریسک |
|---|---|---|
| `/userdata/ubuntu.img` loop-mounted (الگوی bluejay) | system/vendor استوک دستنخورده میماند | `/data` FBE Encryption است؛ باید decrypt در بوت عادی کار کند |
| فلش rootfs به پارتیشن `system` داخل `super` (الگوی Halium کلاسیک) | روش سنتی و مستندتر | جایگزینی system استوک، نیاز به fastbootd/lptools |

تصمیم نهایی بعد از اولین بوت عادی و تست decrypt `/data` گرفته میشود.
نکته: محدودیت «TEE در ریکاوری بالا نمیآید» مربوط به بوت **ریکاوری** است؛
در بوت عادی TEE توسط بوتلودر اجرا میشود، پس نباید مانع Halium شود.

## تصمیم ۴: بازگشت به استوک قبل از نصب

GSI اندروید ۱۷ فعلی با vendor اندروید ۱۵ همخوانی ندارد. قبل از هر فلش UT،
باید بیلد `A145PXXUEDZJ2` (همانی که TWRP build 31 را تأیید کرد) روی دستگاه
باشد. نسخهٔ GSI Halium را هم بر اساس همان vendor پین میکنیم.

## تصمیم ۵: ساخت روی هاست، نه روی گوشی

ساخت kernel + rootfs حدود ۲۵ گیگ فضای دیسک و SDK/toolchain میخواهد. از
GitHub Actions استفاده میکنیم که درخت TWRP هم از همان الگو استفاده میکند.
گوشی فقط محل تست و جمعآوری لاگ است.

## تصمیم ۶: کار روی کرنل در برنچ جداگانه

تمام تغییرات کرنل مربوط به UT در
[`bump/ubuntu-touch-halium-6.6`](https://github.com/Behrooz140/behi-kernel-sm-a145p/tree/bump/ubuntu-touch-halium-6.6)
انجام میشود و `main` دستنخورده میماند. دلیل نام `bump/`: CI کرنل فقط روی `main`
و برنچهای `bump/**` اجرا میشود؛ برنچ ما یک **ارتifact تست** میسازد ولی Release
منتشر نمیکند، چون تنها `refs/heads/main` مجوز انتشار دارد. بنابراین میتوانیم
هر بار بوت ایمیج تست را از Actions بگیریم بدون اینکه نسخهٔ پایدار v1.6.1 جابجا
شود.

پایهٔ برنچ، کامیت `fbdd52db35005f47b09cd287af928d1da27975eb` (تگ `v1.6.1`) است.
اولین کامیت پورت `1a3814092` است: فایل
`kernel/kernel_device_modules-6.6/kernel/configs/halium_ut.config` اضافه شد و به
لیست `DEFCONFIG_OVERLAYS` متصل گردید؛ نگهبان KMI و تمام چکهای موجود CI بدون تغییر
اجرا میشوند.

**نکتهٔ مهم:** fragment فعلی فقط گزینههایی را دوباره اعلام میکند که از قبل در
بیلد v1.6.1 فعالاند (از روی `/proc/config.gz` زنده دستگاه تأیید شد). بنابراین
انتظار میرود KMI دقیقاً همان baseline بماند؛ این کامیت «سالم بودن مسیر بیلد»
را تست میکند، نه اضافه کردن قابلیت تازه. هر گزینهٔ جدید Halium (مثل AppArmor)
در کامیت جداگانه و پس از دیدن نتیجهٔ KMI اضافه میشود.

اولین بیلد تست **موفق** بود:  
https://github.com/Behrooz140/behi-kernel-sm-a145p/actions/runs/45077953406

در لاگ آن بیلد هر سه چک مهم عبور کردند:

- `Halium / Ubuntu Touch sanity check` — تمام گزینههای fragment در `.config` نهایی موجوداند؛
- `KMI compatibility gate` — `kmi_check.py verify` در برابر
  `kmi-baseline-v1.6.1.txt` بدون خطا؛
- `Stock vermagic pinned: 6.6.118-android15-8-abA145PXXUEDZJ2-4k SMP preempt mod_unload modversions aarch64`.

هش بوت ایمیج تست (`fee2b398…`) با نسخهٔ پایدار منتشرشده (`d5078f5d…`) یکسان نیست،
چون تاریخ کامپایل داخل رشتهٔ Linux version قرار میگیرد؛ ولی هر دو همان تنظیمات و
همان KMI را دارند. ما نسخهٔ پایدار منتشرشده را پین میکنیم تا قابلتولید مجدد بماند.

## تصمیم ۷: مصرف بوت ایمیج منتشرشدهٔ کرنل، نه ساخت مجدد KMI

`build.sh` کرنل را دوباره کامپایل نمیکند. ورودی آن
`kernel-ut-boot.img` است — همان بوت ایمیج منتشرشدهٔ behi v1.6.1 با SHA256
`d5078f5d…` — که در CI کرنل از چک تنظیمات، `kmi_check.py verify` و چک ورماجیک
استوک عبور کرده است. کاری که این ریپو میکند:

1. هش بوت ایمیج و رشتهٔ ورماجیک استوک را دوباره چک میکند؛
2. پارامترهای دقیق هدر v4 را با `unpack_bootimg.py --format mkbootimg` از آن
   استخراج میکند؛
3. راندیمس Halium را جایگزین و با همان هدر + AVB (کلید تست AOSP) دوباره میبندد.

بدین ترتیب KMI دوباره ساخته نمیشود و تنها یک هش واحد، معیار سالم بودن کرنل
را به این ریپو منتقل میکند.

جزئیات بوت GKI و محل راندیمس هنوز نیاز به تست روی دستگاه دارد
([#4](https://github.com/Behrooz140/ubuntu-touch-a14m/issues/4)).
