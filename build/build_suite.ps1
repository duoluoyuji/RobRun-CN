# -*- coding: utf-8 -*-
# ROB RUN 汉化发布包一键编译与打包脚本

$ErrorActionPreference = 'Stop'

$SuiteDir = $PSScriptRoot
$Root     = Split-Path (Split-Path $SuiteDir -Parent) -Parent  # F:\RobRun_汉化接手
$ZhSrc    = Join-Path $Root '04_交付\pack_zh'
$TwSrc    = Join-Path $Root '04_交付\pack_tw'
$Dist     = Join-Path $Root '04_交付\ROB_RUN_汉化工具_v1.0'
$ZipOut   = Join-Path $Root '04_交付\ROB_RUN_汉化工具_v1.0.zip'

$Csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path $Csc)) { throw "未找到 csc.exe: $Csc" }

Write-Host "[1/5] 检查资源包" -ForegroundColor Cyan
if (-not (Test-Path $ZhSrc)) { throw "缺少简体资源: $ZhSrc" }
if (-not (Test-Path $TwSrc)) { throw "缺少繁体资源: $TwSrc" }

Write-Host "[2/5] 编译图形版 (1-图形版-双击启动.exe)" -ForegroundColor Cyan
$CsSource = Join-Path $SuiteDir 'RobRunCNTool.cs'
$ExeOut   = Join-Path $SuiteDir '1-图形版-双击启动.exe'

& $Csc /nologo /target:winexe /optimize `
    /r:System.Windows.Forms.dll /r:System.Drawing.dll `
    "/out:$ExeOut" $CsSource

if ($LASTEXITCODE -ne 0) { throw "csc 编译失败: $LASTEXITCODE" }
Write-Host "编译成功: $ExeOut ($((Get-Item $ExeOut).Length) 字节)" -ForegroundColor Green

Write-Host "[3/5] 准备发布目录: $Dist" -ForegroundColor Cyan
if (Test-Path $Dist) { Remove-Item $Dist -Recurse -Force }
New-Item -ItemType Directory -Force -Path $Dist | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $Dist 'zh') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $Dist 'zh-TW') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $Dist 'src') | Out-Null

Write-Host "[4/5] 拷贝脚本、文档与汉化载荷" -ForegroundColor Cyan
Copy-Item (Join-Path $SuiteDir '0-使用说明（先看这里）.txt') $Dist -Force
Copy-Item $ExeOut $Dist -Force
Copy-Item (Join-Path $SuiteDir '*.bat') $Dist -Force
Copy-Item (Join-Path $SuiteDir 'RobRunCNTool.ps1') $Dist -Force
Copy-Item (Join-Path $SuiteDir 'RobRunDiag.ps1') $Dist -Force

# 源码归档备份
Copy-Item $CsSource (Join-Path $Dist 'src\RobRunCNTool.cs') -Force
Copy-Item $MyInvocation.MyCommand.Path (Join-Path $Dist 'src\build_suite.ps1') -Force

# 复制 zh 和 zh-TW 载荷
Copy-Item (Join-Path $ZhSrc '*') (Join-Path $Dist 'zh') -Force
Copy-Item (Join-Path $TwSrc '*') (Join-Path $Dist 'zh-TW') -Force

Write-Host "[5/5] 打包生成 ZIP 压缩包" -ForegroundColor Cyan
if (Test-Path $ZipOut) { Remove-Item $ZipOut -Force }
Compress-Archive -Path (Join-Path $Dist '*') -DestinationPath $ZipOut -CompressionLevel Optimal

$len = (Get-Item $ZipOut).Length
$hash = (Get-FileHash -LiteralPath $ZipOut -Algorithm SHA256).Hash

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "  打包成功完成！" -ForegroundColor Green
Write-Host "  发布目录: $Dist" -ForegroundColor Green
Write-Host "  ZIP 压缩包: $ZipOut" -ForegroundColor Green
Write-Host "  大小: $([math]::Round($len / 1MB, 2)) MB" -ForegroundColor Green
Write-Host "  SHA256: $hash" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
