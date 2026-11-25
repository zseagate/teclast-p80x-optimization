# 01 · 设备审计

对台电 P80X (G5K6) 的完整审计，确认硬件、系统、预装应用与网络基线。

## 硬件与系统

| 项目 | 值 |
| --- | --- |
| 型号 | `P80X(G5K6)`，品牌 `Teclast` |
| Android | 9（SDK 28） |
| CPU 架构 | `arm64-v8a` |
| 内存 | MemTotal 1863464 kB（约 1.8 GB），空闲 ~110 MB |
| 存储 | `/data` 25 GB，已用 11 GB，剩 14 GB（44%） |
| 屏幕 | 物理 800×1280 |
| root | 无（`su` 不存在） |
| SELinux | Enforcing |
| toybox | 0.7.6 |
| GMS | 无 |

## 关键观察

- **无 GMS、无 root、SELinux Enforcing**：无法写 `/system`，无法用 root 停用系统服务；
  只能走 `pm`（`pm disable-user` / `pm enable`）与应用级手段，且全程可逆。
- **内存仅 1.8 GB**：不宜同时跑多个重型影视应用，故采用**分软件**方案（点播/直播分开）。
- **arm64-v8a**：选 APK 必须匹配（TVBox4.1+ / FongMi mobile-arm64_v8a / 阿B听书 arm64-v8a）。

## 预装相关应用（审计时）

| 包名 | 说明 |
| --- | --- |
| — | 无 TVBox / FongMi 预装 |
| — | 无 GMS 生态 |

## 网络基线

| 项目 | 值 |
| --- | --- |
| WiFi SSID | `greenzx_2.4G` |
| 平板 IP | `192.168.10.114` |
| DNS | 正常（`bfzyapi.com` → 174.37.175.229，`baidu` 22ms） |
| WiFi 状态 | `Supplicant state: COMPLETED`，但 **Link speed 1Mbps**（见 `05-wifi-diagnosis.md`） |

## 审计命令

```powershell
adb -s <SERIAL> shell getprop ro.product.model
adb -s <SERIAL> shell getprop ro.product.cpu.abi
adb -s <SERIAL> shell cat /proc/meminfo
adb -s <SERIAL> shell df -h /data
adb -s <SERIAL> shell wm size
adb -s <SERIAL> shell getenforce
adb -s <SERIAL> shell pm list packages
```

自动化脚本见 [`scripts/audit.sh`](../scripts/audit.sh)。
