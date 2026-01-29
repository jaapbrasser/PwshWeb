# Installation

## Prerequisites

- PowerShell 5.1 or higher (PowerShell 7.x recommended)
- .NET Framework (Windows) or .NET Core (cross-platform)

## Install from Source

### Clone the Repository

```powershell
# Clone the repository
git clone https://github.com/pwshweb/pwshweb.git
cd PwshWeb
```

### Import the Module

```powershell
# Import the module
Import-Module ./PwshWeb/PwshWeb.psd1

# Verify the module is loaded
Get-Module PwshWeb

# Get available commands
Get-Command -Module PwshWeb
```

### Permanent Installation

To make the module available in all PowerShell sessions:

```powershell
# Copy module to PowerShell Modules directory
$modulePath = Join-Path $env:PSModulePath.Split(';')[0] 'PwshWeb'
Copy-Item -Path ./PwshWeb -Destination $modulePath -Recurse -Force

# Now you can import without specifying path
Import-Module PwshWeb
```

## Verify Installation

```powershell
# Check if the command is available
Get-Command Start-PwshWeb

# Get help for the command
Get-Help Start-PwshWeb -Full

# Test with WhatIf
Start-PwshWeb -WhatIf