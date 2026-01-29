# PwshWeb

A lightweight PowerShell web server inspired by Python's `http.server`.

## Overview

PwshWeb provides a simple, Python-like syntax for starting HTTP web servers directly from PowerShell. It serves files from a directory and provides automatic directory listings, similar to Python's built-in `http.server` module.

## Features

- **Python-like syntax**: `Start-PwshWeb [PORT]` - just like `python3 -m http.server [PORT]`
- **Default port 8000**: Matches Python's http.server default behavior
- **Background job support**: Run the server as a background PowerShell job with `-AsJob`
- **Rich object output**: Returns detailed server information objects
- **Directory listings**: Auto-generated HTML directory listings
- **MIME type support**: Serves common file types with proper content types
- **Cross-platform**: Works on Windows, macOS, and Linux
- **WhatIf support**: Preview operations before executing

## Quick Example

```powershell
# Start server on default port 8000
Start-PwshWeb

# Start server on port 8080
Start-PwshWeb -Port 8080

# Start server as background job
$server = Start-PwshWeb -Port 9000 -AsJob

# Stop the background job
Stop-Job $server.Job
Remove-Job $server.Job
```

## Installation

```powershell
# Clone the repository
git clone https://github.com/pwshweb/pwshweb.git

# Import the module
Import-Module ./PwshWeb/PwshWeb.psd1
```

## Requirements

- PowerShell 5.1 or higher (PowerShell 7.x recommended)
- .NET Framework (Windows) or .NET Core (cross-platform)