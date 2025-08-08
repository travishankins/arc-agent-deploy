# Azure Arc GPO Onboarding

This repository contains a PowerShell script and instructions for onboarding Windows Servers to Azure Arc using Group Policy (GPO).

## Overview

The script is designed to be deployed via a GPO Scheduled Task and supports:

- **Automatic installation or upgrade** of the Azure Connected Machine Agent (CMA)  
  - Attempts to download the latest CMA from Microsoft  
  - Falls back to a UNC share if direct download fails  
- **Service Principal authentication** for non-interactive onboarding  
  - Securely decrypts the service principal secret from `encryptedServicePrincipalSecret`  
  - Falls back to a plain-text value in `ArcInfo.json` (for testing only)  
- **Custom tagging** of onboarded servers from values in `ArcInfo.json`  
- **Proxy configuration** (optional)

## File Structure

- `Onboard-AzureArc.ps1` – Main onboarding script  
- `ArcInfo.json` – Configuration file containing:
  - Tenant ID
  - Subscription ID
  - Resource Group
  - Location
  - Service Principal Client ID
  - Tags (optional)
- `AzureArcDeployment.psm1` – Module with DPAPI decryption logic  
- `encryptedServicePrincipalSecret` – Encrypted service principal secret  
- `AzureConnectedMachineAgent.msi` – (Optional) Offline CMA installer

## How It Works

1. **Reads `ArcInfo.json`** from a UNC path (e.g., `\\<domain>\NETLOGON\ArcDeploy`).
2. **Decrypts the SP secret** from `encryptedServicePrincipalSecret` if present.
3. **Downloads the latest CMA** from Microsoft’s official endpoint.
4. **Installs or updates the agent** if a newer version is found.
5. **Connects the machine to Azure Arc** using:
   - Resource name (local hostname)
   - Service Principal credentials
   - Configured subscription, resource group, location
6. **Applies tags** from `ArcInfo.json`.

## GPO Deployment

1. Copy the following to a domain-accessible share (e.g., `\\<domain>\NETLOGON\ArcDeploy`):
   - Script (`Onboard-AzureArc.ps1`)
   - `ArcInfo.json`
   - `AzureArcDeployment.psm1`
   - `encryptedServicePrincipalSecret`
   - `AzureConnectedMachineAgent.msi` (optional)
2. Create a Scheduled Task in GPO to run the script:
   - Action: **Start a Program**
   - Program: `powershell.exe`
   - Arguments: `-ExecutionPolicy Bypass -File "\\<domain>\NETLOGON\ArcDeploy\Onboard-AzureArc.ps1"`
   - Run as **SYSTEM**
3. Link the GPO to the target OU.

## Example `ArcInfo.json`

```json
{
  "TenantId": "00000000-0000-0000-0000-000000000000",
  "SubscriptionId": "00000000-0000-0000-0000-000000000000",
  "ResourceGroup": "Arc-Servers",
  "Location": "eastus",
  "ServicePrincipalClientId": "00000000-0000-0000-0000-000000000000",
  "Tags": {
    "Environment": "Prod",
    "Owner": "IT"
  }
}
