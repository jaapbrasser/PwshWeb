@{
    RootModule = 'pwshweb.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author = 'Jaap Brasser'
    Description = 'A lightweight PowerShell web server inspired by Python http.server'
    PowerShellVersion = '5.1'
    FunctionsToExport = @('Start-PwshWeb')
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('webserver', 'http', 'server', 'web')
            LicenseUri = ''
            ProjectUri = ''
        }
    }
}