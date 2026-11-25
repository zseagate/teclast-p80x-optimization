# TVBox 直播 txt → 标准 M3U 转换
# 用法: .\scripts\txt2m3u.ps1 -InFile live.txt -OutFile live.m3u
# 输入格式: "频道名,URL" 每行，分组标题 "组名,#genre#"
# 输出: UTF-8 无 BOM 的标准 M3U (EXTM3U + EXTINF group-title)
param(
    [string]$InFile  = "live.txt",
    [string]$OutFile = "live.m3u"
)

if (-not (Test-Path $InFile)) { throw "输入文件不存在: $InFile" }

$lines = [System.IO.File]::ReadAllLines($InFile, [System.Text.Encoding]::UTF8)
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("#EXTM3U")

$group = ""
$count = 0
foreach ($raw in $lines) {
    $line = $raw.Trim()
    if ($line -eq "") { continue }
    if ($line -match '^(.*?),(#genre#)$') {
        $group = $Matches[1].Trim()
        continue
    }
    $idx = $line.IndexOf(',')
    if ($idx -le 0) { continue }
    $name = $line.Substring(0, $idx).Trim()
    $url  = $line.Substring($idx + 1).Trim()
    if ($url -eq "") { continue }
    [void]$sb.AppendLine("#EXTINF:-1 group-title=`"$group`",$name")
    [void]$sb.AppendLine($url)
    $count++
}

[System.IO.File]::WriteAllText($OutFile, $sb.ToString(), (New-Object System.Text.UTF8Encoding($false)))
Write-Output "转换完成: $count 频道 -> $OutFile"
