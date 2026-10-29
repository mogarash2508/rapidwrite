@echo off
title RapidWrite - Push to GitHub for 24/7 Live Streaming
echo ======================================================================
echo    RapidWrite Studio - One-Click GitHub Push for 24/7 Live Streaming
echo ======================================================================
echo.

set "GIT_CMD=git"
where git >nul 2>&1
if %errorlevel% neq 0 (
    if exist "C:\Users\mohan\AppData\Local\GitHubDesktop\app-3.5.4\resources\app\git\cmd\git.exe" (
        set "GIT_CMD=C:\Users\mohan\AppData\Local\GitHubDesktop\app-3.5.4\resources\app\git\cmd\git.exe"
    )
)

cd /d "%~dp0"

echo [1/4] Checking Git repository status...
"%GIT_CMD%" status --short
echo.

echo [2/4] Staging and committing any recent changes...
"%GIT_CMD%" add .
"%GIT_CMD%" commit -m "Update RapidWrite Studio for 24/7 live streaming" >nul 2>&1

echo [3/4] Checking GitHub Remote...
for /f "tokens=*" %%a in ('"%GIT_CMD%" remote get-url origin 2^>nul') do set REMOTE_URL=%%a

if "%REMOTE_URL%"=="" (
    echo.
    echo No GitHub remote repository connected yet.
    echo ------------------------------------------------------------------
    echo Step A: Go to https://github.com/new and create a new repository.
    echo         (You can name it: rapidwrite or handwriting-evaluator)
    echo Step B: Copy the repository HTTPS link.
    echo ------------------------------------------------------------------
    echo.
    set /p REPO_URL="Paste your GitHub Repository URL here: "
    if not "%REPO_URL%"=="" (
        "%GIT_CMD%" remote add origin %REPO_URL%
    )
)

echo.
echo [4/4] Pushing to GitHub (branch: main)...
"%GIT_CMD%" branch -M main
"%GIT_CMD%" push -u origin main

if %errorlevel% equ 0 (
    echo.
    echo ======================================================================
    echo   SUCCESS! PUSHED TO GITHUB!
    echo ======================================================================
    echo   To enable 24/7 Live Streaming on GitHub Pages:
    echo   1. Open your repository on GitHub.
    echo   2. Go to "Settings" -^> "Pages" (in the left sidebar).
    echo   3. Under "Build and deployment", select Source: "GitHub Actions".
    echo   4. Your site is live worldwide 24/7 forever!
    echo ======================================================================
) else (
    echo.
    echo ------------------------------------------------------------------
    echo If GitHub asks for authentication or credentials:
    echo You can also use GitHub Desktop (already installed on your PC):
    echo File -^> Add Local Repository -^> Select this folder -^> Publish repo!
    echo ------------------------------------------------------------------
)

echo.
pause
