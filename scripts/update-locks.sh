#!/usr/bin/env bash

set -euo pipefail

cat <<EOF
Review these refs and update versions.lock intentionally:
SOURCE_COMMIT=$(git ls-remote https://github.com/padavanonly/immortalwrt-mt798x-6.6.git refs/heads/openwrt-24.10-6.6 | awk '{print $1}')
PACKAGES_COMMIT=$(git ls-remote https://github.com/immortalwrt/packages.git refs/heads/openwrt-24.10 | awk '{print $1}')
LUCI_COMMIT=$(git ls-remote https://github.com/immortalwrt/luci.git refs/heads/openwrt-24.10 | awk '{print $1}')
ROUTING_COMMIT=$(git ls-remote https://github.com/openwrt/routing.git refs/heads/openwrt-24.10 | awk '{print $1}')
TELEPHONY_COMMIT=$(git ls-remote https://github.com/openwrt/telephony.git refs/heads/openwrt-24.10 | awk '{print $1}')
HELLOWORLD_COMMIT=$(git ls-remote https://github.com/fw876/helloworld.git refs/heads/master | awk '{print $1}')
META_RULES_GENERATION_COMMIT=$(git ls-remote https://github.com/MetaCubeX/meta-rules-dat.git refs/heads/meta | awk '{print $1}')
META_RULES_RELEASE_COMMIT=$(git ls-remote https://github.com/MetaCubeX/meta-rules-dat.git refs/heads/release | awk '{print $1}')
EOF

