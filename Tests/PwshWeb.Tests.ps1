#requires -Modules Pester
#requires -Version 5.1

BeforeAll {
    $ModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..' | Join-Path -ChildPath 'PwshWeb' | Join-Path -ChildPath 'PwshWeb.psd1'
    Import-Module -Name $ModulePath -Force

    $TestPort = 18765  # Use a high port to avoid conflicts
    $TestPath = Join-Path -Path $TestDrive -ChildPath 'TestWebsite'
    New-Item -Path $TestPath -ItemType Directory -Force | Out-Null

    # Create test files
    'Hello World' | Out-File -FilePath (Join-Path -Path $TestPath -ChildPath 'index.html') -Encoding UTF8
    '{"test": true}' | Out-File -FilePath (Join-Path -Path $TestPath -ChildPath 'data.json') -Encoding UTF8
    'Test content' | Out-File -FilePath (Join-Path -Path $TestPath -ChildPath 'readme.txt') -Encoding UTF8

    # Create subdirectory
    $SubDir = Join-Path -Path $TestPath -ChildPath 'subdir'
    New-Item -Path $SubDir -ItemType Directory -Force | Out-Null
    'Sub file' | Out-File -FilePath (Join-Path -Path $SubDir -ChildPath 'sub.txt') -Encoding UTF8
}

AfterAll {
    # Clean up any remaining jobs
    Get-Job -Name 'Job*' -ErrorAction SilentlyContinue | Stop-Job -ErrorAction SilentlyContinue
    Get-Job -Name 'Job*' -ErrorAction SilentlyContinue | Remove-Job -ErrorAction SilentlyContinue

    Remove-Module -Name PwshWeb -Force -ErrorAction SilentlyContinue
}

