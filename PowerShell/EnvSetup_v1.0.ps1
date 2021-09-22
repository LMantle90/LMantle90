<#
.NOTES
  Purpose:           To create Azure Resource Group, Azure Log Analytics Workspace, Azure Storage Account and Azure Storage Table in Client Azure Subscription. Also to enable Azure Sentinel on Log Analytics Workspace.
  Version:           1.0
  Author:            Lewis Mantle
  Company:           DXC
  Creation Date:     18/08/2020
  Last Updated Date: 22/07/2020
  Last Updated By:   Lewis Mantle
  Purpose/Change:    Hard-coded Storage Table name. Added check for Log Analytics Workspace Name that has been soft deleted. Standardised Module installation steps.
#>

param (
[Parameter(Mandatory=$true)][string]$ResourceGroupName,
[Parameter(Mandatory=$true)][string]$SubscriptionID,
[Parameter(Mandatory=$true)][string]$TenantID,
[Parameter(Mandatory=$true)][string]$WorkspaceName,
[Parameter(Mandatory=$true)][string]$Location,
[Parameter(Mandatory=$true)][string]$StorageAccountName,
[Parameter(Mandatory=$true)][string]$storageTableName
)

function Test-IsGuid
{
	[OutputType([bool])]
	param
	(
		[Parameter(Mandatory = $true)]
		[string]$ObjectGuid
	)
	# Define verification regex
	[regex]$guidRegex = '(?im)^[{(]?[0-9A-F]{8}[-]?(?:[0-9A-F]{4}[-]?){3}[0-9A-F]{12}[)}]?$'

	# Check guid against regex
	return $ObjectGuid -match $guidRegex
}

# Provide User with options before stopping the script if any errors occur
#$ErrorActionPreference = "Inquire"

## Checking version of PowerShell. V6.2 Required for AzSentinel Module.
#$ver = $PSVersionTable.PSVersion.Major,$PSVersionTable.PSVersion.Minor -join "."

#If($ver -ge 6.2){
#Write-Output "Version 6.2 of PowerShell is required to run this script."
#Write-Output "Current version installed is: $ver"
#}
#else{
#    Write-Output "Latest Version of PowerShell is required to run this script."
#    Write-Output "Current version is: $ver"
#    Write-Output "Checking for Version 7..."
#
#    $pathcheck = Test-Path "C:\Program Files\PowerShell\7\pwsh.exe"
#    if($pathcheck -eq "True"){
#        Write-Output "Launching script in PowerShell version 7. This window will now close."
#        $exe = "pwsh.exe"
#        $thisPath = "`"$PSCommandPath`" -ResourceGroupName $ResourceGroupName -SubscriptionID $SubscriptionID -TenantID $TenantID -WorkspaceName $WorkspaceName -Location $Location -StorageAccountName $StorageAccountName"
#        Start-Process $exe $thisPath
#        exit
#    }
#    else{
#        Write-Output "Updating PowerShell to latest version. Follow GUI instructions. Once installed, script will continue in PowerShell Version 7"
#        iex "& { $(irm https://aka.ms/install-powershell.ps1) } -UseMSI"
#        $exe = "pwsh.exe"
#        $thisPath = "`"$PSCommandPath`" -ResourceGroupName $ResourceGroupName -SubscriptionID $SubscriptionID -TenantID $TenantID -WorkspaceName $WorkspaceName -Location $Location -StorageAccountName $StorageAccountName"
#        Start-Process $exe $thisPath
#        exit
#    }
#}

# Confirming Subscription ID is a valid GUID
if((Test-IsGuid -ObjectGuid $SubscriptionID) -eq $True){
Write-Output "Confirmed that Subscription ID given matches GUID RegEx."
}
Else{
    Do{
        Write-Output "Subscription ID provided does not match format for valid Subscription ID. (XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX)"
        Write-Output "Please correct the Subscription ID syntax and retry running the Pipeline."
        exit
    }
    While ((Test-IsGuid -ObjectGuid $SubscriptionID) -eq $False)
}


# Confirming Tenant ID is a valid GUID
if((Test-IsGuid -ObjectGuid $TenantID) -eq $True){
Write-Output "Confirmed that Tenant ID given matches GUID RegEx."
}
Else{
    Do{
        Write-Output "Tenant ID provided does not match format for valid Tenant ID. (XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX)"
        Write-Output "Please correct the Tenant ID syntax and retry running the Pipeline."
        exit
    }
    While ((Test-IsGuid -ObjectGuid $TenantID) -eq $False)
}

