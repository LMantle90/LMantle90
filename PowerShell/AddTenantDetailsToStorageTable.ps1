# This script is used to update an Azure Storage Table with the SubscriptionID, TenantID, and a unique GUID (specific to each Subscription)
# The script starts by generating the GUID, then sets the correct context - to ensure the information is added to our MSP tenant.
# Then, using an existing Storage Account, it checks whether the required table exists within it, if not, the script creates the table.
# The script then ads a new row to the table, containing the client details


# Set variables - (These are currently hard-coded, however details such as clientTenantID and clientSubscritionID
# will be passed through as parameters from the parent Powershell script)

$storageAccountName = "clientdetailsstorage1"
$location = "uksouth"
$resourceGroup = ""
$mspTenantID = ""
$mspSubscriptionID = ""
$tableName = ""
$partitionKey = ""

#############################################################################
## These values will need changing to take parmeters from Master script #####
#############################################################################

$clientTenantID = "This-Wll-Be-Client-Tenant-ID"
$clientSubscriptionID = "This-Will-Be-Client-Subscription-ID"

##############################################################################
##############################################################################
##############################################################################


## Creates a new unique ID that will be associated with each new table entry.
$guid = [guid]::NewGuid()

## Ensure MSP tenant and subscription is selected
Set-AzContext -Tenant $mspTenantID -Subscription $mspSubscriptionID


## Uses an existing storage account
$storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroup `
  -Name $storageAccountName

## Sets the context for the Storage Account
$ctx = $storageAccount.Context


## Lists name's of available storage accounts - For Debugging #
#Get-AzStorageTable -Context $ctx | Select Name


## If $table does not exist, then create it.

Get-AzStorageTable -Name $tableName -Context $ctx -ErrorVariable tableError -ErrorAction SilentlyContinue
if ($tableError) 
    {
        New-AzStorageTable –Name $tableName –Context $ctx
    }

## Add Storage Table details to variable
$storageTable = Get-AzStorageTable –Name $tableName –Context $ctx

## References CloudTable property of specific table
## (To perform operations on a table using AzTable, you need a reference to CloudTable property of a specific table.)
$cloudTable = (Get-AzStorageTable –Name $tableName –Context $ctx).CloudTable


## Add row to table
Add-AzTableRow `
    -table $cloudTable `
    -partitionKey $partitionKey `
    -rowKey ($clientSubscriptionID) -property @{"SubscriptionID"=$clientSubscriptionID;"TenantID"=$clientTenantID; "GUID"=$guid}