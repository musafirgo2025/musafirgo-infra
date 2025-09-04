# MusafirGO Itinerary Service - Pipeline Optimisée avec UUIDs Prédéfinis
# Cette version utilise des UUIDs fixes du dump data pour éliminer les problèmes de résolution dynamique

param(
    [string]$BaseUrl = "http://localhost:8080",
    [switch]$SkipInit = $false,
    [switch]$SkipDataLoad = $false,
    [switch]$SkipTests = $false
)

# Import Excel module
try {
    Import-Module ImportExcel -ErrorAction Stop
    Write-Host "ImportExcel module loaded successfully" -ForegroundColor Green
}
catch {
    Write-Host "Installing ImportExcel module..." -ForegroundColor Yellow
    try {
        Install-Module -Name ImportExcel -Force -Scope CurrentUser -AllowClobber
        Import-Module ImportExcel
        Write-Host "ImportExcel module installed and loaded successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to install ImportExcel module. Will use CSV export instead." -ForegroundColor Yellow
        $Global:UseCSV = $true
    }
}

# UUIDs prédéfinis du dump data
$Global:TestUUIDs = @{
    Casablanca = "11111111-1111-1111-1111-111111111111"
    Marrakech = "22222222-2222-2222-2222-222222222222"
    Fes = "33333333-3333-3333-3333-333333333333"
    Chefchaouen = "44444444-4444-4444-4444-444444444444"
    Essaouira = "55555555-5555-5555-5555-555555555555"
    NonExistent = "99999999-9999-9999-9999-999999999999"  # Pour les tests d'erreur
}

# Global variables for pipeline results
$Global:PipelineResults = @{
    StartTime = Get-Date
    Steps = @{}
    TotalDuration = 0
    Success = $false
}

# Global variable for Excel test results
$Global:ExcelTestResults = @()

# Logging function
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "SUCCESS" { "Green" }
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        default { "White" }
    }
    
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

# Step 1: Check prerequisites
function Step-CheckPrerequisites {
    Write-Log "Checking prerequisites..." "INFO"
    
    $prerequisites = @{
        Docker = $false
        DockerCompose = $false
        PowerShell = $false
    }
    
    # Check Docker
    try {
        $dockerVersion = docker --version 2>$null
        if ($dockerVersion) {
            $prerequisites.Docker = $true
            Write-Log "Docker: OK" "SUCCESS"
        }
    }
    catch {
        Write-Log "Docker: NOT FOUND" "ERROR"
    }
    
    # Check Docker Compose
    try {
        $composeVersion = docker-compose --version 2>$null
        if ($composeVersion) {
            $prerequisites.DockerCompose = $true
            Write-Log "Docker Compose: OK" "SUCCESS"
        }
    }
    catch {
        Write-Log "Docker Compose: NOT FOUND" "ERROR"
    }
    
    # Check PowerShell version
    if ($PSVersionTable.PSVersion.Major -ge 5) {
        $prerequisites.PowerShell = $true
        Write-Log "PowerShell: OK (v$($PSVersionTable.PSVersion.ToString()))" "SUCCESS"
    }
    else {
        Write-Log "PowerShell: VERSION TOO OLD (v$($PSVersionTable.PSVersion.ToString()))" "ERROR"
    }
    
    $Global:PipelineResults.Steps.Prerequisites = $prerequisites
    
    if ($prerequisites.Docker -and $prerequisites.DockerCompose -and $prerequisites.PowerShell) {
        Write-Log "All prerequisites met!" "SUCCESS"
        return $true
    }
    else {
        Write-Log "Some prerequisites are missing!" "ERROR"
        return $false
    }
}

