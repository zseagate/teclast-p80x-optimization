# 04 · 直播部署（FongMi + 自带服务器读本地文件，重启持久）

直播由 **FongMi 影视 5.9.0**（`com.fongmi.android.tv`，mobile-arm64_v8a）承担，
直播源通过 **FongMi 自带 NanoHTTPD 服务器 `/file/` 端点**读 `/sdcard/Download/` 本地文件。

> ⭐ 本方案的核心：**彻底摆脱外部回环 HTTP 服务，平板重启后无需任何手动步骤**。

## 安装

```powershell
adb -s <SERIAL> install -r fongmi-5.9.0-mobile-arm64_v8a.apk
# 包名 com.fongmi.android.tv
```

## 问题：`clan://` 不认，外部回环服务重启失效

FongMi 的 Decoder 只认 `http://` / `https://`，不认 `clan://`。
最初用外部回环 HTTP 服务（`toybox nc -L` 监听 `127.0.0.1:8099`）服务直播源：

```sh
# 需在平板 shell 执行，重启后失效，必须手动重起 —— 不持久 ✗
nohup toybox nc -s 127.0.0.1 -p 8099 -L /data/local/tmp/iptv_httpd.sh >/dev/null 2>&1 &
```

但**平板重启后该服务失效**，需重新执行——不符合"持久化"要求。

## 解法：用 FongMi 自带服务器 `/file/` 端点

排查 FongMi 源码发现其自带 NanoHTTPD 服务器（`Server.start()` 从 **9978 起**扫描空闲端口）
有 **`/file/` 端点**，能把 `file://` 配置地址转成本地 HTTP 服务。

```java
// UrlUtil.convert
case "file" -> Server.get().getAddress("/file/") + Uri.encode(url.substring((prefix).length()), "/");
```

- `Server.start()`：`for (int i = 9978; i < 9999; i++) if (start(i)) return true;` —— 端口从 9978 动态起。
- `Local.getFile`：`Path.local(path)` 以 `/storage/emulated/0` 为根解析路径，`isLoopback` 放行本地请求。
- 服务器随 App 启动（`BaseConfig.ensureLoaded()` → `Server.get().start()`）。

### 配置地址

直播配置地址设为：

```
file:///sdcard/Download/live.txt
```

FongMi 加载时 `UrlUtil.convert` 自动转成 `http://127.0.0.1:9978/file//sdcard/Download/live.txt`，
从自带服务器读取本地文件。

## 验证

```powershell
# 端口确认（FongMi 前台运行后）
adb -s <SERIAL> shell netstat -tln | grep 9978
# tcp6  0  0  :::9978  :::*  LISTEN

# /file/ 端点验证（经 adb forward）
adb -s <SERIAL> forward tcp:9978 tcp:9978
Invoke-WebRequest http://127.0.0.1:9978/file//sdcard/Download/live.txt
# HTTP 200  CT=text/plain  len=165701
```

## 实测效果

- 频道分组完整：央视频道 / 卫视频道 / 港澳台 / 新闻 / 电影 / 体育…（1899 频道）。
- 实测播放成功：凤凰中文、凤凰资讯（访谈）、CCTV-11（乒乓球决赛）、CNN 等。

## 关键结论

1. **FongMi 自带服务器 `/file/` 端点**可服务 `/sdcard/` 下任意文件，无需外部 `toybox nc`。
2. **重启后持久**：文件在 `/sdcard/Download/`（重启保留），服务器随 App 启动（9978）。
3. 端口从 9978 起动态分配，**不一定是 9978**——`Server.start()` 会扫描 9978~9998 找空闲。
4. `pm disable` 等可逆手段之外，本方案**零系统改动**，全部走应用层。

## 相关源码

- `UrlUtil.convert`（`file://` → `/file/` 端点）
- `Local.getFile` / `Path.local`（路径解析，根 = `/storage/emulated/0`）
- `Server.start()`（端口 9978~9998 扫描）
- `BaseConfig.ensureLoaded()`（启动即开服务器）

> 源码位于 FongMi-TV 项目，本仓库不附带第三方源码。
