# 06 · 变更清单与可逆恢复

本方案**零系统改动**（未改 `/system`、未刷机、未 root），所有变更都在应用层，
均可一键还原。列出全部变更与恢复方法。

## 变更清单

| # | 变更 | 位置 | 持久 | 可逆 |
| --- | --- | --- | --- | --- |
| 1 | 安装 TVBox4.1+（点播） | `/data/app/com.tvbox.android44` | ✅ | `pm uninstall` |
| 2 | 安装 FongMi 5.9.0（直播） | `/data/app/com.fongmi.android.tv` | ✅ | `pm uninstall` |
| 3 | 安装阿B听书 v1.2.2 | `/data/app/dev.pages.abts` | ✅ | `pm uninstall` |
| 4 | 推送直播源 live.txt / live.m3u | `/sdcard/Download/` | ✅ | `rm` |
| 5 | FongMi 直播配置地址 | `file:///sdcard/Download/live.txt` | ✅（应用内持久） | 设置页改回 |
| 6 | TVBox 点播源（暴风资源） | 应用内（扫码接口） | ✅（应用内持久） | 设置页删除 |
| 7 | 旧回环 HTTP 服务（已弃用） | `toybox nc` 127.0.0.1:8099 | ❌（重启失效） | 已不再需要 |

## 与 unt413a 盒子方案的区别

本平板**没有做**这些（盒子方案做过，此处不适用）：

- 未替换 `/system` 脚本（平板无 root、SELinux Enforcing，不碰系统分区）。
- 未用 `pm disable-user` 停用预装（本平板预装少，无推广/遥测负担，无需停用）。
- 未装第三方 launcher（平板自带桌面可用，非 leanback 设备）。

## 恢复方法

### 卸载应用

```powershell
adb -s <SERIAL> uninstall com.tvbox.android44
adb -s <SERIAL> uninstall com.fongmi.android.tv
adb -s <SERIAL> uninstall dev.pages.abts
```

### 删除直播源文件

```powershell
adb -s <SERIAL> shell rm /sdcard/Download/live.txt /sdcard/Download/live.m3u
```

### 还原 FongMi 直播配置

在 FongMi 设置页将直播配置地址改回原值或清空。

## 为什么这样最稳

- **不 root、不刷机**：保留保修、不触发系统完整性校验，设备随时可正常用。
- **应用层可逆**：卸载即还原，无残留。
- **配置持久于应用内**（Room/Hawk）：重启后点播源、直播配置地址都保留。
- **直播源文件持久于 `/sdcard/Download/`**：重启后 FongMi 自带服务器照样能读。

> 唯一"不持久"的是旧回环 HTTP 服务，但它已被 `/file/` 方案替代，不再需要。
