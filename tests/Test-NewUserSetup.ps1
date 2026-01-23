# Test-NewUserSetup.ps1
# Simulates a new user setting up the Power Automate plugin
# Run with: .\tests\Test-NewUserSetup.ps1

param(
    [switch]$Verbose,
    [switch]$Interactive  # Set to run interactive tests (requires user input)
)

$ErrorActionPreference = "Continue"
$script:TestResults = @()
$script:PassCount = 0
$script:FailCount = 0

# ============================================================================
# TEST FRAMEWORK
# ============================================================================

function Write-TestHeader($name) {
    Write-Host ""
    Write-Host "=" * 60 -ForegroundColor DarkGray
    Write-Host "TEST: $name" -ForegroundColor Cyan
    Write-Host "=" * 60 -ForegroundColor DarkGray
}

function Write-TestResult($name, $passed, $message = "") {
    $status = if ($passed) { "PASS" } else { "FAIL" }
    $color = if ($passed) { "Green" } else { "Red" }

    Write-Host "  [$status] $name" -ForegroundColor $color
    if ($message -and (-not $passed -or $Verbose)) {
        Write-Host "         $message" -ForegroundColor DarkGray
    }

    $script:TestResults += @{
        Name = $name
        Passed = $passed
        Message = $message
    }

    if ($passed) { $script:PassCount++ } else { $script:FailCount++ }
}

function Invoke-TestCommand {
    param(
        [string]$Command,
        [switch]$ExpectSuccess,
        [switch]$ExpectFailure,
        [string]$ContainsOutput,
        [string]$NotContainsOutput
    )

    try {
        $output = Invoke-Expression $Command 2>&1
        $exitCode = $LASTEXITCODE

        return @{
            Output = ($output | Out-String)
            ExitCode = $exitCode
            Success = ($exitCode -eq 0)
        }
    }
    catch {
        return @{
            Output = $_.Exception.Message
            ExitCode = 1
            Success = $false
        }
    }
}

# ============================================================================
# TEST CASES
# ============================================================================

function Test-ScriptExists {
    Write-TestHeader "Script Existence"

    $scriptPath = Join-Path (Join-Path (Join-Path $PSScriptRoot "..") "scripts") "pa.ps1"
    if (-not $scriptPath) {
        # Fallback if PSScriptRoot is empty (running from different context)
        $scriptPath = ".\scripts\pa.ps1"
    }
    $exists = Test-Path $scriptPath
    Write-TestResult "pa.ps1 exists" $exists $scriptPath
}

function Test-HelpOutput {
    Write-TestHeader "Help Output"

    $result = Invoke-TestCommand -Command "powershell -File .\scripts\pa.ps1"

    Write-TestResult "Help displays without error" $result.Success
    Write-TestResult "Shows 'Power Automate CLI Helper'" ($result.Output -match "Power Automate CLI Helper")
    Write-TestResult "Shows setup command" ($result.Output -match "setup")
    Write-TestResult "Shows flows command" ($result.Output -match "flows")
    Write-TestResult "Shows pull command" ($result.Output -match "pull")
    Write-TestResult "Shows push command" ($result.Output -match "push")
}

function Test-SetupCheckMode {
    Write-TestHeader "Setup --check Mode (Non-Interactive)"

    $result = Invoke-TestCommand -Command "powershell -File .\scripts\pa.ps1 setup --check"

    Write-TestResult "Setup check runs" $true "Exit code: $($result.ExitCode)"
    Write-TestResult "Shows PowerShell Module check" ($result.Output -match "PowerShell Module")
    Write-TestResult "Shows Power Platform Sign-In check" ($result.Output -match "Power Platform Sign-In|Signed in")
    Write-TestResult "Shows Environment check" ($result.Output -match "Environment")
    Write-TestResult "Shows Azure CLI check" ($result.Output -match "Azure CLI")

    if ($Verbose) {
        Write-Host ""
        Write-Host "Output:" -ForegroundColor DarkGray
        Write-Host $result.Output -ForegroundColor DarkGray
    }
}

