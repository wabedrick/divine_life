#!/usr/bin/env pwsh

# Test the anagkazo field using PowerShell and Invoke-RestMethod

Write-Host "=== Testing Anagkazo Field in Reports ===" -ForegroundColor Green
Write-Host ""

$apiUrl = "http://localhost:8000/api"

# Step 1: Login
Write-Host "1. Logging in as MC Leader..." -ForegroundColor Yellow

$loginData = @{
    email = "david@divinelifechurch.org"
    password = "password123"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$apiUrl/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    $token = $loginResponse.access_token
    Write-Host "Login successful! Token received." -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "Login failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 2: Create report with anagkazo field
Write-Host "2. Creating MC report with anagkazo field..." -ForegroundColor Yellow

$reportData = @{
    week_ending = (Get-Date).AddDays(7 - (Get-Date).DayOfWeek.value__).ToString("yyyy-MM-dd")
    members_met = 15
    new_members = 2
    salvations = 1
    anagkazo = 3
    offerings = 500.00
    general_notes = "Test report with anagkazo field - PowerShell test!"
} | ConvertTo-Json

$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
    "Accept" = "application/json"
}

try {
    $createResponse = Invoke-RestMethod -Uri "$apiUrl/reports" -Method POST -Body $reportData -Headers $headers
    Write-Host "✅ SUCCESS: Report created successfully with anagkazo field!" -ForegroundColor Green
    Write-Host "Report ID: $($createResponse.data.id)" -ForegroundColor Cyan
    Write-Host "Anagkazo value: $($createResponse.data.anagkazo)" -ForegroundColor Cyan
    Write-Host ""
    
    # Step 3: Verify by retrieving the report
    $reportId = $createResponse.data.id
    Write-Host "3. Retrieving created report to verify anagkazo field..." -ForegroundColor Yellow
    
    $getResponse = Invoke-RestMethod -Uri "$apiUrl/reports/$reportId" -Method GET -Headers $headers
    Write-Host "Retrieved report anagkazo value: $($getResponse.data.anagkazo)" -ForegroundColor Cyan
    
    if ($getResponse.data.anagkazo -eq 3) {
        Write-Host "✅ VERIFICATION SUCCESS: Anagkazo field saved and retrieved correctly!" -ForegroundColor Green
    } else {
        Write-Host "❌ VERIFICATION FAILED: Anagkazo field not found or incorrect value" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ FAILED: Report creation failed" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    
    if ($_.Exception.Response) {
        $responseBody = $_.Exception.Response | Get-Member
        Write-Host "Response details: $responseBody" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== Test Complete ===" -ForegroundColor Green