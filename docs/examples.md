# Examples

## Basic Examples

### Simple Server

Start a basic web server on the default port:

```powershell
Start-PwshWeb
```

Access at: `http://localhost:8000/`

### Custom Port

Start on port 8080:

```powershell
Start-PwshWeb -Port 8080
```

Access at: `http://localhost:8080/`

### Specific Directory

Serve a website folder:

```powershell
Start-PwshWeb -Port 8080 -Path "C:\MyWebsite"
```

## Background Job Examples

### Start Background Server

```powershell
$server = Start-PwshWeb -Port 9000 -AsJob
Write-Host "Server running at $($server.Uri)"
```

### Check Server Status

```powershell
$server.Job | Get-Job
```

### Stop Background Server

```powershell
$server.Job | Stop-Job
$server.Job | Remove-Job
```

### Restart Background Server

```powershell
# Stop existing
Stop-Job $server.Job
Remove-Job $server.Job

# Start new
$server = Start-PwshWeb -Port 9000 -AsJob
```

## Development Workflow

### Static Website Development

```powershell
# Navigate to project
Set-Location C:\Projects\MySite

# Start server with verbose output
Start-PwshWeb -Port 3000 -Verbose
```

### API Testing

```powershell
# Start server for API documentation
$api = Start-PwshWeb -Port 8080 -Path "C:\API\Docs" -AsJob

# Test endpoints while server runs
Invoke-RestMethod -Uri "http://localhost:8080/api.json"

# Clean up
Stop-Job $api.Job
Remove-Job $api.Job
```

### Multiple Servers

```powershell
# Start multiple servers on different ports
$web = Start-PwshWeb -Port 8001 -Path "C:\Website" -AsJob
$api = Start-PwshWeb -Port 8002 -Path "C:\API" -AsJob
$docs = Start-PwshWeb -Port 8003 -Path "C:\Docs" -AsJob

# List all servers
Get-Job

# Stop all servers
Get-Job | Stop-Job
Get-Job | Remove-Job
```

## Advanced Examples

### Preview Before Starting

```powershell
# Check what would happen
Start-PwshWeb -Port 8080 -Path "C:\Website" -WhatIf

# Actually start
Start-PwshWeb -Port 8080 -Path "C:\Website"
```

### With Confirmation

```powershell
# Will prompt before starting
Start-PwshWeb -Port 8080 -Confirm
```

### Verbose Logging

```powershell
# See all requests
Start-PwshWeb -Port 8080 -Verbose
```

Output:
```
VERBOSE: Performing the operation "Start" on target "web server on port 8080 serving 'C:\Website'".
VERBOSE: Starting PwshWeb server in current session...
VERBOSE: PwshWeb server started on port 8080 serving 'C:\Website'
VERBOSE: [a1b2c3d4] GET http://localhost:8080/
VERBOSE: [a1b2c3d4] GET http://localhost:8080/style.css
VERBOSE: [a1b2c3d4] GET http://localhost:8080/script.js
```

## Scripting Examples

### Automated Testing Script

```powershell
# Start test server
$testServer = Start-PwshWeb -Port 18765 -Path "C:\TestSite" -AsJob
Start-Sleep -Seconds 2

try {
    # Run tests
    $response = Invoke-WebRequest -Uri "http://localhost:18765/" -UseBasicParsing
    if ($response.StatusCode -eq 200) {
        Write-Host "Server test passed!" -ForegroundColor Green
    }
}
finally {
    # Always clean up
    Stop-Job $testServer.Job -ErrorAction SilentlyContinue
    Remove-Job $testServer.Job -ErrorAction SilentlyContinue
}
```

### CI/CD Pipeline

```powershell
# Start server for integration tests
$server = Start-PwshWeb -Port 8080 -AsJob
Start-Sleep -Seconds 3

# Run your tests here
# Invoke-Pester, etc.

# Clean up
Stop-Job $server.Job
Remove-Job $server.Job
```

## Common Use Cases

### File Sharing

Quickly share files on your local network:

```powershell
# Share Downloads folder
Start-PwshWeb -Port 8080 -Path "$env:USERPROFILE\Downloads"
```

### Documentation Server

Serve generated documentation:

```powershell
# Serve MkDocs output
Start-PwshWeb -Port 8000 -Path ".\site"
```

### Static Site Testing

Test a static website before deployment:

```powershell
# Build your site
# npm run build, hugo, etc.

# Test locally
Start-PwshWeb -Port 8000 -Path ".\dist"