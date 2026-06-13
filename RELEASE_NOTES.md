# Cudy TR3000 Open F50 112M v2026.06.13-r1

This release targets only the old 128MB NAND Cudy TR3000 v1 with the
`cudy_tr3000-v1-ubootmod` 112MiB UBI layout.

## Included

- ImmortalWrt MT798x 6.6 source locked at `899cb039`
- OpenClash 0.47.071
- Embedded Mihomo v1.19.27 and Geo databases
- ZTE F50 USB 3.0 RNDIS and CDC-NCM drivers
- MTK TurboACC/HNAT and WED/WARP
- MTK Wi-Fi configuration, wrtbwmon, and ttyd

## Verified Build

- Kernel: `6.6.133`
- Image size: `46,705,477` bytes
- Release image SHA256:
  `50fc7debe97003546e1c4b61f82f18d684b1a1ceceb9a9c096aeeaeca0fe310f`
- GitHub Actions build and static verification: passed

## Flash Safety

Do not flash unless `scripts/device-check.sh` confirms:

- NAND `F50L1G41LB`
- Compatible `cudy,tr3000-v1-ubootmod`
- UBI size `0x07000000`

Image size and SHA256 are recorded in the attached verification files.
