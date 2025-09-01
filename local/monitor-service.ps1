#!/usr/bin/env pwsh

Write-Host "📊 Monitoring Continu - Itinerary Service" -ForegroundColor Green
Write-Host "Appuyez sur Ctrl+C pour arrêter" -ForegroundColor Yellow
Write-Host ""

# Configuration
$BASE_URL = "http://localhost:8080"
$CHECK_INTERVAL = 30  # secondes
$TIMEOUT = 10

# Variables de suivi
$startTime = Get-Date
$totalChecks = 0
$successfulChecks = 0
$failedChecks = 0

# Fonction de vérification
function Test-ServiceHealth {
    try {
        $response = Invoke-WebRequest -Uri "$BASE_URL/actuator/health" -TimeoutSec $TIMEOUT -ErrorAction Stop
        
        if ($response.StatusCode -eq 200) {
            try {
                $healthData = $response.Content | ConvertFrom-Json
                $status = $healthData.status
                $dbStatus = if ($healthData.components.db) { $healthData.components.db.status } else { "UNKNOWN" }
                
                return @{
                    Success = $true
                    Status = $status
                    DbStatus = $dbStatus
                    ResponseTime = $response.BaseResponse.ResponseTime
                }
            } catch {
                return @{
                    Success = $true
                    Status = "UP"
                    DbStatus = "UNKNOWN"
                    ResponseTime = $response.BaseResponse.ResponseTime
                }
            }
        } else {
            return @{
                Success = $false
                Status = "HTTP $($response.StatusCode)"
                DbStatus = "UNKNOWN"
                ResponseTime = $null
            }
        }
    } catch {
        return @{
            Success = $false
            Status = "ERROR"
            DbStatus = "UNKNOWN"
            ResponseTime = $null
            Error = $_.Exception.Message
        }
    }
}

# Fonction d'affichage des statistiques
function Show-Statistics {
    $elapsed = (Get-Date) - $startTime
    $successRate = if ($totalChecks -gt 0) { [math]::Round(($successfulChecks / $totalChecks) * 100, 2) } else { 0 }
    
    Write-Host ""
    Write-Host "📈 STATISTIQUES" -ForegroundColor Cyan
    Write-Host "================" -ForegroundColor Cyan
    Write-Host "Temps écoulé: $($elapsed.ToString('hh\:mm\:ss'))" -ForegroundColor White
    Write-Host "Vérifications totales: $totalChecks" -ForegroundColor White
    Write-Host "Succès: $successfulChecks" -ForegroundColor Green
    Write-Host "Échecs: $failedChecks" -ForegroundColor Red
    Write-Host "Taux de succès: $successRate%" -ForegroundColor White
    Write-Host ""
}

# Gestion de l'interruption
$null = Register-EngineEvent PowerShell.Exiting -Action {
    Show-Statistics
    Write-Host "Monitoring arrêté." -ForegroundColor Yellow
}

# Boucle principale de monitoring
try {
    while ($true) {
        $totalChecks++
        $currentTime = Get-Date -Format "HH:mm:ss"
        
        Write-Host "[$currentTime] Vérification #$totalChecks..." -ForegroundColor Cyan
        
        $health = Test-ServiceHealth
        
        if ($health.Success) {
            $successfulChecks++
            $statusColor = if ($health.Status -eq "UP") { "Green" } else { "Yellow" }
            $dbColor = if ($health.DbStatus -eq "UP") { "Green" } else { "Red" }
            
            Write-Host "  ✅ Service: $($health.Status)" -ForegroundColor $statusColor
            Write-Host "  🗄️  Database: $($health.DbStatus)" -ForegroundColor $dbColor
            
            if ($health.ResponseTime) {
                Write-Host "  ⏱️  Temps de réponse: $($health.ResponseTime.TotalMilliseconds)ms" -ForegroundColor White
            }
        } else {
            $failedChecks++
            Write-Host "  ❌ Service: $($health.Status)" -ForegroundColor Red
            
            if ($health.Error) {
                Write-Host "  🔍 Erreur: $($health.Error)" -ForegroundColor Red
            }
        }
        
        Write-Host ""
        
        # Attendre avant la prochaine vérification
        Start-Sleep -Seconds $CHECK_INTERVAL
    }
} catch {
    Write-Host "Erreur dans le monitoring: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    Show-Statistics
}
