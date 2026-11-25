# 推送直播源到平板 /sdcard/Download/ 并验证 FongMi /file/ 端点
# 用法: .\scripts\push_live_sources.ps1 <SERIAL> [-LiveTxt live.txt] [-LiveM3u live.m3u]
param(
    [Parameter(Mandatory=$true)][string]$SERIAL,
    [string]$LiveTxt = "live.txt",
    [string]$LiveM3u = "live.m3u",
    [string]$Adb = "adb"
)

function Invoke-Adb([string]$args) {
    $out = & $Adb -s $SERIAL shell $args 2>&1
    return ($out -join "`n")
}

Write-Output "===== 推送直播源 -> $SERIAL ====="

# 1. 推送
if (Test-Path $LiveTxt) {
    & $Adb -s $SERIAL push $LiveTxt /sdcard/Download/live.txt
    Write-Output "live.txt 已推送"
} else { Write-Warning "未找到 $LiveTxt，跳过" }

if (Test-Path $LiveM3u) {
    & $Adb -s $SERIAL push $LiveM3u /sdcard/Download/live.m3u
    Write-Output "live.m3u 已推送"
} else { Write-Warning "未找到 $LiveM3u，跳过" }

# 2. 校验文件
Write-Output "--- 设备端文件 ---"
Invoke-Adb "ls -l /sdcard/Download/live.txt /sdcard/Download/live.m3u"

# 3. 验证 FongMi /file/ 端点（需 FongMi 前台运行，服务器在 9978 起）
Write-Output "--- FongMi 服务器端口 ---"
$port = (Invoke-Adb "netstat -tln 2>/dev/null | grep -oE ':(99[0-9]{2})' | head -1") -replace ':',''
if (-not $port) { Write-Warning "未找到 FongMi 服务器端口（9978-9998），请先在前台打开 FongMi"; exit 1 }

& $Adb -s $SERIAL forward "tcp:$port" "tcp:$port" | Out-Null
try {
    $r = Invoke-WebRequest -Uri "http://127.0.0.1:$port/file//sdcard/Download/live.txt" -TimeoutSec 8 -UseBasicParsing
    Write-Output ("/file/ 验证: HTTP " + $r.StatusCode + " len=" + $r.Content.Length + " (端口 $port)")
} catch {
    Write-Warning "/file/ 验证失败: $($_.Exception.Message)"
    exit 1
}

Write-Output "===== 完成 ====="
