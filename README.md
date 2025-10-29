# Azure Arc Agent GPO Deployment# Azure Arc Agent GPO Deployment# Azure Arc GPO Onboarding



> **Automate Windows Server onboarding to Azure Arc using Group Policy**



This repository provides a **production-ready PowerShell solution** for deploying and managing Azure Arc Connected Machine Agent across Windows Server environments using Group Policy Objects (GPO).> **Automate Windows Server onboarding to Azure Arc using Group Policy**This repository contains a PowerShell script and instructions for onboarding Windows Servers to Azure Arc using Group Policy (GPO).



## 🚀 Key Features



| Feature | Description |This repository provides a **production-ready PowerShell solution** for deploying and managing Azure Arc Connected Machine Agent across Windows Server environments using Group Policy Objects (GPO).## Overview

|---------|-------------|

| **Automatic Agent Management** | Downloads, installs, and updates Azure Connected Machine Agent |

| **GPO-Based Deployment** | Centralized deployment via Active Directory Group Policy |

| **Service Principal Authentication** | Secure, non-interactive onboarding |## 🚀 Key FeaturesThe script is designed to be deployed via a GPO Scheduled Task and supports:

| **Encrypted Secrets** | DPAPI-NG encryption for Service Principal credentials |

| **Version Management** | Automatic upgrade detection and installation |

| **Flexible Configuration** | JSON-based configuration with tags and custom settings |

| **Proxy Support** | Built-in support for corporate proxy environments || Feature | Description |- **Automatic installation or upgrade** of the Azure Connected Machine Agent (CMA)  

| **Private Link Ready** | Support for Azure Arc Private Link Scope |

| **Comprehensive Logging** | Detailed execution logs for troubleshooting ||---------|-------------|  - Attempts to download the latest CMA from Microsoft  



## 📐 Architecture| **Automatic Agent Management** | Downloads, installs, and updates Azure Connected Machine Agent |  - Falls back to a UNC share if direct download fails  



```mermaid| **GPO-Based Deployment** | Centralized deployment via Active Directory Group Policy |- **Service Principal authentication** for non-interactive onboarding  

graph TB

    subgraph "Active Directory Environment"| **Service Principal Authentication** | Secure, non-interactive onboarding |  - Securely decrypts the service principal secret from `encryptedServicePrincipalSecret`  

        DC[Domain Controller<br/>NETLOGON Share]

        GPO[Group Policy Object]| **Encrypted Secrets** | DPAPI-NG encryption for Service Principal credentials |  - Falls back to a plain-text value in `ArcInfo.json` (for testing only)  

        

        subgraph "Deployment Files"| **Version Management** | Automatic upgrade detection and installation |- **Custom tagging** of onboarded servers from values in `ArcInfo.json`  

            SCRIPT[azure-arc-onboarding.ps1]

            CONFIG[ArcInfo.json]| **Flexible Configuration** | JSON-based configuration with tags and custom settings |- **Proxy configuration** (optional)

            SECRET[encryptedServicePrincipalSecret]

            MODULE[AzureArcDeployment.psm1]| **Proxy Support** | Built-in support for corporate proxy environments |

            MSI[AzureConnectedMachineAgent.msi]

        end| **Private Link Ready** | Support for Azure Arc Private Link Scope |## File Structure

        

        DC --> SCRIPT| **Comprehensive Logging** | Detailed execution logs for troubleshooting |

        DC --> CONFIG

        DC --> SECRET- `Onboard-AzureArc.ps1` – Main onboarding script  

        DC --> MODULE

        DC --> MSI## 📐 Architecture- `ArcInfo.json` – Configuration file containing:

    end

      - Tenant ID

    subgraph "Target Servers"

        SVR1[Windows Server 1]```mermaid  - Subscription ID

        SVR2[Windows Server 2]

        SVR3[Windows Server N...]graph TB  - Resource Group

        

        SVR1 -.->|Scheduled Task| EXEC1[Execute Script]    subgraph "Active Directory Environment"  - Location

        SVR2 -.->|Scheduled Task| EXEC2[Execute Script]

        SVR3 -.->|Scheduled Task| EXEC3[Execute Script]        DC[Domain Controller<br/>NETLOGON Share]  - Service Principal Client ID

    end

            GPO[Group Policy Object]  - Tags (optional)

    subgraph "Azure"

        AAD[Azure AD<br/>Service Principal]        - `encryptedServicePrincipalSecret` – Encrypted service principal secret  

        ARC[Azure Arc]

        RG[Resource Group]        subgraph "Deployment Files"- `AzureConnectedMachineAgent.msi` – (Optional) Offline CMA installer

        

        EXEC1 -->|Authenticate| AAD            SCRIPT[azure-arc-onboarding.ps1]

        EXEC2 -->|Authenticate| AAD

        EXEC3 -->|Authenticate| AAD            CONFIG[ArcInfo.json]## How It Works

        

        AAD -->|Connect| ARC            SECRET[encryptedServicePrincipalSecret]

        ARC --> RG

    end            MODULE[AzureArcDeployment.psm1]1. **Reads `ArcInfo.json`** from a UNC path (e.g., `\\<domain>\NETLOGON\ArcDeploy`).

    

    GPO -.->|Apply Policy| SVR1            MSI[AzureConnectedMachineAgent.msi]2. **Decrypts the SP secret** from `encryptedServicePrincipalSecret` if present.

    GPO -.->|Apply Policy| SVR2

    GPO -.->|Apply Policy| SVR3        end3. **Downloads the latest CMA** from Microsoft’s official endpoint.

    

    EXEC1 -.->|Read Config| DC        4. **Installs or updates the agent** if a newer version is found.

    EXEC2 -.->|Read Config| DC

    EXEC3 -.->|Read Config| DC        DC --> SCRIPT5. **Connects the machine to Azure Arc** using:



    style GPO fill:#e1f5fe        DC --> CONFIG   - Resource name (local hostname)

    style ARC fill:#fff3e0

    style AAD fill:#e8f5e8        DC --> SECRET   - Service Principal credentials

    style DC fill:#f3e5f5

