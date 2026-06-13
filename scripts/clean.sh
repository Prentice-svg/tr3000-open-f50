#!/usr/bin/env bash

set -euo pipefail

BUILD_ROOT="${BUILD_ROOT:-/root/tr3000-open-f50-build}"
test "$BUILD_ROOT" = "/root/tr3000-open-f50-build"
rm -rf "$BUILD_ROOT"

