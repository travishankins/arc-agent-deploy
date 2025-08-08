# Azure Arc Onboarding (via GPO or manual)

PowerShell script to onboard Windows Servers to **Azure Arc**.  
It installs/updates the **Connected Machine Agent (CMA)**, then runs `azcmagent connect` using values from `ArcInfo.json`.

## What the script does (quick flow)

1. **Resolve config**
   - Reads `ArcInfo.json` from your share (tenant, subscription, RG, location, SPN ID, optional Private Link scope, proxy, tags).
   - Optionally decrypts the SPN **secret** from `encryptedServicePrincipalSecret` using `AzureArcDeployment.psm1` (DPAPI).  
     Fallback: `ServicePrincipalSecretPlain` in `ArcInfo.json` (not recommended for long-term).

2. **Install/Update the agent**
   - Tries to **download the latest CMA** from Microsoft (`https://aka.ms/AzureConnectedMachineAgent`) to a local work folder.
   - Reads the MSI **ProductVersion** and compares it to the installed agent version.
   - **If the downloaded version is newer** → installs/upgrades silently.
   - **If download fails** (no internet, proxy issues) → **falls back to your UNC copy** of the MSI.
   - Skips install if the installed version is already the same or newer.

3. **Connect to Azure Arc**
   - Applies optional proxy and bypass (“Arc”) settings.
   - Runs `azcmagent connect` with tags (default adds `DeployedBy='GPO'` + any tags from `ArcInfo.json`).
   - Verifies status with `azcmagent show/check` and the local agentstatus endpoint.

## Default paths in this repo/example

- UNC base: `\\lvdc-dc02\netlogon\Global\Arc\AzureArcDeploy`
- Files you store there:
  - `ArcInfo.json`
  - `AzureArcDeployment.psm1`
  - `encryptedServicePrincipalSecret`
  - `AzureConnectedMachineAgent.msi` *(fallback copy; keep it reasonably current)*
- The script writes a temporary MSI to a local work folder (e.g., `C:\Temp\ArcAgent\AzureConnectedMachineAgent.msi`) and runs the install from there.

## ArcInfo.json (example)

```json
{
  "ServicePrincipalClientId": "00000000-0000-0000-0000-000000000000",
  "TenantId": "00000000-0000-0000-0000-000000000000",
  "SubscriptionId": "00000000-0000-0000-0000-000000000000",
  "ResourceGroup": "Arc-Servers",
  "Location": "eastus",
  "PrivateLinkScopeId": "",
  "ProxyUrl": "",
  "Tags": {
    "Environment": "Prod",
    "Owner": "IT"
  }

  // Optional, short-term only:
  // "ServicePrincipalSecretPlain": "your-sp-secret"
}
