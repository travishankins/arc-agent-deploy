# ArcInfo.json Configuration Reference

This document describes all configuration options available in `ArcInfo.json`.

## Configuration Schema

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
    "Environment": "Production",
    "ManagedBy": "GPO"
  },
  "ServicePrincipalSecretPlain": "TESTING-ONLY-DO-NOT-USE-IN-PRODUCTION"
}
```

## Required Fields

### ServicePrincipalClientId
- **Type:** String (GUID)
- **Required:** Yes
- **Description:** The Application (client) ID of the Azure AD Service Principal used for authentication
- **Example:** `"12345678-1234-1234-1234-123456789012"`
- **How to get:**
  ```powershell
  $sp = New-AzADServicePrincipal -DisplayName "AzureArc-GPO" -Role "Azure Connected Machine Onboarding"
  $sp.AppId
  ```

### TenantId
- **Type:** String (GUID)
- **Required:** Yes
- **Description:** Your Azure AD Tenant ID
- **Example:** `"87654321-4321-4321-4321-210987654321"`
- **How to get:**
  ```powershell
  (Get-AzContext).Tenant.Id
  ```

### SubscriptionId
- **Type:** String (GUID)
- **Required:** Yes
- **Description:** The Azure Subscription ID where Arc resources will be created
- **Example:** `"11112222-3333-4444-5555-666677778888"`
- **How to get:**
  ```powershell
  (Get-AzContext).Subscription.Id
  ```

### ResourceGroup
- **Type:** String
- **Required:** Yes
- **Description:** Name of the Azure Resource Group where Arc-enabled servers will be registered
- **Example:** `"Arc-Servers"` or `"rg-arc-prod-eastus"`
- **Notes:** Resource Group must already exist before running the script

### Location
- **Type:** String
- **Required:** Yes
- **Description:** Azure region where the Arc resource metadata will be stored
- **Example:** `"eastus"`, `"westus2"`, `"northeurope"`
- **Valid values:** Any Azure region supporting Azure Arc
- **Best practice:** Use the same region as your Resource Group

## Optional Fields

### PrivateLinkScopeId
- **Type:** String (Azure Resource ID)
- **Required:** No
- **Default:** Empty string (public endpoints used)
- **Description:** Resource ID of Azure Arc Private Link Scope for private connectivity
- **Example:** `"/subscriptions/11112222-3333-4444-5555-666677778888/resourceGroups/rg-arc/providers/Microsoft.HybridCompute/privateLinkScopes/my-arc-pls"`
- **When to use:** When you want Arc agents to communicate with Azure over private networks (ExpressRoute/VPN)
- **How to get:**
  ```powershell
  $pls = Get-AzArcPrivateLinkScope -ResourceGroupName "rg-arc" -Name "my-arc-pls"
  $pls.Id
  ```

### ProxyUrl
- **Type:** String (URL)
- **Required:** No
- **Default:** Empty string (no proxy)
- **Description:** HTTP/HTTPS proxy server URL for agent communication
- **Example:** `"http://proxy.contoso.com:8080"` or `"https://proxy.contoso.com:443"`
- **Format:** `http(s)://hostname:port`
- **When to use:** When servers require a proxy to reach the internet
- **Notes:** 
  - Supports both HTTP and HTTPS proxies
  - Authentication not supported in URL (use system proxy settings for auth)

### Tags
- **Type:** Object (key-value pairs)
- **Required:** No
- **Default:** Empty object
- **Description:** Custom tags to apply to Arc-enabled server resources in Azure
- **Example:**
  ```json
  {
    "Environment": "Production",
    "Department": "IT",
    "CostCenter": "CC-1234",
    "Owner": "john.doe@contoso.com",
    "Application": "Database",
    "MaintenanceWindow": "Sunday-0200"
  }
  ```
- **Notes:**
  - Maximum 50 tags per resource
  - Tag names: max 512 characters
  - Tag values: max 256 characters
  - Case-insensitive but preserves case
  - A default tag `DeployedBy = 'GPO'` is automatically added by the script

### ServicePrincipalSecretPlain
- **Type:** String
- **Required:** No (but either this or encrypted secret required)
- **Default:** Not set
- **Description:** Plain-text Service Principal secret for **TESTING ONLY**
- **Example:** `"AbC123~XyZ789-MnO456_PqR"`
- **⚠️ SECURITY WARNING:**
  - **DO NOT USE IN PRODUCTION**
  - This stores credentials in plain text
  - Use `encryptedServicePrincipalSecret` file instead
  - Only use for initial testing/POC environments
  - Remove from production `ArcInfo.json` files

## Configuration Examples

