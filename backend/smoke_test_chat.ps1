$base = 'http://127.0.0.1:8000/api'
try {
    $login = Invoke-RestMethod -Method Post -Uri "$base/auth/login" -Body (ConvertTo-Json @{email = 'admin@divinelifechurch.org'; password = 'password123' }) -ContentType 'application/json' -ErrorAction Stop
    Write-Output '---LOGIN RESPONSE---'
    Write-Output (ConvertTo-Json $login -Depth 5)
    $token = $login.access_token
    if (-not $token) { Write-Error 'Login did not return access_token'; exit 2 }

    Write-Output '---GET CONVERSATIONS---'
    $convs = Invoke-RestMethod -Headers @{Authorization = "Bearer $token" } -Uri "$base/chat/conversations" -Method Get -ErrorAction Stop
    Write-Output (ConvertTo-Json $convs -Depth 5)
    $convId = $convs.data[0].id
    Write-Output "Using conversation id: $convId"

    Write-Output '---SEND MESSAGE---'
    $send = Invoke-RestMethod -Headers @{Authorization = "Bearer $token" } -Uri "$base/chat/messages" -Method Post -Body (ConvertTo-Json @{conversation_id = $convId; content = ('Smoke test message ' + (Get-Date -Format o)) }) -ContentType 'application/json' -ErrorAction Stop
    Write-Output (ConvertTo-Json $send -Depth 5)
    $msgId = $send.data.id
    Write-Output "Sent message id: $msgId"

    Write-Output '---EDIT MESSAGE---'
    $edit = Invoke-RestMethod -Headers @{Authorization = "Bearer $token" } -Uri "$base/chat/messages/$msgId" -Method Put -Body (ConvertTo-Json @{content = ('Edited smoke test message ' + (Get-Date -Format o)) }) -ContentType 'application/json' -ErrorAction Stop
    Write-Output (ConvertTo-Json $edit -Depth 5)

    Write-Output '---DELETE MESSAGE---'
    $del = Invoke-RestMethod -Headers @{Authorization = "Bearer $token" } -Uri "$base/chat/messages/$msgId" -Method Delete -ErrorAction Stop
    Write-Output (ConvertTo-Json $del -Depth 5)
}
catch {
    Write-Error "ERROR: $_"
    exit 1
}
