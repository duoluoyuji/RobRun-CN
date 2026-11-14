@echo off
setlocal
cd /d "%~dp0"
title ROB RUN ∫∫ªØ’Ô∂œ

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0RobRunDiag.ps1"
echo.
pause
