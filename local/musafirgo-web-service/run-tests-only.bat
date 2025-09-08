@echo off
echo 🚀 MusafirGO Web Service Pipeline - Tests Only
echo ==============================================

echo 📦 Building pipeline executable...
go build -o musafirgo-web-pipeline.exe pipeline.go

if %errorlevel% neq 0 (
    echo ❌ Build failed!
    pause
    exit /b 1
)

echo ✅ Build successful!
echo.

echo 🏃 Running pipeline with tests only (skip build)...
echo Base URL: http://localhost:3000
echo Project Path: C:\Users\omars\workspace\musafirgo\musafirgo-web-service
echo.

musafirgo-web-pipeline.exe http://localhost:3000 --skip-init --skip-data-load

echo.
echo 📊 Tests pipeline completed!
echo 📋 Check the generated HTML report for detailed results.
pause
