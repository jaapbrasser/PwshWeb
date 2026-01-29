# Start-PwshWeb

## Synopsis

Starts a lightweight PowerShell web server.

## Syntax

```powershell
Start-PwshWeb
    [[-Port] <Int32>]
    [[-Path] <String>]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

```powershell
Start-PwshWeb
    [[-Port] <Int32>]
    [[-Path] <String>]
    -AsJob
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

## Description

The `Start-PwshWeb` cmdlet starts a lightweight HTTP web server similar to Python's `http.server`. It serves files from the current directory or a specified directory and provides automatic HTML directory listings.

When run without the `-AsJob` parameter, the server runs in the current session and blocks until stopped (Ctrl+C). When run with `-AsJob`, the server runs as a background PowerShell job and returns a [`PwshWeb.ServerJob`](PwshWeb/PwshWeb.psm1:1) object.

## Parameters

### -Port

The port number to listen on. Defaults to 8000.

| Type | Int32 |
|------|-------|
| Position | 0 |
| Default value | 8000 |
| Accept pipeline input | False |
| Accept wildcard characters | False |

Valid range: 1-65535

### -Path

The directory to serve files from. Defaults to the current directory.

| Type | String |
|------|--------|
| Position | 1 |
| Default value | Current directory |
| Accept pipeline input | False |
| Accept wildcard characters | False |

The path must exist and be a directory.

### -AsJob

Run the web server as a background job.

| Type | SwitchParameter |
|------|-----------------|
| Position | Named |
| Default value | None |
| Accept pipeline input | False |
| Accept wildcard characters | False |

When specified, the server runs in a background job and the cmdlet returns a [`PwshWeb.ServerJob`](PwshWeb/PwshWeb.psm1:1) object.

### -WhatIf

Shows what would happen if the cmdlet runs. The cmdlet is not run.

| Type | SwitchParameter |
|------|-----------------|
| Position | Named |
| Default value | None |
| Accept pipeline input | False |
| Accept wildcard characters | False |

### -Confirm

Prompts you for confirmation before running the cmdlet.

| Type | SwitchParameter |
|------|-----------------|
| Position | Named |
| Default value | None |
| Accept pipeline input | False |
| Accept wildcard characters | False |

## Inputs

None. You cannot pipe input to `Start-PwshWeb`.

## Outputs

### PwshWeb.ServerJob

When the `-AsJob` parameter is specified, the cmdlet returns a `PwshWeb.ServerJob` object with the following properties:

| Property | Type | Description |
|----------|------|-------------|
| Port | Int32 | The port the server is listening on |
| Path | String | The directory being served |
| Uri | String | The server URI (e.g., `http://localhost:8000/`) |
| State | String | The server state (Running, Starting) |
| StartTime | DateTime | When the server started |
| Job | Job | The PowerShell background job object |

## Notes

- The server binds to `http://+:{Port}/` which allows connections from any IP address
- The server supports common MIME types including HTML, CSS, JS, JSON, images, and more
- Directory listings are automatically generated for directories
- 404 errors are returned for non-existent files
- 500 errors are returned for server errors

## Examples

### Example 1: Start server on default port

```powershell
Start-PwshWeb
```

Starts a web server on port 8000 serving the current directory. The session will block until the server is stopped.

### Example 2: Start server on custom port

```powershell
Start-PwshWeb -Port 8080
```

Starts a web server on port 8080 serving the current directory.

### Example 3: Start server serving specific directory

```powershell
Start-PwshWeb -Port 8080 -Path C:\Website
```

Starts a web server on port 8080 serving the `C:\Website` directory.

### Example 4: Start server as background job

```powershell
$server = Start-PwshWeb -Port 9000 -AsJob
```

Starts a web server as a background job on port 9000 and stores the job object in `$server`.

### Example 5: Stop background server

```powershell
Stop-Job $server.Job
Remove-Job $server.Job
```

Stops and removes the background job created in Example 4.

### Example 6: Preview with WhatIf

```powershell
Start-PwshWeb -Port 8080 -WhatIf
```

Shows what would happen if the server were started, without actually starting it.

### Example 7: Verbose output

```powershell
Start-PwshWeb -Verbose
```

Starts the server with verbose logging of all requests.

## Related Links

- [Python http.server documentation](https://docs.python.org/3/library/http.server.html)