# Power Automate + Claude

Create and manage Power Automate flows just by describing what you want. No clicking through menus, no learning the portal.

---

## What Can It Do?

**Create flows from scratch:**
> "Send me an email every Monday at 9am with a weekly summary"

**Edit your existing flows:**
> "Add error handling to my Daily Report flow"

**Manage your flows:**
> "Show me all my flows that have 'email' in the name"
> "Turn off the Old Backup flow"

Claude handles all the technical details. You just describe what you want.

---

## Get Started

### Step 1: Install the Plugin

In Claude Code, type:
```
/plugin install https://github.com/wtandler/power-automate-claude
```

### Step 2: Start Talking

Just describe what you want:
> "Create a flow that posts to Teams whenever I get an email from my boss"

Claude will:
1. Check if you're signed in (and help you sign in if not)
2. Build the flow
3. Deploy it
4. Give you a link to test it

That's it. No setup commands to memorize.

---

## Example Requests

### Creating New Flows

> "Make a flow that saves email attachments to SharePoint"

> "Create a button I can click to send a Teams message"

> "Build a flow that runs every Friday and emails me a report"

### Editing Existing Flows

> "Pull my Weekly Digest flow and make it run on Mondays too"

> "Add a Teams notification to my approval flow"

> "Show me what my Daily Sync flow does and suggest improvements"

### Managing Flows

> "List all my flows"

> "Find flows related to SharePoint"

> "Disable the Test Flow"

> "Open the Daily Report flow"

---

## First Time?

When you first ask Claude to work with flows, it will:

1. **Check if you're signed in** - If not, it'll walk you through signing in with your work account
2. **Help you pick your environment** - Shows you a list, you pick a number
3. **Install any needed tools** - Asks permission first, handles it automatically

You don't need to do anything in advance. Just ask for what you want, and Claude handles the setup.

---

## Security

**Your data is protected by multiple layers of security.** This plugin was designed with enterprise security in mind.

### What's Protected

| Your Data | How It's Protected |
|-----------|-------------------|
| Email addresses | Replaced with placeholders before Claude sees them |
| URLs and links | Automatically hidden from AI processing |
| Names and messages | Extracted and stored only on your machine |
| API keys and tokens | Never exposed in error messages |
| Flow credentials | Managed by Azure CLI, never stored locally |

### Key Security Features

- **Data stays local** - Sensitive information never leaves your computer
- **Protected local storage** - Your secrets stay on your machine, never shared
- **AI sees structure only** - Claude works with the flow's logic, not your private data
- **No accidental commits** - Sensitive files are automatically excluded from git
- **Defense in depth** - Multiple independent security layers protect your data

### For Compliance Teams

See [SECURITY.md](SECURITY.md) for technical security documentation, including threat model, controls matrix, and compliance considerations.

---

### How Data Protection Works

When editing flows, the plugin automatically protects emails, URLs, names, and other private information:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            PULL (Download Flow)                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   Power Automate                                                            │
│   ┌─────────────────────────────────────┐                                   │
│   │ "To": "john@company.com"            │                                   │
│   │ "Subject": "Q4 Sales Report"        │──────┐                            │
│   │ "Body": "Hi John, here's the..."    │      │                            │
│   └─────────────────────────────────────┘      │                            │
│                                                ▼                            │
│                                    ┌─────────────────────┐                  │
│                                    │  Extract & Replace  │                  │
│                                    │    with {{...}}     │                  │
│                                    └─────────────────────┘                  │
│                                          │         │                        │
│                              ┌───────────┘         └───────────┐            │
│                              ▼                                 ▼            │
│              ┌───────────────────────────────┐    ┌────────────────────┐    │
│              │  flows/daily-report.json      │    │  .secrets.json     │    │
│              │  (Safe for Claude)            │    │  (Never shared)    │    │
│              ├───────────────────────────────┤    ├────────────────────┤    │
│              │ "To": "{{EMAIL_1}}"           │    │ {{EMAIL_1}}:       │    │
│              │ "Subject": "{{STRING_1}}"     │    │  john@company.com  │    │
│              │ "Body": "{{STRING_2}}"        │    │ {{STRING_1}}:      │    │
│              └───────────────────────────────┘    │  Q4 Sales Report   │    │
│                              │                    └────────────────────┘    │
│                              ▼                             │                │
│                     ┌─────────────────┐                    │                │
│                     │  Claude edits   │                    │                │
│                     │  (sees schema   │                    │                │
│                     │   only)         │                    │                │
│                     └─────────────────┘                    │                │
│                              │                             │                │
├──────────────────────────────┼─────────────────────────────┼────────────────┤
│                            PUSH (Upload Changes)           │                │
├──────────────────────────────┼─────────────────────────────┼────────────────┤
│                              ▼                             │                │
│                    ┌─────────────────────┐                 │                │
│                    │  Rehydrate: Replace │◄────────────────┘                │
│                    │  {{...}} with real  │                                  │
│                    │  values             │                                  │
│                    └─────────────────────┘                                  │
│                              │                                              │
│                              ▼                                              │
│   Power Automate                                                            │
│   ┌─────────────────────────────────────┐                                   │
│   │ "To": "john@company.com"  ✓ restored│                                   │
│   │ "Subject": "Q4 Sales Report"        │                                   │
│   │ "Body": "Hi John, here's the..."    │                                   │
│   └─────────────────────────────────────┘                                   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

