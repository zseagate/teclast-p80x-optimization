#!/usr/bin/env bash
# 一键采集 Teclast P80X 设备审计信息（脱敏）
# 用法: ./scripts/audit.sh <SERIAL>
set -euo pipefail

SERIAL="${1:?用法: audit.sh <SERIAL>}"
ADB="adb -s $SERIAL"

echo "===== 设备审计: $SERIAL ====="
echo "--- 硬件/系统 ---"
$ADB shell getprop ro.product.model
$ADB shell getprop ro.product.brand
$ADB shell getprop ro.build.version.release
$ADB shell getprop ro.build.version.sdk
$ADB shell getprop ro.product.cpu.abi
echo "--- 内存 ---"
$ADB shell cat /proc/meminfo | head -2
echo "--- 存储 ---"
$ADB shell df -h /data
echo "--- 屏幕 ---"
$ADB shell wm size
echo "--- SELinux ---"
$ADB shell getenforce
echo "--- 应用(影视类) ---"
$ADB shell pm list packages | grep -iE 'fongmi|tvbox|tivimate|abts' || echo "(无匹配)"
echo "--- WiFi 链路 ---"
$ADB shell dumpsys wifi | grep -iE 'Supplicant state:|Link speed' | head -2
echo "===== 审计完成 ====="
