########### Edit These Variables Only ##################################

$TenantID = "" ## The Tenant ID which the Subscription is inside of.
$Subscription = "" ## The Subscription ID, that the storage Tables will be created in.
$resourceGroupName = "" ## The Resource Group Name that the Storage Tables will be created in.
$storageAccountName = "" ## Must be globally unique, under 24 characters, lower-case, no special characters.
$location = "" ## The Location/Region that the Resource Group is in.

########################################################################


## Checks to ensure Azure PowerShell Modues are installed.
## Installs them if missing.
If(-not(Get-InstalledModule Az -ErrorAction silentlycontinue)){
Write-Host "Azure PowerShell module is missing. Installing this before continuing..."
Install-Module Az -Confirm:$false -Force
}

## Prompts the User for their Username and Password.
## These are the credentials that will be used to log into Azure.
$username = Read-Host ("Enter Azure Username")
$pwd = Read-Host ("Enter Azure Password for " + $username) -AsSecureString
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, $pwd

## Logs into Azure using above Credentials
Connect-AzAccount -Tenant $TenantID -Subscription $Subscription -Credential $Credential

## Checks if the provided Resource Group exists.
## If not, it creates the Resource Group.
Get-AzResourceGroup -Name $resourceGroupName -ErrorVariable rgExists -ErrorAction SilentlyContinue
    if ($rgExists -like "*resource group does not exist*"){
    Write-Host "Resource Group does not exist"
    Write-Host "Creating Resource Group..."
    New-AzResourceGroup -Name $resourceGroupName -Location $location
    }

## Checks if the provided Storage Account exists.
## If not, it creates the Storage Account.
## If the Storage Account name already exists, then it exits the script after prompting the User to update the variables.
Get-AzStorageAccount -Name $storageAccountName -ResourceGroupName $resourceGroupName -ErrorVariable saExists -ErrorAction SilentlyContinue
    if ($saExists -like "*was not found*"){
    Write-Host "Storage Account does not exist"
    Write-Host "Creating Storage Account..."
    New-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName -Location $location -SkuName Standard_RAGRS -Kind StorageV2
    if($nameTaken -like "*is already taken.*"){
        Write-Host "The name"$resourceGroupName "already exists as a Storage Account Name."
        Write-Host "Storage Account names need to be Globally unique."
        Write-Host "Please amend the variables in the script, and provide a new Storage Account Name."
        Read-Host "Press Enter to exit."
        Break

        }
    }

## Gets the account key from the Storage Account, and sets the correct Context.
$storageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageAccountName).Value[0]
$storageContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey

## Creates the 2 requires File Shares in the Storage Account
New-AzStorageShare -Name "json" -Context $storageContext
New-AzStorageShare -Name "notebook" -Context $storageContext

## Creates the 3 required Storage Tables in the Storage Account
New-AzStorageTable -Name "LogicStatusQuery" -Context $storageContext
New-AzStorageTable -Name "ClientDetails" -Context $storageContext
New-AzStorageTable -Name "ResourcesTable" -Context $storageContext

$clientDetailsTable = (Get-AzStorageTable –Name "ClientDetails" –Context $storageContext).CloudTable

## Gathers Details of the currently logged in Subscription
$subscriptionDetails = Get-AzSubscription -SubscriptionId $Subscription -TenantId $TenantID | Select Name,Id,TenantId
$subscriptionName = $subscriptionDetails.Name

## Adds these details to the ClientDetails Storage Table.
Add-AzTableRow -table $clientDetailsTable -partitionKey "Subscriptions" -rowKey $Subscription -property @{"DisplayName"=$subscriptionName;"SUBSCRIPTIONID"=$Subscription;"GUID"=""}

## Gathers Details of all of the Resources within this Subscription.
$resourcesTable = (Get-AzStorageTable –Name "ResourcesTable" –Context $storageContext).CloudTable
$resources = Get-AzResource | Select Name,ResourceGroupName,Location,ResourceType
ForEach ($resource in $resources){



$smallType = $resource.ResourceType
$smallType = $smallType -replace '[/]',''
$rowKey = ($resource.Name + $smallType)
$partitionKey = $resource.ResourceGroupName
$resourceName = $resource.Name
$resourceName = $resourceName -replace'[/]',''
$resourceLocation = $resource.Location

## Adds the details of each resource into the ResourcesTable Storage Table
Add-AzTableRow -table $resourcesTable -partitionKey $partitionKey -rowKey $rowKey -property @{"ResourceName"=$resourceName;"Location"=$resourceLocation;"SUBSCRIPTIONID"=$Subscription} -ErrorVariable tableError -ErrorAction SilentlyContinue
    if ($tableError -like 'Exception calling "Execute" with "1" argument(s): "The remote server returned an error: (400) Bad Request."*')
        {
        Write-Host "#### ERROR ####"
        Write-Host $vaultError
        Write-Host "###############"

        Write-Host "The resource" $resourceName "has not been added to the Storage Table"
        Write-Host "This is normally due to a conflict with the name of the resource."
        }

}