@echo off
title RapidWrite Cloudflare Live Tunnel (iPad & Mobile Access)
echo ======================================================================
echo    RapidWrite - Cloudflare Live Public Tunnel for iPad & Mobile
echo ======================================================================
echo.

set CLOUDFLARED="C:\Program Files (x86)\cloudflared\cloudflared.exe"

if not exist %CLOUDFLARED% (
    echo Cloudflared not found in default location, searching...
    for /f "delims=" %%i in ('where cloudflared 2^>nul') do set CLOUDFLARED="%%i"
)

echo Starting Cloudflare Tunnel (HTTP/2 stable protocol) ...
echo Connecting to http://localhost:8080 ...
echo.

%CLOUDFLARED% tunnel --protocol http2 --edge-ip-version 4 --url http://localhost:8080

pause