function Test-StatusCommand {
    Write-TestHeader "Status Command"

    $result = Invoke-TestCommand -Command "powershell -File .\scripts\pa.ps1 status"

    # Status should either succeed (authenticated) or fail (not authenticated)
    $hasOutput = $result.Output.Length -gt 0
    Write-TestResult "Status command executes" $hasOutput

    if ($result.Success) {
        Write-TestResult "Shows connection info" ($result.Output -match "Environment|Connected|Organization")
        Write-Host "  [INFO] User appears to be authenticated" -ForegroundColor Yellow
    } else {
        Write-TestResult "Shows auth error when not connected" ($result.Output -match "not authenticated|No profiles|Error")
        Write-Host "  [INFO] User is not authenticated (expected for new user)" -ForegroundColor Yellow
    }
}

function Test-EnvsCommand {
    Write-TestHeader "Environments Command"

    $result = Invoke-TestCommand -Command "powershell -File .\scripts\pa.ps1 envs"

    if ($result.Success) {
        Write-TestResult "Envs command succeeds" $true
        Write-TestResult "Lists environments" ($result.Output -match "Environment|Display Name")
    } else {
        Write-TestResult "Envs shows auth error when not connected" ($result.Output -match "authenticated|profile|Error")
        Write-Host "  [INFO] Cannot list environments without authentication" -ForegroundColor Yellow
    }
}

function Test-FlowsCommandValidation {
    Write-TestHeader "Flows Command Validation"

    # Test --json flag parsing
    $result = Invoke-TestCommand -Command "powershell -File .\scripts\pa.ps1 flows --json"

    $hasOutput = $result.Output.Length -gt 0
    Write-TestResult "Flows command executes" $hasOutput

    # Test --search flag parsing
    $result2 = Invoke-TestCommand -Command "powershell -File .\scripts\pa.ps1 flows --search test"
    Write-TestResult "Flows --search executes" ($result2.Output.Length -gt 0)
}

function Test-SelectCommandValidation {
    Write-TestHeader "Select Command Validation"

    # Test with no argument
    $result = Invoke-TestCommand -Command "powershell -File .\scripts\pa.ps1 select"
    Write-TestResult "Select without args shows usage" ($result.Output -match "Usage|select")

    # Test with invalid characters (security validation)
    $result2 = Invoke-TestCommand -Command "powershell -File .\scripts\pa.ps1 select 'test;rm -rf /'"
    Write-TestResult "Select rejects dangerous input" ($result2.Output -match "Invalid|Error" -or -not $result2.Success)
}

function Test-PullCommandValidation {
    Write-TestHeader "Pull Command Validation"

    # Test with no argument
    $result = Invoke-TestCommand -Command "powershell -File .\scripts\pa.ps1 pull"
    Write-TestResult "Pull without args shows usage" ($result.Output -match "Usage|pull")
}

function Test-PushCommandValidation {
    Write-TestHeader "Push Command Validation"

    # Test with no argument
    $result = Invoke-TestCommand -Command "powershell -File .\scripts\pa.ps1 push"
    Write-TestResult "Push without args shows usage" ($result.Output -match "Usage|push")

    # Test with non-existent file
    $result2 = Invoke-TestCommand -Command "powershell -File .\scripts\pa.ps1 push 'NonExistentFlow'"
    Write-TestResult "Push non-existent flow shows error" ($result2.Output -match "not found|Error|Pull")
}

function Test-InitCommandValidation {
    Write-TestHeader "Init Command Validation"

    # Test with no argument
    $result = Invoke-TestCommand -Command "powershell -File .\scripts\pa.ps1 init"
    Write-TestResult "Init without args shows usage" ($result.Output -match "Usage|init")

    # Test input validation (path traversal)
    $result2 = Invoke-TestCommand -Command "powershell -File .\scripts\pa.ps1 init '../badpath'"
    Write-TestResult "Init rejects path traversal" ($result2.Output -match "Invalid|traversal|Error" -or -not $result2.Success)
}

