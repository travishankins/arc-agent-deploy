# ==========================
# Azure Arc Onboarding Script
# ==========================

# --- UNC path to deployment folder ---
$SourceFilesFullPath = '\\lvdc-dc02\netlogon\Global\Arc\AzureArcDeploy'
$WorkFolder          = "$env:TEMP\ArcAgent"
$Azcm                = "$env:ProgramW6432\AzureConnectedMachineAgent\azcmagent.exe"

# --- Ensure work folder exists ---
if (-not (Test-Path $WorkFolder)) {
    New-Item -Path $WorkFolder -ItemType Directory -Force | Out-Null
}

# --- Load ArcInfo.json ---
$ArcInfoPath = Join-Path $SourceFilesFullPath 'ArcInfo.json'
if (-not (Test-Path $ArcInfoPath)) {
    throw "ArcInfo.json not found in $SourceFilesFullPath"
}
$arcInfo = Get-Content $ArcInfoPath -Raw | ConvertFrom-Json

# --- Helper: Get SP secret ---
function Get-ServicePrincipalSecret {
    $psm1 = Join-Path $SourceFilesFullPath 'AzureArcDeployment.psm1'
    $enc  = Join-Path $SourceFilesFullPath 'encryptedServicePrincipalSecret'

    if ((Test-Path $psm1) -and (Test-Path $enc)) {
        try {
            Copy-Item $psm1 (Join-Path $WorkFolder 'AzureArcDeployment.psm1') -Force
            Import-Module (Join-Path $WorkFolder 'AzureArcDeployment.psm1') -Force
            $encryptedSecret = Get-Content $enc -Raw
            $sps = [DpapiNgUtil]::UnprotectBase64($encryptedSecret)
            Remove-Item (Join-Path $WorkFolder 'AzureArcDeployment.psm1') -Force -ErrorAction SilentlyContinue
            if ([string]::IsNullOrWhiteSpace($sps)) { return $null }
            return $sps
        } catch {
            Write-Output "WARN: Could not decrypt SP secret with DPAPI: $($_.Exception.Message)"
            return $null
        }
    }

    if ($arcInfo.ServicePrincipalSecretPlain) {
        return [string]$arcInfo.ServicePrincipalSecretPlain
    }
    return $null
}

# --- Install/Update CMA ---
function Install-Or-Update-CMA {
    Write-Output "Checking CMA version..."
    $downloadUrl = 'https://aka.ms/AzureConnectedMachineAgent'
    $msiLocal    = Join-Path $WorkFolder 'AzureConnectedMachineAgent.msi'

    try {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $msiLocal -UseBasicParsing -ErrorAction Stop
        Write-Output "Downloaded latest CMA from Microsoft."
    } catch {
        Write-Output "Download failed: $($_.Exception.Message) — using UNC fallback."
        $msiUNC = Join-Path $SourceFilesFullPath 'AzureConnectedMachineAgent.msi'
        if (-not (Test-Path $msiUNC)) { throw "No CMA installer available." }
        Copy-Item $msiUNC $msiLocal -Force
    }

    # Compare versions
    $getVersion = {
        param($path)
        $windowsInstaller = New-Object -ComObject WindowsInstaller.Installer
        $database = $windowsInstaller.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $Null, $windowsInstaller, @($path, 0))
        $view = $database.GetType().InvokeMember("OpenView", "InvokeMethod", $Null, $database, ("SELECT Value FROM Property WHERE Property = 'ProductVersion'"))
        $view.GetType().InvokeMember("Execute", "InvokeMethod", $Null, $view, $Null)
        $record = $view.GetType().InvokeMember("Fetch", "InvokeMethod", $Null, $view, $Null)
        return $record.GetType().InvokeMember("StringData", "GetProperty", $Null, $record, 1)
    }

    $newVersion = [Version](& $getVersion $msiLocal)

    if (Test-Path $Azcm) {
        $currentVersion = [Version]((& $Azcm show -j | ConvertFrom-Json).agentVersion)
        if ($newVersion -gt $currentVersion) {
            Write-Output "Updating CMA from $currentVersion to $newVersion"
            Start-Process msiexec.exe -ArgumentList "/i `"$msiLocal`" /qn" -Wait
        } else {
            Write-Output "CMA already up to date ($currentVersion)"
        }
    } else {
        Write-Output "Installing CMA version $newVersion"
        Start-Process msiexec.exe -ArgumentList "/i `"$msiLocal`" /qn" -Wait
    }
}

# --- MAIN ---
Install-Or-Update-CMA

$spSecret = Get-ServicePrincipalSecret
if (-not $spSecret) { throw "No service principal secret available." }

# Build tags
$tagsHash = @{ DeployedBy = 'GPO' }
if ($arcInfo.Tags) {
    $arcInfo.Tags.psobject.properties | ForEach-Object { $tagsHash[$_.Name] = $_.Value }
}
$tagsString = ($tagsHash.GetEnumerator() | ForEach-Object { "$($_.Key)='$($_.Value)'" }) -join ','

# Connect
& $Azcm connect `
  --resource-name $env:COMPUTERNAME `
  --service-principal-id $arcInfo.ServicePrincipalClientId `
  --service-principal-secret $spSecret `
  --resource-group $arcInfo.ResourceGroup `
  --tenant-id $arcInfo.TenantId `
  --location $arcInfo.Location `
  --subscription-id $arcInfo.SubscriptionId `
  --cloud AzureCloud `
  --tags $tagsString

# Verify
& $Azcm show
