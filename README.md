# Cudy TR3000 Open F50 112M

Reproducible local and GitHub Actions build based on
[`clfang666/tr3000-open`](https://github.com/clfang666/tr3000-open) and
`padavanonly/immortalwrt-mt798x-6.6`.

This project builds only the old 128MB NAND Cudy TR3000 v1 with the 112MiB
UBootMod layout:

- Target: `cudy_tr3000-v1-ubootmod`
- Compatible: `cudy,tr3000-v1-ubootmod`
- NAND: `F50L1G41LB`
- UBI: start `0x005c0000`, size `0x07000000`

Do not flash it on the 256MB NAND model or the stock 64MiB layout.

## Included

- Original tr3000-open feature set:
  - OpenClash 0.47.071
  - MTK TurboACC/HNAT, WED/WARP, and MTK Wi-Fi configuration
  - wrtbwmon and ttyd
- ZTE F50 support:
  - USB 3.0
  - RNDIS and CDC Ethernet
  - CDC-NCM compatibility mode
  - usbutils
- Embedded ARM64 Mihomo core and OpenClash GeoIP, GeoSite, Country MMDB,
  and ASN MMDB data

Tailscale, Argon, iStore, and AdGuard Home are intentionally not included.

## Local Build

Run in PowerShell:

```powershell
wsl.exe -d CodexUbuntuNoble -- bash /mnt/e/Dev/tr3000-open-f50/scripts/build.sh
```

The source, feeds, Mihomo core, and Geo data are pinned in `versions.lock`.
Verified output is copied to `artifacts/`.

## Device Check

Copy `scripts/device-check.sh` to the router and run it before flashing. It
must confirm `F50L1G41LB`, `cudy,tr3000-v1-ubootmod`, and `0x07000000` UBI.

## Runtime Checks

Set the ZTE F50 to RNDIS mode, confirm a USB network interface appears, and
verify DHCP connectivity. Test throughput both with and without MTK TurboACC.
The acceleration switch alone does not prove that USB traffic entered HNAT.

