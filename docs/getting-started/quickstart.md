# Quick Start

## Basic Usage

### Start Server on Default Port

Start a web server on port 8000 (just like Python's http.server):

```powershell
Start-PwshWeb
```

The server will start and block the current session. Press `Ctrl+C` to stop.

### Start Server on Custom Port

```powershell
Start-PwshWeb -Port 8080
```

### Start Server in Background

Run the server as a background job:

```powershell
$server = Start-PwshWeb -Port 9000 -AsJob
```

### Stop Background Server

```powershell
Stop-Job $server.Job
Remove-Job $server.Job
```

## Serving Specific Directory

```powershell
# Serve current directory (default)
Start-PwshWeb

# Serve specific directory
Start-PwshWeb -Port 8080 -Path C:\Website

# Serve directory with spaces
Start-PwshWeb -Port 8080 -Path "C:\My Website"
```

## Preview Mode

Use `-WhatIf` to see what would happen without starting the server:

```powershell
Start-PwshWeb -Port 8080 -WhatIf
```

Output:
```
What if: Performing the operation "Start" on target "web server on port 8080 serving 'C:\Website'".
```

## Verbose Output

Get detailed information about server operations:

```powershell
Start-PwshWeb -Verbose
```

Output:
```
VERBOSE: Performing the operation "Start" on target "web server on port 8000 serving 'C:\CurrentDirectory'".
VERBOSE: Starting PwshWeb server in current session...
VERBOSE: PwshWeb server started on port 8000 serving 'C:\CurrentDirectory'
VERBOSE: [guid] GET http://localhost:8000/
VERBOSE: [guid] GET http://localhost:8000/style.css
```

## Accessing the Server

Once running, access the server at:

```
http://localhost:8000/
```

Or with a custom port:

```
http://localhost:8080/
```

## Server Output Object

When running as a job, a rich object is returned:

```powershell
$server = Start-PwshWeb -Port 9000 -AsJob
$server
```

Output:
```
Port       : 9000
Path       : C:\CurrentDirectory
Uri        : http://localhost:9000/
State      : Running
StartTime  : 1/29/2026 6:00:00 PM
Job        : System.Management.Automation.PSRemotingJob
```

Access properties:

```powershell
$server.Port    # 9000
$server.Uri     # http://localhost:9000/
$server.Job.Id  # Job ID