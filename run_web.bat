@echo off
setlocal

cd /d "%~dp0"

echo Building Fayoum Students for Web...
flutter build web --release
if errorlevel 1 (
    echo.
    echo Build failed.
    pause
    exit /b 1
)

echo Starting local Web server...
start "Fayoum Students Server" cmd /k "cd /d ""%~dp0"" && python -m http.server 8080 --directory build\web"

timeout /t 2 /nobreak >nul
start "" "http://localhost:8080"

endlocal
