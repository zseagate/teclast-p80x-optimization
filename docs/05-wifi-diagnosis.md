# 05 · WiFi 链路诊断

直播流能播，但平板连 `greenzx_2.4G` 的**链路速率在 1↔13Mbps 间波动**（RSSI -46~-67），
导致直播流**时断时续**（画面能出但 0 KB/s 缓冲）。本文记录完整诊断，确认是**物理链路问题**。

## 症状

- FongMi 直播播放中，画面能出但常停；截图对比 6 秒内画面相同、速度 **0 KB/s**。
- 过一会又推进（凤凰资讯 → CCTV-11 → CNN 快速切换），说明流在"能连/连不上"间跳变。

## 诊断记录

### 1. WiFi 链路速率异常低

```text
mWifiInfo SSID: greenzx_2.4G, BSSID: e2:ef:02:72:62:15
  Supplicant state: COMPLETED, RSSI: -67, Link speed: 1Mbps, Frequency: 2412MHz
```

**COMPLETED 但 Link speed 仅 1Mbps**——连接状态正常，物理速率却极低。

### 2. ping 公网正常，但流服务器不可达

```text
# ping baidu: 22.7ms 0% 丢包 —— 网络"通"
PING www.a.shifen.com (180.101.51.73) 56(84) bytes: 2 received, 0% loss

# ping 流服务器: 100% 丢包 —— 但流服务器连不上
PING 43.152.224.209: 2 transmitted, 0 received, 100% packet loss
```

### 3. ExoPlayer 报 EHOSTUNREACH

```text
Caused by: java.net.ConnectException: failed to connect to /43.152.224.209 (port 80)
  from /192.168.10.114 (port 42542) after 30000ms:
  isConnected failed: EHOSTUNREACH (No route to host)
```

### 4. 链路在波动

```text
RSSI -67  Link 1Mbps   →  RSSI -57  Link 1Mbps   →  RSSI -46  Link 13Mbps
RSSI -51  Link 1Mbps   →  RSSI -55  Link 1Mbps   →  RSSI -53  Link 1Mbps
```

RSSI 改善时链路速率可到 **13Mbps**（此时直播能推进），随后又掉回 **1Mbps**。

### 5. Android `NO_INTERNET` 循环

WiFi 曾触发 Android 的 `NO_INTERNET` 判定，导致系统短暂禁用 WiFi 又重连
（`private_dns_mode` 实验也曾触发）。回退 `private_dns_mode=off` 后不再由配置引发，
但仍存在物理层断流。

## 结论

**这是平板 WiFi 物理链路偏弱/不稳定的问题，不是软件配置问题。**

- 平板距 AP 较远或 2.4G 频段干扰大 → 协商速率掉到 1Mbps，直播流（几 Mbps）跟不上。
- 应用层（TVBox / FongMi）配置均正确，直播源本地化也无 DNS 问题。
- 网络"通"（ping 22ms）不代表能承载直播流（需持续几 Mbps）。

## 改善手段（择一即可）

1. **把平板移近路由器/AP**（或让 AP 远离干扰源）。
2. 在平板上**关开一次 WiFi**（设置→WLAN 开关），或**重启平板**。
3. **重启路由器/AP**。

## 记录要点

> 排障时别只看"ping 通不通"。IP 网络层通 ≠ 能承载流媒体。
> 要看 **`Link speed`（协商速率）** 和 **`RSSI`**，这两个才决定直播流能否稳定播放。