# Step 2: Initialize environment
function Step-InitializeEnvironment {
    if ($SkipInit) {
        Write-Log "Skipping environment initialization" "WARNING"
        return $true
    }
    
    Write-Log "Initializing environment..." "INFO"
    
    try {
        # Stop existing containers
        Write-Log "Stopping existing containers..." "INFO"
        docker-compose down 2>$null
        
        # Start services
        Write-Log "Starting services..." "INFO"
        docker-compose up -d
        
        # Wait for services to be ready
        Write-Log "Waiting for services to be ready..." "INFO"
        $maxWait = 60
        $waited = 0
        
        do {
            Start-Sleep -Seconds 2
            $waited += 2
            
            try {
                $healthResponse = Invoke-WebRequest -Uri "$BaseUrl/actuator/health" -Method GET -UseBasicParsing -TimeoutSec 5
                if ($healthResponse.StatusCode -eq 200) {
                    Write-Log "Services are ready!" "SUCCESS"
                    break
                }
            }
            catch {
                # Continue waiting
            }
            
            if ($waited -ge $maxWait) {
                Write-Log "Services did not start within $maxWait seconds" "ERROR"
                return $false
            }
        } while ($true)
        
        $Global:PipelineResults.Steps.Initialization = @{ Success = $true }
        return $true
    }
    catch {
        Write-Log "Failed to initialize environment: $($_.Exception.Message)" "ERROR"
        $Global:PipelineResults.Steps.Initialization = @{ Success = $false; Error = $_.Exception.Message }
        return $false
    }
}

# Step 3: Load test data
function Step-LoadTestData {
    if ($SkipDataLoad) {
        Write-Log "Skipping test data loading" "WARNING"
        return $true
    }
    
    Write-Log "Loading test data..." "INFO"
    
    try {
        # Copy dump data to container
        Write-Log "Copying dump data to container..." "INFO"
        docker cp "data/dump-data.sql" musafirgo-itinerary-postgres:/tmp/dump-data.sql
        
        # Execute dump data
        Write-Log "Executing dump data..." "INFO"
        docker exec musafirgo-itinerary-postgres psql -U musafirgo_user -d musafirgo_dev -f /tmp/dump-data.sql
        
        Write-Log "Test data loaded successfully!" "SUCCESS"
        $Global:PipelineResults.Steps.DataLoad = @{ Success = $true }
        return $true
    }
    catch {
        Write-Log "Failed to load test data: $($_.Exception.Message)" "ERROR"
        $Global:PipelineResults.Steps.DataLoad = @{ Success = $false; Error = $_.Exception.Message }
        return $false
    }
}

