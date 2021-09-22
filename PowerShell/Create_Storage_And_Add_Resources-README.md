# DXC Managed Sentinel Offering
 ## Create Storage Tables and File Shares within Azure Storage Account

 ### Quick Overview:

 - [x] PowerShell script created to create a number of Azure Storage Tables, and Azure File Shares, which are needed to hold data used as part of the Analytics process.
 - [x] This script also incorporates actions which were, up until now undertaken by Azure Logic Apps.
 - [x] The PowerShell scripts must first be provided with a number of variables, see below.
 - [x] When the script runs, it will prompt the User to log in to Azure.
 - [x] It will then Ensure that the Resource Group and Storage Account specified exist.
 - [x] The script will then create the required File Shares, and Storage Tables.
 - [x] It will then populate the Storage Tables with data regarding the Subscription and its Resources, that the Analytics process will utilise.
 
 #### Prerequisites
  
 - PowerShell must be installed on the local machine.
 - Admin permissions on the local machine - To allow the installation of PowerShell modules if necessary.
 - A login for Microsoft Azure. 
 
 #### Instructions
 
 - Open the 'Create_Storage_And_Add_Resources.ps1' PowerShell script in a PowerShell editor, for example PowerShell ISE.

 - The script will show 5 variables at the top which need editing, to match the details of the Subscription that you are wanting to create these tables in.
	$TenantID = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" ## The Tenant ID which the Subscription is inside of.
	$Subscription = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" ## The Subscription ID, that the storage Tables will be created in.
	$resourceGroupName = "ResourceGroupName" ## The Resource Group Name that the Storage Tables will be created in.
	$storageAccountName = "storageaccountname82736" ## Must be globally unique, under 24 characters, lower-case, no special characters.
	$location = "westus" ## The Location/Region that the Resource Group is in.
 
 - The Tenant ID and the Subscription ID can be found within Azure, in the Subscription that you're wanting to create these storage tables in.
 - The Resource Group Name can be either a pre-existing Resource Group, in the afore mentioned Subscription, or a new one, which will be created at runtime.
 - The Location refers to the Location/Region of this Resource Group. Either where it currently sits, or where it is going to be created.
 - The Storage Account Name is either the name of a pre-existing storage account, where these tables and file shares are going to be added into, or the name of a new Storage Account that is to be created.
 - Note: If choosing to create a new Storage Account, the Storage Account Name MUST be globally unique, and must meet various format requirements. i.e. Less than 24 characters, lowercase alphanumeric characters only.
 
 - Once these 5 values have been set, the script can be run.
 - This can be run directly from within the PowerShell ISE, by hitting F5.
 
 - When the script initiates, it will begin by checking that the required PowerShell modules are installed.
 - If there are any required Modules missing, then these will be installed.
 - Depending on what is missing, this can take some time.
 
 - The script will continue by prompting the User for their Username and Password for Azure.
 - Note: Going forward this can be amended to utilise a Service Principal instead.
 
 - Once the script has connected to Azure, it checks if the provided Resource Group name exists within the logged-in Subscription.
 - If the Resource Group does not exist, then the script creates it.
 
 - The same action is then performed for the Storage Account, however a further check is done - If when creating the Storage Account, the script determines that the Storage Account name is already taken, then it produces a prompt to the user to change the value of the Storage Account Name variable, and ends the script.
 
 - If the Resource Group and Storage Account are valid, and have been created, then the script continue to create the 2 required File Shares:
 - 'json'
 - 'notebook'
 
 - It then creates the 3 required Storage Tables:
 - 'LogicStatusQuery'
 - 'ClientDetails'
 - 'ResourcesTable'
 
 - The script then gathers details of the currently logged in Subscription, specifically the Display Name of the Subscription, as well as its Subscription ID.
 - These details are added to the newly created 'ClientDetails' table. These details will be used going forward by the Analytics team.
 
 - The script then gathers the details of all of the Resources within the Subscription.
 - It adds each Resource (The Resource's name, location, the Resource Group it's in, etc.) to the newly created 'ResourcesTable' Storage Table.
 
 
---