### Minimal Configuration (Production with Encrypted Secret)
```json
{
  "ServicePrincipalClientId": "12345678-1234-1234-1234-123456789012",
  "TenantId": "87654321-4321-4321-4321-210987654321",
  "SubscriptionId": "11112222-3333-4444-5555-666677778888",
  "ResourceGroup": "Arc-Servers",
  "Location": "eastus"
}
```
*Requires: `encryptedServicePrincipalSecret` file in same directory*

### With Proxy
```json
{
  "ServicePrincipalClientId": "12345678-1234-1234-1234-123456789012",
  "TenantId": "87654321-4321-4321-4321-210987654321",
  "SubscriptionId": "11112222-3333-4444-5555-666677778888",
  "ResourceGroup": "Arc-Servers",
  "Location": "eastus",
  "ProxyUrl": "http://proxy.contoso.com:8080"
}
```

### With Private Link
```json
{
  "ServicePrincipalClientId": "12345678-1234-1234-1234-123456789012",
  "TenantId": "87654321-4321-4321-4321-210987654321",
  "SubscriptionId": "11112222-3333-4444-5555-666677778888",
  "ResourceGroup": "Arc-Servers",
  "Location": "eastus",
  "PrivateLinkScopeId": "/subscriptions/11112222-3333-4444-5555-666677778888/resourceGroups/rg-arc/providers/Microsoft.HybridCompute/privateLinkScopes/my-arc-pls"
}
```

### Full Configuration (All Options)
```json
{
  "ServicePrincipalClientId": "12345678-1234-1234-1234-123456789012",
  "TenantId": "87654321-4321-4321-4321-210987654321",
  "SubscriptionId": "11112222-3333-4444-5555-666677778888",
  "ResourceGroup": "Arc-Servers-Prod",
  "Location": "eastus",
  "PrivateLinkScopeId": "/subscriptions/11112222-3333-4444-5555-666677778888/resourceGroups/rg-arc/providers/Microsoft.HybridCompute/privateLinkScopes/my-arc-pls",
  "ProxyUrl": "http://proxy.contoso.com:8080",
  "Tags": {
    "Environment": "Production",
    "Department": "IT",
    "CostCenter": "CC-1234",
    "Owner": "it-ops@contoso.com",
    "BackupSchedule": "Daily",
    "PatchGroup": "Group-A"
  }
}
```

### Testing/POC Configuration (Plain-text Secret - NOT FOR PRODUCTION)
```json
{
  "ServicePrincipalClientId": "12345678-1234-1234-1234-123456789012",
  "TenantId": "87654321-4321-4321-4321-210987654321",
  "SubscriptionId": "11112222-3333-4444-5555-666677778888",
  "ResourceGroup": "Arc-Servers-Test",
  "Location": "eastus",
  "ServicePrincipalSecretPlain": "AbC123~XyZ789-MnO456_PqR",
  "Tags": {
    "Environment": "Test"
  }
}
```

## Common Azure Regions

| Region Code | Region Name | Location |
|-------------|-------------|----------|
| `eastus` | East US | Virginia |
| `eastus2` | East US 2 | Virginia |
| `westus` | West US | California |
| `westus2` | West US 2 | Washington |
| `centralus` | Central US | Iowa |
| `northeurope` | North Europe | Ireland |
| `westeurope` | West Europe | Netherlands |
| `uksouth` | UK South | London |
| `ukwest` | UK West | Cardiff |
| `australiaeast` | Australia East | New South Wales |
| `southeastasia` | Southeast Asia | Singapore |
| `japaneast` | Japan East | Tokyo |

Full list: https://azure.microsoft.com/global-infrastructure/geographies/

## Validation

Before deploying, validate your configuration:

```powershell
# Test JSON syntax
$config = Get-Content "ArcInfo.json" -Raw | ConvertFrom-Json

# Verify required fields
$required = @('ServicePrincipalClientId', 'TenantId', 'SubscriptionId', 'ResourceGroup', 'Location')
$required | ForEach-Object {
    if ([string]::IsNullOrWhiteSpace($config.$_)) {
        Write-Error "Required field '$_' is missing or empty"
    }
}

# Verify GUIDs are valid
[guid]::Parse($config.ServicePrincipalClientId)
[guid]::Parse($config.TenantId)
[guid]::Parse($config.SubscriptionId)
```

## Security Best Practices

1. ✅ **Use encrypted secrets** - Never use `ServicePrincipalSecretPlain` in production
2. ✅ **Restrict file permissions** - Limit access to `ArcInfo.json` on NETLOGON share
3. ✅ **Rotate credentials** - Regularly rotate Service Principal secrets
4. ✅ **Use least privilege** - Service Principal should only have "Azure Connected Machine Onboarding" role
5. ✅ **Monitor access** - Enable auditing on the NETLOGON share
6. ✅ **Use Private Link** - For enhanced security, use Private Link Scope
7. ✅ **Validate regularly** - Periodically review and validate configuration