```        DC --> MODULE   - Configured subscription, resource group, location



### 🔄 Onboarding Flow        DC --> MSI6. **Applies tags** from `ArcInfo.json`.



```mermaid    end

sequenceDiagram

    participant GPO as GPO Scheduled Task    ## GPO Deployment

    participant Script as PowerShell Script

    participant NETLOGON as NETLOGON Share    subgraph "Target Servers"

    participant MS as Microsoft CDN

    participant Agent as Arc Agent        SVR1[Windows Server 1]1. Copy the following to a domain-accessible share (e.g., `\\<domain>\NETLOGON\ArcDeploy`):

    participant Azure as Azure Arc Service

        SVR2[Windows Server 2]   - Script (`Onboard-AzureArc.ps1`)

    GPO->>Script: Trigger Execution (SYSTEM account)

    Script->>NETLOGON: Read ArcInfo.json        SVR3[Windows Server N...]   - `ArcInfo.json`

    NETLOGON-->>Script: Configuration Data

    Script->>NETLOGON: Decrypt SP Secret (DPAPI-NG)           - `AzureArcDeployment.psm1`

    NETLOGON-->>Script: Service Principal Credentials

            SVR1 -.->|Scheduled Task| EXEC1[Execute Script]   - `encryptedServicePrincipalSecret`

    Script->>MS: Download Latest Agent (aka.ms)

    alt Download Success        SVR2 -.->|Scheduled Task| EXEC2[Execute Script]   - `AzureConnectedMachineAgent.msi` (optional)

        MS-->>Script: AzureConnectedMachineAgent.msi

    else Download Failure        SVR3 -.->|Scheduled Task| EXEC3[Execute Script]2. Create a Scheduled Task in GPO to run the script:

        Script->>NETLOGON: Fallback to UNC Copy

        NETLOGON-->>Script: Local MSI Copy    end   - Action: **Start a Program**

    end

           - Program: `powershell.exe`

    Script->>Script: Compare Versions

    alt Update Needed    subgraph "Azure"   - Arguments: `-ExecutionPolicy Bypass -File "\\<domain>\NETLOGON\ArcDeploy\Onboard-AzureArc.ps1"`

        Script->>Agent: Install/Update via msiexec

    else Already Current        AAD[Azure AD<br/>Service Principal]   - Run as **SYSTEM**

        Script->>Script: Skip Installation

    end        ARC[Azure Arc]3. Link the GPO to the target OU.

    

    Script->>Agent: Execute: azcmagent connect        RG[Resource Group]

    Agent->>Azure: Authenticate (Service Principal)

    Azure-->>Agent: Authentication Success        ## Example `ArcInfo.json`

    Agent->>Azure: Register Machine

    Azure-->>Agent: Registration Complete        EXEC1 -->|Authenticate| AAD

    Agent-->>Script: Connection Status

    Script->>Agent: Verify: azcmagent show        EXEC2 -->|Authenticate| AAD```json

    Agent-->>Script: Agent Status + Resource ID

    Script->>Script: Log Success & Exit        EXEC3 -->|Authenticate| AAD{

```

          "TenantId": "00000000-0000-0000-0000-000000000000",

