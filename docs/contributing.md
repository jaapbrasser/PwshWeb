# Contributing

Thank you for your interest in contributing to PwshWeb!

## Development Setup

1. Fork the repository
2. Clone your fork:
   ```powershell
   git clone https://github.com/yourusername/pwshweb.git
   cd PwshWeb
   ```
3. Create a branch for your changes:
   ```powershell
   git checkout -b feature/my-feature
   ```

## Running Tests

All contributions should include tests. Run the test suite with:

```powershell
Invoke-Pester -Path ./Tests/PwshWeb.Tests.ps1
```

For detailed output:

```powershell
Invoke-Pester -Path ./Tests/PwshWeb.Tests.ps1 -Output Detailed
```

## Code Style

- Follow PowerShell best practices
- Use verb-noun naming for functions
- Include comment-based help for all public functions
- Add examples to comment-based help

## Documentation

Update documentation when adding or modifying features:

- Update comment-based help in the module
- Update relevant Markdown files in `docs/`
- Add examples for new functionality

## Submitting Changes

1. Commit your changes:
   ```powershell
   git add .
   git commit -m "Add feature: description"
   ```
2. Push to your fork:
   ```powershell
   git push origin feature/my-feature
   ```
3. Create a Pull Request

## Pull Request Guidelines

- Ensure all tests pass
- Update documentation
- Describe what your changes do and why
- Link any related issues

## Reporting Issues

When reporting issues, please include:

- PowerShell version (`$PSVersionTable.PSVersion`)
- Operating system
- Steps to reproduce
- Expected behavior
- Actual behavior
- Error messages (if any)

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.