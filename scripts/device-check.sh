#!/bin/sh

set -u

echo "== Cudy TR3000 v1 128MB / 112M UBootMod pre-flash check =="
failures=0
compatible="$(tr '\0' '\n' </proc/device-tree/compatible 2>/dev/null)"
echo "$compatible"
dmesg | grep -Ei 'spi.?nand|nand|F50L1G41L[BC]' | tail -30
cat /proc/mtd

case "$compatible" in
  *cudy,tr3000-v1-ubootmod*) echo "PASS: compatible is the 112M UBootMod target" ;;
  *) echo "FAIL: compatible does not contain cudy,tr3000-v1-ubootmod"; failures=$((failures + 1)) ;;
esac

if dmesg | grep -q 'F50L1G41LB'; then
  echo "PASS: old F50L1G41LB NAND detected"
else
  echo "FAIL: F50L1G41LB NAND not confirmed"
  failures=$((failures + 1))
fi

ubi_hex="$(awk -F'[: ]+' '$4=="\"ubi\"" {print $3}' /proc/mtd | head -1)"
case "$ubi_hex" in
  07000000) echo "PASS: UBI partition is 0x07000000" ;;
  *) echo "FAIL: UBI partition is ${ubi_hex:-unknown}, expected 07000000"; failures=$((failures + 1)) ;;
esac

if [ "$failures" -ne 0 ]; then
  echo "BLOCKED: $failures required hardware/layout check(s) failed."
  exit 1
fi

echo "PASS: hardware identity and 112M layout confirmed."

