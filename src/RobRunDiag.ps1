# -*- coding: utf-8 -*-
# ROB RUN 汉化一键诊断工具（只读，不修改任何文件）
# 输出：同目录下 ROB_RUN_汉化诊断_时间.txt

$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'

$ToolDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$reportFile = Join-Path $ToolDir ("ROB_RUN_汉化诊断_" + $stamp + ".txt")

$script:rep = New-Object System.Collections.Generic.List[string]
function Log-Line([string]$s) { $script:rep.Add($s); Write-Host $s }

Log-Line "=========================================================="
Log-Line ("  ROB RUN 简繁双语汉化一键诊断报告 v1.0 (" + $stamp + ")")
Log-Line "=========================================================="
Log-Line ""

# 1. 系统环境与权限
Log-Line "[1/5] 系统环境与权限"
Log-Line ("  操作系统: " + [System.Environment]::OSVersion.VersionString)
Log-Line ("  64位系统: " + [System.Environment]::Is64BitOperatingSystem)
Log-Line ("  当前用户: " + $env:USERNAME)
Log-Line ("  工具目录: " + $ToolDir)
Log-Line ""

# 2. 载荷完整性自检
Log-Line "[2/5] 本地汉化工具包自检"
$zhDir = Join-Path $ToolDir "zh"
$twDir = Join-Path $ToolDir "zh-TW"
$expected = @(
    'inbuild_assets_all.bundle',
    'localization-locales_assets_all.bundle',
    'localization-string-tables-english(unitedstates)(en-us)_assets_all.bundle',
    'localization-string-tables-french(fr)_assets_all.bundle',
    'localization-string-tables-german(de)_assets_all.bundle',
    'localization-string-tables-portuguese(pt)_assets_all.bundle',
    'localization-string-tables-russian(russia)(ru-ru)_assets_all.bundle',
    'localization-string-tables-spanish(es)_assets_all.bundle'
)

$zhOk = $true
foreach ($n in $expected) {
    $p = Join-Path $zhDir $n
    if (Test-Path $p) {
        $len = (Get-Item $p).Length
        Log-Line ("  [zh] 存在: " + $n + " (" + $len + " 字节)")
    } else {
        Log-Line ("  [zh] 缺失: " + $n)
        $zhOk = $false
    }
}

$twOk = $true
foreach ($n in $expected) {
    $p = Join-Path $twDir $n
    if (Test-Path $p) {
        $len = (Get-Item $p).Length
        Log-Line ("  [zh-TW] 存在: " + $n + " (" + $len + " 字节)")
    } else {
        Log-Line ("  [zh-TW] 缺失: " + $n)
        $twOk = $false
    }
}
Log-Line ""

