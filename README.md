# PwshWeb

**PwshWeb** is a lightweight, cross-platform PowerShell web server inspired by Python’s built-in `http.server`. It is designed for quick, ad-hoc file serving and local development scenarios with minimal setup and a familiar, Python-like command experience.

If you need a simple way to expose a directory over HTTP, inspect files via a browser, or spin up a temporary web server directly from PowerShell, this module is built for that exact use case.

---

## 🔨 Installation

Load the module by using:

```powershell
Import-Module PwshWeb
```

## 🚀 Overview
PwshWeb provides a clean, minimal interface for starting an HTTP server directly from PowerShell. Its behavior intentionally mirrors Python’s python3 -m http.server, making it intuitive for anyone familiar with that workflow.

By default, PwshWeb serves files from the current working directory and automatically generates directory listings in HTML.

## ✨ Features
* Python-like syntax
    * Start-PwshWeb [PORT] — comparable to python3 -m http.server [PORT]
* Default port 8000
    * Matches Python’s default behavior
* Background job support
    * Run the server as a PowerShell background job using -AsJob
* Rich object output
    * Returns structured objects with server metadata (port, root path, job info)
* Automatic directory listings
    * HTML directory indexes generated on the fly
* MIME type support
    * Common file types are served with appropriate content types
* Cross-platform
    * Works on Windows, macOS, and Linux (PowerShell 7+)
* WhatIf support
    * Preview server startup behavior without binding ports

## ⚡ Quick Start
Start a web server on the default port (8000):

```powershell
Start-PwshWeb
```

Start a server on a custom port:

```powershell
Start-PwshWeb -Port 8080
```

Run the server as a background job:

```powershell
$server = Start-PwshWeb -Port 9000 -AsJob
```

Stop and clean up the background job:

```powershell
Stop-Job $server.Job
Remove-Job $server.Job
```

## 📘 Documentation
The module is intentionally small and focused. If behavior is unclear or undocumented, please open an issue. The goal is simplicity, predictability, and parity with Python’s http.server—not a full web framework.

Planned and existing documentation typically covers:

Command reference (Start-PwshWeb)

Object output structure

Cross-platform considerations

Security and local-network usage notes

## 💪 Contributing
Contributions are welcome and encouraged. This includes:

* Bug reports
* Documentation improvements
* Feature requests that align with the module’s minimal philosophy

Please keep changes lightweight and focused—PwshWeb is intentionally not a full-featured web server.

## 📌 License
MIT License