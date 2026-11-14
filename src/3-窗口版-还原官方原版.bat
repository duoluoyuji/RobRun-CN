@echo off
setlocal
cd /d "%~dp0"
title ROB RUN 一键还原官方原版英文

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0RobRunCNTool.ps1" -Restore
if %errorlevel% neq 0 (
    echo.
    echo 执行过程出现异常，退出代码: %errorlevel%
)
pause
