#!/usr/bin/env bash

set -euo pipefail

mode="${1:-}"
if [ "$mode" = "--prebuild" ]; then
  SOURCE_DIR="$2"
  OUT_DIR="$3"
else
  SOURCE_DIR="${1:-/root/tr3000-open-f50-build/immortalwrt-mt798x}"
  OUT_DIR="${2:-/mnt/e/Dev/tr3000-open-f50/artifacts}"
fi

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$PROJECT_DIR/versions.lock"
CONFIG="$SOURCE_DIR/.config"
DTS="$SOURCE_DIR/target/linux/mediatek/dts/mt7981b-cudy-tr3000-v1-ubootmod.dts"
BIN_DIR="$SOURCE_DIR/bin/targets/mediatek/filogic"

test -f "$DTS"
grep -q 'compatible = "cudy,tr3000-v1-ubootmod", "mediatek,mt7981";' "$DTS"
grep -Eq 'reg = <0x0*5c0000 0x0*7000000>;' "$DTS"
grep -q '^CONFIG_TARGET_mediatek_filogic_DEVICE_cudy_tr3000-v1-ubootmod=y' "$CONFIG"
! grep -q '^CONFIG_TARGET_mediatek_filogic_DEVICE_cudy_tr3000-v1-256mb=y' "$CONFIG"

for option in \
  CONFIG_PACKAGE_luci-app-openclash \
  CONFIG_PACKAGE_luci-app-turboacc-mtk \
  CONFIG_PACKAGE_luci-app-mtwifi-cfg \
  CONFIG_PACKAGE_luci-app-wrtbwmon \
  CONFIG_PACKAGE_luci-app-ttyd \
  CONFIG_PACKAGE_kmod-mediatek_hnat \
  CONFIG_PACKAGE_kmod-warp \
  CONFIG_PACKAGE_kmod-nft-offload \
  CONFIG_PACKAGE_kmod-usb3 \
  CONFIG_PACKAGE_kmod-usb-net \
  CONFIG_PACKAGE_kmod-usb-net-cdc-ether \
  CONFIG_PACKAGE_kmod-usb-net-rndis \
  CONFIG_PACKAGE_kmod-usb-net-cdc-ncm \
  CONFIG_PACKAGE_usbutils
do
  grep -q "^$option=y" "$CONFIG"
done

if [ "$mode" = "--prebuild" ]; then
  echo "Prebuild verification passed: TR3000 112M UBootMod with F50 packages."
  exit 0
fi

IMAGE="$(find "$BIN_DIR" -maxdepth 1 -type f -name '*cudy_tr3000-v1-ubootmod*squashfs-sysupgrade.bin' | head -1)"
MANIFEST="$(find "$BIN_DIR" -maxdepth 1 -type f -name '*cudy_tr3000-v1-ubootmod.manifest' | head -1)"
ROOTFS="$(find "$SOURCE_DIR/build_dir" -type d -name root-mediatek | head -1)"
KERNEL_CONFIG="$(find "$SOURCE_DIR/build_dir" -path '*/linux-mediatek_filogic/linux-*/.config' | head -1)"

test -s "$IMAGE"
test -s "$MANIFEST"
test -d "$ROOTFS"
test -s "$KERNEL_CONFIG"

size="$(stat -c %s "$IMAGE")"
limit=$((112 * 1024 * 1024))
test "$size" -lt "$limit"
grep -q '"cudy,tr3000-v1-ubootmod"' "$BIN_DIR/profiles.json"
! grep -q '"cudy,tr3000-v1-256mb"' "$BIN_DIR/profiles.json"

for pkg in \
  luci-app-openclash luci-app-turboacc-mtk luci-app-mtwifi-cfg \
  luci-app-wrtbwmon luci-app-ttyd kmod-mediatek_hnat kmod-warp \
  kmod-nft-offload kmod-usb3 kmod-usb-net kmod-usb-net-cdc-ether \
  kmod-usb-net-rndis kmod-usb-net-cdc-ncm usbutils
do
  grep -q "^$pkg " "$MANIFEST"
done

grep -q "^luci-app-openclash - $OPENCLASH_VERSION" "$MANIFEST"
test -x "$ROOTFS/etc/openclash/core/clash_meta"
test -s "$ROOTFS/etc/openclash/GeoIP.dat"
test -s "$ROOTFS/etc/openclash/GeoSite.dat"
test -s "$ROOTFS/etc/openclash/Country.mmdb"
test -s "$ROOTFS/etc/openclash/ASN.mmdb"
echo "$MIHOMO_BIN_SHA256  $ROOTFS/etc/openclash/core/clash_meta" | sha256sum -c -
echo "$GEOIP_SHA256  $ROOTFS/etc/openclash/GeoIP.dat" | sha256sum -c -
echo "$GEOSITE_SHA256  $ROOTFS/etc/openclash/GeoSite.dat" | sha256sum -c -
echo "$COUNTRY_MMDB_SHA256  $ROOTFS/etc/openclash/Country.mmdb" | sha256sum -c -
echo "$ASN_MMDB_SHA256  $ROOTFS/etc/openclash/ASN.mmdb" | sha256sum -c -
grep -q '^CONFIG_NET_MEDIATEK_SOC=y' "$KERNEL_CONFIG"

mkdir -p "$OUT_DIR"
rm -f "$OUT_DIR"/*
cp -f "$IMAGE" "$MANIFEST" "$BIN_DIR/profiles.json" "$BIN_DIR/sha256sums" "$OUT_DIR/"
cp -f "$PROJECT_DIR/versions.lock" "$OUT_DIR/versions.lock"
(cd "$SOURCE_DIR" && ./scripts/diffconfig.sh) > "$OUT_DIR/effective.diffconfig"

{
  cat "$PROJECT_DIR/versions.lock"
  echo "KERNEL_VERSION=6.6$(sed -n 's/^LINUX_VERSION-6.6 = //p' "$SOURCE_DIR/include/kernel-6.6")"
  echo "BUILD_DATE=$(date -u +%FT%TZ)"
} > "$OUT_DIR/build-versions.txt"

cat > "$OUT_DIR/verification.txt" <<EOF
profile=cudy_tr3000-v1-ubootmod
supported_device=cudy,tr3000-v1-ubootmod
ubi_start=0x005c0000
ubi_size=0x07000000
image_size_bytes=$size
image_limit_bytes=$limit
openclash_version=$OPENCLASH_VERSION
embedded_mihomo_version=$MIHOMO_VERSION
embedded_geo_data=present
f50_rndis=present
f50_cdc_ncm=present
usb3=present
mtk_hnat=present
mtk_wed_warp=present
mtk_turboacc=present
forbidden_256mb_target=absent
EOF

(
  cd "$OUT_DIR"
  sha256sum "$(basename "$IMAGE")" > RELEASE_SHA256SUMS
  sha256sum * > SHA256SUMS
)

echo "Verified: $IMAGE ($size bytes)"
