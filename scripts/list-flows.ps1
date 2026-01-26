Import-Module Microsoft.PowerApps.Administration.PowerShell -DisableNameChecking 3>$null
$envInfoJson = pac org who --json 2>&1
$envInfo = $envInfoJson | ConvertFrom-Json
Write-Host "Environment: $($envInfo.FriendlyName)" -ForegroundColor Cyan
Write-Host ""
$flows = Get-AdminFlow -EnvironmentName $envInfo.EnvironmentId | Sort-Object DisplayName
for ($i = 0; $i -lt $flows.Count; $i++) {
    $f = $flows[$i]
    $status = if ($f.Enabled -eq $true) { "On" } else { "Off" }
    Write-Host "$($i + 1). $($f.DisplayName) [$status]"
}
Write-Host ""
Write-Host "$($flows.Count) flow(s) found." -ForegroundColor Cyan
