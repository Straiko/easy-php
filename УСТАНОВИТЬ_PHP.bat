@echo off
chcp 65001 >nul 2>&1
title PHP Installation
echo.
echo ========================================
echo   PHP Automatic Installation
echo ========================================
echo.
echo This script will download and install PHP automatically
echo.
pause

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-php.ps1"

echo.
pause