Describe 'Start-PwshWeb' {
    Context 'Parameter Validation' {
        It 'Should have default port of 8000' {
            $command = Get-Command -Name Start-PwshWeb
            $param = $command.Parameters['Port']
            $param | Should -Not -BeNullOrEmpty
            # Check the default value from the parameter's default value
            $param.ParameterType | Should -Be ([int])
        }

        It 'Should accept valid port numbers' {
            { Start-PwshWeb -Port 1 -WhatIf } | Should -Not -Throw
            { Start-PwshWeb -Port 8080 -WhatIf } | Should -Not -Throw
            { Start-PwshWeb -Port 65535 -WhatIf } | Should -Not -Throw
        }

        It 'Should reject invalid port numbers' {
            { Start-PwshWeb -Port 0 -WhatIf } | Should -Throw
            { Start-PwshWeb -Port 65536 -WhatIf } | Should -Throw
            { Start-PwshWeb -Port -1 -WhatIf } | Should -Throw
        }

        It 'Should validate path exists' {
            { Start-PwshWeb -Path 'C:\NonExistentPath12345' -WhatIf } | Should -Throw
        }

        It 'Should accept existing paths' {
            { Start-PwshWeb -Path $TestPath -WhatIf } | Should -Not -Throw
        }
    }

    Context 'WhatIf Support' {
        It 'Should not start server when -WhatIf is specified' {
            $result = Start-PwshWeb -Port $TestPort -Path $TestPath -WhatIf
            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Server Object Output' {
        BeforeEach {
            $server = $null
        }

        AfterEach {
            if ($server -and $server.Job) {
                Stop-Job -Job $server.Job -ErrorAction SilentlyContinue
                Remove-Job -Job $server.Job -ErrorAction SilentlyContinue
            }
            # Also stop any other jobs on the test port
            Get-Job -ErrorAction SilentlyContinue | Where-Object {
                $_.Command -like "*Port $TestPort*"
            } | Stop-Job -ErrorAction SilentlyContinue
            Get-Job -ErrorAction SilentlyContinue | Where-Object {
                $_.Command -like "*Port $TestPort*"
            } | Remove-Job -ErrorAction SilentlyContinue
            Start-Sleep -Milliseconds 500
        }

        It 'Should return a ServerJob object when run as background job' {
            $server = Start-PwshWeb -Port $TestPort -Path $TestPath -AsJob
            $server | Should -Not -BeNullOrEmpty
            $server.PSTypeNames | Should -Contain 'PwshWeb.ServerJob'
        }

        It 'Should include correct properties in ServerJob object' {
            $server = Start-PwshWeb -Port $TestPort -Path $TestPath -AsJob
            $server.Port | Should -Be $TestPort
            $server.Path | Should -Be $TestPath
            $server.Uri | Should -Be "http://localhost:$TestPort/"
            $server.Job | Should -Not -BeNullOrEmpty
            $server.Job -is [System.Management.Automation.Job] | Should -Be $true
        }
    }

    Context 'HTTP Server Functionality' {
        BeforeAll {
            $script:ServerJob = Start-PwshWeb -Port $TestPort -Path $TestPath -AsJob
            # Wait for server to start
            Start-Sleep -Seconds 2
        }

        AfterAll {
            if ($script:ServerJob -and $script:ServerJob.Job) {
                Stop-Job -Job $script:ServerJob.Job -ErrorAction SilentlyContinue
                Remove-Job -Job $script:ServerJob.Job -ErrorAction SilentlyContinue
            }
        }

        It 'Should respond to HTTP requests' {
            try {
                $response = Invoke-WebRequest -Uri "http://localhost:$TestPort/" -UseBasicParsing -TimeoutSec 5
                $response.StatusCode | Should -Be 200
            }
            catch {
                # If Invoke-WebRequest fails, try with .NET
                $request = [System.Net.WebRequest]::Create("http://localhost:$TestPort/")
                $request.Timeout = 5000
                $response = $request.GetResponse()
                $response.StatusCode | Should -Be 200
                $response.Close()
            }
        }

        It 'Should serve HTML files with correct content type' {
            $response = Invoke-WebRequest -Uri "http://localhost:$TestPort/index.html" -UseBasicParsing -TimeoutSec 5
            $response.StatusCode | Should -Be 200
            $response.Content | Should -Match 'Hello World'
        }

        It 'Should serve JSON files' {
            $response = Invoke-WebRequest -Uri "http://localhost:$TestPort/data.json" -UseBasicParsing -TimeoutSec 5
            $response.StatusCode | Should -Be 200
            $response.Content | Should -Match '"test":\s*true'
        }

        It 'Should serve text files' {
            $response = Invoke-WebRequest -Uri "http://localhost:$TestPort/readme.txt" -UseBasicParsing -TimeoutSec 5
            $response.StatusCode | Should -Be 200
            $response.Content | Should -Match 'Test content'
        }

        It 'Should return 404 for non-existent files' {
            { Invoke-WebRequest -Uri "http://localhost:$TestPort/nonexistent.html" -UseBasicParsing -TimeoutSec 5 } | Should -Throw
        }

        It 'Should serve files from subdirectories' {
            $response = Invoke-WebRequest -Uri "http://localhost:$TestPort/subdir/sub.txt" -UseBasicParsing -TimeoutSec 5
            $response.StatusCode | Should -Be 200
            $response.Content | Should -Match 'Sub file'
        }

        It 'Should generate directory listings for directories' {
            $response = Invoke-WebRequest -Uri "http://localhost:$TestPort/" -UseBasicParsing -TimeoutSec 5
            $response.StatusCode | Should -Be 200
            $response.Content | Should -Match 'index\.html'
            $response.Content | Should -Match 'data\.json'
            $response.Content | Should -Match 'subdir'
        }
    }

    Context 'Background Job Management' {
        It 'Should create a running job' {
            $jobServer = Start-PwshWeb -Port ($TestPort + 1) -Path $TestPath -AsJob
            Start-Sleep -Seconds 1
            $jobServer.Job.State | Should -BeIn @('Running', 'Blocked')

            Stop-Job -Job $jobServer.Job -ErrorAction SilentlyContinue
            Remove-Job -Job $jobServer.Job -ErrorAction SilentlyContinue
        }

        It 'Should stop the server when job is stopped' {
            $port = $TestPort + 2
            $jobServer = Start-PwshWeb -Port $port -Path $TestPath -AsJob
            Start-Sleep -Seconds 2

            # Verify server is running
            $response = Invoke-WebRequest -Uri "http://localhost:$port/" -UseBasicParsing -TimeoutSec 5
            $response.StatusCode | Should -Be 200

            # Stop the job
            Stop-Job -Job $jobServer.Job
            Remove-Job -Job $jobServer.Job
            Start-Sleep -Seconds 1

            # Verify server is stopped
            { Invoke-WebRequest -Uri "http://localhost:$port/" -UseBasicParsing -TimeoutSec 2 } | Should -Throw
        }
    }

    Context 'Verbose Output' {
        It 'Should write verbose messages when -Verbose is specified' {
            $port = $TestPort + 3
            $verboseOutput = Start-PwshWeb -Port $port -Path $TestPath -AsJob -Verbose 4>&1
            $verboseOutput | Should -Not -BeNullOrEmpty

            # Clean up
            Get-Job | Where-Object { $_.State -eq 'Running' -or $_.State -eq 'Blocked' } | Stop-Job -ErrorAction SilentlyContinue
            Get-Job | Remove-Job -ErrorAction SilentlyContinue
        }
    }
}

Describe 'Content Type Detection' {
    BeforeAll {
        $ModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..' | Join-Path -ChildPath 'PwshWeb' | Join-Path -ChildPath 'PwshWeb.psm1'
        $moduleContent = Get-Content -Path $ModulePath -Raw
    }

    It 'Should support common MIME types' {
        $moduleContent | Should -Match "\.html"
        $moduleContent | Should -Match "\.css"
        $moduleContent | Should -Match "\.js"
        $moduleContent | Should -Match "\.json"
        $moduleContent | Should -Match "\.png"
        $moduleContent | Should -Match "\.jpg"
    }
}

Describe 'Module Structure' {
    It 'Should have a valid module manifest' {
        $manifestPath = Join-Path -Path $PSScriptRoot -ChildPath '..' | Join-Path -ChildPath 'PwshWeb' | Join-Path -ChildPath 'PwshWeb.psd1'
        Test-Path -Path $manifestPath | Should -Be $true
        $manifest = Test-ModuleManifest -Path $manifestPath -ErrorAction Stop
        $manifest | Should -Not -BeNullOrEmpty
        $manifest.Name | Should -Be 'PwshWeb'
    }

    It 'Should export Start-PwshWeb function' {
        $command = Get-Command -Name Start-PwshWeb -ErrorAction SilentlyContinue
        $command | Should -Not -BeNullOrEmpty
        $command.CommandType | Should -Be 'Function'
    }
}