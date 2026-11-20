
# -*- coding: utf-8 -*-
# ROB RUN 简繁双语一键汉化与还原工具 v1.3
# 制作: B站@吃素的佩奇 (https://space.bilibili.com/3379443)

param(
    [switch]$Install,
    [switch]$Restore,
    [string]$Lang = "",
    [switch]$Repair
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ToolDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$ZhDir   = Join-Path $ToolDir 'zh'
$ZhTwDir = Join-Path $ToolDir 'zh-TW'

$Zh0Names = @(
    'inbuild_assets_all.bundle',
    'localization-locales_assets_all.bundle',
    'localization-string-tables-english(unitedstates)(en-us)_assets_all.bundle',
    'localization-string-tables-french(fr)_assets_all.bundle',
    'localization-string-tables-german(de)_assets_all.bundle',
    'localization-string-tables-portuguese(pt)_assets_all.bundle',
    'localization-string-tables-russian(russia)(ru-ru)_assets_all.bundle',
    'localization-string-tables-spanish(es)_assets_all.bundle'
)

function Write-Log([string]$msg, [string]$color = "White") {
    $time = (Get-Date).ToString("HH:mm:ss")
    Write-Host ("[" + $time + "] " + $msg) -ForegroundColor $color
}

function Test-GameDir([string]$d) {
    if (-not $d) { return $false }
    if (Test-Path (Join-Path $d 'ROB RUN.exe')) { return $true }
    if (Test-Path (Join-Path $d 'ROB RUN_Data\StreamingAssets\aa\StandaloneWindows64')) { return $true }
    return $false
}

function Find-GameDir {
    $cands = @()
    try {
        $sp = (Get-ItemProperty -Path 'HKCU:\Software\Valve\Steam' -Name 'SteamPath' -ErrorAction SilentlyContinue).SteamPath
        if ($sp) {
            $vdf1 = Join-Path $sp 'steamapps\libraryfolders.vdf'
            $vdf2 = Join-Path $sp 'config\libraryfolders.vdf'
            foreach ($v in @($vdf1, $vdf2)) {
                if (Test-Path $v) {
                    $txt = Get-Content -LiteralPath $v -Raw -ErrorAction SilentlyContinue
                    foreach ($m in [regex]::Matches($txt, '"path"\s+"([^"]+)"')) {
                        $p = ($m.Groups[1].Value -replace '\\\\','\\')
                        $cands += (Join-Path $p 'steamapps\common\Rob Run')
                    }
                }
            }
        }
    } catch {}

    # 检查工具当前目录与上级目录
    $cands += $ToolDir
    $parent = Split-Path $ToolDir -Parent
    if ($parent) { $cands += $parent }

    # 动态扫描所有就绪驱动器
    try {
        foreach ($d in [System.IO.DriveInfo]::GetDrives()) {
            if ($d.IsReady) {
                $root = $d.RootDirectory.FullName
                $cands += (Join-Path $root 'SteamLibrary\steamapps\common\Rob Run')
                $cands += (Join-Path $root 'steamapps\common\Rob Run')
                $cands += (Join-Path $root 'Program Files (x86)\Steam\steamapps\common\Rob Run')
                $cands += (Join-Path $root 'Steam\steamapps\common\Rob Run')
            }
        }
    } catch {}

    foreach ($c in ($cands | Select-Object -Unique)) {
        if (Test-GameDir $c) { return $c }
    }
    return $null
}

function Get-CacheDir {
    $localLow = Join-Path $env:USERPROFILE 'AppData\LocalLow'
    return (Join-Path $localLow 'Kefir\ROB RUN\com.unity.addressables')
}

function Replace-Bytes([byte[]]$data, [byte[]]$find, [byte[]]$repl) {
    $out = New-Object System.Collections.Generic.List[byte]
    $i = 0
    $n = $data.Length; $m = $find.Length
    while ($i -lt $n) {
        $match = $false
        if ($m -gt 0 -and $i + $m -le $n) {
            $match = $true
            for ($j = 0; $j -lt $m; $j++) {
                if ($data[$i + $j] -ne $find[$j]) { $match = $false; break }
            }
        }
        if ($match) { foreach ($b in $repl) { $out.Add($b) }; $i += $m }
        else { $out.Add($data[$i]); $i++ }
    }
    return ,$out.ToArray()
}

# 把用户缓存目录整体改名备份，避免“旧的 catalog.bin + 新的 .hash”导致 E-0124 / 资源找不到
function Reset-CacheDir([string]$reason) {
    $cache = Get-CacheDir
    if (Test-Path $cache) {
        $stamp = (Get-Date).ToString('yyyyMMddHHmmss')
        $bak = $cache + '.bak_' + $stamp
        try {
            Rename-Item -LiteralPath $cache -NewName ('com.unity.addressables.bak_' + $stamp) -ErrorAction Stop
            Write-Log ('已把旧的运行时缓存改名备份 -> ' + (Split-Path $bak -Leaf) + '（' + $reason + '）') 'Cyan'
        } catch {
            Remove-Item -LiteralPath $cache -Recurse -Force -ErrorAction SilentlyContinue
            Write-Log ('已清理旧的运行时缓存（' + $reason + '）') 'Cyan'
        }
    }
}

function Get-CatalogName([string]$g) {
    $settings = Join-Path $g 'ROB RUN_Data\StreamingAssets\aa\settings.json'
    if (Test-Path $settings) {
        $txt = [System.IO.File]::ReadAllText($settings, [System.Text.Encoding]::UTF8)
        $m = [regex]::Matches($txt, 'catalog_[0-9][0-9\.]+')
        if ($m.Count -gt 0) {
            $cand = @($m | ForEach-Object { $_.Value.TrimEnd('.') } | Where-Object { ($_.ToCharArray() | Where-Object { $_ -eq '.' }).Count -ge 3 } | Sort-Object Length -Descending)
            if ($cand.Count -gt 0) { return $cand[0] }
        }
    }
    $cache = Get-CacheDir
    if (Test-Path $cache) {
        $f = Get-ChildItem -LiteralPath $cache -Filter 'catalog_*.bin' -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($f) { return [System.IO.Path]::GetFileNameWithoutExtension($f.Name) }
    }
    return 'catalog'
}

# 关键：只改写【用户缓存】里的 catalog，安装目录的 catalog.bin / catalog.hash 一律不动（否则触发反作弊“未知的文件版本”）
function Apply-CatalogRedirect([string]$g) {
    $masterBin  = Join-Path $g 'ROB RUN_Data\StreamingAssets\aa\catalog.bin'
    $masterHash = Join-Path $g 'ROB RUN_Data\StreamingAssets\aa\catalog.hash'
    if (-not (Test-Path $masterBin)) { throw ('找不到主 catalog.bin: ' + $masterBin) }

    $cache = Get-CacheDir
    if (-not (Test-Path $cache)) { New-Item -ItemType Directory -Path $cache -Force | Out-Null }
    $catName = Get-CatalogName $g
    $cacheBin  = Join-Path $cache ($catName + '.bin')
    $cacheHash = Join-Path $cache ($catName + '.hash')

    [byte[]]$data = [System.IO.File]::ReadAllBytes($masterBin)
    $enc = [System.Text.Encoding]::ASCII
    $hits = 0
    foreach ($n in $Zh0Names) {
        $z = $n.Replace('_all.bundle', '_zh0.bundle')
        [byte[]]$find = $enc.GetBytes($n)
        [byte[]]$repl = $enc.GetBytes($z)
        if ($find.Length -eq $repl.Length) {
            $before = [System.Text.Encoding]::ASCII.GetString($data)
            if ($before.Contains($n)) { $data = Replace-Bytes $data $find $repl; $hits++ }
        }
    }
    [System.IO.File]::WriteAllBytes($cacheBin, $data)
    if (Test-Path $masterHash) { Copy-Item -LiteralPath $masterHash -Destination $cacheHash -Force }
    Write-Log ('[成功] 已把 ' + $hits + '/8 处包名指向 *_zh0.bundle') 'Green'
    $hashText = ''
    if (Test-Path $cacheHash) { $hashText = [System.IO.File]::ReadAllText($cacheHash) }
    Write-Log ('[成功] 已写入缓存 catalog 哈希（' + $hashText + '）') 'Green'

    # 兜底：把缓存里其它 catalog_*.bin 也一并改写，避免版本名不一致导致失效
    foreach ($cf in (Get-ChildItem -LiteralPath $cache -Filter 'catalog_*.bin' -ErrorAction SilentlyContinue)) {
        if ($cf.FullName -ne $cacheBin) {
            [System.IO.File]::WriteAllBytes($cf.FullName, $data)
            $h2 = [System.IO.Path]::ChangeExtension($cf.FullName, '.hash')
            if (Test-Path $masterHash) { Copy-Item -LiteralPath $masterHash -Destination $h2 -Force }
            Write-Log ('已同步缓存副本: ' + $cf.Name) 'Gray'
        }
    }
}

function Ensure-GameClosed {
    $procs = Get-Process -Name 'ROB RUN' -ErrorAction SilentlyContinue
    if ($procs) {
        Write-Log "【提示】检测到 ROB RUN 正在运行，正在等待退出..." "Yellow"
        $w = 0
        while ((Get-Process -Name 'ROB RUN' -ErrorAction SilentlyContinue) -and $w -lt 20) {
            Start-Sleep -Milliseconds 500
            $w++
        }
        if (Get-Process -Name 'ROB RUN' -ErrorAction SilentlyContinue) {
            throw "游戏仍在运行中，请先完全退出游戏后再执行操作！"
        }
    }
}

# ==================== 专属定制免责声明弹窗 ====================
function Show-Disclaimer {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "ROB RUN 汉化工具 - 制作: B站@吃素的佩奇"
    $form.Size = New-Object System.Drawing.Size(580, 480)
    $form.StartPosition = 'CenterScreen'
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.BackColor = [System.Drawing.Color]::FromArgb(24,24,28)

    # 顶部横幅
    $banner = New-Object System.Windows.Forms.Panel
    $banner.Dock = 'Top'
    $banner.Height = 65
    $banner.BackColor = [System.Drawing.Color]::FromArgb(35,35,45)
    $form.Controls.Add($banner)

    $icon = New-Object System.Windows.Forms.Label
    $icon.Text = '!'
    $icon.Font = New-Object System.Drawing.Font('Arial', 24, [System.Drawing.FontStyle]::Bold)
    $icon.ForeColor = [System.Drawing.Color]::FromArgb(255,165,0)
    $icon.Location = New-Object System.Drawing.Point(16,12)
    $icon.Size = New-Object System.Drawing.Size(36,40)
    $icon.TextAlign = 'MiddleCenter'
    $banner.Controls.Add($icon)

    $title = New-Object System.Windows.Forms.Label
    $title.Text = '重要操作风险说明'
    $title.Font = New-Object System.Drawing.Font('Microsoft YaHei UI', 15, [System.Drawing.FontStyle]::Bold)
    $title.ForeColor = [System.Drawing.Color]::FromArgb(255,165,0)
    $title.Location = New-Object System.Drawing.Point(58,16)
    $title.AutoSize = $true
    $banner.Controls.Add($title)

    # 中部说明文字区
    $body = New-Object System.Windows.Forms.Panel
    $body.Dock = 'Fill'
    $body.BackColor = [System.Drawing.Color]::FromArgb(28,28,34)
    $body.Padding = New-Object System.Windows.Forms.Padding(20,12,20,0)
    $form.Controls.Add($body)
    $form.Controls.SetChildIndex($body, 0)

    $items = @(
        '1. 本汉化补丁仅供技术交流与学习参考，免费分享，严禁倒卖牟利。',
        '2. 本工具采用独立载荷与 catalog 重定向，随时可用「一键还原」恢复官方纯净英文。',
        '3. 任何对游戏客户端的修改行为均可能存在潜在风险（包括游戏异常或账号风险）。',
        '4. 使用本工具产生的一切后果及风险由使用者本人自担。',
        '5. 执行安装或还原前请确保 ROB RUN 游戏进程已完全退出。'
    )
    $y = 12
    foreach ($it in $items) {
        $l = New-Object System.Windows.Forms.Label
        $l.Text = $it
        $l.Font = New-Object System.Drawing.Font('Microsoft YaHei UI', 10)
        $l.ForeColor = [System.Drawing.Color]::FromArgb(220,220,225)
        $l.AutoSize = $false
        $l.Location = New-Object System.Drawing.Point(16,$y)
        $l.Size = New-Object System.Drawing.Size(515,48)
        $l.TextAlign = 'TopLeft'
        $body.Controls.Add($l)
        $y += 52
    }

    # 声明栏
    $authorBanner = New-Object System.Windows.Forms.Label
    $authorBanner.Text = "★ 制作团队: B站@吃素的佩奇 | 免费分享严禁倒卖"
    $authorBanner.Font = New-Object System.Drawing.Font('Microsoft YaHei UI', 9, [System.Drawing.FontStyle]::Bold)
    $authorBanner.ForeColor = [System.Drawing.Color]::FromArgb(160,130,240)
    $newY = $y + 4
    $authorBanner.Location = New-Object System.Drawing.Point(16, $newY)
    $authorBanner.Size = New-Object System.Drawing.Size(515,22)
    $authorBanner.TextAlign = 'MiddleLeft'
    $body.Controls.Add($authorBanner)

    # 底部勾选确认栏
    $checkRow = New-Object System.Windows.Forms.Panel
    $checkRow.Dock = 'Bottom'
    $checkRow.Height = 56
    $checkRow.BackColor = [System.Drawing.Color]::FromArgb(20,20,26)
    $form.Controls.Add($checkRow)

    $chk = New-Object System.Windows.Forms.CheckBox
    $chk.Text = '我已充分了解修改客户端的潜在风险，并自愿承担可能带来的一切后果。'
    $chk.Font = New-Object System.Drawing.Font('Microsoft YaHei UI', 9.5)
    $chk.ForeColor = [System.Drawing.Color]::FromArgb(200,200,205)
    $chk.Location = New-Object System.Drawing.Point(18,16)
    $chk.AutoSize = $true
    $checkRow.Controls.Add($chk)

    # 按钮栏
    $btnRow = New-Object System.Windows.Forms.Panel
    $btnRow.Dock = 'Bottom'
    $btnRow.Height = 64
    $btnRow.BackColor = [System.Drawing.Color]::FromArgb(32,32,38)
    $form.Controls.Add($btnRow)

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = '取消退出'
    $btnCancel.BackColor = [System.Drawing.Color]::FromArgb(55,55,62)
    $btnCancel.ForeColor = [System.Drawing.Color]::FromArgb(200,200,200)
    $btnCancel.FlatStyle = 'Flat'
    $btnCancel.Location = New-Object System.Drawing.Point(20,15)
    $btnCancel.Size = New-Object System.Drawing.Size(100,34)
    $btnCancel.Add_Click({
        $form.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $form.Close()
    })
    $btnRow.Controls.Add($btnCancel)

    $btnBili = New-Object System.Windows.Forms.Button
    $btnBili.Text = '关注作者B站'
    $btnBili.BackColor = [System.Drawing.Color]::FromArgb(251, 114, 153)
    $btnBili.ForeColor = [System.Drawing.Color]::White
    $btnBili.FlatStyle = 'Flat'
    $btnBili.Location = New-Object System.Drawing.Point(140,15)
    $btnBili.Size = New-Object System.Drawing.Size(115,34)
    $btnBili.Font = New-Object System.Drawing.Font('Microsoft YaHei UI', 9, [System.Drawing.FontStyle]::Bold)
    $btnBili.Add_Click({
        try { [System.Diagnostics.Process]::Start("https://space.bilibili.com/3379443") } catch {}
    })
    $btnRow.Controls.Add($btnBili)

    $btnGo = New-Object System.Windows.Forms.Button
    $btnGo.Text = '已了解，继续'
    $btnGo.BackColor = [System.Drawing.Color]::FromArgb(70,70,80)
    $btnGo.ForeColor = [System.Drawing.Color]::FromArgb(160,160,165)
    $btnGo.FlatStyle = 'Flat'
    $btnGo.Location = New-Object System.Drawing.Point(410,15)
    $btnGo.Size = New-Object System.Drawing.Size(130,34)
    $btnGo.Font = New-Object System.Drawing.Font('Microsoft YaHei UI', 9.5, [System.Drawing.FontStyle]::Bold)
    $btnGo.Enabled = $false
    $btnGo.Add_Click({
        $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $form.Close()
    })
    $btnRow.Controls.Add($btnGo)

    $chk.Add_CheckedChanged({
        $btnGo.Enabled = $chk.Checked
        if ($chk.Checked) {
            $btnGo.BackColor = [System.Drawing.Color]::FromArgb(34, 197, 94)
            $btnGo.ForeColor = [System.Drawing.Color]::White
        } else {
            $btnGo.BackColor = [System.Drawing.Color]::FromArgb(70,70,80)
            $btnGo.ForeColor = [System.Drawing.Color]::FromArgb(160,160,165)
        }
    })

    $res = $form.ShowDialog()
    return $res
}

# ================= 命令行模式 =================
if ($Install -or $Restore -or $Repair) {
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "       ROB RUN 简繁双语一键汉化工具 v1.3" -ForegroundColor Cyan
    Write-Host "       制作团队: B站@吃素的佩奇" -ForegroundColor Magenta
    Write-Host "       主页: https://space.bilibili.com/3379443" -ForegroundColor Gray
    Write-Host "==========================================================" -ForegroundColor Cyan

    $game = Find-GameDir
    if (-not $game) {
        Write-Host "【错误】未自动定位到 ROB RUN 安装目录，请确认游戏已正确安装。" -ForegroundColor Red
        exit 1
    }
    Write-Log ("定位到游戏目录: " + $game) "Green"
    Ensure-GameClosed

    $aa = Join-Path $game 'ROB RUN_Data\StreamingAssets\aa\StandaloneWindows64'

    if ($Restore) {
        Write-Log "正在执行一键还原官方原版英文..." "Yellow"
        foreach ($n in $Zh0Names) {
            $z = Join-Path $aa ($n.Replace('_all.bundle', '_zh0.bundle'))
            if (Test-Path $z) {
                Remove-Item -LiteralPath $z -Force
                Write-Log ("已清理: " + [System.IO.Path]::GetFileName($z)) "Gray"
            }
        }
        $masterBin = Join-Path $game 'ROB RUN_Data\StreamingAssets\aa\catalog.bin'
        $masterHash = Join-Path $game 'ROB RUN_Data\StreamingAssets\aa\catalog.hash'
        # 直接把运行时缓存整体改名备份，游戏会回退到安装目录里的官方 catalog
        Reset-CacheDir '还原官方原版'
        Write-Log '已把用户缓存 catalog 还原为官方版本' 'Green'
        Write-Host ""
        Write-Host "【成功】已完全还原官方原版英文！直接启动游戏即可。" -ForegroundColor Green
        exit 0
    }

    if ($Repair) {
        Write-Log '正在处理启动报错（E-0124 / 资源加载失败）...' 'Yellow'
        Reset-CacheDir '手动修复'
        Write-Host ''
        Write-Host '【成功】已清理旧的运行时缓存。现在启动游戏即可（若已装汉化，中文仍在）。' -ForegroundColor Green
        exit 0
    }

    if ($Install) {
        $sourceDir = if ($Lang -eq 'zh-TW') { $ZhTwDir } else { $ZhDir }
        $langTitle = if ($Lang -eq 'zh-TW') { '繁体中文' } else { '简体中文' }

        $disclaimerResult = Show-Disclaimer
        if ($disclaimerResult -ne [System.Windows.Forms.DialogResult]::OK) {
            Write-Host "用户已取消操作，未对游戏做任何修改。" -ForegroundColor Yellow
            exit 0
        }

        Write-Host ""
        Reset-CacheDir '安装前清理旧缓存'
        Write-Log ("正在安装【" + $langTitle + "】汉化包...") "Yellow"
        if (-not (Test-Path $sourceDir)) { throw ("缺少汉化资源包目录: " + $sourceDir) }
        if (-not (Test-Path $aa)) { New-Item -ItemType Directory -Path $aa -Force | Out-Null }

        foreach ($n in $Zh0Names) {
            $src = Join-Path $sourceDir $n
            if (-not (Test-Path $src)) { throw ("资源包缺失: " + $src) }
            $dst = Join-Path $aa ($n.Replace('_all.bundle', '_zh0.bundle'))
            Copy-Item -LiteralPath $src -Destination $dst -Force
            $fileLen = (Get-Item $dst).Length
            Write-Log ("已写入: " + [System.IO.Path]::GetFileName($dst) + " (" + $fileLen + " 字节)") "Gray"
        }

        Apply-CatalogRedirect $game

        Write-Host ""
        Write-Host "==========================================================" -ForegroundColor Green
        Write-Host ("【成功】ROB RUN 【" + $langTitle + "】安装完成！") -ForegroundColor Green
        Write-Host "现在可直接启动游戏体验汉化。" -ForegroundColor Green
        Write-Host "==========================================================" -ForegroundColor Green
        exit 0
    }
}

Write-Log "正在启动图形化界面..." "Cyan"
$exe = Join-Path $ToolDir '1-图形版-双击启动.exe'
if (Test-Path $exe) {
    Start-Process -FilePath $exe
} else {
    Write-Host "未找到 1-图形版-双击启动.exe，请使用窗口版快捷方式执行安装。" -ForegroundColor Yellow
}
