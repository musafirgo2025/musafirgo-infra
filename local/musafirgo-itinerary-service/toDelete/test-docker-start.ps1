# Test Docker Auto-Start Functionality
Write-Host "=== Test Docker Auto-Start ===" -ForegroundColor Cyan

# Vérifier si Docker est en cours d'exécution
Write-Host "🔍 Checking Docker status..." -ForegroundColor Yellow
$dockerInfo = docker info 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Docker is already running" -ForegroundColor Green
    exit 0
} else {
    Write-Host "⚠️  Docker is not running" -ForegroundColor Yellow
}

# Essayer de démarrer Docker Desktop
Write-Host "🚀 Attempting to start Docker Desktop..." -ForegroundColor Yellow
Start-Process "Docker Desktop" -ErrorAction SilentlyContinue
Write-Host "📱 Docker Desktop launch command sent" -ForegroundColor Green

# Attendre que Docker soit prêt
Write-Host "⏳ Waiting for Docker to start..." -ForegroundColor Yellow
$maxAttempts = 30
$attempt = 0

while ($attempt -lt $maxAttempts) {
    $attempt++
    Start-Sleep -Seconds 2
    
    $dockerInfo = docker info 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Docker started successfully after $($attempt * 2) seconds!" -ForegroundColor Green
        Write-Host "🐳 Docker is now ready to use" -ForegroundColor Green
        exit 0
    }
    
    Write-Host "⏳ Still waiting... ($attempt/$maxAttempts)" -ForegroundColor Yellow
}

Write-Host "❌ Docker did not start within $($maxAttempts * 2) seconds" -ForegroundColor Red
Write-Host "💡 Please start Docker Desktop manually and try again" -ForegroundColor Yellow
exit 1