## Confirming Location Value is valid

$LocationTest = 'eastasia','southeastasia','centralus','eastus','eastus2','westus','northcentralus','southcentralus','northeurope','westeurope','japanwest','japaneast','brazilsouth','australiaeast','australiasoutheast','southindia','centralindia','westindia','canadacentral','canadaeast','uksouth','ukwest','westcentralus','westus2','koreacentral','koreasouth','francecentral','francesouth','australiacentral','australiacentral2','southafricanorth','southafricawest' -contains $Location
if($LocationTest -eq $True){
Write-Output "Confirmed that Location provided is valid Azure Location."
}
Else{
    Do{
        Get-AzLocation
        Write-Output "The Location value provided ($Location) is not a valid Azure Location."
        Write-Output "See above for valid list of locations, and enter location as per the value given for 'Location:'."
        Write-Output "Please correct the Location value and retry running the Pipeline."
        exit
    }
    While ($LocationTest -eq $False)
}

## Confirming Storage Account Name is valid.

if($StorageAccountName -cmatch '[^a-z0-9]' -or $StorageAccountName.Length -gt 23 -or $StorageAccountName.Length -lt 3)
{
Write-Output "Invalid Storage Table Name"
    Do{
        Write-Output "Storage Account Name provided ($StorageAccountName) does not match the requirements for an Azure Storage Account name."
        Write-Output "Storage Account Names must contain only lower-case letters and numbers. And must be between 3 and 23 characters in length."
        exit
    }
    While (($StorageAccountName -cmatch '[^a-z0-9]' -or $StorageAccountName.Length -gt 23 -or $StorageAccountName.Length -lt 3) -eq $True)
}
else{
Write-Output "Confirmed Storage Account Name is Valid. Once a connection to Azure has been made, the script will check whether this name is already in use."
Write-Output "If it is already in use, then a new globally unique name will need to be provided."
}


## Instaling Required Modules


if(Get-Module -ListAvailable -Name Az.Accounts){
    Write-Output "Azure Accounts Powershell Module is installed."
}
else{
    Write-Output "Azure Accounts PowerShell module is missing. Installing module..."
    Install-Module Az.Accounts -Scope CurrentUser -Force -AllowClobber
    Import-Module Az.Accounts -Force
}

if(Get-Module -ListAvailable -Name AzTable){
    Write-Output "Azure Table Powershell Module is installed."
}
else{
    Write-Output "Azure Table PowerShell module is missing. Installing module..."
    Install-Module AzTable -Scope CurrentUser -Force -AllowClobber
    Import-Module AzTable -Force
}

if(Get-Module -ListAvailable -Name Az.Storage){
    Write-Output "Azure Storage Powershell Module is installed."
}
else{
    Write-Output "Azure Storage PowerShell module is missing. Installing module..."
    Install-Module Az.Storage -Scope CurrentUser -Force -AllowClobber
    Import-Module Az.Storage -Force
}

#if(Get-Module -ListAvailable -Name AzSentinel){
#    Write-Output "Azure Sentinel Powershell Module is installed."
#}
#else{
#    Write-Output "Azure Sentinel PowerShell module is missing. Installing module..."
#    Install-Module AzSentinel -Scope CurrentUser -Force -AllowClobber
#    Import-Module AzSentinel -Force
#}

if(Get-Module -ListAvailable -Name Az.Resources){
    Write-Output "Azure Resources Powershell Module is installed."
}
else{
    Write-Output "Azure Resources PowerShell module is missing. Installing module..."
    Install-Module Az.Resources -Scope CurrentUser -Force -AllowClobber
    Import-Module Az.Resources -Force
}

if(Get-Module -ListAvailable -Name Az.OperationalInsights){
    Write-Output "Azure Operational Insights Powershell Module is installed."
}
else{
    Write-Output "Azure Operational Insights PowerShell module is missing. Installing module..."
    Install-Module Az.OperationalInsights -Scope CurrentUser -Force -AllowClobber
    Import-Module Az.OperationalInsightss -Force
}

#######################

