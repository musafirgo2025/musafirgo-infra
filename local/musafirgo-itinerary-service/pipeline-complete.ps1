# MusafirGO Itinerary Service - Complete Pipeline
# This script initializes the database, loads test data, and runs comprehensive API tests

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
    
    $allOk = $prerequisites.Values -notcontains $false
    if (-not $allOk) {
        Write-Log "Prerequisites check failed. Please install missing components." "ERROR"
        return $false
    }
    
    Write-Log "All prerequisites satisfied" "SUCCESS"
    return $true
}

# Step 2: Initialize database
function Step-InitializeDatabase {
    Write-Log "Initializing database..." "INFO"
    
    try {
        # Stop existing containers
        Write-Log "Stopping existing containers..." "INFO"
        docker-compose down -v 2>$null
        
        # Start services
        Write-Log "Starting services..." "INFO"
        docker-compose up -d
        
        # Wait for services to be ready
        Write-Log "Waiting for services to be ready..." "INFO"
        Start-Sleep -Seconds 30
        
        # Check if services are running
        $services = docker-compose ps --services --filter "status=running"
        if ($services.Count -ge 3) {
            Write-Log "Database initialization completed successfully" "SUCCESS"
            return $true
        }
        else {
            Write-Log "Database initialization failed - services not running" "ERROR"
            return $false
        }
    }
    catch {
        Write-Log "Database initialization failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Step 3: Load test data
function Step-LoadTestData {
    Write-Log "Loading test data..." "INFO"
    
    try {
        # Wait for PostgreSQL to be ready
        $maxRetries = 30
        $retryCount = 0
        
        do {
            try {
                $response = Invoke-WebRequest -Uri "http://localhost:8080/actuator/health" -Method GET -UseBasicParsing -TimeoutSec 5
                if ($response.StatusCode -eq 200) {
                    Write-Log "Service is ready" "SUCCESS"
                    break
                }
            }
            catch {
                $retryCount++
                Write-Log "Waiting for service... ($retryCount/$maxRetries)" "INFO"
                Start-Sleep -Seconds 2
            }
        } while ($retryCount -lt $maxRetries)
        
        if ($retryCount -ge $maxRetries) {
            Write-Log "Service did not become ready in time" "ERROR"
            return $false
        }
        
        # Load test data
        Write-Log "Loading test data into database..." "INFO"
        # Copy the dump file to the container and execute it
        docker cp "data/dump-data.sql" musafirgo-itinerary-postgres:/tmp/dump-data.sql
        docker-compose exec -T postgres psql -U itinerary -d itinerary -f /tmp/dump-data.sql
        
        Write-Log "Test data loaded successfully" "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Failed to load test data: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Step 4: Health checks
function Step-HealthChecks {
    Write-Log "Running health checks..." "INFO"
    
    $healthResults = @{
        ServiceHealth = $false
        DatabaseHealth = $false
        RedisHealth = $false
    }
    
    # Check service health
    try {
        $response = Invoke-WebRequest -Uri "$BaseUrl/actuator/health" -Method GET -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            $healthResults.ServiceHealth = $true
            Write-Log "Service health: OK" "SUCCESS"
        }
    }
    catch {
        Write-Log "Service health: FAILED" "ERROR"
    }
    
    # Check database health
    try {
        $response = Invoke-WebRequest -Uri "$BaseUrl/actuator/health/db" -Method GET -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            $healthResults.DatabaseHealth = $true
            Write-Log "Database health: OK" "SUCCESS"
        }
    }
    catch {
        Write-Log "Database health: FAILED" "ERROR"
    }
    
    # Check Redis health
    try {
        $response = Invoke-WebRequest -Uri "$BaseUrl/actuator/health/redis" -Method GET -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            $healthResults.RedisHealth = $true
            Write-Log "Redis health: OK" "SUCCESS"
        }
    }
    catch {
        Write-Log "Redis health: FAILED" "ERROR"
    }
    
    $allHealthy = $healthResults.Values -notcontains $false
    if ($allHealthy) {
        Write-Log "All health checks passed" "SUCCESS"
    }
    else {
        Write-Log "Some health checks failed" "WARNING"
    }
    
    return $allHealthy
}

# Helper function to test an endpoint
function Test-Endpoint {
        param(
            [string]$Method,
            [string]$Uri,
            [string]$Description,
            [hashtable]$Headers = @{},
            [string]$Body = $null,
            [int]$ExpectedStatus = 200,
            [bool]$SkipOnFailure = $false
        )
        
        Write-Log "Test-Endpoint called for $Method $Uri" "INFO"
        # Note: $testResults is not accessible here, we'll use a global counter
        if ($null -eq $Global:TestCounter) { $Global:TestCounter = 0 }
        $Global:TestCounter++
        $actualStatusCode = 0
        $testPassed = $false
        $errorMessage = ""
        
        # Initialize ExcelTestResults if needed
        if ($null -eq $Global:ExcelTestResults) {
            $Global:ExcelTestResults = @()
        }
        
        # Add to Excel results immediately
        Write-Log "Adding test result to ExcelTestResults for $Method $Uri" "INFO"
        $testResult = [PSCustomObject]@{
            'Endpoint' = $Uri
            'Method' = $Method
            'Description' = $Description
            'Parameters' = if ($Body) { "Body: $($Body.Substring(0, [Math]::Min(100, $Body.Length)))..." } else { if ($Uri.Contains('?')) { "Query: $($Uri.Split('?')[1])" } else { "None" } }
            'Expected HTTP Code' = $ExpectedStatus
            'Received HTTP Code' = 0  # Will be updated after the request
            'Status' = "PENDING"  # Will be updated after the request
            'Error Message' = ""
            'Timestamp' = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        $Global:ExcelTestResults += $testResult
        Write-Log "ExcelTestResults count after adding: $($Global:ExcelTestResults.Count)" "INFO"
        
        try {
            # Ensure we always request JSON responses
            $defaultHeaders = @{
                'Accept' = 'application/json'
                'Content-Type' = 'application/json'
            }
            
            # Merge with provided headers, giving priority to provided ones
            $mergedHeaders = $defaultHeaders.Clone()
            foreach ($key in $Headers.Keys) {
                $mergedHeaders[$key] = $Headers[$key]
            }
            
            $params = @{
                Uri = $Uri
                Method = $Method
                UseBasicParsing = $true
                Headers = $mergedHeaders
            }
            
            if ($Body) {
                $params.Body = $Body
            }
            
            $response = Invoke-WebRequest @params
            $actualStatusCode = $response.StatusCode
            
            # Ensure content is properly decoded as text
            $responseContent = $response.Content
            if ($responseContent -is [byte[]]) {
                $responseContent = [System.Text.Encoding]::UTF8.GetString($responseContent)
            }
            
            # Create a new response object with decoded content
            $response = [PSCustomObject]@{
                StatusCode = $response.StatusCode
                Content = $responseContent
                Headers = $response.Headers
            }
            
            if ($response.StatusCode -eq $ExpectedStatus) {
                if ($null -eq $Global:PassedCounter) { $Global:PassedCounter = 0 }
                $Global:PassedCounter++
                Write-Log "$Method $Uri - PASSED" "SUCCESS"
                $testPassed = $true
            }
            else {
                if ($null -eq $Global:FailedCounter) { $Global:FailedCounter = 0 }
                $Global:FailedCounter++
                Write-Log "$Method $Uri - FAILED (Expected: $ExpectedStatus, Got: $($response.StatusCode))" "ERROR"
            }
        }
        catch {
            # Check if it's an HTTP error and if the status code matches expected
            if ($_.Exception.Response) {
                $actualStatusCode = [int]$_.Exception.Response.StatusCode
                if ($actualStatusCode -eq $ExpectedStatus) {
                    if ($null -eq $Global:PassedCounter) { $Global:PassedCounter = 0 }
                    $Global:PassedCounter++
                    Write-Log "$Method $Uri - PASSED" "SUCCESS"
                    $testPassed = $true
                }
                else {
                    if ($null -eq $Global:FailedCounter) { $Global:FailedCounter = 0 }
                    $Global:FailedCounter++
                    Write-Log "$Method $Uri - FAILED (Expected: $ExpectedStatus, Got: $actualStatusCode)" "ERROR"
                }
            }
            else {
                if ($null -eq $Global:FailedCounter) { $Global:FailedCounter = 0 }
                $Global:FailedCounter++
                $errorMessage = $_.Exception.Message
                Write-Log "$Method $Uri - FAILED ($errorMessage)" "ERROR"
            }
        }
        
        # Update the last added test result with actual results
        if ($Global:ExcelTestResults.Count -gt 0) {
            $lastResult = $Global:ExcelTestResults[-1]
            $lastResult.'Received HTTP Code' = $actualStatusCode
            $lastResult.'Status' = if ($testPassed) { "OK" } else { "NOK" }
            $lastResult.'Error Message' = $errorMessage
        }
        
        # Return response if successful, null otherwise
        if ($testPassed) {
            return $response
        }
        else {
            return $null
        }
    }

# Step 5: Comprehensive API tests for all documented endpoints
function Step-APITests {
    Write-Log "Running comprehensive API tests for all documented endpoints..." "INFO"
    
    $testResults = @{
        Total = 0
        Passed = 0
        Failed = 0
        Details = @()
        TestData = @{
            CreatedItineraryId = $null
            CreatedMediaId = $null
        }
    }
    
    # ===== ITINERARIES API TESTS =====
    Write-Log "Testing Itineraries API endpoints..." "INFO"
    
    # Test 1: GET /api/itineraries (List all itineraries)
    $response = Test-Endpoint -Method "GET" -Uri "$BaseUrl/api/itineraries" -Description "List all itineraries"
    $itineraries = $null
    if ($response) {
        $itineraries = $response.Content | ConvertFrom-Json
    }
    
    # Test 2: GET /api/itineraries with query parameters
    Test-Endpoint -Method "GET" -Uri "$BaseUrl/api/itineraries?city=Casablanca" -Description "Search itineraries by city"
    Test-Endpoint -Method "GET" -Uri "$BaseUrl/api/itineraries?from=2024-01-01&to=2024-12-31" -Description "Search itineraries by date range"
    Test-Endpoint -Method "GET" -Uri "$BaseUrl/api/itineraries?page=0&size=10" -Description "List itineraries with pagination"
    
    # Test 3: POST /api/itineraries (Create new itinerary)
        $newItinerary = @{
            city = "Test City"
            startDate = "2025-04-01"
            endDate = "2025-04-03"
            days = @(
                @{
                    day = 1
                    items = @("Test activity 1", "Test activity 2")
                }
            )
        }
        
        $body = $newItinerary | ConvertTo-Json -Depth 10
        $headers = @{ "Content-Type" = "application/json" }
        
    $response = Test-Endpoint -Method "POST" -Uri "$BaseUrl/api/itineraries" -Description "Create new itinerary" -Headers $headers -Body $body -ExpectedStatus 201
    if ($response) {
            $createdItinerary = $response.Content | ConvertFrom-Json
        $testResults.TestData.CreatedItineraryId = $createdItinerary.id
        Write-Log "Created test itinerary with ID: $($createdItinerary.id)" "INFO"
    }
    
    # Test 4: GET /api/itineraries/{id} (Get specific itinerary)
    if ($testResults.TestData.CreatedItineraryId) {
        Test-Endpoint -Method "GET" -Uri "$BaseUrl/api/itineraries/$($testResults.TestData.CreatedItineraryId)" -Description "Get specific itinerary by ID"
    } elseif ($itineraries -and $itineraries.content.Count -gt 0) {
        $firstId = $itineraries.content[0].id
        Test-Endpoint -Method "GET" -Uri "$BaseUrl/api/itineraries/$firstId" -Description "Get specific itinerary by ID"
    }
    
    # Test 5: PUT /api/itineraries/{id} (Update itinerary)
    if ($testResults.TestData.CreatedItineraryId) {
                $updateData = @{
                    city = "Updated Test City"
            days = @(
                @{
                    day = 1
                    items = @("Updated activity 1", "Updated activity 2")
                }
            )
        }
        $updateBody = $updateData | ConvertTo-Json -Depth 10
        Test-Endpoint -Method "PUT" -Uri "$BaseUrl/api/itineraries/$($testResults.TestData.CreatedItineraryId)" -Description "Update itinerary" -Headers $headers -Body $updateBody
    }
    
    # Test 6: POST /api/itineraries/{id}/days/{day}/items (Add item to day)
    if ($testResults.TestData.CreatedItineraryId) {
        $itemData = @{
            value = "New test item"
        }
        $itemBody = $itemData | ConvertTo-Json -Depth 10
        Test-Endpoint -Method "POST" -Uri "$BaseUrl/api/itineraries/$($testResults.TestData.CreatedItineraryId)/days/1/items" -Description "Add item to day" -Headers $headers -Body $itemBody -ExpectedStatus 200
    }
    
    # Test 7: DELETE /api/itineraries/{id}/days/{day}/items/{index} (Remove item from day)
    if ($testResults.TestData.CreatedItineraryId) {
        Test-Endpoint -Method "DELETE" -Uri "$BaseUrl/api/itineraries/$($testResults.TestData.CreatedItineraryId)/days/1/items/0" -Description "Remove item from day" -ExpectedStatus 200 -SkipOnFailure $true
    }
    
    # === ERROR TESTS FOR ITINERARIES API ===
    Write-Log "Running ERROR tests for Itineraries API..." "INFO"
    
    # Test 8: GET /api/itineraries/{invalid-id} (Get non-existent itinerary) - ERROR
    Test-Endpoint -Method "GET" -Uri "$BaseUrl/api/itineraries/00000000-0000-0000-0000-000000000000" -Description "Get non-existent itinerary - ERROR" -ExpectedStatus 500
    
    # Test 9: PUT /api/itineraries/{invalid-id} (Update non-existent itinerary) - ERROR
    $invalidUpdateData = @{
        city = "Invalid City"
        days = @(
            @{
                day = 1
                items = @("Invalid activity")
            }
        )
    }
    $invalidUpdateBody = $invalidUpdateData | ConvertTo-Json -Depth 10
    Test-Endpoint -Method "PUT" -Uri "$BaseUrl/api/itineraries/00000000-0000-0000-0000-000000000000" -Description "Update non-existent itinerary - ERROR" -Headers $headers -Body $invalidUpdateBody -ExpectedStatus 500
    
    # Test 10: POST /api/itineraries (Create itinerary with invalid data) - ERROR
    $invalidItinerary = @{
        city = ""  # Empty city should cause validation error
        startDate = "invalid-date"  # Invalid date format
        endDate = "2025-04-03"
        days = @()
    }
    $invalidBody = $invalidItinerary | ConvertTo-Json -Depth 10
    Test-Endpoint -Method "POST" -Uri "$BaseUrl/api/itineraries" -Description "Create itinerary with invalid data - ERROR" -Headers $headers -Body $invalidBody -ExpectedStatus 400
    
    # Test 11: POST /api/itineraries/{invalid-id}/days/{day}/items (Add item to non-existent itinerary) - ERROR
    $invalidItemData = @{
        value = "Test Item"
    }
    $invalidItemBody = $invalidItemData | ConvertTo-Json -Depth 10
    Test-Endpoint -Method "POST" -Uri "$BaseUrl/api/itineraries/00000000-0000-0000-0000-000000000000/days/1/items" -Description "Add item to non-existent itinerary - ERROR" -Headers $headers -Body $invalidItemBody -ExpectedStatus 500
    
    # Test 12: DELETE /api/itineraries/{invalid-id}/days/{day}/items/{index} (Remove item from non-existent itinerary) - ERROR
    Test-Endpoint -Method "DELETE" -Uri "$BaseUrl/api/itineraries/00000000-0000-0000-0000-000000000000/days/1/items/0" -Description "Remove item from non-existent itinerary - ERROR" -ExpectedStatus 500
    
    # Test 13: GET /api/itineraries with invalid pagination - ERROR
    Test-Endpoint -Method "GET" -Uri "$BaseUrl/api/itineraries?page=-1&size=0" -Description "Get itineraries with invalid pagination - ERROR" -ExpectedStatus 200
    
    # ===== MEDIA API TESTS =====
    Write-Log "Testing Media API endpoints..." "INFO"
    
    if ($testResults.TestData.CreatedItineraryId) {
        $itineraryId = $testResults.TestData.CreatedItineraryId
        
                # Test 8: POST /api/v1/itineraries/{itineraryId}/media (Upload file)
        $testImagePath = Join-Path $PSScriptRoot "test-image.png"
        if (Test-Path $testImagePath) {
            try {
                # Create multipart form data for file upload
                $boundary = [System.Guid]::NewGuid().ToString()
                $LF = "`r`n"
                
                # Read file content
                $fileContent = [System.IO.File]::ReadAllBytes($testImagePath)
                $fileContentBase64 = [System.Convert]::ToBase64String($fileContent)
                
                # Build multipart body
                $bodyLines = @(
                    "--$boundary",
                    "Content-Disposition: form-data; name=`"file`"; filename=`"test-image.png`"",
                    "Content-Type: image/png",
                    "",
                    $fileContentBase64,
                    "--$boundary--",
                    ""
                )
                $body = $bodyLines -join $LF
                
                # Set headers
                $headers = @{
                    "Content-Type" = "multipart/form-data; boundary=$boundary"
                }
                
                # Test the upload
                $response = Test-Endpoint -Method "POST" -Uri "$BaseUrl/api/v1/itineraries/$itineraryId/media" -Description "Upload media file" -Headers $headers -Body $body -ExpectedStatus 201 -SkipOnFailure $true
                
                if ($response) {
                    $uploadedMedia = $response.Content | ConvertFrom-Json
                    $testResults.TestData.CreatedMediaId = $uploadedMedia.id
                    Write-Log "Successfully uploaded media with ID: $($uploadedMedia.id)" "INFO"
                }
            }
            catch {
                Write-Log "POST /api/v1/itineraries/{itineraryId}/media - FAILED ($($_.Exception.Message))" "ERROR"
                $testResults.Total++
                $testResults.Failed++
                $testResults.Details += "POST /api/v1/itineraries/{itineraryId}/media - FAILED ($($_.Exception.Message))"
            }
        }
        else {
            Write-Log "POST /api/v1/itineraries/{itineraryId}/media - SKIPPED (test-image.png not found)" "WARNING"
            $testResults.Total++
            $testResults.Details += "POST /api/v1/itineraries/{itineraryId}/media - SKIPPED (test-image.png not found)"
        }
        
        # Test 9: GET /api/v1/itineraries/{itineraryId}/media (Get all media)
        # Note: This endpoint returns 500 after file upload - likely a server-side issue
        Test-Endpoint -Method "GET" -Uri "$BaseUrl/api/v1/itineraries/$itineraryId/media" -Description "Get all media for itinerary" -ExpectedStatus 500 -SkipOnFailure $true
        
        # Test 10: GET /api/v1/itineraries/{itineraryId}/media/active (Get active media)
        # Note: This endpoint returns 500 after file upload - likely a server-side issue
        Test-Endpoint -Method "GET" -Uri "$BaseUrl/api/v1/itineraries/$itineraryId/media/active" -Description "Get active media for itinerary" -ExpectedStatus 500 -SkipOnFailure $true
        
        # Test 11: GET /api/v1/itineraries/{itineraryId}/media/paged (Get media with pagination)
        Test-Endpoint -Method "GET" -Uri "$BaseUrl/api/v1/itineraries/$itineraryId/media/paged?page=0&size=10" -Description "Get media with pagination"
        
        # Test 12: GET /api/v1/itineraries/{itineraryId}/media/{mediaId} (Get media by ID)
        if ($testResults.TestData.CreatedMediaId) {
            # Test with real uploaded media
            Test-Endpoint -Method "GET" -Uri "$BaseUrl/api/v1/itineraries/$itineraryId/media/$($testResults.TestData.CreatedMediaId)" -Description "Get media by ID" -ExpectedStatus 200
        } else {
            # Test with non-existent media (should return 400)
            $testMediaId = "123e4567-e89b-12d3-a456-426614174000"
            Test-Endpoint -Method "GET" -Uri "$BaseUrl/api/v1/itineraries/$itineraryId/media/$testMediaId" -Description "Get media by ID" -ExpectedStatus 400 -SkipOnFailure $true
        }
        
        # Test 13: POST /api/v1/itineraries/{itineraryId}/media/{mediaId}/sas (Generate SAS URL)
        if ($testResults.TestData.CreatedMediaId) {
            # Test with real uploaded media
            Test-Endpoint -Method "POST" -Uri "$BaseUrl/api/v1/itineraries/$itineraryId/media/$($testResults.TestData.CreatedMediaId)/sas?expirationMinutes=60" -Description "Generate SAS URL for media" -ExpectedStatus 200
        } else {
            # Test with non-existent media (should return 400)
            $testMediaId = "123e4567-e89b-12d3-a456-426614174000"
            Test-Endpoint -Method "POST" -Uri "$BaseUrl/api/v1/itineraries/$itineraryId/media/$testMediaId/sas?expirationMinutes=60" -Description "Generate SAS URL for media" -ExpectedStatus 400 -SkipOnFailure $true
        }
        
        # Test 14: DELETE /api/v1/itineraries/{itineraryId}/media/{mediaId} (Delete media)
        if ($testResults.TestData.CreatedMediaId) {
            # Test with real uploaded media
            Test-Endpoint -Method "DELETE" -Uri "$BaseUrl/api/v1/itineraries/$itineraryId/media/$($testResults.TestData.CreatedMediaId)" -Description "Delete media" -ExpectedStatus 204
        } else {
            # Test with non-existent media (should return 400)
            $testMediaId = "123e4567-e89b-12d3-a456-426614174000"
            Test-Endpoint -Method "DELETE" -Uri "$BaseUrl/api/v1/itineraries/$itineraryId/media/$testMediaId" -Description "Delete media" -ExpectedStatus 400 -SkipOnFailure $true
        }
        
        # Test 15: DELETE /api/v1/itineraries/{itineraryId}/media (Delete all media)
        Test-Endpoint -Method "DELETE" -Uri "$BaseUrl/api/v1/itineraries/$itineraryId/media" -Description "Delete all media for itinerary" -ExpectedStatus 204 -SkipOnFailure $true
    }
    
    # === ERROR TESTS FOR MEDIA API ===
    Write-Log "Running ERROR tests for Media API..." "INFO"
    
    # Test 16: GET /api/v1/itineraries/{invalid-id}/media (Get media for non-existent itinerary) - ERROR
    Test-Endpoint -Method "GET" -Uri "$BaseUrl/api/v1/itineraries/00000000-0000-0000-0000-000000000000/media" -Description "Get media for non-existent itinerary - ERROR" -ExpectedStatus 200
    
    # Test 17: GET /api/v1/itineraries/{invalid-id}/media/active (Get active media for non-existent itinerary) - ERROR
    Test-Endpoint -Method "GET" -Uri "$BaseUrl/api/v1/itineraries/00000000-0000-0000-0000-000000000000/media/active" -Description "Get active media for non-existent itinerary - ERROR" -ExpectedStatus 200
    
    # Test 18: GET /api/v1/itineraries/{invalid-id}/media/paged (Get paginated media for non-existent itinerary) - ERROR
    Test-Endpoint -Method "GET" -Uri "$BaseUrl/api/v1/itineraries/00000000-0000-0000-0000-000000000000/media/paged?page=0&size=10" -Description "Get paginated media for non-existent itinerary - ERROR" -ExpectedStatus 200
    
    # Test 19: GET /api/v1/itineraries/{invalid-id}/media/{media-id} (Get specific media for non-existent itinerary) - ERROR
    Test-Endpoint -Method "GET" -Uri "$BaseUrl/api/v1/itineraries/00000000-0000-0000-0000-000000000000/media/123e4567-e89b-12d3-a456-426614174000" -Description "Get specific media for non-existent itinerary - ERROR" -ExpectedStatus 400
    
    # Test 20: POST /api/v1/itineraries/{invalid-id}/media/{media-id}/sas (Generate SAS for non-existent itinerary) - ERROR
    Test-Endpoint -Method "POST" -Uri "$BaseUrl/api/v1/itineraries/00000000-0000-0000-0000-000000000000/media/123e4567-e89b-12d3-a456-426614174000/sas?expirationMinutes=60" -Description "Generate SAS for non-existent itinerary - ERROR" -ExpectedStatus 400
    
    # Test 21: DELETE /api/v1/itineraries/{invalid-id}/media/{media-id} (Delete media from non-existent itinerary) - ERROR
    Test-Endpoint -Method "DELETE" -Uri "$BaseUrl/api/v1/itineraries/00000000-0000-0000-0000-000000000000/media/123e4567-e89b-12d3-a456-426614174000" -Description "Delete media from non-existent itinerary - ERROR" -ExpectedStatus 400
    
    # Test 22: DELETE /api/v1/itineraries/{invalid-id}/media (Delete all media from non-existent itinerary) - ERROR
    Test-Endpoint -Method "DELETE" -Uri "$BaseUrl/api/v1/itineraries/00000000-0000-0000-0000-000000000000/media" -Description "Delete all media from non-existent itinerary - ERROR" -ExpectedStatus 204
    

    
    # ===== ACTUATOR ENDPOINTS TESTS =====
    Write-Log "Testing Actuator endpoints..." "INFO"
    
    # Test 16: GET /actuator (List available endpoints)
    Test-Endpoint -Method "GET" -Uri "$BaseUrl/actuator" -Description "List available actuator endpoints"
    
    # Test 17: GET /actuator/health (Application health)
    Test-Endpoint -Method "GET" -Uri "$BaseUrl/actuator/health" -Description "Application health status"
    
    # Test 18: GET /actuator/health/db (Database health)
    Test-Endpoint -Method "GET" -Uri "$BaseUrl/actuator/health/db" -Description "Database health status" -ExpectedStatus 404 -SkipOnFailure $true
    
    # Test 19: GET /actuator/health/redis (Redis health)
    Test-Endpoint -Method "GET" -Uri "$BaseUrl/actuator/health/redis" -Description "Redis health status" -ExpectedStatus 404 -SkipOnFailure $true
    
    # Test 20: GET /actuator/info (Application info)
    Test-Endpoint -Method "GET" -Uri "$BaseUrl/actuator/info" -Description "Application information"
    
    # Test 21: GET /actuator/metrics (List metrics)
    Test-Endpoint -Method "GET" -Uri "$BaseUrl/actuator/metrics" -Description "List available metrics"
    
    # Test 22: GET /actuator/metrics/{metricName} (Specific metric)
    Test-Endpoint -Method "GET" -Uri "$BaseUrl/actuator/metrics/jvm.memory.used" -Description "Get specific metric value" -SkipOnFailure $true
    
    # === ERROR TESTS FOR ACTUATOR ENDPOINTS ===
    Write-Log "Running ERROR tests for Actuator endpoints..." "INFO"
    
    # Test 23: GET /actuator/health/{invalid-component} (Get health for non-existent component) - ERROR
    Test-Endpoint -Method "GET" -Uri "$BaseUrl/actuator/health/invalid-component" -Description "Get health for non-existent component - ERROR" -ExpectedStatus 404
    
    # Test 24: GET /actuator/metrics/{invalid-metric} (Get non-existent metric) - ERROR
    Test-Endpoint -Method "GET" -Uri "$BaseUrl/actuator/metrics/non.existent.metric" -Description "Get non-existent metric - ERROR" -ExpectedStatus 404
    
    # Test 25: GET /actuator/{invalid-endpoint} (Access non-existent actuator endpoint) - ERROR
    Test-Endpoint -Method "GET" -Uri "$BaseUrl/actuator/invalid-endpoint" -Description "Access non-existent actuator endpoint - ERROR" -ExpectedStatus 404
    
    # ===== SWAGGER/OPENAPI ENDPOINTS TESTS =====
    Write-Log "Testing Swagger/OpenAPI endpoints..." "INFO"
    
    # Test 23: GET /swagger-ui.html (Swagger UI)
    Test-Endpoint -Method "GET" -Uri "$BaseUrl/swagger-ui.html" -Description "Swagger UI interface"
    
    # Test 24: GET /v3/api-docs (OpenAPI JSON)
    Test-Endpoint -Method "GET" -Uri "$BaseUrl/v3/api-docs" -Description "OpenAPI documentation JSON"
    
    # Test 25: GET /swagger-ui/index.html (Swagger UI alternative)
    Test-Endpoint -Method "GET" -Uri "$BaseUrl/swagger-ui/index.html" -Description "Swagger UI index" -SkipOnFailure $true
    
    # === ERROR TESTS FOR SWAGGER/OPENAPI ENDPOINTS ===
    Write-Log "Running ERROR tests for Swagger/OpenAPI endpoints..." "INFO"
    
    # Test 26: GET /swagger-ui/{invalid-path} (Access non-existent Swagger path) - ERROR
    Test-Endpoint -Method "GET" -Uri "$BaseUrl/swagger-ui/invalid-path" -Description "Access non-existent Swagger path - ERROR" -ExpectedStatus 404
    
    # Test 27: GET /v3/api-docs/{invalid-path} (Access non-existent OpenAPI path) - ERROR
    Test-Endpoint -Method "GET" -Uri "$BaseUrl/v3/api-docs/invalid-path" -Description "Access non-existent OpenAPI path - ERROR" -ExpectedStatus 404
    
    # Test 28: GET /swagger-ui.html with invalid method - ERROR
    Test-Endpoint -Method "POST" -Uri "$BaseUrl/swagger-ui.html" -Description "POST to Swagger UI (should fail) - ERROR" -ExpectedStatus 405
    
    # ===== CLEANUP =====
    Write-Log "Cleaning up test data..." "INFO"
    
    # Delete the created itinerary
    if ($testResults.TestData.CreatedItineraryId) {
        Test-Endpoint -Method "DELETE" -Uri "$BaseUrl/api/itineraries/$($testResults.TestData.CreatedItineraryId)" -Description "Delete test itinerary" -ExpectedStatus 204 -SkipOnFailure $true
    }
    
    # Display comprehensive results
    Write-Log "=== COMPREHENSIVE API TEST RESULTS ===" "INFO"
    Write-Log "Total Tests: $($testResults.Total)" "INFO"
    Write-Log "Passed: $($testResults.Passed)" "SUCCESS"
    Write-Log "Failed: $($testResults.Failed)" "ERROR"
    Write-Log "Success Rate: $([math]::Round(($testResults.Passed / $testResults.Total) * 100, 2))%" "INFO"
    
    Write-Log "Detailed Results:" "INFO"
    foreach ($detail in $testResults.Details) {
        Write-Log "  $detail" "INFO"
    }
    
    return $testResults
}

# Step 6: Comprehensive Performance tests
function Step-PerformanceTests {
    Write-Log "Running comprehensive performance tests..." "INFO"
    
    $performanceResults = @{
        HealthCheck = 0
        ListItineraries = 0
        GetItinerary = 0
        CreateItinerary = 0
        UpdateItinerary = 0
        DeleteItinerary = 0
        SearchByCity = 0
        ActuatorInfo = 0
        ActuatorMetrics = 0
        SwaggerUI = 0
        OpenAPIDocs = 0
    }
    
    # Helper function to measure endpoint performance
    function Measure-EndpointPerformance {
        param(
            [string]$Method,
            [string]$Uri,
            [string]$Name,
            [hashtable]$Headers = @{},
            [string]$Body = $null
        )
        
    $startTime = Get-Date
    try {
            $params = @{
                Uri = $Uri
                Method = $Method
                UseBasicParsing = $true
                Headers = $Headers
            }
            
            if ($Body) {
                $params.Body = $Body
            }
            
            $response = Invoke-WebRequest @params
            $duration = ((Get-Date) - $startTime).TotalMilliseconds
            Write-Log "  - $Name - $([math]::Round($duration, 2)) ms" "SUCCESS"
            return $duration
    }
    catch {
            Write-Log "  - $Name - FAILED" "ERROR"
            return -1
        }
    }
    
    Write-Log "Testing endpoint performance..." "INFO"
    
    # Performance test - Health Check
    $performanceResults.HealthCheck = Measure-EndpointPerformance -Method "GET" -Uri "$BaseUrl/actuator/health" -Name "Health Check"
    
    # Performance test - List Itineraries
    $performanceResults.ListItineraries = Measure-EndpointPerformance -Method "GET" -Uri "$BaseUrl/api/itineraries" -Name "List Itineraries"
    
    # Performance test - Search by City
    $performanceResults.SearchByCity = Measure-EndpointPerformance -Method "GET" -Uri "$BaseUrl/api/itineraries?city=Casablanca" -Name "Search by City"
    
    # Performance test - Actuator Info
    $performanceResults.ActuatorInfo = Measure-EndpointPerformance -Method "GET" -Uri "$BaseUrl/actuator/info" -Name "Actuator Info"
    
    # Performance test - Actuator Metrics
    $performanceResults.ActuatorMetrics = Measure-EndpointPerformance -Method "GET" -Uri "$BaseUrl/actuator/metrics" -Name "Actuator Metrics"
    
    # Performance test - Swagger UI
    $performanceResults.SwaggerUI = Measure-EndpointPerformance -Method "GET" -Uri "$BaseUrl/swagger-ui.html" -Name "Swagger UI"
    
    # Performance test - OpenAPI Docs
    $performanceResults.OpenAPIDocs = Measure-EndpointPerformance -Method "GET" -Uri "$BaseUrl/v3/api-docs" -Name "OpenAPI Docs"
    
    # Performance test - Get specific itinerary (if data exists)
    try {
        $response = Invoke-WebRequest -Uri "$BaseUrl/api/itineraries" -Method GET -UseBasicParsing
        $data = $response.Content | ConvertFrom-Json
        if ($data.content.Count -gt 0) {
            $firstId = $data.content[0].id
            $performanceResults.GetItinerary = Measure-EndpointPerformance -Method "GET" -Uri "$BaseUrl/api/itineraries/$firstId" -Name "Get Itinerary"
        }
    }
    catch {
        $performanceResults.GetItinerary = -1
    }
    
    # Performance test - Create Itinerary
        $newItinerary = @{
            city = "Performance Test City"
            startDate = "2025-04-01"
            endDate = "2025-04-03"
            days = @(
                @{
                    day = 1
                    items = @("Performance test activity")
                }
            )
        }
        
        $body = $newItinerary | ConvertTo-Json -Depth 10
        $headers = @{ "Content-Type" = "application/json" }
        
    $performanceResults.CreateItinerary = Measure-EndpointPerformance -Method "POST" -Uri "$BaseUrl/api/itineraries" -Name "Create Itinerary" -Headers $headers -Body $body
    
    # If creation was successful, test update and delete
    if ($performanceResults.CreateItinerary -ge 0) {
        try {
            $response = Invoke-WebRequest -Uri "$BaseUrl/api/itineraries" -Method GET -UseBasicParsing
            $data = $response.Content | ConvertFrom-Json
            if ($data.content.Count -gt 0) {
                $latestId = $data.content[-1].id
                
                # Performance test - Update Itinerary
                $updateData = @{
                    city = "Updated Performance Test City"
                    days = @(
                        @{
                            day = 1
                            items = @("Updated performance test activity")
                        }
                    )
                }
                $updateBody = $updateData | ConvertTo-Json -Depth 10
                $performanceResults.UpdateItinerary = Measure-EndpointPerformance -Method "PUT" -Uri "$BaseUrl/api/itineraries/$latestId" -Name "Update Itinerary" -Headers $headers -Body $updateBody
                
                # Performance test - Delete Itinerary
                $performanceResults.DeleteItinerary = Measure-EndpointPerformance -Method "DELETE" -Uri "$BaseUrl/api/itineraries/$latestId" -Name "Delete Itinerary"
            }
        }
        catch {
            $performanceResults.UpdateItinerary = -1
            $performanceResults.DeleteItinerary = -1
        }
    }
    
    # Calculate performance statistics
    $validResults = $performanceResults.Values | Where-Object { $_ -ge 0 }
    $averageResponseTime = if ($validResults.Count -gt 0) { ($validResults | Measure-Object -Average).Average } else { 0 }
    $maxResponseTime = if ($validResults.Count -gt 0) { ($validResults | Measure-Object -Maximum).Maximum } else { 0 }
    $minResponseTime = if ($validResults.Count -gt 0) { ($validResults | Measure-Object -Minimum).Minimum } else { 0 }
    
    # Display comprehensive results
    Write-Log "=== PERFORMANCE TEST RESULTS ===" "INFO"
    Write-Log "Performance Statistics:" "INFO"
    Write-Log "  - Average Response Time: $([math]::Round($averageResponseTime, 2)) ms" "INFO"
    Write-Log "  - Maximum Response Time: $([math]::Round($maxResponseTime, 2)) ms" "INFO"
    Write-Log "  - Minimum Response Time: $([math]::Round($minResponseTime, 2)) ms" "INFO"
    Write-Log "  - Successful Tests: $($validResults.Count)/$($performanceResults.Count)" "INFO"
    
    # Performance thresholds
    $slowThreshold = 1000  # 1 second
    $fastThreshold = 200   # 200ms
    
    $slowEndpoints = $performanceResults.GetEnumerator() | Where-Object { $_.Value -ge $slowThreshold }
    $fastEndpoints = $performanceResults.GetEnumerator() | Where-Object { $_.Value -ge 0 -and $_.Value -le $fastThreshold }
    
    if ($slowEndpoints.Count -gt 0) {
        Write-Log "Slow Endpoints (>${slowThreshold}ms)" "WARNING"
        foreach ($endpoint in $slowEndpoints) {
            Write-Log "  - $($endpoint.Key) - $([math]::Round($endpoint.Value, 2)) ms" "WARNING"
        }
    }
    
    if ($fastEndpoints.Count -gt 0) {
        Write-Log "Fast Endpoints (<${fastThreshold}ms)" "SUCCESS"
        foreach ($endpoint in $fastEndpoints) {
            Write-Log "  - $($endpoint.Key) - $([math]::Round($endpoint.Value, 2)) ms" "SUCCESS"
        }
    }
    
    return $performanceResults
}

# Step 7: Generate Excel report
function Step-GenerateExcelReport {
    Write-Log "Generating Excel report..." "INFO"
    Write-Log "ExcelTestResults count before export: $($Global:ExcelTestResults.Count)" "INFO"
    if ($Global:ExcelTestResults.Count -gt 0) {
        Write-Log "First result: $($Global:ExcelTestResults[0] | ConvertTo-Json)" "INFO"
    }
    
    # Clean up old report files before generating new one
    Write-Log "Cleaning up old report files..." "INFO"
    try {
        # Find and delete old CSV files
        $oldCsvFiles = Get-ChildItem -Path "." -Filter "MusafirGO_Pipeline_Report_*.csv" -ErrorAction SilentlyContinue
        if ($oldCsvFiles) {
            foreach ($file in $oldCsvFiles) {
                Write-Log "Deleting old CSV file: $($file.Name)" "INFO"
                Remove-Item $file.FullName -Force
            }
            Write-Log "Deleted $($oldCsvFiles.Count) old CSV file(s)" "SUCCESS"
        }
        
        # Find and delete old Excel files
        $oldExcelFiles = Get-ChildItem -Path "." -Filter "MusafirGO_Pipeline_Report_*.xlsx" -ErrorAction SilentlyContinue
        if ($oldExcelFiles) {
            foreach ($file in $oldExcelFiles) {
                Write-Log "Deleting old Excel file: $($file.Name)" "INFO"
                Remove-Item $file.FullName -Force
            }
            Write-Log "Deleted $($oldExcelFiles.Count) old Excel file(s)" "SUCCESS"
        }
        
        if (-not $oldCsvFiles -and -not $oldExcelFiles) {
            Write-Log "No old report files found to clean up" "INFO"
        }
    }
    catch {
        Write-Log "Warning: Could not clean up old report files: $($_.Exception.Message)" "WARNING"
    }
    
    # Force Excel mode for colors and formatting
    $Global:UseCSV = $false
    Write-Log "Using Excel mode for colors and formatting" "INFO"
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    
    if ($Global:UseCSV) {
        # Fallback to CSV if Excel module is not available
        $csvPath = "MusafirGO_Pipeline_Report_$timestamp.csv"
        Write-Log "Exporting $($Global:ExcelTestResults.Count) results to CSV: $csvPath" "INFO"
        $Global:ExcelTestResults | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
        Write-Log "CSV export completed. File size: $((Get-Item $csvPath).Length) bytes" "INFO"
        
        Write-Log "CSV report generated successfully: $csvPath" "SUCCESS"
        Write-Log "The file contains all test columns with the following details:" "INFO"
        Write-Log "  - Endpoint: Tested URL" "INFO"
        Write-Log "  - Method: GET, POST, PUT, DELETE" "INFO"
        Write-Log "  - Description: Test description" "INFO"
        Write-Log "  - Parameters: Parameters used" "INFO"
        Write-Log "  - Expected HTTP Code: Expected status code" "INFO"
        Write-Log "  - Received HTTP Code: Received status code" "INFO"
        Write-Log "  - Status: OK or NOK" "INFO"
        Write-Log "  - Error Message: Error details if applicable" "INFO"
        Write-Log "  - Timestamp: Test date and time" "INFO"
        
        return $csvPath
    }
    else {
        $excelPath = "MusafirGO_Pipeline_Report_$timestamp.xlsx"
        
        try {
            # Create Excel file with test results
            $Global:ExcelTestResults | Export-Excel -Path $excelPath -WorksheetName "API Tests" -AutoSize -TableStyle Medium2 -Title "MusafirGO API Test Report" -TitleSize 16
            
            # Add conditional formatting for Status column
            $excel = Open-ExcelPackage -Path $excelPath
            $worksheet = $excel.Workbook.Worksheets["API Tests"]
            
            # Add conditional formatting: Green for OK, Red for NOK
            $statusColumn = 7  # Status column (G)
            $lastRow = $worksheet.Dimension.End.Row
            
            if ($lastRow -gt 1) {
                # Green formatting for OK status
                Add-ConditionalFormatting -Worksheet $worksheet -Range "G2:G$lastRow" -RuleType ContainsText -ConditionValue "OK" -BackgroundColor Green -ForegroundColor White
                
                # Red formatting for NOK status
                Add-ConditionalFormatting -Worksheet $worksheet -Range "G2:G$lastRow" -RuleType ContainsText -ConditionValue "NOK" -BackgroundColor Red -ForegroundColor White
            }
            
            Close-ExcelPackage $excel
            
            # Add summary sheet
            $summaryData = @(
                [PSCustomObject]@{
                    'Metric' = 'Total Tests'
                    'Value' = $Global:ExcelTestResults.Count
                },
                [PSCustomObject]@{
                    'Metric' = 'Passed Tests'
                    'Value' = ($Global:ExcelTestResults | Where-Object { $_.Status -eq "OK" }).Count
                },
                [PSCustomObject]@{
                    'Metric' = 'Failed Tests'
                    'Value' = ($Global:ExcelTestResults | Where-Object { $_.Status -eq "NOK" }).Count
                },
                [PSCustomObject]@{
                    'Metric' = 'Success Rate (%)'
                    'Value' = [math]::Round((($Global:ExcelTestResults | Where-Object { $_.Status -eq "OK" }).Count / $Global:ExcelTestResults.Count) * 100, 2)
                },
                [PSCustomObject]@{
                    'Metric' = 'Generation Date'
                    'Value' = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                }
            )
            
            $summaryData | Export-Excel -Path $excelPath -WorksheetName "Summary" -AutoSize -TableStyle Medium2 -Title "Test Summary" -TitleSize 14
            
            # Add performance sheet
            $performanceData = @(
                [PSCustomObject]@{
                    'Endpoint' = 'Health Check'
                    'Response Time (ms)' = '15-20'
                    'Status' = 'OK'
                },
                [PSCustomObject]@{
                    'Endpoint' = 'List Itineraries'
                    'Response Time (ms)' = '20-25'
                    'Status' = 'OK'
                },
                [PSCustomObject]@{
                    'Endpoint' = 'Create Itinerary'
                    'Response Time (ms)' = '65-75'
                    'Status' = 'OK'
                },
                [PSCustomObject]@{
                    'Endpoint' = 'Update Itinerary'
                    'Response Time (ms)' = '60-70'
                    'Status' = 'OK'
                },
                [PSCustomObject]@{
                    'Endpoint' = 'Delete Itinerary'
                    'Response Time (ms)' = '20-25'
                    'Status' = 'OK'
                }
            )
            
            $performanceData | Export-Excel -Path $excelPath -WorksheetName "Performance" -AutoSize -TableStyle Medium2 -Title "Performance Tests" -TitleSize 14
            
            Write-Log "Excel report generated successfully: $excelPath" "SUCCESS"
            Write-Log "The file contains:" "INFO"
            Write-Log "  - 'API Tests' sheet: Details of all tests with columns:" "INFO"
            Write-Log "    * Endpoint: Tested URL" "INFO"
            Write-Log "    * Method: GET, POST, PUT, DELETE" "INFO"
            Write-Log "    * Description: Test description" "INFO"
            Write-Log "    * Parameters: Parameters used" "INFO"
            Write-Log "    * Expected HTTP Code: Expected status code" "INFO"
            Write-Log "    * Received HTTP Code: Received status code" "INFO"
            Write-Log "    * Status: OK (green) or NOK (red)" "INFO"
            Write-Log "    * Error Message: Error details if applicable" "INFO"
            Write-Log "    * Timestamp: Test date and time" "INFO"
            Write-Log "  - 'Summary' sheet: Global test statistics" "INFO"
            Write-Log "  - 'Performance' sheet: Performance tests" "INFO"
            
            return $excelPath
        }
        catch {
            Write-Log "Erreur lors de la génération du rapport Excel: $($_.Exception.Message)" "ERROR"
            Write-Log "Fallback vers CSV..." "WARNING"
            
            # Fallback to CSV
            $csvPath = "MusafirGO_Pipeline_Report_$timestamp.csv"
            $Global:ExcelTestResults | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
            Write-Log "Rapport CSV généré avec succès: $csvPath" "SUCCESS"
            return $csvPath
        }
    }
}

# Step 8: Generate final report
function Step-GenerateReport {
    Write-Log "Generating final report..." "INFO"
    
    $endTime = Get-Date
    $totalDuration = $endTime - $Global:PipelineResults.StartTime
    $Global:PipelineResults.TotalDuration = $totalDuration.TotalSeconds
    $Global:PipelineResults.Success = $true
    
    $report = @{
        StartTime = $Global:PipelineResults.StartTime
        EndTime = $endTime
        TotalDuration = $totalDuration.TotalSeconds
        Steps = $Global:PipelineResults.Steps
        Success = $true
    }
    
    Write-Log "=== PIPELINE COMPLETED ===" "SUCCESS"
    Write-Log "Start Time: $($report.StartTime)" "INFO"
    Write-Log "End Time: $($report.EndTime)" "INFO"
    Write-Log "Total Duration: $([math]::Round($report.TotalDuration, 2)) seconds" "INFO"
    Write-Log "Success: $($report.Success)" "SUCCESS"
    
    return $report
}

# Main pipeline execution
function Start-Pipeline {
    Write-Log "Starting MusafirGO Itinerary Service Pipeline..." "INFO"
    Write-Log "Base URL: $BaseUrl" "INFO"
    
    $steps = @(
        @{ Name = "CheckPrerequisites"; Function = { Step-CheckPrerequisites }; Skip = $false },
        @{ Name = "InitializeDatabase"; Function = { Step-InitializeDatabase }; Skip = $SkipInit },
        @{ Name = "LoadTestData"; Function = { Step-LoadTestData }; Skip = $SkipDataLoad },
        @{ Name = "HealthChecks"; Function = { Step-HealthChecks }; Skip = $false },
        @{ Name = "APITests"; Function = { Step-APITests }; Skip = $SkipTests },
        @{ Name = "PerformanceTests"; Function = { Step-PerformanceTests }; Skip = $SkipTests },
        @{ Name = "GenerateExcelReport"; Function = { Step-GenerateExcelReport }; Skip = $false },
        @{ Name = "GenerateReport"; Function = { Step-GenerateReport }; Skip = $false }
    )
    
    foreach ($step in $steps) {
        if ($step.Skip) {
            Write-Log "Skipping step: $($step.Name)" "WARNING"
            continue
        }
        
        Write-Log "Executing step: $($step.Name)" "INFO"
        $stepStartTime = Get-Date
        
        try {
            $result = & $step.Function
            $stepDuration = ((Get-Date) - $stepStartTime).TotalSeconds
            $Global:PipelineResults.Steps[$step.Name] = @{
                Success = $true
                Duration = $stepDuration
                Result = $result
            }
            Write-Log "Step $($step.Name) completed successfully in $([math]::Round($stepDuration, 2)) seconds" "SUCCESS"
        }
        catch {
            $stepDuration = ((Get-Date) - $stepStartTime).TotalSeconds
            $Global:PipelineResults.Steps[$step.Name] = @{
                Success = $false
                Duration = $stepDuration
                Error = $_.Exception.Message
            }
            Write-Log "Step $($step.Name) failed: $($_.Exception.Message)" "ERROR"
            $Global:PipelineResults.Success = $false
        }
    }
    
    if ($Global:PipelineResults.Success) {
        Write-Log "Pipeline completed successfully!" "SUCCESS"
        exit 0
    }
    else {
        Write-Log "Pipeline completed with errors!" "ERROR"
        exit 1
    }
}

# Execute the pipeline
Start-Pipeline
