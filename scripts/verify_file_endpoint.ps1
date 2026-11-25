# 验证 FongMi /file/ 端点可服务本地直播源
# 用法: .\scripts\verify_file_endpoint.ps1 <SERIAL>
# 前提: FongMi 已在前台运行（服务器在 9978 起），直播源已推送到 /sdcard/Download/
param(
    [Parameter(Mandatory=$true)][string]$SERIAL,
    [string]$Adb = "adb"
)

Write-Output "===== 验证 FongMi /file/ 端点 =====

# 找服务器端口（9978-9998）
$out = & $Adb -s $SERIAL shell "netstat -tln 2>/dev/null" 2>&1
$port = $null
foreach ($line in $out) {
    if ($line -match ':(99[0-9]{2})\s') { $port = $Matches[1]; break }
}
if (-not $port) { Write-Error "未找到 FongMi 服务器端口（9978-9998），请先在前台打开 FongMi"; exit 1 }
Write-Output "FongMi 服务器端口: $port"

& $Adb -s $SERIAL forward "tcp:$port" "tcp:$port" | Out-Null

foreach ($f in @("live.txt","live.m3u")) {
    try {
        $r = Invoke-WebRequest -Uri "http://127.0.0.1:$port/file//sdcard/Download/$f" -TimeoutSec 8 -UseBasicParsing
        Write-Output ("OK  $f -> HTTP " + $r.StatusCode + " len=" + $r.Content.Length)
    } catch {
        $c = ""; if ($_.Exception.Response) { $c = [int]$_.Exception.Response.StatusCode }
        Write-Output ("ERR $f -> " + $c)
    }
}
