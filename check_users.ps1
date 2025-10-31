# Get auth token
$response = Invoke-RestMethod -Uri 'http://192.168.42.147:8000/api/auth/login' -Method Post -Body '{"email":"admin@divinelifechurch.org","password":"password123"}' -ContentType 'application/json'
Write-Host "Login Response:"
$response | ConvertTo-Json -Depth 3
Write-Host "`n===================`n"

$token = $response.access_token
Write-Host "Token: $token"
Write-Host "`n===================`n"

# Get users
try {
    $users = Invoke-RestMethod -Uri 'http://192.168.42.147:8000/api/users' -Method Get -Headers @{'Authorization'="Bearer $token"} -ContentType 'application/json'
    Write-Host "Users Response:"
    $users | ConvertTo-Json -Depth 3
} catch {
    Write-Host "Error getting users: $($_.Exception.Message)"
    Write-Host "Response: $($_.Exception.Response)"
}