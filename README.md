# Teclast P80X (G5K6) 平板优化记录

> 一台台电 P80X 平板（Android 9 / arm64-v8a / 1.8GB RAM）的完整优化与 IPTV 部署过程：
> 直播 + 点播分软件落地、直播源本地化、FongMi 自带服务器读本地文件、WiFi 链路诊断。
> 全部通过 ADB（USB 调试）完成，不刷机、不 root。

English: A field report for debloating and deploying IPTV (live + VOD) on a low-end
Teclast P80X tablet (Android 9, arm64-v8a, 1.8 GB RAM). Everything is done via ADB
over USB debugging; no firmware flashing, no root.

## 结果

| 项目 | 内容 |
| --- | --- |
| 点播 | **TVBox4.1+**（`com.tvbox.android44`）— 暴风资源（MacCMS，HTTPS 直连源） |
| 直播 | **FongMi 影视 5.9.0**（`com.fongmi.android.tv`）— 本地化直播源（1899 频道 / 47 组） |
| 直播源加载 | FongMi **自带服务器 `/file/` 端点**读 `/sdcard/Download/` 本地文件，无需外部回环服务 |
| 附加应用 | 阿B听书 v1.2.2（B 站有声小说播放器） |
| 网络 | WiFi 链路不稳定（1↔13Mbps 波动），已诊断定位为物理链路问题，非配置问题 |
| 系统状态 | 无 root、SELinux Enforcing、未改动 `/system`（全程可逆） |

## 设备

| 项目 | 值 |
| --- | --- |
| 型号 | Teclast P80X（G5K6） |
| 系统 | Android 9（SDK 28），SELinux Enforcing，无 root |
| CPU / 架构 | arm64-v8a |
| 内存 | 1.8 GB（MemTotal 1863464 kB） |
| 存储 | `/data` 25 GB（已用 11 GB，剩 14 GB） |
| 屏幕 | 800×1280 物理分辨率 |
| 预装 | 无 GMS，toybox 0.7.6，ADB 经 USB 调试 |

> 仓库不含设备序列号、MAC、账号或任何个人可识别信息。ADB 设备序列号不写入。

## 方案总览

用户明确要求**分工**：点播和直播由不同软件承担，避免单个软件功能过载。

```
┌─────────────────────────────────────────────────────────┐
│  平板 (Teclast P80X, Android 9)                          │
│                                                         │
│   TVBox4.1+  ── 点播 ── 暴风资源 (MacCMS)                 │
│   FongMi 5.9.0 ── 直播 ── /sdcard/Download/live.txt       │
│                              ▲                           │
│                              │ file://                   │
│              FongMi 自带服务器 /file/ (127.0.0.1:9978)    │
│                                                         │
│   直播源文件 (live.txt / live.m3u) 持久于 /sdcard/Download │
└─────────────────────────────────────────────────────────┘
```

## 关键决策与发现

### 1. 直播 + 点播分软件，不混用

低端设备上单个"全能"软件（点播+直播+爬虫）常因功能过载而卡顿。按用户决策：

- **点播** → TVBox4.1+（`com.tvbox.android44`），内置较新 SSL，HTTPS 源（暴风资源）可用。
- **直播** → FongMi 影视 5.9.0（`com.fongmi.android.tv`），单 App 直播，播放稳定。

### 2. 直播源本地化，绕开 DNS 污染

直播源清单从 TiviMate 播放列表（`merged.m3u`，1899 频道 / 47 组）转换而来，
推送到 `/sdcard/Download/`（`live.txt` TVBox 格式 + `live.m3u` 标准 M3U 格式）。
本地文件加载不受公网 DNS 污染影响，无需每次联网拉取。

### 3. 用 FongMi 自带服务器读本地文件（最关键）

FongMi 的配置地址**不认 `clan://`**，最初用外部回环 HTTP 服务
（`toybox nc -L` 监听 `127.0.0.1:8099`）来服务直播源——但该服务**平板重启后失效**，
需手动重起，不持久。

排查 FongMi 源码（`UrlUtil.convert` / `Local.java` / `Path.local`）发现：
**FongMi 自带 NanoHTTPD 服务器（端口从 9978 起）有 `/file/` 端点**，
能把 `file://` 配置地址转成本地 HTTP 服务。

```java
// UrlUtil.convert: "file:///sdcard/Download/live.txt"
//   -> "http://127.0.0.1:9978/file//sdcard/Download/live.txt"
case "file" -> Server.get().getAddress("/file/") + Uri.encode(...);
```

因此直播配置地址设为：

```
file:///sdcard/Download/live.txt
```

- FongMi 启动即自动开服务器（9978），`/file/` 端点可服务 `/sdcard/` 下任意文件。
- **重启后无需任何手动步骤**——服务器随 App 启动，文件持久于 `/sdcard/Download/`。
- 验证：`GET http://127.0.0.1:9978/file//sdcard/Download/live.txt` → **HTTP 200**（165701 字节）。

**结论：彻底摆脱外部 `toybox nc` 回环服务，重启不再失效。**

### 4. 点播源（暴风资源）走 HTTPS 直连

