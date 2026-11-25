# 02 · 直播源本地化

把直播源清单从 TiviMate 播放列表转换、去重、探测后本地化，推送到平板 `/sdcard/Download/`，
绕开公网 DNS 污染，实现稳定加载。

## 来源与规模

- 来源：TiviMate 播放列表 `merged.m3u`（来自配套仓库 `zseagate/iptv-tivimate`）。
- 规模：**1899 频道 / 47 组**（央视频道、卫视频道、港澳台、新闻、电影、体育、少儿、综艺…）。
- 处理：按 URL + 频道名去重、逐个探测存活、剔除死链（83 条不可解析条目移除）。

## 两种格式

同时生成两种格式，供不同软件使用：

| 格式 | 说明 | 文件 |
| --- | --- | --- |
| **TVBox txt** | `频道名,URL`，分组用 `组名,#genre#` | `live.txt`（169 KB） |
| **标准 M3U** | `#EXTM3U` + `#EXTINF:-1 group-title="组名",频道名` | `live.m3u`（243 KB） |

## 转换命令

TVBox txt → 标准 M3U 用脚本：

```powershell
# live.txt 为 TVBox 格式输入
.\scripts\txt2m3u.ps1 -InFile live.txt -OutFile live.m3u
```

脚本逻辑：逐行读 `频道名,URL`，遇 `组名,#genre#` 记当前组，
输出 `#EXTINF:-1 group-title="组名",频道名` + URL。结果 UTF-8 无 BOM，1899 条。

## 推送到平板

```powershell
adb -s <SERIAL> push live.txt   /sdcard/Download/live.txt
adb -s <SERIAL> push live.m3u   /sdcard/Download/live.m3u
```

> `/sdcard/Download/` 是 FongMi `/file/` 端点可服务的位置（见 `04-live-fongmi-file.md`）。

## 持久性

- 文件在 `/sdcard/Download/`，**平板重启后保留**。
- 不再依赖外部回环 HTTP 服务，FongMi 自带服务器直接读（见 `04`）。
- 更新直播源时只需重新 `push` 覆盖同名文件，FongMi 重新加载即生效。

## 验证

```powershell
adb -s <SERIAL> shell head -6 /sdcard/Download/live.m3u
# #EXTM3U
# #EXTINF:-1 group-title="央视频道",CCTV-1 (720p)
# http://74.91.26.218:82/live/cctv1hd.m3u8
```

中文组名 `央视频道` 显示正常，说明 UTF-8 编码正确。
