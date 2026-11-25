# 03 · 点播部署（TVBox4.1+ / 暴风资源）

点播由 **TVBox4.1+**（`com.tvbox.android44`）承担，数据源为**暴风资源**（MacCMS，HTTPS）。

## 为什么用 TVBox4.1+

- 内置较新 SSL/TLS，**HTTPS 源**（暴风资源）可用——老版本 TVBox 常因 TLS 过旧加载失败。
- 内置 MacCMS spider，无需额外 jar。
- 支持扫码添加接口（端口 9979），手机端配置方便。

## 安装

```powershell
adb -s <SERIAL> install -r TVBox4.1+_v0.0.7.apk
# 包名 com.tvbox.android44
```

## 数据源：暴风资源

- MacCMS 接口：`https://bfzyapi.com/api.php/provide/vod/`
- 平板 DNS 曾不稳定（GFW 污染），后解析到 `174.37.175.229`，HTTPS + Host 头返回真实 JSON。

### 扫码接口添加（端口 9979，token 5 分钟有效）

TVBox4.1+ 的扫码接口绑定平板 Wi-Fi IP `192.168.10.114:9979`（非 127.0.0.1），主机可直连：

```powershell
curl -X POST -d 'name=暴风资源' \
  --data-urlencode 'baseUrl=https://bfzyapi.com/api.php/provide/vod/' \
  'http://192.168.10.114:9979/<token>'
```

成功即自动保存并关闭会话。

## 验证（全链路）

| 步骤 | 结果 |
| --- | --- |
| 添加源 | "当前视频源=暴风资源" ✅ |
| 分类加载 | 首页分类/详情加载成功 ✅ |
| 线路 | 详情含 10 条线路，`暴风资源-bfzym3u8` 选中 ✅ |
| 播放 | 实测视频播放成功（剧集画面） ✅ |

## DNS 污染后备

TVBox4.1+ 内置 DNS over HTTPS 选项（设置 → DNS）：腾讯 `doh.pub`、阿里 `dns.alidns.com`、360 `doh.360.cn`。
当系统 DNS 被污染时，可启用 DoH 绕开，保证 HTTPS 源解析正常。

## 注意

- 扫码 token 仅 5 分钟有效，需在有效期内完成添加。
- 系统 DNS 恢复后无需 DoH；若再次污染，启用 DoH 即可。
