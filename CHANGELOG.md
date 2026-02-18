# Changelog

All notable changes to PwshWeb will be documented in this file.

## [1.0.2] - Unreleased

### Changed
- Added support for serving `index.html` and `index.htm` index files when a directory is requested
  - If an index file is present in the requested directory, it is served directly instead of generating a directory listing
  - Falls back to the directory listing when no index file is found

## [1.0.1] - 2026-01-29

### Fixed
- Changed HTTP listener prefix from `http://+:$Port/` to `http://localhost:$Port/` for improved compatibility and to avoid requiring elevated privileges on Windows
- Removed redundant `$listener.Stop()` call before `$listener.Close()` in the cleanup block to prevent double-stop errors
- Added missing newline at end of `pwshweb.psm1` and `pwshweb.psd1`

### Documentation
- Added full MkDocs-based documentation site with command reference, examples, quickstart guide, and contributing guide
- Added `README.md` with project overview, installation instructions, and usage examples
- Added `LICENSE` file

### CI/CD
- Added GitHub Actions CI pipeline for automated testing
- Updated CI workflow to only trigger on pull requests
- Added GitHub Actions workflow for automated documentation deployment

## [1.0.0] - 2026-01-29

### Added
- Initial release of PwshWeb — a lightweight PowerShell HTTP web server inspired by Python's `http.server`
- `Start-PwshWeb` function with the following features:
  - Serve files from the current directory or a specified path
  - Configurable port number (default: `8000`)
  - HTML directory listing for browsing served directories
  - MIME type detection for common file extensions
  - `-AsJob` parameter to run the server as a background job
  - `-WhatIf` and `-Confirm` support via `SupportsShouldProcess`
  - Verbose logging support
- Pester test suite covering core functionality
- Module manifest (`pwshweb.psd1`) targeting PowerShell 5.1 and above