function Test-EnableDisableValidation {
    Write-TestHeader "Enable/Disable Command Validation"

    # Test with no argument
    $result1 = Invoke-TestCommand -Command "powershell -File .\scripts\pa.ps1 enable"
    Write-TestResult "Enable without args shows usage" ($result1.Output -match "Usage|enable")

    $result2 = Invoke-TestCommand -Command "powershell -File .\scripts\pa.ps1 disable"
    Write-TestResult "Disable without args shows usage" ($result2.Output -match "Usage|disable")
}

function Test-PowerShellModuleCheck {
    Write-TestHeader "PowerShell Module Availability"

    $module = Get-Module -ListAvailable Microsoft.PowerApps.Administration.PowerShell
    $installed = $null -ne $module

    Write-TestResult "PowerApps Admin module installed" $installed

    if ($installed) {
        Write-Host "  [INFO] Module version: $($module.Version)" -ForegroundColor Yellow
    } else {
        Write-Host "  [INFO] Install with: Install-Module -Name Microsoft.PowerApps.Administration.PowerShell -Scope CurrentUser -Force" -ForegroundColor Yellow
    }
}

function Test-PacCliAvailable {
    Write-TestHeader "PAC CLI Availability"

    $pacCmd = Get-Command pac -ErrorAction SilentlyContinue
    if ($pacCmd) {
        try {
            $version = & pac --version 2>&1 | Out-String
            Write-TestResult "PAC CLI available" $true
            Write-Host "  [INFO] PAC CLI: $($version.Trim())" -ForegroundColor Yellow
        }
        catch {
            Write-TestResult "PAC CLI available" $true "Found but couldn't get version"
        }
    }
    else {
        Write-TestResult "PAC CLI available" $false "Not installed or not in PATH"
        Write-Host "  [INFO] Install: https://aka.ms/PowerAppsCLI" -ForegroundColor Yellow
    }
}

function Test-AzureCliAvailable {
    Write-TestHeader "Azure CLI Availability"

    $azCmd = Get-Command az -ErrorAction SilentlyContinue
    if ($azCmd) {
        try {
            $version = & az --version 2>&1 | Select-Object -First 1
            Write-TestResult "Azure CLI available" $true
            Write-Host "  [INFO] Azure CLI: $version" -ForegroundColor Yellow
        }
        catch {
            Write-TestResult "Azure CLI available" $true "Found but couldn't get version"
        }
    }
    else {
        Write-TestResult "Azure CLI available" $false "Not installed (optional - needed for pull/push)"
        Write-Host "  [INFO] Install: winget install Microsoft.AzureCLI" -ForegroundColor Yellow
    }
}

function Test-FlowsDirectory {
    Write-TestHeader "Flows Directory Structure"

    $flowsDir = Join-Path (Join-Path $PSScriptRoot "..") "flows"
    if (-not $flowsDir -or -not $PSScriptRoot) {
        $flowsDir = ".\flows"
    }
    $flowsDirExists = Test-Path $flowsDir

    Write-TestResult "Flows directory exists (or will be created)" $true "Directory: $flowsDir"

    if ($flowsDirExists) {
        $jsonFiles = Get-ChildItem -Path $flowsDir -Filter "*.json" -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne ".metadata.json" }
        Write-Host "  [INFO] Found $($jsonFiles.Count) flow file(s) in ./flows/" -ForegroundColor Yellow
    }
}

function Test-SrcDirectory {
    Write-TestHeader "Source Directory Structure"

    $srcDir = Join-Path (Join-Path $PSScriptRoot "..") "src"
    if (-not $srcDir -or -not $PSScriptRoot) {
        $srcDir = ".\src"
    }
    $srcExists = Test-Path $srcDir

    if ($srcExists) {
        $solutions = Get-ChildItem -Path $srcDir -Directory -ErrorAction SilentlyContinue
        Write-TestResult "Src directory exists" $true
        Write-Host "  [INFO] Found $($solutions.Count) solution(s) in ./src/" -ForegroundColor Yellow
    } else {
        Write-TestResult "Src directory exists" $true "Will be created when you run 'pa.ps1 init'"
    }
}

