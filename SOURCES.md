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
| منبع کرنل ۶٫۶٫۱۴۴ (GKI + نگهبان KMI) | [`Behrooz140/behi-kernel-sm-a145p`](https://github.com/Behrooz140/behi-kernel-sm-a145p) | `fbdd52d` / tag `v1.6.1` | TBD | GPL-2.0 |
| اسکریپت بوت ایمیج v4 + AVB | همان ریپازیتوری `scripts/build_boot_image.sh` | `fbdd52d` | TBD | GPL-2.0 |
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