## 📁 Project Structure

        AAD -->|Connect| ARC  "SubscriptionId": "00000000-0000-0000-0000-000000000000",

```

arc-agent-deploy/        ARC --> RG  "ResourceGroup": "Arc-Servers",

├── azure-arc-onboarding.ps1      # Main onboarding script

├── ArcInfo.json.example          # Configuration template    end  "Location": "eastus",

├── README.md                     # This documentation

├── CONFIGURATION.md              # Detailed configuration reference      "ServicePrincipalClientId": "00000000-0000-0000-0000-000000000000",

└── deployment-files/             # Files to deploy to NETLOGON

    ├── ArcInfo.json                 # Actual configuration (create from example)    GPO -.->|Apply Policy| SVR1  "Tags": {

    ├── encryptedServicePrincipalSecret  # Encrypted SP secret

    ├── AzureArcDeployment.psm1      # DPAPI-NG decryption module    GPO -.->|Apply Policy| SVR2    "Environment": "Prod",

    └── AzureConnectedMachineAgent.msi   # (Optional) Offline installer

```    GPO -.->|Apply Policy| SVR3    "Owner": "IT"



## ⚡ Quick Start      }



### Prerequisites    EXEC1 -.->|Read Config| DC}



- ✅ Active Directory domain environment    EXEC2 -.->|Read Config| DC

- ✅ Azure subscription with appropriate permissions    EXEC3 -.->|Read Config| DC

- ✅ Azure AD Service Principal with Arc onboarding rights

- ✅ Domain-accessible file share (e.g., NETLOGON)    style GPO fill:#e1f5fe

- ✅ Windows Server 2012 R2 or later target machines    style ARC fill:#fff3e0

    style AAD fill:#e8f5e8

### Step 1: Create Azure Resources    style DC fill:#f3e5f5

```

Create a Service Principal for Arc onboarding:

### 🔄 Onboarding Flow

```powershell

# Connect to Azure```mermaid

Connect-AzAccountsequenceDiagram

    participant GPO as GPO Scheduled Task

# Create Service Principal    participant Script as PowerShell Script

$sp = New-AzADServicePrincipal -DisplayName "AzureArc-GPO-Onboarding" -Role "Azure Connected Machine Onboarding"    participant NETLOGON as NETLOGON Share

    participant MS as Microsoft CDN

# Save these values for ArcInfo.json    participant Agent as Arc Agent

$sp.AppId          # ServicePrincipalClientId    participant Azure as Azure Arc Service

$sp.PasswordCredentials.SecretText  # Service Principal Secret

(Get-AzContext).Tenant.Id  # TenantId    GPO->>Script: Trigger Execution (SYSTEM account)

(Get-AzContext).Subscription.Id  # SubscriptionId    Script->>NETLOGON: Read ArcInfo.json

