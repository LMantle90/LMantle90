$TenantID = ""
$SubscriptionID = ""
$ResourceGroup = ""
$Workspace = ""

if(Get-Module -ListAvailable -Name Az.Accounts){
    Write-Output "Azure Accounts Powershell Module is installed."
}
else{
    Write-Output "Azure Accounts PowerShell module is missing. Installing module..."
    Install-Module Az.Accounts -Scope CurrentUser -Force -AllowClobber
    Import-Module Az.Accounts -Force
}

if(Get-Module -ListAvailable -Name Az.OperationalInsights){
    Write-Output "Azure Operational Insights Powershell Module is installed."
}
else{
    Write-Output "Azure Operational Insights PowerShell module is missing. Installing module..."
    Install-Module Az.OperationalInsights -Scope CurrentUser -Force -AllowClobber
    Import-Module Az.OperationalInsightss -Force
}

# Connect to the current Azure account
Write-Output "Pulling Azure account credentials..."

Connect-AzAccount -Tenant $TenantID -Subscription $SubscriptionID -ErrorAction SilentlyContinue -ErrorVariable connectCheck
if($connectCheck -ne $null){
    Write-Output "Failed to connect to Azure using Tenant: $TenantID and Subscription: $SubscriptionID"
    Write-Output "Please check that these values are correct, and the login credentials being used are correct, and then re-run this script."
    Read-Host "Press Enter to exit script"
    exit
}
Set-AzContext -Subscription $SubscriptionID


Remove-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroup -Name $Workspace -Force