# Connect to the current Azure account
#Write-Output "Pulling Azure account credentials..."
#
#Connect-AzAccount -Tenant $TenantID -Subscription $SubscriptionID -ErrorAction SilentlyContinue -ErrorVariable connectCheck
#if($connectCheck -ne $null){
#    Write-Output "Failed to connect to Azure using Tenant: $TenantID and Subscription: $SubscriptionID"
#    Write-Output "Please check that these values are correct, and the login credentials being used are correct, and then re-run this script."
#    Read-Host "Press Enter to exit script"
#    exit
#}
#Set-AzContext -Subscription $SubscriptionID


# Check if Resource Group Exists, if not, Create it.
try {
    $RGCheck = Get-AzResourceGroup -Name $ResourceGroupName -Location $Location -ErrorAction Stop
    Write-Output "Resource Group named $ResourceGroupName already exists in Subscription $SubscriptionID."

} catch {
    Write-Output "Resource Group $ResourceGroupName does not exist in Subscription $SubscriptionID."
    Write-Output "Creating Resource Group $ResourceGroupName..."
    New-AzResourceGroup -Name $ResourceGroupName -Location $Location
}

# Create a new Log Analytics workspace if needed
try {

    $Workspace = Get-AzOperationalInsightsWorkspace -Name $WorkspaceName -ResourceGroupName $ResourceGroupName  -ErrorAction Stop
    $ExistingtLocation = $Workspace.Location
    Write-Output "Workspace named $WorkspaceName in region $ExistingLocation already exists."

} catch {
    Write-Output "Creating new workspace named $WorkspaceName in region $Location..."

    # Create the new workspace for the given name, region, and resource group
    $Workspace = New-AzOperationalInsightsWorkspace -Location $Location -Name $WorkspaceName -Sku Standard -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue -ErrorVariable lawError
    if($lawError -ne $null){
        Write-Output "ERROR"
        Write-Output $lawError
        Write-Output "Error usually caused by the Log Analytics Workspace name being reserved." 
        Write-Output "This can happen if a Log Analytics workspace named $workspaceName has recently been deleted from a different Resource Group in your Subscription"
        Write-Output "These deletions are 'soft-deletes', so the Workspace can be recovered within 30-days of deletion if needed."
        Do{
        $workspaceName = Read-Host "Please provide a new Log Analytics Workspace Name and retry running the Pipeline"
        exit
        }
        While ($lawError -ne $null)
    }
    Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $WorkspaceName
    

}
# Enable Azure Sentinel on the Log Anlytics Workspace
#Write-Output "Enabling Sentinel on Workspace: $WorkspaceName"
#Set-AzSentinel -SubscriptionID $SubscriptionID -WorkspaceName $WorkspaceName

## Storage Account Creation ##
Write-Output "Checking if Storage Account $storageAccountName exists in Resource Group $ResourceGroup."
$StorageAccount = Get-AzStorageAccount -Name $storageAccountName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue

if($StorageAccount -eq $null){ #(PSScriptAnalyser - $null should be on the left side of equality comparisons.)
#if($null -eq $StorageAccount){
	Write-Output "$storageAccountName does not exist in this subscription."

    Write-Output "Checking availability of Storage Account Name: $storageAccountName"
    $storageAccountCheck = ((Get-AzStorageAccountNameAvailability -Name $storageAccountName).NameAvailable)

    if ($storageAccountCheck -eq $True){
        Write-Output "This Storage Account Name is valid"
    }
    else{
        Write-Output "This Storage Account Name is invalid"
        Write-Output ((Get-AzStorageAccountNameAvailability -Name $storageAccountName).Message)
        Write-Output "Please provide a new Storage Account name and retry running the Pipeline."

        }
    Write-Output "Creating Storage Account..."
	New-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName -Location $location -SkuName Standard_RAGRS -Kind StorageV2
}

else{
    Write-Output "$storageAccountName already exists in this Subscription"

}


## Gets the account key from the Storage Account, and sets the correct Context.
Write-Output "Storage Account Name: $storageAccountName"
$storageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageAccountName).Value[0]
Write-Output "Storage Account Key: $storageAccountKey"

$storageContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey
Write-Output "Storage Context: $storageContext"


# Create Storage Table ##


$tableCheck = Get-AzStorageTable -Name $storageTableName -Context $storageContext -ErrorAction SilentlyContinue
if($tableCheck -eq $null){ #(PSScriptAnalyser - $null should be on the left side of equality comparisons.)
#if($null -eq $tableCheck){
    Write-Output "Creating $storageTableName Storage Table"
    New-AzStorageTable -Name $storageTableName -Context $storageContext
}
else{
    Write-Output "$storageTableName Storage Table already exists"
}