```    NETLOGON-->>Script: Configuration Data

    Script->>NETLOGON: Decrypt SP Secret (DPAPI-NG)

### Step 2: Prepare Configuration    NETLOGON-->>Script: Service Principal Credentials

    

1. **Copy and customize ArcInfo.json:**    Script->>MS: Download Latest Agent (aka.ms)

   ```powershell    alt Download Success

   Copy-Item ArcInfo.json.example \\<domain>\NETLOGON\ArcDeploy\ArcInfo.json        MS-->>Script: AzureConnectedMachineAgent.msi

   ```    else Download Failure

        Script->>NETLOGON: Fallback to UNC Copy

2. **Edit with your values:**        NETLOGON-->>Script: Local MSI Copy

   ```json    end

   {    

     "ServicePrincipalClientId": "<your-sp-app-id>",    Script->>Script: Compare Versions

     "TenantId": "<your-tenant-id>",    alt Update Needed

     "SubscriptionId": "<your-subscription-id>",        Script->>Agent: Install/Update via msiexec

     "ResourceGroup": "Arc-Servers",    else Already Current

     "Location": "eastus",        Script->>Script: Skip Installation

     "Tags": {    end

       "Environment": "Production",    

       "ManagedBy": "GPO",    Script->>Agent: Execute: azcmagent connect

       "Department": "IT"    Agent->>Azure: Authenticate (Service Principal)

     }    Azure-->>Agent: Authentication Success

   }    Agent->>Azure: Register Machine

   ```    Azure-->>Agent: Registration Complete

    Agent-->>Script: Connection Status

### Step 3: Encrypt Service Principal Secret (Recommended)    Script->>Agent: Verify: azcmagent show

    Agent-->>Script: Agent Status + Resource ID

For production environments, use encrypted secrets:    Script->>Script: Log Success & Exit

```

```powershell

# Create encryption module and encrypt secret## 📁 Project Structure

# (Details in CONFIGURATION.md - requires DPAPI-NG setup)

$secret = "<your-sp-secret>"```

# Use DPAPI-NG to encrypt and save to encryptedServicePrincipalSecretarc-agent-deploy/

```├── azure-arc-onboarding.ps1      # Main onboarding script

├── ArcInfo.json.example          # Configuration template

**For testing only**, you can use plain-text in ArcInfo.json:├── README.md                     # This documentation

```json└── deployment-files/             # Files to deploy to NETLOGON

{    ├── ArcInfo.json                 # Actual configuration (create from example)

  "ServicePrincipalSecretPlain": "<your-sp-secret>"    ├── encryptedServicePrincipalSecret  # Encrypted SP secret

}    ├── AzureArcDeployment.psm1      # DPAPI-NG decryption module

```    └── AzureConnectedMachineAgent.msi   # (Optional) Offline installer

```

### Step 4: Deploy Files to NETLOGON

## ⚡ Quick Start

Copy all required files to your domain share:

### Prerequisites

```powershell

$deployPath = "\\<domain>\NETLOGON\Global\Arc\AzureArcDeploy"- ✅ Active Directory domain environment

New-Item -Path $deployPath -ItemType Directory -Force- ✅ Azure subscription with appropriate permissions

- ✅ Azure AD Service Principal with Arc onboarding rights

Copy-Item azure-arc-onboarding.ps1 $deployPath\- ✅ Domain-accessible file share (e.g., NETLOGON)

Copy-Item ArcInfo.json $deployPath\- ✅ Windows Server 2012 R2 or later target machines

Copy-Item encryptedServicePrincipalSecret $deployPath\  # If using encryption

Copy-Item AzureArcDeployment.psm1 $deployPath\          # If using encryption### Step 1: Create Azure Resources

```

Create a Service Principal for Arc onboarding:

### Step 5: Create GPO Scheduled Task

