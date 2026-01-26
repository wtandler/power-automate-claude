# Create Hi Kyle flow via Dataverse API
$ErrorActionPreference = "Stop"

# Get environment info
$envInfoJson = pac org who --json 2>&1
$envInfo = $envInfoJson | ConvertFrom-Json
$orgUrl = $envInfo.OrgUrl

Write-Host "Creating flow in: $($envInfo.FriendlyName)" -ForegroundColor Cyan

# Get token
$token = az account get-access-token --resource $orgUrl.TrimEnd('/') --query accessToken -o tsv
if (-not $token) {
    Write-Host "Failed to get token. Run: az login" -ForegroundColor Red
    exit 1
}

# Flow definition
$flowDefinition = @{
    schemaVersion = "1.0.0.0"
    properties = @{
        connectionReferences = @{
            shared_office365 = @{
                connectionName = ""
                source = "Invoker"
                id = "/providers/Microsoft.PowerApps/apis/shared_office365"
                tier = "NotSpecified"
            }
        }
        definition = @{
            "`$schema" = "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#"
            contentVersion = "1.0.0.0"
            parameters = @{
                "`$connections" = @{
                    defaultValue = @{}
                    type = "Object"
                }
                "`$authentication" = @{
                    defaultValue = @{}
                    type = "SecureObject"
                }
            }
            triggers = @{
                Recurrence = @{
                    type = "Recurrence"
                    recurrence = @{
                        frequency = "Day"
                        interval = 1
                        schedule = @{
                            hours = @("6")
                            minutes = @("0")
                        }
                        timeZone = "Eastern Standard Time"
                    }
                }
            }
            actions = @{
                Send_an_email = @{
                    type = "OpenApiConnection"
                    inputs = @{
                        host = @{
                            connectionName = "shared_office365"
                            operationId = "SendEmailV2"
                            apiId = "/providers/Microsoft.PowerApps/apis/shared_office365"
                        }
                        parameters = @{
                            "emailMessage/To" = "kybradsh@microsoft.com"
                            "emailMessage/Subject" = "Hi"
                            "emailMessage/Body" = "<p>Hi</p>"
                            "emailMessage/Importance" = "Normal"
                        }
                        authentication = "@parameters('`$authentication')"
                    }
                    runAfter = @{}
                }
            }
            outputs = @{}
        }
    }
} | ConvertTo-Json -Depth 20 -Compress

# Create workflow record
$body = @{
    name = "Hi Kyle Daily Email"
    type = 1
    category = 5
    statecode = 0  # Draft state initially
    primaryentity = "none"
    clientdata = $flowDefinition
} | ConvertTo-Json -Depth 10

$headers = @{
    "Authorization" = "Bearer $token"
    "Accept" = "application/json"
    "OData-Version" = "4.0"
    "Content-Type" = "application/json"
}

$uri = "$($orgUrl.TrimEnd('/'))/api/data/v9.2/workflows"

Write-Host "Creating flow..." -ForegroundColor Cyan

try {
    $response = Invoke-RestMethod -Uri $uri -Method POST -Headers $headers -Body $body
    Write-Host "Flow created successfully!" -ForegroundColor Green

    # Get the workflow ID from response
    $workflowId = $response.workflowid
    Write-Host ""
    Write-Host "Flow ID: $workflowId" -ForegroundColor White
    Write-Host ""
    Write-Host "Open in Power Automate:" -ForegroundColor Cyan
    Write-Host "https://make.powerautomate.com/environments/$($envInfo.EnvironmentId)/flows/$workflowId" -ForegroundColor White
    Write-Host ""
    Write-Host "NOTE: You'll need to sign into Outlook when you first open the flow." -ForegroundColor Yellow
}
catch {
    Write-Host "Error creating flow:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host $_.ErrorDetails.Message -ForegroundColor Red
    }
    exit 1
}