- 暴风资源 MacCMS 接口：`https://bfzyapi.com/api.php/provide/vod/`。
- 平板 DNS 曾不稳定（GFW 污染），后解析到 `174.37.175.229`，HTTPS 返回真实 JSON。
- TVBox4.1+ 内置 DNS over HTTPS 选项（腾讯 doh.pub / 阿里 / 360）可绕开污染，作为后备。
- 扫码接口（端口 9979，token 5 分钟有效）POST 添加源，实测分类/详情/播放全链路成功。

### 5. WiFi 链路不稳定是物理问题，非配置问题

直播流能播放，但 `greenzx_2.4G` 链路速率在 **1↔13Mbps** 波动（RSSI -46~-67），
导致直播流时断时续（画面能出但 0 KB/s 缓冲）。诊断确认：

- `Supplicant state: COMPLETED` 但 Link speed 仅 1Mbps，`ping baidu` 却 22ms 正常。
- 断网时 `ping 43.152.224.209`（流服务器）报 `EHOSTUNREACH`。
- 曾触发 Android 的 `NO_INTERNET` 循环（WiFi 被判无效又重连）。

结论：**平板距 AP 较远 / 2.4G 干扰**，非软件配置问题。改善手段：移近路由器、关开 WiFi、重启 AP。

## 完整部署步骤

见 [`docs/`](docs) 各分册：

- [`docs/01-device-audit.md`](docs/01-device-audit.md) — 设备审计（硬件/系统/预装）
- [`docs/02-live-source-localization.md`](docs/02-live-source-localization.md) — 直播源本地化（转 M3U/TXT、推送、持久）
- [`docs/03-vod-tvbox.md`](docs/03-vod-tvbox.md) — 点播部署（TVBox4.1+ / 暴风资源 / 扫码接口）
- [`docs/04-live-fongmi-file.md`](docs/04-live-fongmi-file.md) — 直播部署（FongMi + `/file/` 本地文件，**重启持久**）
- [`docs/05-wifi-diagnosis.md`](docs/05-wifi-diagnosis.md) — WiFi 链路诊断（1↔13Mbps 波动 / NO_INTERNET 循环）
- [`docs/06-changes-and-recovery.md`](docs/06-changes-and-recovery.md) — 变更清单与可逆恢复

## 脚本

| 脚本 | 作用 |
| --- | --- |
| [`scripts/audit.sh`](scripts/audit.sh) | 一键采集设备审计信息（硬件/系统/包/网络，脱敏） |
| [`scripts/push_live_sources.ps1`](scripts/push_live_sources.ps1) | 将直播源推送到 `/sdcard/Download/` 并验证 `/file/` 端点 |
| [`scripts/txt2m3u.ps1`](scripts/txt2m3u.ps1) | TVBox 直播 txt → 标准 M3U 转换 |
| [`scripts/verify_file_endpoint.ps1`](scripts/verify_file_endpoint.ps1) | 验证 FongMi `/file/` 端点可服务本地直播源 |

## 配套项目

- 直播源清单（`merged.m3u` 1899 频道，含第三方流地址）单独维护在
  [`zseagate/iptv-tivimate`](https://github.com/zseagate/iptv-tivimate)，**不公开**。
- 方法论来源：[`zseagate/iptv-tvbox-lowend-android`](https://github.com/zseagate/iptv-tvbox-lowend-android)
  （低端 Android 盒子 IPTV 方案）。
- 本仓库只记录**平板部署与优化过程**（可复现步骤、诊断、脚本），不含直播源清单内容。

## 快速使用

```powershell
# 1. 确认设备
adb devices
adb -s <SERIAL> shell getprop ro.product.model   # 应为 P80X(G5K6)

# 2. 采集审计
.\scripts\audit.sh <SERIAL>

# 3. 推送直播源（源文件来自配套仓库，本地转换后推送）
.\scripts\txt2m3u.ps1 -InFile live.txt -OutFile live.m3u
.\scripts\push_live_sources.ps1 <SERIAL>

# 4. 验证 FongMi /file/ 端点
.\scripts\verify_file_endpoint.ps1 <SERIAL>
```

## 免责声明

- 本项目仅记录在一台**自有设备**上的操作，不提供固件、不包含任何厂商或第三方 APK。
- 改动全部通过 `pm` / ADB 完成，未修改 `/system`，未刷机，未 root；停用系统包可通过
  `pm enable` 一键还原（见 [`docs/06-changes-and-recovery.md`](docs/06-changes-and-recovery.md)）。
- 文中第三方应用（TVBox4.1+、FongMi、阿B听书）名称仅用于说明部署，不构成推荐或分发。
- 直播/点播源内容来自第三方公开接口，其合法性与版权与本文档无关，请遵守当地法规。

## License

[MIT](LICENSE)，见 [LICENSE](LICENSE)。截图中的第三方应用图标归各自所有者。

---

## 📖 完整图文教程

这个仓库放的是技术实现本身。想看**图文并茂的完整折腾记录**（踩坑过程、效果截图、WiFi 诊断实录），
请关注公众号 **绿启未来工坊**——每个项目的完整记录都在那里。

- 🌐 网站：[www.greenzx.com](https://www.greenzx.com) — 微型技术服务：小团队系统故障排查 / 轻量化网站搭建 / AI 提效落地
- 💻 全部项目：[github.com/zseagate](https://github.com/zseagate)
- ✉️ 联系：**138-3420-2583（微信同号）** · zseagate@qq.com

> 一个人做的硬核交付：代码开源、过程留痕、踩坑记录全公开。
