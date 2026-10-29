@echo off
title RapidWrite Handwriting Evaluator Server
echo ======================================================================
echo    RapidWrite Handwriting Evaluation Environment - Localhost Server
echo ======================================================================
echo.

cd /d "%~dp0"

echo Starting server...
echo.

start "" "http://localhost:8080/"

if exist "C:\users\mohan\appdata\local\python\pythoncore-3.14-64\python.exe" (
    "C:\users\mohan\appdata\local\python\pythoncore-3.14-64\python.exe" server.py
) else (
    python server.py
)

pause