# Step 4: Run API tests
function Step-RunAPITests {
    if ($SkipTests) {
        Write-Log "Skipping API tests" "WARNING"
        return $true
    }
    
    Write-Log "Running API tests..." "INFO"
    
    $testResults = @{
        Total = 0
        Passed = 0
        Failed = 0
        Tests = @()
        Performance = @()
    }
    
    # Headers par défaut pour forcer JSON
    $defaultHeaders = @{
        'Accept' = 'application/json'
        'Content-Type' = 'application/json'
    }
    
    # Test 1: Health Check
    Write-Log "Test 1: Health Check" "INFO"
    $testResults.Total++
    $startTime = Get-Date
    
    try {
        $response = Invoke-WebRequest -Uri "$BaseUrl/actuator/health" -Method GET -UseBasicParsing -Headers $defaultHeaders
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMilliseconds
        
        if ($response.StatusCode -eq 200) {
            $testResults.Passed++
            $status = "OK"
            Write-Log "Health Check: PASSED" "SUCCESS"
        }
        else {
            $testResults.Failed++
            $status = "NOK"
            Write-Log "Health Check: FAILED (Status: $($response.StatusCode))" "ERROR"
        }
    }
    catch {
        $testResults.Failed++
        $status = "NOK"
        Write-Log "Health Check: FAILED ($($_.Exception.Message))" "ERROR"
        $duration = 0
    }
    
    $testResults.Tests += @{
        Test = "Health Check"
        Endpoint = "/actuator/health"
        Method = "GET"
        Status = $status
        ResponseTime = $duration
        ExpectedStatus = 200
        ActualStatus = if ($response) { $response.StatusCode } else { "ERROR" }
    }
    
    $testResults.Performance += @{
        Endpoint = "/actuator/health"
        ResponseTime = $duration
    }
    
    # Test 2: GET /api/itineraries (List all itineraries)
    Write-Log "Test 2: GET /api/itineraries" "INFO"
    $testResults.Total++
    $startTime = Get-Date
    
    try {
        $response = Invoke-WebRequest -Uri "$BaseUrl/api/itineraries" -Method GET -UseBasicParsing -Headers $defaultHeaders
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMilliseconds
        
        if ($response.StatusCode -eq 200) {
            $testResults.Passed++
            $status = "OK"
            Write-Log "GET /api/itineraries: PASSED" "SUCCESS"
        }
        else {
            $testResults.Failed++
            $status = "NOK"
            Write-Log "GET /api/itineraries: FAILED (Status: $($response.StatusCode))" "ERROR"
        }
    }
    catch {
        $testResults.Failed++
        $status = "NOK"
        Write-Log "GET /api/itineraries: FAILED ($($_.Exception.Message))" "ERROR"
        $duration = 0
    }
    
    $testResults.Tests += @{
        Test = "List All Itineraries"
        Endpoint = "/api/itineraries"
        Method = "GET"
        Status = $status
        ResponseTime = $duration
        ExpectedStatus = 200
        ActualStatus = if ($response) { $response.StatusCode } else { "ERROR" }
    }
    
    $testResults.Performance += @{
        Endpoint = "/api/itineraries"
        ResponseTime = $duration
    }
    
    # Test 3: GET /api/itineraries/{id} (Get specific itinerary) - Utilise UUID prédéfini
    Write-Log "Test 3: GET /api/itineraries/{id} (Casablanca)" "INFO"
    $testResults.Total++
    $startTime = Get-Date
    $testId = $Global:TestUUIDs.Casablanca
    
    try {
        $response = Invoke-WebRequest -Uri "$BaseUrl/api/itineraries/$testId" -Method GET -UseBasicParsing -Headers $defaultHeaders
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMilliseconds
        
        if ($response.StatusCode -eq 200) {
            $testResults.Passed++
            $status = "OK"
            Write-Log "GET /api/itineraries/${testId}: PASSED" "SUCCESS"
        }
        else {
            $testResults.Failed++
            $status = "NOK"
            Write-Log "GET /api/itineraries/${testId}: FAILED (Status: $($response.StatusCode))" "ERROR"
        }
    }
    catch {
        $testResults.Failed++
        $status = "NOK"
        Write-Log "GET /api/itineraries/${testId}: FAILED ($($_.Exception.Message))" "ERROR"
        $duration = 0
    }
    
    $testResults.Tests += @{
        Test = "Get Specific Itinerary (Casablanca)"
        Endpoint = "/api/itineraries/$testId"
        Method = "GET"
        Status = $status
        ResponseTime = $duration
        ExpectedStatus = 200
        ActualStatus = if ($response) { $response.StatusCode } else { "ERROR" }
    }
    
    $testResults.Performance += @{
        Endpoint = "/api/itineraries/$testId"
        ResponseTime = $duration
    }
    
    # Test 4: GET /api/itineraries/{id} (Get specific itinerary) - Marrakech
    Write-Log "Test 4: GET /api/itineraries/{id} (Marrakech)" "INFO"
    $testResults.Total++
    $startTime = Get-Date
    $testId = $Global:TestUUIDs.Marrakech
    
    try {
        $response = Invoke-WebRequest -Uri "$BaseUrl/api/itineraries/$testId" -Method GET -UseBasicParsing -Headers $defaultHeaders
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMilliseconds
        
        if ($response.StatusCode -eq 200) {
            $testResults.Passed++
            $status = "OK"
            Write-Log "GET /api/itineraries/${testId}: PASSED" "SUCCESS"
        }
        else {
            $testResults.Failed++
            $status = "NOK"
            Write-Log "GET /api/itineraries/${testId}: FAILED (Status: $($response.StatusCode))" "ERROR"
        }
    }
    catch {
        $testResults.Failed++
        $status = "NOK"
        Write-Log "GET /api/itineraries/${testId}: FAILED ($($_.Exception.Message))" "ERROR"
        $duration = 0
    }
    
    $testResults.Tests += @{
        Test = "Get Specific Itinerary (Marrakech)"
        Endpoint = "/api/itineraries/$testId"
        Method = "GET"
        Status = $status
        ResponseTime = $duration
        ExpectedStatus = 200
        ActualStatus = if ($response) { $response.StatusCode } else { "ERROR" }
    }
    
    $testResults.Performance += @{
        Endpoint = "/api/itineraries/$testId"
        ResponseTime = $duration
    }
    
    # Test 5: GET /api/itineraries/{id} (Non-existent itinerary) - Test d'erreur
    Write-Log "Test 5: GET /api/itineraries/{id} (Non-existent)" "INFO"
    $testResults.Total++
    $startTime = Get-Date
    $testId = $Global:TestUUIDs.NonExistent
    
    try {
        $response = Invoke-WebRequest -Uri "$BaseUrl/api/itineraries/$testId" -Method GET -UseBasicParsing -Headers $defaultHeaders
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMilliseconds
        
        # Pour un UUID non existant, on s'attend à une erreur 404
        if ($response.StatusCode -eq 404) {
            $testResults.Passed++
            $status = "OK"
            Write-Log "GET /api/itineraries/${testId}: PASSED (404 as expected)" "SUCCESS"
        }
        else {
            $testResults.Failed++
            $status = "NOK"
            Write-Log "GET /api/itineraries/${testId}: FAILED (Expected 404, got $($response.StatusCode))" "ERROR"
        }
    }
    catch {
        # Si c'est une erreur 404, c'est attendu
        if ($_.Exception.Response.StatusCode -eq 404) {
            $testResults.Passed++
            $status = "OK"
            Write-Log "GET /api/itineraries/${testId}: PASSED (404 as expected)" "SUCCESS"
        }
        else {
            $testResults.Failed++
            $status = "NOK"
            Write-Log "GET /api/itineraries/${testId}: FAILED ($($_.Exception.Message))" "ERROR"
        }
        $duration = 0
    }
    
    $testResults.Tests += @{
        Test = "Get Non-existent Itinerary"
        Endpoint = "/api/itineraries/$testId"
        Method = "GET"
        Status = $status
        ResponseTime = $duration
        ExpectedStatus = 404
        ActualStatus = if ($response) { $response.StatusCode } else { "ERROR" }
    }
    
    $testResults.Performance += @{
        Endpoint = "/api/itineraries/$testId"
        ResponseTime = $duration
    }
    
    # Test 6: POST /api/itineraries (Create new itinerary)
    Write-Log "Test 6: POST /api/itineraries" "INFO"
    $testResults.Total++
    $startTime = Get-Date
    
    $newItinerary = @{
        city = "Test City"
    } | ConvertTo-Json
    
    try {
        $response = Invoke-WebRequest -Uri "$BaseUrl/api/itineraries" -Method POST -UseBasicParsing -Headers $defaultHeaders -Body $newItinerary
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMilliseconds
        
        if ($response.StatusCode -eq 201) {
            $testResults.Passed++
            $status = "OK"
            Write-Log "POST /api/itineraries: PASSED" "SUCCESS"
        }
        else {
            $testResults.Failed++
            $status = "NOK"
            Write-Log "POST /api/itineraries: FAILED (Status: $($response.StatusCode))" "ERROR"
        }
    }
    catch {
        $testResults.Failed++
        $status = "NOK"
        Write-Log "POST /api/itineraries: FAILED ($($_.Exception.Message))" "ERROR"
        $duration = 0
    }
    
    $testResults.Tests += @{
        Test = "Create New Itinerary"
        Endpoint = "/api/itineraries"
        Method = "POST"
        Status = $status
        ResponseTime = $duration
        ExpectedStatus = 201
        ActualStatus = if ($response) { $response.StatusCode } else { "ERROR" }
    }
    
    $testResults.Performance += @{
        Endpoint = "/api/itineraries"
        ResponseTime = $duration
    }
    
    # Test 7: PUT /api/itineraries/{id} (Update itinerary) - Utilise UUID prédéfini
    Write-Log "Test 7: PUT /api/itineraries/{id} (Fès)" "INFO"
    $testResults.Total++
    $startTime = Get-Date
    $testId = $Global:TestUUIDs.Fes
    
    $updatedItinerary = @{
        city = "Fès Updated"
    } | ConvertTo-Json
    
    try {
        $response = Invoke-WebRequest -Uri "$BaseUrl/api/itineraries/$testId" -Method PUT -UseBasicParsing -Headers $defaultHeaders -Body $updatedItinerary
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMilliseconds
        
        if ($response.StatusCode -eq 200) {
            $testResults.Passed++
            $status = "OK"
            Write-Log "PUT /api/itineraries/$testId: PASSED" "SUCCESS"
        }
        else {
            $testResults.Failed++
            $status = "NOK"
            Write-Log "PUT /api/itineraries/$testId: FAILED (Status: $($response.StatusCode))" "ERROR"
        }
    }
    catch {
        $testResults.Failed++
        $status = "NOK"
        Write-Log "PUT /api/itineraries/$testId: FAILED ($($_.Exception.Message))" "ERROR"
        $duration = 0
    }
    
    $testResults.Tests += @{
        Test = "Update Itinerary (Fès)"
        Endpoint = "/api/itineraries/$testId"
        Method = "PUT"
        Status = $status
        ResponseTime = $duration
        ExpectedStatus = 200
        ActualStatus = if ($response) { $response.StatusCode } else { "ERROR" }
    }
    
    $testResults.Performance += @{
        Endpoint = "/api/itineraries/$testId"
        ResponseTime = $duration
    }
    
    # Test 8: DELETE /api/itineraries/{id} (Delete itinerary) - Utilise UUID prédéfini
    Write-Log "Test 8: DELETE /api/itineraries/{id} (Chefchaouen)" "INFO"
    $testResults.Total++
    $startTime = Get-Date
    $testId = $Global:TestUUIDs.Chefchaouen
    
    try {
        $response = Invoke-WebRequest -Uri "$BaseUrl/api/itineraries/$testId" -Method DELETE -UseBasicParsing -Headers $defaultHeaders
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMilliseconds
        
        if ($response.StatusCode -eq 200) {
            $testResults.Passed++
            $status = "OK"
            Write-Log "DELETE /api/itineraries/$testId: PASSED" "SUCCESS"
        }
        else {
            $testResults.Failed++
            $status = "NOK"
            Write-Log "DELETE /api/itineraries/$testId: FAILED (Status: $($response.StatusCode))" "ERROR"
        }
    }
    catch {
        $testResults.Failed++
        $status = "NOK"
        Write-Log "DELETE /api/itineraries/$testId: FAILED ($($_.Exception.Message))" "ERROR"
        $duration = 0
    }
    
    $testResults.Tests += @{
        Test = "Delete Itinerary (Chefchaouen)"
        Endpoint = "/api/itineraries/$testId"
        Method = "DELETE"
        Status = $status
        ResponseTime = $duration
        ExpectedStatus = 200
        ActualStatus = if ($response) { $response.StatusCode } else { "ERROR" }
    }
    
    $testResults.Performance += @{
        Endpoint = "/api/itineraries/$testId"
        ResponseTime = $duration
    }
    
    # Test 9: GET /api/itineraries?city=... (Search by city)
    Write-Log "Test 9: GET /api/itineraries?city=Casablanca" "INFO"
    $testResults.Total++
    $startTime = Get-Date
    
    try {
        $response = Invoke-WebRequest -Uri "$BaseUrl/api/itineraries?city=Casablanca" -Method GET -UseBasicParsing -Headers $defaultHeaders
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMilliseconds
        
        if ($response.StatusCode -eq 200) {
            $testResults.Passed++
            $status = "OK"
            Write-Log "GET /api/itineraries?city=Casablanca: PASSED" "SUCCESS"
        }
        else {
            $testResults.Failed++
            $status = "NOK"
            Write-Log "GET /api/itineraries?city=Casablanca: FAILED (Status: $($response.StatusCode))" "ERROR"
        }
    }
    catch {
        $testResults.Failed++
        $status = "NOK"
        Write-Log "GET /api/itineraries?city=Casablanca: FAILED ($($_.Exception.Message))" "ERROR"
        $duration = 0
    }
    
    $testResults.Tests += @{
        Test = "Search Itineraries by City"
        Endpoint = "/api/itineraries?city=Casablanca"
        Method = "GET"
        Status = $status
        ResponseTime = $duration
        ExpectedStatus = 200
        ActualStatus = if ($response) { $response.StatusCode } else { "ERROR" }
    }
    
    $testResults.Performance += @{
        Endpoint = "/api/itineraries?city=Casablanca"
        ResponseTime = $duration
    }
    
    # Test 10: GET /api/v1/itineraries/{id}/media (Get media for itinerary)
    Write-Log "Test 10: GET /api/v1/itineraries/{id}/media (Essaouira)" "INFO"
    $testResults.Total++
    $startTime = Get-Date
    $testId = $Global:TestUUIDs.Essaouira
    
    try {
        $response = Invoke-WebRequest -Uri "$BaseUrl/api/v1/itineraries/$testId/media" -Method GET -UseBasicParsing -Headers $defaultHeaders
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMilliseconds
        
        if ($response.StatusCode -eq 200) {
            $testResults.Passed++
            $status = "OK"
            Write-Log "GET /api/v1/itineraries/$testId/media: PASSED" "SUCCESS"
        }
        else {
            $testResults.Failed++
            $status = "NOK"
            Write-Log "GET /api/v1/itineraries/$testId/media: FAILED (Status: $($response.StatusCode))" "ERROR"
        }
    }
    catch {
        $testResults.Failed++
        $status = "NOK"
        Write-Log "GET /api/v1/itineraries/$testId/media: FAILED ($($_.Exception.Message))" "ERROR"
        $duration = 0
    }
    
    $testResults.Tests += @{
        Test = "Get Media for Itinerary (Essaouira)"
        Endpoint = "/api/v1/itineraries/$testId/media"
        Method = "GET"
        Status = $status
        ResponseTime = $duration
        ExpectedStatus = 200
        ActualStatus = if ($response) { $response.StatusCode } else { "ERROR" }
    }
    
    $testResults.Performance += @{
        Endpoint = "/api/v1/itineraries/$testId/media"
        ResponseTime = $duration
    }
    
    # Test 11: GET /v3/api-docs (OpenAPI documentation)
    Write-Log "Test 11: GET /v3/api-docs" "INFO"
    $testResults.Total++
    $startTime = Get-Date
    
    try {
        $response = Invoke-WebRequest -Uri "$BaseUrl/v3/api-docs" -Method GET -UseBasicParsing -Headers $defaultHeaders
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMilliseconds
        
        if ($response.StatusCode -eq 200) {
            $testResults.Passed++
            $status = "OK"
            Write-Log "GET /v3/api-docs: PASSED" "SUCCESS"
        }
        else {
            $testResults.Failed++
            $status = "NOK"
            Write-Log "GET /v3/api-docs: FAILED (Status: $($response.StatusCode))" "ERROR"
        }
    }
    catch {
        $testResults.Failed++
        $status = "NOK"
        Write-Log "GET /v3/api-docs: FAILED ($($_.Exception.Message))" "ERROR"
        $duration = 0
    }
    
    $testResults.Tests += @{
        Test = "OpenAPI Documentation"
        Endpoint = "/v3/api-docs"
        Method = "GET"
        Status = $status
        ResponseTime = $duration
        ExpectedStatus = 200
        ActualStatus = if ($response) { $response.StatusCode } else { "ERROR" }
    }
    
    $testResults.Performance += @{
        Endpoint = "/v3/api-docs"
        ResponseTime = $duration
    }
    
    # Test 12: GET /swagger-ui/index.html (Swagger UI)
    Write-Log "Test 12: GET /swagger-ui/index.html" "INFO"
    $testResults.Total++
    $startTime = Get-Date
    
    try {
        $response = Invoke-WebRequest -Uri "$BaseUrl/swagger-ui/index.html" -Method GET -UseBasicParsing -Headers $defaultHeaders
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMilliseconds
        
        if ($response.StatusCode -eq 200) {
            $testResults.Passed++
            $status = "OK"
            Write-Log "GET /swagger-ui/index.html: PASSED" "SUCCESS"
        }
        else {
            $testResults.Failed++
            $status = "NOK"
            Write-Log "GET /swagger-ui/index.html: FAILED (Status: $($response.StatusCode))" "ERROR"
        }
    }
    catch {
        $testResults.Failed++
        $status = "NOK"
        Write-Log "GET /swagger-ui/index.html: FAILED ($($_.Exception.Message))" "ERROR"
        $duration = 0
    }
    
    $testResults.Tests += @{
        Test = "Swagger UI"
        Endpoint = "/swagger-ui/index.html"
        Method = "GET"
        Status = $status
        ResponseTime = $duration
        ExpectedStatus = 200
        ActualStatus = if ($response) { $response.StatusCode } else { "ERROR" }
    }
    
    $testResults.Performance += @{
        Endpoint = "/swagger-ui/index.html"
        ResponseTime = $duration
    }
    
    # Calculer les métriques de performance
    $avgResponseTime = if ($testResults.Performance.Count -gt 0) { 
        ($testResults.Performance | Measure-Object -Property ResponseTime -Average).Average 
    } else { 0 }
    
    $maxResponseTime = if ($testResults.Performance.Count -gt 0) { 
        ($testResults.Performance | Measure-Object -Property ResponseTime -Maximum).Maximum 
    } else { 0 }
    
    # Afficher les résultats
    Write-Log "API Tests completed!" "SUCCESS"
    Write-Log "Total Tests: $($testResults.Total)" "INFO"
    Write-Log "Passed: $($testResults.Passed)" "SUCCESS"
    Write-Log "Failed: $($testResults.Failed)" "ERROR"
    Write-Log "Success Rate: $([math]::Round(($testResults.Passed / $testResults.Total) * 100, 2))%" "INFO"
    Write-Log "Average Response Time: $([math]::Round($avgResponseTime, 2)) ms" "INFO"
    Write-Log "Max Response Time: $([math]::Round($maxResponseTime, 2)) ms" "INFO"
    
    # Stocker les résultats pour Excel
    $Global:ExcelTestResults = $testResults.Tests
    
    $Global:PipelineResults.Steps.APITests = $testResults
    return $testResults.Passed -eq $testResults.Total
}