```powershell

1. **Open Group Policy Management Console**# Connect to Azure

2. **Create or edit a GPO** linked to your target servers OUConnect-AzAccount

3. **Navigate to:**

   ```# Create Service Principal

   Computer Configuration → Preferences → Control Panel Settings → Scheduled Tasks$sp = New-AzADServicePrincipal -DisplayName "AzureArc-GPO-Onboarding" -Role "Azure Connected Machine Onboarding"

   ```

# Save these values for ArcInfo.json

4. **Create new Scheduled Task:**$sp.AppId          # ServicePrincipalClientId

   - **Name:** Azure Arc Onboarding$sp.PasswordCredentials.SecretText  # Service Principal Secret

   - **User:** `NT AUTHORITY\SYSTEM`(Get-AzContext).Tenant.Id  # TenantId

   - **Run whether user is logged on or not:** ✓(Get-AzContext).Subscription.Id  # SubscriptionId

   - **Run with highest privileges:** ✓```

   - **Trigger:** Daily (or at startup + daily for retry logic)

   - **Action:** Start a program### Step 2: Prepare Configuration

     - **Program:** `powershell.exe`

     - **Arguments:** `-ExecutionPolicy Bypass -WindowStyle Hidden -File "\\<domain>\NETLOGON\Global\Arc\AzureArcDeploy\azure-arc-onboarding.ps1"`1. **Copy and customize ArcInfo.json:**

   ```powershell

5. **Link GPO to target OU**   Copy-Item ArcInfo.json.example \\<domain>\NETLOGON\ArcDeploy\ArcInfo.json

   ```

### Step 6: Verify Deployment

2. **Edit with your values:**

Wait for GPO to apply (or force with `gpupdate /force`), then check:   ```json

   {

```powershell     "ServicePrincipalClientId": "<your-sp-app-id>",

# On target server - check if agent is installed     "TenantId": "<your-tenant-id>",

Test-Path "C:\Program Files\AzureConnectedMachineAgent\azcmagent.exe"     "SubscriptionId": "<your-subscription-id>",

     "ResourceGroup": "Arc-Servers",

# Check agent status     "Location": "eastus",

