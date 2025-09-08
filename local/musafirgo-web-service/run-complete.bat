@echo off
echo 🚀 MusafirGO Web Service Pipeline - Complete Run
echo ===============================================

echo 📦 Building pipeline executable...
go build -o musafirgo-web-pipeline.exe pipeline.go

if %errorlevel% neq 0 (
    echo ❌ Build failed!
    pause
    exit /b 1
)

echo ✅ Build successful!
echo.

echo 🏃 Running complete pipeline (no skips)...
echo Base URL: http://localhost:3000
echo Project Path: C:\Users\omars\workspace\musafirgo\musafirgo-web-service
echo.

musafirgo-web-pipeline.exe http://localhost:3000

echo.
echo 📊 Complete pipeline finished!
echo 📋 Check the generated HTML report for detailed results.
pause
