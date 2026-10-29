@echo off
title RapidWrite - Live Studio & Worldwide Public Tunnel
cd /d "%~dp0web_testing_environment"

echo ======================================================================
echo    RapidWrite Handwriting Evaluator Studio - Live Public Launcher
echo ======================================================================
echo.
echo Starting Studio Server and Worldwide Cloudflare Tunnel...
echo.

if exist "C:\users\mohan\appdata\local\python\pythoncore-3.14-64\python.exe" (
    "C:\users\mohan\appdata\local\python\pythoncore-3.14-64\python.exe" run_live_tunnel.py
) else (
    python run_live_tunnel.py
)

pause

