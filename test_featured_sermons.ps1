$loginData = @{
    email = "admin@divinelifechurch.org"
    password = "password123"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri 'http://192.168.42.54:8000/api/auth/login' -Method Post -Body $loginData -ContentType 'application/json'
    $token = $loginResponse.access_token
    Write-Host "✅ Login successful"

    $headers = @{Authorization = "Bearer $token"}
    $featuredResponse = Invoke-RestMethod -Uri 'http://192.168.42.54:8000/api/sermons/featured' -Headers $headers

    Write-Host "📋 Featured Response Type: $($featuredResponse.GetType().Name)"
    
    if ($featuredResponse -is [array]) {
        Write-Host "📊 Featured Count: $($featuredResponse.Count)"
        if ($featuredResponse.Count -gt 0) {
            Write-Host "🔍 First Featured Sermon: $($featuredResponse[0].title)"
        }
    } else {
        Write-Host "❌ Featured response is not an array: $featuredResponse"
    }
} catch {
    Write-Host "❌ Error: $_"
}