# 3. 游戏目录探测
Log-Line "[3/5] 游戏安装目录与 Steam 库检测"
$gameCandidates = @(
    $ToolDir,
    (Split-Path $ToolDir -Parent)
)
try {
    foreach ($d in [System.IO.DriveInfo]::GetDrives()) {
        if ($d.IsReady) {
            $root = $d.RootDirectory.FullName
            $gameCandidates += (Join-Path $root 'SteamLibrary\steamapps\common\Rob Run')
            $gameCandidates += (Join-Path $root 'steamapps\common\Rob Run')
            $gameCandidates += (Join-Path $root 'Program Files (x86)\Steam\steamapps\common\Rob Run')
            $gameCandidates += (Join-Path $root 'Steam\steamapps\common\Rob Run')
        }
    }
} catch {}
try {
    $sp = (Get-ItemProperty -Path 'HKCU:\Software\Valve\Steam' -Name 'SteamPath' -ErrorAction SilentlyContinue).SteamPath
    if ($sp) {
        Log-Line ("  SteamPath 注册表: " + $sp)
        $vdf = Join-Path $sp 'steamapps\libraryfolders.vdf'
        if (Test-Path $vdf) {
            $txt = Get-Content -LiteralPath $vdf -Raw
            foreach ($m in [regex]::Matches($txt, '"path"\s+"([^"]+)"')) {
                $gameCandidates += (Join-Path ($m.Groups[1].Value -replace '\\\\','\') 'steamapps\common\Rob Run')
            }
        }
    }
} catch {}

$foundGame = $null
foreach ($c in ($gameCandidates | Select-Object -Unique)) {
    if (Test-Path (Join-Path $c 'ROB RUN.exe')) {
        $foundGame = $c
        Log-Line ("  -> 找到游戏根目录: " + $c)
        break
    }
}
if (-not $foundGame) {
    Log-Line "  【警告】未在预设路径检测到已安装的 ROB RUN.exe"
}
Log-Line ""

# 4. 游戏内汉化载荷与 catalog 状态
Log-Line "[4/5] 游戏文件与 catalog 重定向状态"
if ($foundGame) {
    $aa = Join-Path $foundGame 'ROB RUN_Data\StreamingAssets\aa\StandaloneWindows64'
    if (Test-Path $aa) {
        $zhBundles = Get-ChildItem -LiteralPath $aa -Filter '*_zh0.bundle' -ErrorAction SilentlyContinue
        Log-Line ("  已部署的 _zh0.bundle 数量: " + $zhBundles.Count)
        foreach ($b in $zhBundles) {
            Log-Line ("    " + $b.Name + " (" + $b.Length + " 字节)")
        }
    }

    $masterBin = Join-Path $foundGame 'ROB RUN_Data\StreamingAssets\aa\catalog.bin'
    if (Test-Path $masterBin) {
        $binLen = (Get-Item $masterBin).Length
        Log-Line ("  主 catalog.bin 存在 (" + $binLen + " 字节)")
        $bytes = [System.IO.File]::ReadAllBytes($masterBin)
        $txt = [System.Text.Encoding]::ASCII.GetString($bytes)
        $hasRedirect = $txt.Contains('_zh0.bundle')
        $statusStr = if ($hasRedirect) { "已成功生效 (指向 _zh0.bundle)" } else { "官方原版 (未重定向)" }
        Log-Line ("  主 catalog.bin 重定向状态: " + $statusStr)
    }

    $cache = Join-Path $env:USERPROFILE 'AppData\LocalLow\Kefir\ROB RUN\com.unity.addressables'
    if (Test-Path $cache) {
        $cacheCatalogs = Get-ChildItem -LiteralPath $cache -Filter 'catalog*.bin' -ErrorAction SilentlyContinue
        Log-Line ("  运行时缓存 catalog 数量: " + $cacheCatalogs.Count)
        foreach ($c in $cacheCatalogs) {
            $cb = [System.IO.File]::ReadAllBytes($c.FullName)
            $cTxt = [System.Text.Encoding]::ASCII.GetString($cb)
            $cStatus = if ($cTxt.Contains('_zh0.bundle')) { "已同步汉化" } else { "原版缓存" }
            Log-Line ("    " + $c.Name + ": " + $cStatus)
        }
    } else {
        Log-Line "  运行时缓存目录尚未建立 (游戏首次启动前属正常现象)"
    }
}
Log-Line ""

# 5. 进程占用与冲突检查
Log-Line "[5/5] 进程占用检查"
$procs = Get-Process -Name 'ROB RUN' -ErrorAction SilentlyContinue
if ($procs) {
    Log-Line "  【提示】ROB RUN 游戏当前正在运行中！"
} else {
    Log-Line "  ROB RUN 进程未运行 (可正常执行安装与还原)"
}

Log-Line ""
Log-Line "=========================================================="
Log-Line ("诊断完成！诊断结果已保存至: " + $reportFile)
Log-Line "若遇到问题，可将此文件发送反馈。"
Log-Line "=========================================================="

[System.IO.File]::WriteAllLines($reportFile, $script:rep.ToArray(), [System.Text.Encoding]::UTF8)
