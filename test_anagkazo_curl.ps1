#!/usr/bin/env pwsh

# Get authentication token first
$loginData = '{"email":"david@divinelifechurch.org","password":"password123"}'
$loginResponse = curl -X POST http://localhost:8000/api/auth/login -H "Content-Type: application/json" -H "Accept: application/json" -d $loginData

Write-Host "Login Response: $loginResponse"

# Parse token (basic PowerShell JSON parsing)
if ($loginResponse -match '"access_token":"([^"]+)"') {
    $token = $matches[1]
    Write-Host "Token: $token"
    
    # Now test report creation
    $reportData = '{"week_ending":"2025-11-10","members_met":15,"new_members":2,"salvations":1,"anagkazo":3,"offerings":500.00,"general_notes":"Test report with anagkazo field"}'
    
    $reportResponse = curl -X POST http://localhost:8000/api/reports -H "Content-Type: application/json" -H "Accept: application/json" -H "Authorization: Bearer $token" -d $reportData
    
    Write-Host "Report Creation Response: $reportResponse"
} else {
    Write-Host "Failed to extract token from login response"
}