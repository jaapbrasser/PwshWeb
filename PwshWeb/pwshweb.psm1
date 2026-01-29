#requires -Version 5.1

<#
.SYNOPSIS
    Starts a lightweight PowerShell web server.

.DESCRIPTION
    Start-PwshWeb starts a lightweight HTTP web server similar to Python's http.server.
    It serves files from the current directory or a specified directory.

.PARAMETER Port
    The port number to listen on. Defaults to 8000.

.PARAMETER Path
    The directory to serve files from. Defaults to the current directory.

.PARAMETER AsJob
    Run the web server as a background job.

.PARAMETER WhatIf
    Shows what would happen if the cmdlet runs. The cmdlet is not run.

.PARAMETER Confirm
    Prompts you for confirmation before running the cmdlet.

.EXAMPLE
    Start-PwshWeb
    Starts a web server on port 8000 serving the current directory.

.EXAMPLE
    Start-PwshWeb -Port 8080 -Path C:\Website
    Starts a web server on port 8080 serving C:\Website.

.EXAMPLE
    Start-PwshWeb -Port 9000 -AsJob
    Starts a web server, servering the current dictory as a background job on port 9000.
#>
function Start-PwshWeb {
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'Default')]
    param(
        [Parameter(Position = 0, ParameterSetName = 'Default')]
        [Parameter(Position = 0, ParameterSetName = 'AsJob')]
        [ValidateRange(1, 65535)]
        [int]$Port = 8000,

        [Parameter(Position = 1, ParameterSetName = 'Default')]
        [Parameter(Position = 1, ParameterSetName = 'AsJob')]
        [ValidateScript({
            if (-not (Test-Path -Path $_ -PathType Container)) {
                throw "Path '$_' does not exist or is not a directory."
            }
            $true
        })]
        [string]$Path = (Get-Location).Path,

        [Parameter(ParameterSetName = 'AsJob')]
        [switch]$AsJob
    )

    begin {
        $resolvedPath = (Resolve-Path -Path $Path).Path
        $uri = "http://localhost:$Port/"
    }

    process {
        if (-not $PSCmdlet.ShouldProcess("web server on port $Port serving '$resolvedPath'", 'Start')) {
            return
        }

        # Define helper functions as strings to inject into the job scriptblock
        $getDirectoryListingFunction = @'
function Get-DirectoryListing {
    param($Path, $RequestPath, $RootPath)

    $displayPath = if ([string]::IsNullOrEmpty($RequestPath)) { '/' } else { "/$RequestPath/" }
    $escapedPath = [System.Net.WebUtility]::HtmlEncode($displayPath)

    $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Directory listing for $escapedPath</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 40px; }
        h1 { border-bottom: 1px solid #ccc; padding-bottom: 10px; }
        table { border-collapse: collapse; width: 100%; max-width: 800px; }
        th, td { text-align: left; padding: 8px; }
        th { border-bottom: 2px solid #ddd; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        a { text-decoration: none; color: #0066cc; }
        a:hover { text-decoration: underline; }
        .size { text-align: right; }
    </style>
</head>
<body>
    <h1>Directory listing for $escapedPath</h1>
    <table>
        <tr><th>Name</th><th>Size</th><th>Modified</th></tr>
"@

    # Parent directory link
    if ($Path -ne $RootPath) {
        $parentUrl = if ($RequestPath -contains '/') {
            $RequestPath.Substring(0, $RequestPath.LastIndexOf('/'))
        } else { '' }
        $html += "        <tr><td><a href='/$parentUrl'>..</a></td><td>-</td><td>-</td></tr>`n"
    }

    # List directories first
    Get-ChildItem -Path $Path -Directory -ErrorAction SilentlyContinue | Sort-Object Name | ForEach-Object {
        $name = [System.Net.WebUtility]::HtmlEncode($_.Name)
        $url = if ([string]::IsNullOrEmpty($RequestPath)) { $_.Name } else { "$RequestPath/$($_.Name)" }
        $modified = $_.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')
        $html += "        <tr><td><a href='/$url/'>$name/</a></td><td>-</td><td>$modified</td></tr>`n"
    }

    # Then list files
    Get-ChildItem -Path $Path -File -ErrorAction SilentlyContinue | Sort-Object Name | ForEach-Object {
        $name = [System.Net.WebUtility]::HtmlEncode($_.Name)
        $url = if ([string]::IsNullOrEmpty($RequestPath)) { $_.Name } else { "$RequestPath/$($_.Name)" }
        $size = Format-FileSize -Size $_.Length
        $modified = $_.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')
        $html += "        <tr><td><a href='/$url'>$name</a></td><td class='size'>$size</td><td>$modified</td></tr>`n"
    }

    $html += @"
    </table>
    <hr>
    <p><em>PwshWeb Server</em></p>
</body>
</html>
"@
    return $html
}
'@

        $formatFileSizeFunction = @'
function Format-FileSize {
    param([long]$Size)
    if ($Size -ge 1GB) { return '{0:N2} GB' -f ($Size / 1GB) }
    if ($Size -ge 1MB) { return '{0:N2} MB' -f ($Size / 1MB) }
    if ($Size -ge 1KB) { return '{0:N2} KB' -f ($Size / 1KB) }
    return "$Size bytes"
}
'@

        $getContentTypeFunction = @'
function Get-ContentType {
    param([string]$Extension)
    $mimeTypes = @{
        '.html' = 'text/html'
        '.htm'  = 'text/html'
        '.css'  = 'text/css'
        '.js'   = 'application/javascript'
        '.json' = 'application/json'
        '.xml'  = 'application/xml'
        '.txt'  = 'text/plain'
        '.md'   = 'text/markdown'
        '.jpg'  = 'image/jpeg'
        '.jpeg' = 'image/jpeg'
        '.png'  = 'image/png'
        '.gif'  = 'image/gif'
        '.svg'  = 'image/svg+xml'
        '.ico'  = 'image/x-icon'
        '.pdf'  = 'application/pdf'
        '.zip'  = 'application/zip'
        '.mp3'  = 'audio/mpeg'
        '.mp4'  = 'video/mp4'
        '.webm' = 'video/webm'
    }
    $ext = $Extension.ToLower()
    if ($mimeTypes.ContainsKey($ext)) {
        return $mimeTypes[$ext]
    }
    return 'application/octet-stream'
}
'@

        $scriptBlock = {
            param($Port, $RootPath, $VerbosePreference, $GetDirectoryListingFunction, $FormatFileSizeFunction, $GetContentTypeFunction)

            # Import required types inside the job
            Add-Type -AssemblyName System.Net.HttpListener -ErrorAction SilentlyContinue
            Add-Type -AssemblyName System.Web -ErrorAction SilentlyContinue

            # Define helper functions
            Invoke-Expression $GetDirectoryListingFunction
            Invoke-Expression $FormatFileSizeFunction
            Invoke-Expression $GetContentTypeFunction

            $listener = $null
            $runspaceId = [System.Guid]::NewGuid().ToString()

            try {
                $listener = New-Object System.Net.HttpListener
                $listener.Prefixes.Clear()
                $listener.Prefixes.Add("http://localhost:$Port/")
                # or:
                # $listener.Prefixes.Add("http://127.0.0.1:$Port/")
                $listener.Start()

                # Create server info object
                $serverInfo = [PSCustomObject]@{
                    PSTypeName   = 'PwshWeb.ServerInfo'
                    Port         = $Port
                    Path         = $RootPath
                    Uri          = "http://localhost:$Port/"
                    State        = 'Running'
                    StartTime    = Get-Date
                    RunspaceId   = $runspaceId
                    Listener     = $listener
                }

                # Add custom type for formatting
                if (-not ($serverInfo.PSTypeNames -contains 'PwshWeb.ServerInfo')) {
                    $serverInfo.PSTypeNames.Insert(0, 'PwshWeb.ServerInfo')
                }

                Write-Verbose "PwshWeb server started on port $Port serving '$RootPath'" -Verbose:$($VerbosePreference -eq 'Continue')

                # Output server info once at start
                $serverInfo

                while ($listener.IsListening) {
                    $context = $null
                    try {
                        $contextTask = $listener.GetContextAsync()
                        while (-not $contextTask.Wait(100)) {
                            Start-Sleep -Milliseconds 10
                        }
                        $context = $contextTask.Result
                    }
                    catch {
                        break
                    }

                    if ($null -eq $context) { continue }

                    $request = $context.Request
                    $response = $context.Response
                    $requestPath = $request.Url.LocalPath.TrimStart('/')
                    $localPath = Join-Path -Path $RootPath -ChildPath $requestPath

                    Write-Verbose "[$runspaceId] $($request.HttpMethod) $($request.Url)" -Verbose:$($VerbosePreference -eq 'Continue')

                    try {
                        if (Test-Path -Path $localPath -PathType Container) {
                            # Generate directory listing
                            $content = Get-DirectoryListing -Path $localPath -RequestPath $requestPath -RootPath $RootPath
                            $buffer = [System.Text.Encoding]::UTF8.GetBytes($content)
                            $response.ContentType = 'text/html; charset=utf-8'
                            $response.ContentLength64 = $buffer.Length
                            $response.OutputStream.Write($buffer, 0, $buffer.Length)
                        }
                        elseif (Test-Path -Path $localPath -PathType Leaf) {
                            # Serve file
                            $fileInfo = Get-Item -Path $localPath
                            $contentType = Get-ContentType -Extension $fileInfo.Extension
                            $fileBytes = [System.IO.File]::ReadAllBytes($localPath)
                            $response.ContentType = $contentType
                            $response.ContentLength64 = $fileBytes.Length
                            $response.OutputStream.Write($fileBytes, 0, $fileBytes.Length)
                        }
                        else {
                            # 404 Not Found
                            $response.StatusCode = 404
                            $content = '<html><body><h1>404 Not Found</h1></body></html>'
                            $buffer = [System.Text.Encoding]::UTF8.GetBytes($content)
                            $response.ContentLength64 = $buffer.Length
                            $response.OutputStream.Write($buffer, 0, $buffer.Length)
                        }
                    }
                    catch {
                        Write-Verbose "[$runspaceId] Error: $_" -Verbose:$($VerbosePreference -eq 'Continue')
                        $response.StatusCode = 500
                        $errorMessage = $_.Exception.Message -replace '<', '<' -replace '>', '>'
                        $content = "<html><body><h1>500 Internal Server Error</h1><p>$errorMessage</p></body></html>"
                        $buffer = [System.Text.Encoding]::UTF8.GetBytes($content)
                        $response.ContentLength64 = $buffer.Length
                        $response.OutputStream.Write($buffer, 0, $buffer.Length)
                    }
                    finally {
                        $response.Close()
                    }
                }
            }
            catch {
                Write-Error "PwshWeb server error: $_"
            }
            finally {
                if ($null -ne $listener) {
                    $listener.Close()
                }
                Write-Verbose "[$runspaceId] PwshWeb server stopped" -Verbose:$($VerbosePreference -eq 'Continue')
            }
        }

        if ($AsJob) {
            Write-Verbose "Starting PwshWeb server as background job..."

            # Create the job wrapper first with pending state
            $jobWrapper = [PSCustomObject]@{
                PSTypeName = 'PwshWeb.ServerJob'
                Job        = $null
                Port       = $Port
                Path       = $resolvedPath
                Uri        = $uri
                State      = 'Starting'
                StartTime  = Get-Date
            }

            # Add custom type for formatting
            if (-not ($jobWrapper.PSTypeNames -contains 'PwshWeb.ServerJob')) {
                $jobWrapper.PSTypeNames.Insert(0, 'PwshWeb.ServerJob')
            }

            $job = Start-Job -ScriptBlock $scriptBlock -ArgumentList $Port, $resolvedPath, $VerbosePreference, $getDirectoryListingFunction, $formatFileSizeFunction, $getContentTypeFunction
            $jobWrapper.Job = $job

            # Wait for the job to start and verify it's running
            $timeout = [DateTime]::Now.AddSeconds(10)
            $started = $false
            while ([DateTime]::Now -lt $timeout -and -not $started) {
                Start-Sleep -Milliseconds 200
                $jobState = $job.State
                if ($jobState -eq 'Running' -or $jobState -eq 'Blocked') {
                    # Give the listener time to actually bind to the port
                    Start-Sleep -Milliseconds 500
                    $started = $true
                }
            }

            if (-not $started) {
                $job | Stop-Job -ErrorAction SilentlyContinue
                $job | Remove-Job -ErrorAction SilentlyContinue
                throw "Failed to start PwshWeb server as background job. Job state: $($job.State)"
            }

            $jobWrapper.State = 'Running'
            Write-Verbose "PwshWeb server started as job $($job.Id) on port $Port"
            return $jobWrapper
        }
        else {
            # Run in current session
            Write-Verbose "Starting PwshWeb server in current session..."
            & $scriptBlock -Port $Port -RootPath $resolvedPath -VerbosePreference $VerbosePreference -GetDirectoryListingFunction $getDirectoryListingFunction -FormatFileSizeFunction $formatFileSizeFunction -GetContentTypeFunction $getContentTypeFunction
        }
    }
}

# Export the function
Export-ModuleMember -Function Start-PwshWeb