# Step 5: Generate Excel report
function Step-GenerateExcelReport {
    Write-Log "Generating Excel report..." "INFO"
    
    try {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $excelFile = "MusafirGO_Pipeline_Report_$timestamp.xlsx"
        
        # Nettoyer les anciens rapports
        Get-ChildItem -Path "." -Filter "MusafirGO_Pipeline_Report_*.xlsx" | Remove-Item -Force
        Get-ChildItem -Path "." -Filter "MusafirGO_Pipeline_Report_*.csv" | Remove-Item -Force
        
        if ($Global:UseCSV) {
            # Générer un rapport CSV si Excel n'est pas disponible
            $csvFile = "MusafirGO_Pipeline_Report_$timestamp.csv"
            $Global:ExcelTestResults | Export-Csv -Path $csvFile -NoTypeInformation
            Write-Log "CSV report generated: $csvFile" "SUCCESS"
        }
        else {
            # Générer un rapport Excel avec formatage conditionnel
            $excel = New-Object -ComObject Excel.Application
            $excel.Visible = $false
            $workbook = $excel.Workbooks.Add()
            
            # Feuille 1: API Tests
            $worksheet1 = $workbook.Worksheets.Item(1)
            $worksheet1.Name = "API Tests"
            
            # En-têtes
            $headers = @("Test", "Endpoint", "Method", "Status", "Response Time (ms)", "Expected Status", "Actual Status")
            for ($i = 0; $i -lt $headers.Count; $i++) {
                $worksheet1.Cells.Item(1, $i + 1) = $headers[$i]
                $worksheet1.Cells.Item(1, $i + 1).Font.Bold = $true
            }
            
            # Données
            $row = 2
            foreach ($test in $Global:ExcelTestResults) {
                $worksheet1.Cells.Item($row, 1) = $test.Test
                $worksheet1.Cells.Item($row, 2) = $test.Endpoint
                $worksheet1.Cells.Item($row, 3) = $test.Method
                $worksheet1.Cells.Item($row, 4) = $test.Status
                $worksheet1.Cells.Item($row, 5) = $test.ResponseTime
                $worksheet1.Cells.Item($row, 6) = $test.ExpectedStatus
                $worksheet1.Cells.Item($row, 7) = $test.ActualStatus
                
                # Formatage conditionnel pour le statut
                if ($test.Status -eq "OK") {
                    $worksheet1.Cells.Item($row, 4).Interior.Color = 0x00FF00  # Vert
                } else {
                    $worksheet1.Cells.Item($row, 4).Interior.Color = 0x0000FF  # Rouge
                }
                
                $row++
            }
            
            # Auto-fit des colonnes
            $worksheet1.Columns.AutoFit() | Out-Null
            
            # Feuille 2: Summary
            $worksheet2 = $workbook.Worksheets.Add()
            $worksheet2.Name = "Summary"
            
            $worksheet2.Cells.Item(1, 1) = "MusafirGO Pipeline Report"
            $worksheet2.Cells.Item(1, 1).Font.Bold = $true
            $worksheet2.Cells.Item(1, 1).Font.Size = 16
            
            $worksheet2.Cells.Item(3, 1) = "Total Tests:"
            $worksheet2.Cells.Item(3, 2) = $Global:PipelineResults.Steps.APITests.Total
            $worksheet2.Cells.Item(4, 1) = "Passed:"
            $worksheet2.Cells.Item(4, 2) = $Global:PipelineResults.Steps.APITests.Passed
            $worksheet2.Cells.Item(5, 1) = "Failed:"
            $worksheet2.Cells.Item(5, 2) = $Global:PipelineResults.Steps.APITests.Failed
            $worksheet2.Cells.Item(6, 1) = "Success Rate:"
            $worksheet2.Cells.Item(6, 2) = "$([math]::Round(($Global:PipelineResults.Steps.APITests.Passed / $Global:PipelineResults.Steps.APITests.Total) * 100, 2))%"
            
            # Feuille 3: Performance
            $worksheet3 = $workbook.Worksheets.Add()
            $worksheet3.Name = "Performance"
            
            $worksheet3.Cells.Item(1, 1) = "Endpoint"
            $worksheet3.Cells.Item(1, 2) = "Response Time (ms)"
            $worksheet3.Cells.Item(1, 1).Font.Bold = $true
            $worksheet3.Cells.Item(1, 2).Font.Bold = $true
            
            $row = 2
            foreach ($perf in $Global:PipelineResults.Steps.APITests.Performance) {
                $worksheet3.Cells.Item($row, 1) = $perf.Endpoint
                $worksheet3.Cells.Item($row, 2) = $perf.ResponseTime
                $row++
            }
            
            $worksheet3.Columns.AutoFit() | Out-Null
            
            # Sauvegarder le fichier
            $workbook.SaveAs((Resolve-Path ".").Path + "\" + $excelFile)
            $workbook.Close()
            $excel.Quit()
            
            Write-Log "Excel report generated: $excelFile" "SUCCESS"
        }
        
        $Global:PipelineResults.Steps.ExcelReport = @{ Success = $true; File = if ($Global:UseCSV) { $csvFile } else { $excelFile } }
        return $true
    }
    catch {
        Write-Log "Failed to generate Excel report: $($_.Exception.Message)" "ERROR"
        $Global:PipelineResults.Steps.ExcelReport = @{ Success = $false; Error = $_.Exception.Message }
        return $false
    }
}

# Main pipeline execution
function Start-Pipeline {
    Write-Log "Starting MusafirGO Pipeline (Optimized with Predefined UUIDs)" "INFO"
    Write-Log "UUIDs utilisés:" "INFO"
    Write-Log "  Casablanca: $($Global:TestUUIDs.Casablanca)" "INFO"
    Write-Log "  Marrakech:  $($Global:TestUUIDs.Marrakech)" "INFO"
    Write-Log "  Fès:        $($Global:TestUUIDs.Fes)" "INFO"
    Write-Log "  Chefchaouen: $($Global:TestUUIDs.Chefchaouen)" "INFO"
    Write-Log "  Essaouira:  $($Global:TestUUIDs.Essaouira)" "INFO"
    Write-Log "  Non-existent: $($Global:TestUUIDs.NonExistent)" "INFO"
    
    $startTime = Get-Date
    
    # Step 1: Check prerequisites
    if (-not (Step-CheckPrerequisites)) {
        Write-Log "Pipeline failed at prerequisites check" "ERROR"
        return $false
    }
    
    # Step 2: Initialize environment
    if (-not (Step-InitializeEnvironment)) {
        Write-Log "Pipeline failed at environment initialization" "ERROR"
        return $false
    }
    
    # Step 3: Load test data
    if (-not (Step-LoadTestData)) {
        Write-Log "Pipeline failed at test data loading" "ERROR"
        return $false
    }
    
    # Step 4: Run API tests
    if (-not (Step-RunAPITests)) {
        Write-Log "Pipeline failed at API tests" "ERROR"
        return $false
    }
    
    # Step 5: Generate Excel report
    if (-not (Step-GenerateExcelReport)) {
        Write-Log "Pipeline failed at Excel report generation" "ERROR"
        return $false
    }
    
    $endTime = Get-Date
    $Global:PipelineResults.TotalDuration = ($endTime - $startTime).TotalSeconds
    $Global:PipelineResults.Success = $true
    
    Write-Log "Pipeline completed successfully!" "SUCCESS"
    Write-Log "Total duration: $([math]::Round($Global:PipelineResults.TotalDuration, 2)) seconds" "INFO"
    
    return $true
}

# Execute pipeline
Start-Pipeline
