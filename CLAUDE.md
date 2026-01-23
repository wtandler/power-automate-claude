# Power Automate Plugin Reference

Technical reference for creating and managing Power Automate flows.

---

## Command Reference

```powershell
# Setup & Status
.\scripts\pa.ps1 setup              # Check prerequisites
.\scripts\pa.ps1 status             # Check connection
.\scripts\pa.ps1 envs               # List environments
.\scripts\pa.ps1 switch             # Interactive environment picker

# Flow Management
.\scripts\pa.ps1 flows              # List flows
.\scripts\pa.ps1 flows --search "x" # Search flows
.\scripts\pa.ps1 open "Flow Name"   # Open in browser
.\scripts\pa.ps1 enable "Name" --yes
.\scripts\pa.ps1 disable "Name" --yes

# Edit Existing Flows
.\scripts\pa.ps1 pull "Flow Name"   # Download to ./flows/
.\scripts\pa.ps1 push "Flow Name" --yes

# Create New Flows
.\scripts\pa.ps1 init SolutionName prefix
.\scripts\pa.ps1 deploy SolutionName
```

---

## Flow JSON Structure

```json
{
  "schemaVersion": "1.0.0.0",
  "properties": {
    "connectionReferences": {},
    "definition": {
      "$schema": "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#",
      "contentVersion": "1.0.0.0",
      "parameters": {},
      "triggers": {},
      "actions": {},
      "outputs": {}
    }
  }
}
```

---

## Trigger Types

### Button (Manual)
```json
"manual": {
  "type": "Request",
  "kind": "Button",
  "inputs": {
    "schema": {
      "type": "object",
      "properties": {
        "text": { "title": "Input", "type": "string", "x-ms-content-hint": "TEXT" }
      },
      "required": ["text"]
    }
  }
}
```

### Scheduled (Recurrence)
```json
"Recurrence": {
  "type": "Recurrence",
  "recurrence": {
    "frequency": "Day",
    "interval": 1,
    "schedule": { "hours": ["9"], "minutes": ["0"] },
    "timeZone": "Pacific Standard Time"
  }
}
```

### HTTP Webhook
```json
"manual": {
  "type": "Request",
  "kind": "Http",
  "inputs": {
    "method": "POST",
    "schema": { "type": "object", "properties": { "data": { "type": "string" } } }
  }
}
```

---

## Action Types

### Compose
```json
"Compose_Result": {
  "type": "Compose",
  "inputs": "Hello @{triggerBody()['text']}!",
  "runAfter": {}
}
```

### HTTP Request
```json
"Call_API": {
  "type": "Http",
  "inputs": {
    "method": "POST",
    "uri": "https://api.example.com/endpoint",
    "headers": { "Content-Type": "application/json" },
    "body": { "data": "@{triggerBody()['text']}" }
  },
  "runAfter": {}
}
```

### Condition
```json
"Check_Status": {
  "type": "If",
  "expression": { "equals": ["@triggerBody()['status']", "approved"] },
  "actions": {
    "If_Yes": { "type": "Compose", "inputs": "Approved!", "runAfter": {} }
  },
  "else": {
    "actions": {
      "If_No": { "type": "Compose", "inputs": "Rejected", "runAfter": {} }
    }
  },
  "runAfter": {}
}
```

### Loop
```json
"Loop_Items": {
  "type": "Foreach",
  "foreach": "@triggerBody()['items']",
  "actions": {
    "Process": {
      "type": "Compose",
      "inputs": "@items('Loop_Items')",
      "runAfter": {}
    }
  },
  "runAfter": {}
}
```

---

## Expression Functions

| Function | Example |
|----------|---------|
| Trigger input | `@{triggerBody()['field']}` |
| Action output | `@{outputs('ActionName')}` |
| Variable | `@{variables('varName')}` |
| Concatenate | `@{concat('Hello ', variables('name'))}` |
| Current time | `@{utcNow()}` |
| Format date | `@{formatDateTime(utcNow(), 'yyyy-MM-dd')}` |

---

## Workflow XML Template

```xml
<?xml version="1.0" encoding="utf-8"?>
<Workflow WorkflowId="{GUID}" Name="prefix_FlowName">
  <JsonFileName>/Workflows/prefix_FlowName-{GUID}.json</JsonFileName>
  <Type>1</Type>
  <Category>5</Category>
  <Scope>4</Scope>
  <StateCode>1</StateCode>
  <StatusCode>2</StatusCode>
  <RunAs>1</RunAs>
  <IsTransacted>1</IsTransacted>
  <IntroducedVersion>1.0</IntroducedVersion>
  <IsCustomizable>1</IsCustomizable>
  <PrimaryEntity>none</PrimaryEntity>
  <LocalizedNames>
    <LocalizedName languagecode="1033" description="Flow Display Name" />
  </LocalizedNames>
</Workflow>
```

---

## Common Errors

| Error | Solution |
|-------|----------|
| "Not authenticated" | Run `pac auth create --deviceCode` |
| "Azure CLI not authenticated" | Run `az login` |
| "Flow not found" | Run `pa.ps1 flows` to see available flows |
| "Non-solution flow" | Move flow to a solution first, or use `pa.ps1 open` |
| "schemaVersion not found" | Add `"schemaVersion": "1.0.0.0"` at JSON root |
