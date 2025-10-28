# ==========================
# Azure Arc Onboarding Script
# ==========================
# Deploys and configures Azure Arc Connected Machine Agent via GPO
# Version: 2.0
# Date: 2025-10-28

[CmdletBinding()]
param()

# --- Configuration ---
$SourceFilesFullPath = '\\lvdc-dc02\netlogon\Global\Arc\AzureArcDeploy'
$WorkFolder          = "$env:TEMP\ArcAgent"
$Azcm                = "$env:ProgramW6432\AzureConnectedMachineAgent\azcmagent.exe"
$LogFile             = Join-Path $WorkFolder "arc-onboarding-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# --- Logging Function ---
function Write-Log {
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error')]
        [string]$Level = 'Info'
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Write to console and file
    switch ($Level) {
        'Error'   { Write-Error $Message; break }
        'Warning' { Write-Warning $Message; break }
        default   { Write-Output $Message }
    }
    Add-Content -Path $LogFile -Value $logMessage -ErrorAction SilentlyContinue
}

# --- Ensure work folder exists ---
try {
    if (-not (Test-Path $WorkFolder)) {
        New-Item -Path $WorkFolder -ItemType Directory -Force | Out-Null
    }
    Write-Log "Work folder initialized: $WorkFolder"
} catch {
    Write-Error "Failed to create work folder: $($_.Exception.Message)"
    exit 1
}

# --- Load ArcInfo.json ---
Write-Log "Loading configuration from ArcInfo.json"
$ArcInfoPath = Join-Path $SourceFilesFullPath 'ArcInfo.json'
if (-not (Test-Path $ArcInfoPath)) {
    Write-Log "ArcInfo.json not found at $ArcInfoPath" -Level Error
    exit 1
}

try {
    $arcInfo = Get-Content $ArcInfoPath -Raw | ConvertFrom-Json
    Write-Log "Configuration loaded successfully"
    
    # Validate required fields
    $requiredFields = @('TenantId', 'SubscriptionId', 'ResourceGroup', 'Location', 'ServicePrincipalClientId')
    foreach ($field in $requiredFields) {
        if ([string]::IsNullOrWhiteSpace($arcInfo.$field)) {
            Write-Log "Required field '$field' is missing or empty in ArcInfo.json" -Level Error
            exit 1
        }
    }
} catch {
    Write-Log "Failed to parse ArcInfo.json: $($_.Exception.Message)" -Level Error
    exit 1
}

# --- Helper: Get SP secret ---
function Get-ServicePrincipalSecret {
    Write-Log "Retrieving Service Principal secret"
    $psm1 = Join-Path $SourceFilesFullPath 'AzureArcDeployment.psm1'
    $enc  = Join-Path $SourceFilesFullPath 'encryptedServicePrincipalSecret'

    # Try DPAPI decryption first (preferred method)
    if ((Test-Path $psm1) -and (Test-Path $enc)) {
        try {
            Copy-Item $psm1 (Join-Path $WorkFolder 'AzureArcDeployment.psm1') -Force
            Import-Module (Join-Path $WorkFolder 'AzureArcDeployment.psm1') -Force
            $encryptedSecret = Get-Content $enc -Raw
            $sps = [DpapiNgUtil]::UnprotectBase64($encryptedSecret)
            Remove-Item (Join-Path $WorkFolder 'AzureArcDeployment.psm1') -Force -ErrorAction SilentlyContinue
            if (-not [string]::IsNullOrWhiteSpace($sps)) {
                Write-Log "Successfully decrypted Service Principal secret using DPAPI"
                return $sps
            }
        } catch {
            Write-Log "Could not decrypt SP secret with DPAPI: $($_.Exception.Message)" -Level Warning
        }
    } else {
        Write-Log "Encrypted secret files not found, checking for plain-text fallback" -Level Warning
    }

    # Fallback to plain-text (testing only - not recommended for production)
    if ($arcInfo.ServicePrincipalSecretPlain) {
        Write-Log "Using plain-text Service Principal secret (not recommended for production)" -Level Warning
        return [string]$arcInfo.ServicePrincipalSecretPlain
    }
    
    Write-Log "No Service Principal secret available" -Level Error
    return $null
}