**What gets extracted:**
- `{{EMAIL_1}}` - Email addresses
- `{{URL_1}}` - URLs (SharePoint, Teams, APIs)
- `{{GUID_1}}` - IDs and GUIDs
- `{{STRING_1}}` - All other text content

**What stays visible (structural only):**
- Action types (`Compose`, `Http`, `If`)
- HTTP methods (`GET`, `POST`)
- Expressions (`@{triggerBody()['field']}`)

**Files stay local:** The `flows/` folder and `.secrets.json` are gitignored - nothing gets committed.

---

## Tips

- **Be specific**: "Email me on Mondays at 9am" works better than "Send emails sometimes"
- **Use natural language**: You don't need to know Power Automate terminology
- **Ask for changes**: After creating a flow, you can say "Actually, make it run at 8am instead"
- **Edit existing flows**: Say "Pull [flow name]" to download it, make changes, then "Push [flow name]" to update it

---

## Need Help?

- Say "Show me my flows" to see what's available
- Say "What can you do with Power Automate?" for more ideas
- If something goes wrong, Claude will explain what happened and how to fix it

---

## Links

- [Power Automate Portal](https://make.powerautomate.com) - View and run your flows
- [Report Issues](https://github.com/wtandler/power-automate-claude/issues)

---

<details>
<summary><strong>Technical Reference (for IT admins)</strong></summary>

## Prerequisites

The plugin needs these tools (Claude installs them automatically with user permission):

| Tool | Purpose | Install Command |
|------|---------|-----------------|
| Power Platform CLI | Deploy flows | `dotnet tool install --global Microsoft.PowerApps.CLI.Tool` |
| PowerShell Module | List/manage flows | `Install-Module -Name Microsoft.PowerApps.Administration.PowerShell -Scope CurrentUser` |
| Azure CLI | Edit existing flows | `winget install Microsoft.AzureCLI` |

## Authentication

**Device Code Flow (recommended):**
```powershell
pac auth create --deviceCode
```

**For editing flows (pull/push):**
```powershell
az login
```

## CLI Commands

The plugin includes a helper script at `scripts/pa.ps1`:

```powershell
# Setup
.\scripts\pa.ps1 setup --check    # Check prerequisites
.\scripts\pa.ps1 status           # Check connection
.\scripts\pa.ps1 switch           # Pick environment

# Flow Management
.\scripts\pa.ps1 flows            # List flows
.\scripts\pa.ps1 flows --search "term"
.\scripts\pa.ps1 enable "Name"
.\scripts\pa.ps1 disable "Name"
.\scripts\pa.ps1 open "Name"

# Edit Flows
.\scripts\pa.ps1 pull "Name"      # Download to ./flows/
.\scripts\pa.ps1 push "Name"      # Upload changes

# Solutions
.\scripts\pa.ps1 init MySolution  # Create solution
.\scripts\pa.ps1 deploy MySolution
```

## Project Structure

```
power-automate-claude/
├── skills/power-automate/     # Plugin skill definitions
├── scripts/pa.ps1             # CLI helper
├── src/{Solution}/            # New flow solutions
├── flows/                     # Pulled flows for editing
└── CLAUDE.md                  # Claude instructions
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Not authenticated" | Run `pac auth create --deviceCode` |
| "Azure CLI not authenticated" | Run `az login` |
| "PowerApps module not installed" | Run the Install-Module command above |
| "Flow not in solution" | Non-solution flows can't be pulled; edit in browser |

</details>
