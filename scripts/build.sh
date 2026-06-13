#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="${PROJECT_DIR:-/mnt/e/Dev/tr3000-open-f50}"
BUILD_ROOT="${BUILD_ROOT:-/root/tr3000-open-f50-build}"
SOURCE_DIR="$BUILD_ROOT/immortalwrt-mt798x"
RULES_DIR="$BUILD_ROOT/meta-rules-dat"
LOCK_FILE="$PROJECT_DIR/versions.lock"
ARTIFACT_DIR="$PROJECT_DIR/artifacts"
LOG_DIR="$PROJECT_DIR/logs"

source "$LOCK_FILE"
mkdir -p "$BUILD_ROOT/downloads" "$ARTIFACT_DIR" "$LOG_DIR"
exec > >(tee "$LOG_DIR/build-$(date +%Y%m%d-%H%M%S).log") 2>&1

export DEBIAN_FRONTEND=noninteractive
export FORCE_UNSAFE_CONFIGURE=1
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

apt-get -o DPkg::Lock::Timeout=300 update
apt-get -o DPkg::Lock::Timeout=300 install -y \
  build-essential clang flex bison g++ gawk gcc-multilib g++-multilib gettext git \
  libncurses-dev libssl-dev python3 python3-dev python3-setuptools \
  python3-pyelftools python3-docutils rsync swig unzip zlib1g-dev file wget \
  curl jq ca-certificates libelf-dev ecj fastjar java-propose-classpath \
  subversion time xsltproc device-tree-compiler u-boot-tools

clone_locked() {
  local repo="$1" dest="$2" commit="$3" branch="${4:-}"
  if [ ! -d "$dest/.git" ]; then
    if [ -n "$branch" ]; then
      git clone --branch "$branch" "$repo" "$dest"
    else
      git clone "$repo" "$dest"
    fi
  fi
  if [ -n "$branch" ]; then
    git -C "$dest" fetch origin "$branch" --tags
  else
    git -C "$dest" fetch origin --tags
  fi
  git -C "$dest" checkout --detach "$commit"
  git -C "$dest" reset --hard "$commit"
  git -C "$dest" clean -fdx
}

clone_locked "$SOURCE_REPO" "$SOURCE_DIR" "$SOURCE_COMMIT" "$SOURCE_BRANCH"
clone_locked "$META_RULES_REPO" "$RULES_DIR" "$META_RULES_RELEASE_COMMIT" release

cd "$SOURCE_DIR"
ln -sfn "$BUILD_ROOT/downloads" dl
rm -rf feeds package/feeds
grep -q 'src-git helloworld ' feeds.conf.default ||
  echo 'src-git helloworld https://github.com/fw876/helloworld.git' >> feeds.conf.default
./scripts/feeds update -a

for spec in \
  "packages:$PACKAGES_COMMIT" \
  "luci:$LUCI_COMMIT" \
  "routing:$ROUTING_COMMIT" \
  "telephony:$TELEPHONY_COMMIT" \
  "helloworld:$HELLOWORLD_COMMIT"
do
  feed="${spec%%:*}"
  commit="${spec#*:}"
  git -C "feeds/$feed" fetch origin "$commit"
  git -C "feeds/$feed" checkout --detach "$commit"
done

./scripts/feeds install -a

# Preserve the source project's workaround for Rust builds.
sed -i 's/$(TARGET_CONFIGURE_ARGS)/--set llvm.download-ci-llvm=false \\\n\t$(TARGET_CONFIGURE_ARGS)/' \
  feeds/packages/lang/rust/Makefile

rm -rf files
mkdir -p files/etc/openclash/core

core_gz="$BUILD_ROOT/downloads/$(basename "$MIHOMO_URL")"
if [ ! -f "$core_gz" ]; then
  curl -fL --retry 5 --retry-delay 5 "$MIHOMO_URL" -o "$core_gz"
fi
echo "$MIHOMO_GZ_SHA256  $core_gz" | sha256sum -c -
gzip -dc "$core_gz" > files/etc/openclash/core/clash_meta
echo "$MIHOMO_BIN_SHA256  files/etc/openclash/core/clash_meta" | sha256sum -c -
chmod 0755 files/etc/openclash/core/clash_meta

cp -f "$RULES_DIR/geoip.dat" files/etc/openclash/GeoIP.dat
cp -f "$RULES_DIR/geosite.dat" files/etc/openclash/GeoSite.dat
cp -f "$RULES_DIR/country.mmdb" files/etc/openclash/Country.mmdb
cp -f "$RULES_DIR/GeoLite2-ASN.mmdb" files/etc/openclash/ASN.mmdb
echo "$GEOIP_SHA256  files/etc/openclash/GeoIP.dat" | sha256sum -c -
echo "$GEOSITE_SHA256  files/etc/openclash/GeoSite.dat" | sha256sum -c -
echo "$COUNTRY_MMDB_SHA256  files/etc/openclash/Country.mmdb" | sha256sum -c -
echo "$ASN_MMDB_SHA256  files/etc/openclash/ASN.mmdb" | sha256sum -c -

cp "$PROJECT_DIR/configs/upstream-TR3000V1_MOD.config" .config
while IFS= read -r option; do
  case "$option" in
    CONFIG_PACKAGE_*=y)
      key="${option%%=*}"
      sed -i \
        -e "s/^# ${key} is not set$/${option}/" \
        -e "s/^${key}=.*/${option}/" \
        .config
      grep -qxF "$option" .config || echo "$option" >> .config
      ;;
  esac
done < "$PROJECT_DIR/configs/f50-packages.diffconfig"
make defconfig
./scripts/diffconfig.sh | tee "$ARTIFACT_DIR/effective.diffconfig"

bash "$PROJECT_DIR/scripts/verify.sh" --prebuild "$SOURCE_DIR" "$ARTIFACT_DIR"
make download -j8
find dl -size -1024c -delete
make -j"$(nproc)" || make -j1 V=s

bash "$PROJECT_DIR/scripts/verify.sh" "$SOURCE_DIR" "$ARTIFACT_DIR"
