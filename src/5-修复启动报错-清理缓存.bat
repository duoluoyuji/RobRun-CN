@echo off
setlocal
cd /d "%~dp0"
title ROB RUN 修复启动报错（清理旧缓存）
echo 正在清理游戏运行时缓存（旧 catalog 缓存会导致 E-0124 或中文失效）...
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0RobRunCNTool.ps1" -Repair
if %errorlevel% neq 0 (
    echo.
    echo 执行过程出现异常，退出代码: %errorlevel%
)
pause