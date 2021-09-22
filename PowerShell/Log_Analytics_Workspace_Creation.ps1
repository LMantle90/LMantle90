param (
[Parameter(Mandatory=$true)][string]$ResourceGroupName,
[Parameter(Mandatory=$true)][string]$SubscriptionID,
[Parameter(Mandatory=$true)][string]$TenantID,
[Parameter(Mandatory=$true)][string]$WorkspaceName,
[Parameter(Mandatory=$true)][string]$Location
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


## Instaling Required Modules


if(Get-Module -ListAvailable -Name Az.Accounts){
    Write-Output "Azure Accounts Powershell Module is installed."
}
else{
    Write-Output "Azure Accounts PowerShell module is missing. Installing module..."
    Install-Module Az.Accounts -Scope CurrentUser -Force -AllowClobber
    Import-Module Az.Accounts -Force
}


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
