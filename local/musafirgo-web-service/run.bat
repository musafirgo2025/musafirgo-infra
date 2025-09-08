@echo off
echo 🚀 MusafirGO Web Service Pipeline
echo ================================

echo 📦 Building pipeline executable...
go build -o musafirgo-web-pipeline.exe pipeline.go

if %errorlevel% neq 0 (
    echo ❌ Build failed!
    pause
    exit /b 1
)

echo ✅ Build successful!
echo.

echo 🏃 Running pipeline...
echo Base URL: http://localhost:3000
echo Project Path: C:\Users\omars\workspace\musafirgo\musafirgo-web-service
echo.

musafirgo-web-pipeline.exe http://localhost:3000

echo.
echo 📊 Pipeline completed!
pause
