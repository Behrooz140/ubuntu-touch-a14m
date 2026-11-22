# منابع باینریها و مجوزها

هر فایلی که وارد ایمیج میشود باید در اینجا با منبع، commit/نسخه و SHA256 ثبت
شود. مقادیر `TBD` باید قبل از اولین Release پر شوند.

| مؤلفه | منبع | نسخه / commit | SHA256 | مجوز |
|---|---|---|---|---|
| prebuilt kernel (ریکاوری استوک) | [`android_device_samsung_a14m/prebuilt/kernel`](https://github.com/Behrooz140/android_device_samsung_a14m) | `eb19a1d` / `6.6.118` | `e4443063921c342441c04cb5ae4ee4ea` (MD5) | GPL-2.0 |
| DTB استوک | همان ریپازیتوری | `eb19a1d` | `ab5bacb2fe7589c25026e21ab718e5ef` (MD5) | استوک سامسونگ |
| DTBO استوک | همان ریپازیتوری | `eb19a1d` | `08eba6a650cffcad2e8209398b135364` (MD5) | استوک سامسونگ |
| ماژولهای `.ko` (۱۹۸ عدد) | همان ریپازیتوری | `eb19a1d` | TBD | GPL-2.0 |
| فریمور تاچ Himax | همان ریپازیتوری | `eb19a1d` | TBD | استوک سامسونگ |
| منبع کرنل ۶٫۶٫۱۴۴ (GKI + نگهبان KMI) | [`Behrooz140/behi-kernel-sm-a145p`](https://github.com/Behrooz140/behi-kernel-sm-a145p) | `fbdd52d` / tag `v1.6.1`؛ برنچ UT `1a3814092` | `d5078f5d8a5bf9f73ba1ef8d3cec7cf5181a39c79432b9e0f663c0d220b62458` (بوت ایمیج منتشرشده) | GPL-2.0 |
| بوت ایمیج کرنل ۶٫۶٫۱۴۴ | [Release v1.6.1](https://github.com/Behrooz140/behi-kernel-sm-a145p/releases/tag/v1.6.1) | `A145P-Kernel-v1.6.1-boot.img` | `d5078f5d8a5bf9f73ba1ef8d3cec7cf5181a39c79432b9e0f663c0d220b62458` | GPL-2.0 |
| اسکریپت بوت ایمیج v4 + AVB | همان ریپازیتوری `scripts/build_boot_image.sh` | `fbdd52d` | `23dd139102a3596a7cb1c8a93103b5743def9fe294986ba6a0b0432e4160439b` | GPL-2.0 |
| نگهبان KMI | همان ریپازیتوری `scripts/kmi_check.py` | `fbdd52d` | `76c58d9318a64fd97f4efcc91bb0267ee8a17f3f1a271d15c56541e68b9f1d58` | GPL-2.0 |
| baseline CRC صادرشدهها | همان ریپازیتوری `configs/kmi-baseline-v1.6.1.txt` | `fbdd52d` | `e657f8f51a5d5c7eb29f00f9ed543315799375f536dce8722fd0c0e88301a6fe` | GPL-2.0 |
| ابزار AOSP mkbootimg | `android.googlesource.com/platform/system/tools/mkbootimg` | `d2bb0af5ba6d3198a3e99529c97eda1be0b5a093` | در CI هنگام بیلد بررسی میشود | Apache-2.0 |
| ابزار AOSP avbtool | `android.googlesource.com/platform/external/avb` | `3328b7b60ae384e1a92f44d7e6f3ac021c2b05be` | در CI هنگام بیلد بررسی میشود | Apache-2.0 |
| منبع کرنل Android 13 (مرجع تاریخی) | [`forforksake/android_kernel_samsung_a145p`](https://github.com/forforksake/android_kernel_samsung_a145p) | `A145PXXU2AWG1` | TBD | GPL-2.0 |
| rootfs Ubuntu Touch 24.04-x | UBports CI | TBD | TBD | GPL-3.0 / متفرقه |
| Halium GSI arm64 | UBports CI | TBD | TBD | GPL / Apache |
| UBports recovery ramdisk | UBports CI | TBD | TBD | GPL |
| busybox-static | Alpine Linux | 1.37.0 | TBD | GPL-2.0 |

## نکات

- UBports CI بیلدهای قدیمی را پاک میکند؛ بنابراین بعد از پین کردن، باینریها
  در Release همین ریپازیتوری آینه میشوند و `inputs.sha256` به آنها اشاره میکند.
- MD5های بالا از مستندات TWRP نقل شدهاند؛ برای Releaseها حتماً SHA256 هم
  محاسبه شود.
- هیچ باینری استوک سامسونگ بدون مستند مجوزش در Release قرار نگیرد.