# --- Install/Update CMA ---
function Install-Or-Update-CMA {
    Write-Log "Checking Azure Connected Machine Agent version"
    $downloadUrl = 'https://aka.ms/AzureConnectedMachineAgent'
    $msiLocal    = Join-Path $WorkFolder 'AzureConnectedMachineAgent.msi'

    # Download latest CMA
    try {
        Write-Log "Downloading latest CMA from Microsoft"
        Invoke-WebRequest -Uri $downloadUrl -OutFile $msiLocal -UseBasicParsing -ErrorAction Stop
        Write-Log "Downloaded latest CMA successfully"
    } catch {
        Write-Log "Download failed: $($_.Exception.Message) - trying UNC fallback" -Level Warning
        $msiUNC = Join-Path $SourceFilesFullPath 'AzureConnectedMachineAgent.msi'
        if (-not (Test-Path $msiUNC)) {
            Write-Log "No CMA installer available at $msiUNC" -Level Error
            throw "No CMA installer available"
        }
        Copy-Item $msiUNC $msiLocal -Force
        Write-Log "Using CMA installer from UNC path"
    }

    # Get MSI version
    $getVersion = {
        param($path)
        try {
            $windowsInstaller = New-Object -ComObject WindowsInstaller.Installer
            $database = $windowsInstaller.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $null, $windowsInstaller, @($path, 0))
            $view = $database.GetType().InvokeMember("OpenView", "InvokeMethod", $null, $database, ("SELECT Value FROM Property WHERE Property = 'ProductVersion'"))
            $view.GetType().InvokeMember("Execute", "InvokeMethod", $null, $view, $null)
            $record = $view.GetType().InvokeMember("Fetch", "InvokeMethod", $null, $view, $null)
            return $record.GetType().InvokeMember("StringData", "GetProperty", $null, $record, 1)
        } catch {
            Write-Log "Failed to read MSI version: $($_.Exception.Message)" -Level Warning
            return "0.0.0.0"
        }
    }

    $newVersion = [Version](& $getVersion $msiLocal)
    Write-Log "Installer version: $newVersion"

    # Check if agent is already installed
    if (Test-Path $Azcm) {
        try {
            $agentInfo = & $Azcm show -j | ConvertFrom-Json
            $currentVersion = [Version]$agentInfo.agentVersion
            Write-Log "Current CMA version: $currentVersion"
            
            if ($newVersion -gt $currentVersion) {
                Write-Log "Updating CMA from $currentVersion to $newVersion"
                $installArgs = "/i `"$msiLocal`" /qn /l*v `"$WorkFolder\cma-install.log`""
                $process = Start-Process msiexec.exe -ArgumentList $installArgs -Wait -PassThru
                if ($process.ExitCode -ne 0) {
                    Write-Log "CMA installation failed with exit code $($process.ExitCode)" -Level Error
                    throw "CMA installation failed"
                }
                Write-Log "CMA updated successfully"
            } else {
                Write-Log "CMA is already up to date ($currentVersion)"
            }
        } catch {
            Write-Log "Error checking current CMA version: $($_.Exception.Message)" -Level Warning
            Write-Log "Attempting to install/repair CMA"
            $installArgs = "/i `"$msiLocal`" /qn /l*v `"$WorkFolder\cma-install.log`""
            Start-Process msiexec.exe -ArgumentList $installArgs -Wait
        }
    } else {
        Write-Log "Installing CMA version $newVersion"
        $installArgs = "/i `"$msiLocal`" /qn /l*v `"$WorkFolder\cma-install.log`""
        $process = Start-Process msiexec.exe -ArgumentList $installArgs -Wait -PassThru
        if ($process.ExitCode -ne 0) {
            Write-Log "CMA installation failed with exit code $($process.ExitCode)" -Level Error
            throw "CMA installation failed"
        }
        Write-Log "CMA installed successfully"
    }
}

# --- MAIN EXECUTION ---
try {
    Write-Log "=== Azure Arc Onboarding Started ==="
    Write-Log "Machine: $env:COMPUTERNAME"
    
    # Install or update the agent
    Install-Or-Update-CMA

    # Get Service Principal secret
    $spSecret = Get-ServicePrincipalSecret
    if (-not $spSecret) {
        Write-Log "No service principal secret available" -Level Error
        exit 1
    }

    # Build tags
    Write-Log "Preparing tags"
    $tagsHash = @{ DeployedBy = 'GPO' }
    if ($arcInfo.Tags) {
        $arcInfo.Tags.psobject.properties | ForEach-Object {
            $tagsHash[$_.Name] = $_.Value
            Write-Log "  Tag: $($_.Name) = $($_.Value)"
        }
    }
    $tagsString = ($tagsHash.GetEnumerator() | ForEach-Object { "$($_.Key)='$($_.Value)'" }) -join ','

    # Build connection arguments
    Write-Log "Connecting to Azure Arc"
    $connectArgs = @(
        'connect'
        '--resource-name', $env:COMPUTERNAME
        '--service-principal-id', $arcInfo.ServicePrincipalClientId
        '--service-principal-secret', $spSecret
        '--resource-group', $arcInfo.ResourceGroup
        '--tenant-id', $arcInfo.TenantId
        '--location', $arcInfo.Location
        '--subscription-id', $arcInfo.SubscriptionId
        '--cloud', 'AzureCloud'
        '--tags', $tagsString
    )

    # Add optional parameters
    if (-not [string]::IsNullOrWhiteSpace($arcInfo.PrivateLinkScopeId)) {
        Write-Log "Using Private Link Scope: $($arcInfo.PrivateLinkScopeId)"
        $connectArgs += '--private-link-scope', $arcInfo.PrivateLinkScopeId
    }

    if (-not [string]::IsNullOrWhiteSpace($arcInfo.ProxyUrl)) {
        Write-Log "Using Proxy: $($arcInfo.ProxyUrl)"
        $connectArgs += '--proxy', $arcInfo.ProxyUrl
    }

    # Execute connection
    Write-Log "Executing: azcmagent connect..."
    $output = & $Azcm @connectArgs 2>&1
    $exitCode = $LASTEXITCODE

    # Log output
    $output | ForEach-Object { Write-Log $_ }

    if ($exitCode -eq 0) {
        Write-Log "Successfully connected to Azure Arc" -Level Info
        
        # Verify connection
        Write-Log "Verifying connection status"
        $status = & $Azcm show -j | ConvertFrom-Json
        Write-Log "Agent Status: $($status.status)"
        Write-Log "Resource ID: $($status.resourceId)"
        Write-Log "=== Azure Arc Onboarding Completed Successfully ===" -Level Info
        exit 0
    } else {
        Write-Log "Azure Arc connection failed with exit code $exitCode" -Level Error
        exit $exitCode
    }

} catch {
    Write-Log "Fatal error during onboarding: $($_.Exception.Message)" -Level Error
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level Error
    exit 1
}