& "C:\Program Files\AzureConnectedMachineAgent\azcmagent.exe" show     "Tags": {

       "Environment": "Production",

# Review logs       "ManagedBy": "GPO",

Get-Content "$env:TEMP\ArcAgent\arc-onboarding-*.log" | Select-Object -Last 50       "Department": "IT"

```     }

   }

In Azure Portal:   ```

- Navigate to **Azure Arc → Servers**

- Verify your servers appear with correct tags### Step 3: Encrypt Service Principal Secret (Recommended)



## 🔧 Configuration OptionsFor production environments, use encrypted secrets:



### ArcInfo.json Schema```powershell

# Create encryption module and encrypt secret

| Field | Required | Description | Example |# (Details in SECURITY.md - requires DPAPI-NG setup)

|-------|----------|-------------|---------|$secret = "<your-sp-secret>"

| `ServicePrincipalClientId` | ✅ | Azure AD Application (client) ID | `"00000000-0000-0000-0000-000000000000"` |# Use DPAPI-NG to encrypt and save to encryptedServicePrincipalSecret

| `TenantId` | ✅ | Azure AD Tenant ID | `"00000000-0000-0000-0000-000000000000"` |```

| `SubscriptionId` | ✅ | Azure Subscription ID | `"00000000-0000-0000-0000-000000000000"` |

| `ResourceGroup` | ✅ | Target Resource Group name | `"Arc-Servers"` |**For testing only**, you can use plain-text in ArcInfo.json:

| `Location` | ✅ | Azure region | `"eastus"` |```json

| `Tags` | ❌ | Custom tags object | `{"Environment": "Prod"}` |{

| `PrivateLinkScopeId` | ❌ | Azure Arc Private Link Scope resource ID | `"/subscriptions/.../privateLinkScopes/..."` |  "ServicePrincipalSecretPlain": "<your-sp-secret>"

| `ProxyUrl` | ❌ | HTTP(S) proxy URL | `"http://proxy.contoso.com:8080"` |}

| `ServicePrincipalSecretPlain` | ❌ | **Testing only** - Plain-text SP secret | `"your-secret"` |```



### Script Configuration### Step 4: Deploy Files to NETLOGON



Edit these variables in `azure-arc-onboarding.ps1` if needed:Copy all required files to your domain share:



```powershell```powershell

$SourceFilesFullPath = '\\lvdc-dc02\netlogon\Global\Arc\AzureArcDeploy'  # UNC path to files$deployPath = "\\<domain>\NETLOGON\Global\Arc\AzureArcDeploy"

$WorkFolder          = "$env:TEMP\ArcAgent"                               # Local temp folderNew-Item -Path $deployPath -ItemType Directory -Force

```

Copy-Item azure-arc-onboarding.ps1 $deployPath\

## 🔒 Security Best PracticesCopy-Item ArcInfo.json $deployPath\

Copy-Item encryptedServicePrincipalSecret $deployPath\  # If using encryption

| Practice | Implementation |Copy-Item AzureArcDeployment.psm1 $deployPath\          # If using encryption

|----------|----------------|```

| **Encrypted Secrets** | Use DPAPI-NG encrypted `encryptedServicePrincipalSecret` file |

| **Least Privilege** | Service Principal should only have "Azure Connected Machine Onboarding" role |### Step 5: Create GPO Scheduled Task

| **Secure File Share** | Restrict NETLOGON folder access to authorized systems only |

| **Audit Logging** | Review execution logs regularly in `$env:TEMP\ArcAgent\` |1. **Open Group Policy Management Console**

| **Rotate Credentials** | Periodically rotate Service Principal secret |2. **Create or edit a GPO** linked to your target servers OU

| **Private Link** | Use Azure Arc Private Link Scope for enhanced network security |3. **Navigate to:**

| **Avoid Plain-Text** | Never use `ServicePrincipalSecretPlain` in production |   ```

   Computer Configuration → Preferences → Control Panel Settings → Scheduled Tasks

## 📊 Monitoring & Troubleshooting   ```



### Checking Deployment Status4. **Create new Scheduled Task:**

   - **Name:** Azure Arc Onboarding

**On target server:**   - **User:** `NT AUTHORITY\SYSTEM`

```powershell   - **Run whether user is logged on or not:** ✓

# View latest log file   - **Run with highest privileges:** ✓

$latestLog = Get-ChildItem "$env:TEMP\ArcAgent\arc-onboarding-*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1   - **Trigger:** Daily (or at startup + daily for retry logic)

Get-Content $latestLog.FullName   - **Action:** Start a program

     - **Program:** `powershell.exe`

# Check agent status     - **Arguments:** `-ExecutionPolicy Bypass -WindowStyle Hidden -File "\\<domain>\NETLOGON\Global\Arc\AzureArcDeploy\azure-arc-onboarding.ps1"`

& "C:\Program Files\AzureConnectedMachineAgent\azcmagent.exe" show -j | ConvertFrom-Json

5. **Link GPO to target OU**

# Check scheduled task history

Get-ScheduledTask "Azure Arc Onboarding" | Get-ScheduledTaskInfo### Step 6: Verify Deployment

```

Wait for GPO to apply (or force with `gpupdate /force`), then check:

**In Azure Portal:**

``````powershell

Azure Arc → Servers → [Check for registered machines]# On target server - check if agent is installed

Azure Arc → Servers → [Machine] → Activity LogTest-Path "C:\Program Files\AzureConnectedMachineAgent\azcmagent.exe"

```

# Check agent status

### Common Issues& "C:\Program Files\AzureConnectedMachineAgent\azcmagent.exe" show



| Issue | Cause | Solution |# Review logs

|-------|-------|----------|Get-Content "$env:TEMP\ArcAgent\arc-onboarding-*.log" | Select-Object -Last 50

| Agent not installing | Download failure, no internet access | Ensure MSI is in NETLOGON share, check proxy settings |```

| Authentication failure | Wrong SP credentials, expired secret | Verify SP credentials in ArcInfo.json, check secret expiration |

| Connection timeout | Firewall blocking Arc endpoints | Whitelist required URLs (see below) |In Azure Portal:

| DPAPI decrypt fails | Wrong encryption context | Re-encrypt secret, ensure machine/domain context matches |- Navigate to **Azure Arc → Servers**

| "Resource already exists" | Server previously registered | Disconnect old registration or use existing resource |- Verify your servers appear with correct tags



### Required Network Endpoints## 🔧 Configuration Options



Allow outbound HTTPS (443) to:### ArcInfo.json Schema

- `aka.ms` - Agent download

- `*.guestconfiguration.azure.com` - Guest configuration| Field | Required | Description | Example |

- `*.his.arc.azure.com` - Hybrid identity service  |-------|----------|-------------|---------|

- `*.guestnotificationservice.azure.com` - Notification service| `ServicePrincipalClientId` | ✅ | Azure AD Application (client) ID | `"00000000-0000-0000-0000-000000000000"` |

- `management.azure.com` - Azure Resource Manager| `TenantId` | ✅ | Azure AD Tenant ID | `"00000000-0000-0000-0000-000000000000"` |

- `login.microsoftonline.com` - Azure AD authentication| `SubscriptionId` | ✅ | Azure Subscription ID | `"00000000-0000-0000-0000-000000000000"` |

| `ResourceGroup` | ✅ | Target Resource Group name | `"Arc-Servers"` |

Full list: [Azure Arc network requirements](https://learn.microsoft.com/azure/azure-arc/servers/network-requirements)| `Location` | ✅ | Azure region | `"eastus"` |

| `Tags` | ❌ | Custom tags object | `{"Environment": "Prod"}` |

## 🧪 Testing| `PrivateLinkScopeId` | ❌ | Azure Arc Private Link Scope resource ID | `"/subscriptions/.../privateLinkScopes/..."` |

| `ProxyUrl` | ❌ | HTTP(S) proxy URL | `"http://proxy.contoso.com:8080"` |

### Manual Test Execution| `ServicePrincipalSecretPlain` | ❌ | **Testing only** - Plain-text SP secret | `"your-secret"` |



Run script directly on a test server:### Script Configuration



```powershellEdit these variables in `azure-arc-onboarding.ps1` if needed:

# As Administrator

Set-ExecutionPolicy Bypass -Scope Process```powershell

\\<domain>\NETLOGON\Global\Arc\AzureArcDeploy\azure-arc-onboarding.ps1$SourceFilesFullPath = '\\lvdc-dc02\netlogon\Global\Arc\AzureArcDeploy'  # UNC path to files

```$WorkFolder          = "$env:TEMP\ArcAgent"                               # Local temp folder

```

### Verify GPO Application

## 🔒 Security Best Practices

```powershell

# Force GPO update| Practice | Implementation |

gpupdate /force|----------|----------------|

| **Encrypted Secrets** | Use DPAPI-NG encrypted `encryptedServicePrincipalSecret` file |

# Check if scheduled task was created| **Least Privilege** | Service Principal should only have "Azure Connected Machine Onboarding" role |

Get-ScheduledTask "Azure Arc Onboarding"| **Secure File Share** | Restrict NETLOGON folder access to authorized systems only |

| **Audit Logging** | Review execution logs regularly in `$env:TEMP\ArcAgent\` |

# Run task immediately| **Rotate Credentials** | Periodically rotate Service Principal secret |

Start-ScheduledTask "Azure Arc Onboarding"| **Private Link** | Use Azure Arc Private Link Scope for enhanced network security |

```| **Avoid Plain-Text** | Never use `ServicePrincipalSecretPlain` in production |



### Validate Azure Registration## 📊 Monitoring & Troubleshooting



```powershell### Checking Deployment Status

# Azure PowerShell

Connect-AzAccount**On target server:**

Get-AzConnectedMachine -ResourceGroupName "Arc-Servers"```powershell

# View latest log file

# Azure CLI$latestLog = Get-ChildItem "$env:TEMP\ArcAgent\arc-onboarding-*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

az connectedmachine list --resource-group Arc-Servers --output tableGet-Content $latestLog.FullName

```

# Check agent status

## 📚 Additional Resources& "C:\Program Files\AzureConnectedMachineAgent\azcmagent.exe" show -j | ConvertFrom-Json



- **[Azure Arc Documentation](https://learn.microsoft.com/azure/azure-arc/servers/)** - Official Microsoft docs# Check scheduled task history

- **[azcmagent CLI Reference](https://learn.microsoft.com/azure/azure-arc/servers/azcmagent-reference)** - Agent command referenceGet-ScheduledTask "Azure Arc Onboarding" | Get-ScheduledTaskInfo

- **[Azure Arc Jumpstart](https://azurearcjumpstart.io/)** - Community-driven scenarios```

- **[Network Requirements](https://learn.microsoft.com/azure/azure-arc/servers/network-requirements)** - Firewall and proxy configuration

- **[CONFIGURATION.md](CONFIGURATION.md)** - Detailed field-by-field configuration guide**In Azure Portal:**

```

## 🤝 ContributingAzure Arc → Servers → [Check for registered machines]

Azure Arc → Servers → [Machine] → Activity Log

Contributions are welcome! Please:```

1. Fork this repository

2. Create a feature branch### Common Issues

3. Test your changes thoroughly

4. Submit a pull request with clear description| Issue | Cause | Solution |

|-------|-------|----------|

## 📝 Version History| Agent not installing | Download failure, no internet access | Ensure MSI is in NETLOGON share, check proxy settings |

| Authentication failure | Wrong SP credentials, expired secret | Verify SP credentials in ArcInfo.json, check secret expiration |

| Version | Date | Changes || Connection timeout | Firewall blocking Arc endpoints | Whitelist required URLs (see below) |

|---------|------|---------|| DPAPI decrypt fails | Wrong encryption context | Re-encrypt secret, ensure machine/domain context matches |

| 2.0 | 2025-10-28 | Enhanced logging, proxy support, private link, improved error handling || "Resource already exists" | Server previously registered | Disconnect old registration or use existing resource |

| 1.0 | Initial | Basic GPO deployment script |

### Required Network Endpoints

## 📄 License

Allow outbound HTTPS (443) to:

This project is provided as-is for educational and reference purposes.- `aka.ms` - Agent download

- `*.guestconfiguration.azure.com` - Guest configuration

---- `*.his.arc.azure.com` - Hybrid identity service  

- `*.guestnotificationservice.azure.com` - Notification service

<div align="center">- `management.azure.com` - Azure Resource Manager

- `login.microsoftonline.com` - Azure AD authentication

**Built with ❤️ for Azure Arc adoption at scale**

Full list: [Azure Arc network requirements](https://learn.microsoft.com/azure/azure-arc/servers/network-requirements)

</div>

## 🧪 Testing

### Manual Test Execution

Run script directly on a test server:

```powershell
# As Administrator
Set-ExecutionPolicy Bypass -Scope Process
\\<domain>\NETLOGON\Global\Arc\AzureArcDeploy\azure-arc-onboarding.ps1
```

### Verify GPO Application

```powershell
# Force GPO update
gpupdate /force

# Check if scheduled task was created
Get-ScheduledTask "Azure Arc Onboarding"

# Run task immediately
Start-ScheduledTask "Azure Arc Onboarding"
```

### Validate Azure Registration

```powershell
# Azure PowerShell
Connect-AzAccount
Get-AzConnectedMachine -ResourceGroupName "Arc-Servers"

# Azure CLI
az connectedmachine list --resource-group Arc-Servers --output table
```

## 📚 Additional Resources

- **[Azure Arc Documentation](https://learn.microsoft.com/azure/azure-arc/servers/)** - Official Microsoft docs
- **[azcmagent CLI Reference](https://learn.microsoft.com/azure/azure-arc/servers/azcmagent-reference)** - Agent command reference
- **[Azure Arc Jumpstart](https://azurearcjumpstart.io/)** - Community-driven scenarios
- **[Network Requirements](https://learn.microsoft.com/azure/azure-arc/servers/network-requirements)** - Firewall and proxy configuration

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork this repository
2. Create a feature branch
3. Test your changes thoroughly
4. Submit a pull request with clear description

## 📝 Version History

| Version | Date | Changes |
|---------|------|---------|
| 2.0 | 2025-10-28 | Enhanced logging, proxy support, private link, improved error handling |
| 1.0 | Initial | Basic GPO deployment script |

## 📄 License

This project is provided as-is for educational and reference purposes.

---

<div align="center">

**Built with ❤️ for Azure Arc adoption at scale**

</div>