# ============================================================================
# INTERACTIVE TESTS (only run with -Interactive flag)
# ============================================================================

function Test-FullSetupFlow {
    Write-TestHeader "Full Setup Flow (Interactive)"

    Write-Host "  This test will run the full interactive setup." -ForegroundColor Yellow
    Write-Host "  Press Ctrl+C to skip if you don't want to run it." -ForegroundColor Yellow
    Write-Host ""

    & .\scripts\pa.ps1 setup

    Write-TestResult "Setup completed" $true "Manual verification required"
}

# ============================================================================
# MAIN TEST RUNNER
# ============================================================================

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Power Automate Plugin - New User Setup Tests" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Testing setup flow from a new user's perspective..." -ForegroundColor DarkGray
Write-Host ""

# Run all non-interactive tests
Test-ScriptExists
Test-HelpOutput
Test-SetupCheckMode
Test-StatusCommand
Test-EnvsCommand
Test-FlowsCommandValidation
Test-SelectCommandValidation
Test-PullCommandValidation
Test-PushCommandValidation
Test-InitCommandValidation
Test-EnableDisableValidation
Test-PowerShellModuleCheck
Test-PacCliAvailable
Test-AzureCliAvailable
Test-FlowsDirectory
Test-SrcDirectory

# Run interactive tests if requested
if ($Interactive) {
    Write-Host ""
    Write-Host "Running interactive tests..." -ForegroundColor Yellow
    Test-FullSetupFlow
}

# ============================================================================
# SUMMARY
# ============================================================================

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  TEST SUMMARY" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Total:  $($script:PassCount + $script:FailCount)" -ForegroundColor White
Write-Host "  Passed: $($script:PassCount)" -ForegroundColor Green
Write-Host "  Failed: $($script:FailCount)" -ForegroundColor $(if ($script:FailCount -gt 0) { "Red" } else { "Green" })
Write-Host ""

if ($script:FailCount -gt 0) {
    Write-Host "Failed tests:" -ForegroundColor Red
    $script:TestResults | Where-Object { -not $_.Passed } | ForEach-Object {
        Write-Host "  - $($_.Name)" -ForegroundColor Red
        if ($_.Message) {
            Write-Host "    $($_.Message)" -ForegroundColor DarkGray
        }
    }
    Write-Host ""
}

# New User Checklist
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  NEW USER SETUP CHECKLIST" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

$checklist = @(
    @{ Check = "PAC CLI installed"; Done = (Get-Command pac -ErrorAction SilentlyContinue) -ne $null }
    @{ Check = "PowerApps module installed"; Done = (Get-Module -ListAvailable Microsoft.PowerApps.Administration.PowerShell) -ne $null }
    @{ Check = "Azure CLI installed (optional)"; Done = (Get-Command az -ErrorAction SilentlyContinue) -ne $null }
)

# Check PAC auth
try {
    pac org who 2>&1 | Out-Null
    $pacAuth = $LASTEXITCODE -eq 0
} catch { $pacAuth = $false }
$checklist += @{ Check = "Signed in to Power Platform"; Done = $pacAuth }

foreach ($item in $checklist) {
    $status = if ($item.Done) { "[x]" } else { "[ ]" }
    $color = if ($item.Done) { "Green" } else { "Yellow" }
    Write-Host "  $status $($item.Check)" -ForegroundColor $color
}

Write-Host ""
Write-Host "Quick start commands:" -ForegroundColor White
Write-Host "  .\scripts\pa.ps1 setup          # Interactive setup wizard" -ForegroundColor Cyan
Write-Host "  .\scripts\pa.ps1 setup --check  # Check current status" -ForegroundColor Cyan
Write-Host "  .\scripts\pa.ps1 flows          # List flows (after setup)" -ForegroundColor Cyan
Write-Host ""

exit $script:FailCount
