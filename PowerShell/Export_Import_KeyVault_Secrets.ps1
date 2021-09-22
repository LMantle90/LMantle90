# Get variables from .\Params.txt
if (-NOT (Test-Path -Path .\Params.txt))
{
Write-Host "############## Warning ###############"
Write-Host "############## Warning ###############"
Write-Host "The required file Params.txt does not exist in the same directory as this PowerShell script"
Write-Host "Please ensure the file exists, and has the following values, in the below order:"
Write-Host "SourceTenantID = xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
Write-Host "SourceSubscriptionID = xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
Write-Host "SourceKeyVaultName = vaultName"
Write-Host "DestinationTenantID = xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
Write-Host "DestinationSubscriptionID = xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
Write-Host "DestinationResourceGroup = Resource-Group-Name123"
Write-Host "DestinationRegion = uksouth"
Write-Host "#######################################"
Write-Host "#######################################"
Read-Host "Press any key to terminate the script. Re-run the script once the Params.txt file has been created in the same directory as this PowerShell script:"
Break
}
Else
{

}

$values = Get-Content .\Params.txt
$count = 0
foreach ($value in $values)
{
$pos = $value.IndexOf("=")
$value = $value.Substring($pos+1)
$value = $value.Trim()
#Write-Host $value
$count = ($count + 1)
if ($count -eq 1){
$exportTenantID = $value
}
elseif ($count -eq 2){
$exportSubscription = $value
}
elseif ($count -eq 3){
$exportVaultName = $value
}
elseif ($count -eq 4){
$importTenantID = $value
}
elseif ($count -eq 5){
$importSubscription = $value
}
elseif ($count -eq 6){
$importResourceGroup = $value
}
elseif ($count -eq 7){
$importlocation = $value
}

}

$importVaultName = $exportVaultName+$importSubscription.Substring(0,8)
$outputFolder = "C:\Users\" + $env:USERNAME + "\Documents\KeyVault_Test\secrets\"

#####################################################################################################


#####################################################################################################

If(-not(Get-InstalledModule AzureAD -ErrorAction silentlycontinue)){
Write-Hose "AzureAD PowerShell module is missing. Installing this before continuing..."
Install-Module AzureAD -Confirm:$false -Force
}

# Gather Azure Credentials

$username = ($env:USERNAME)
$pwd = Read-Host ("Enter Azure Password for " + $username) -AsSecureString
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, $pwd

# Creates the $outputFolder if it doesn't already exist. If it does exist, prompts user to confirm they are happy to continue.

do {
    Write-Host "Please ensure " $outputFolder " is an empty folder, or a new directory, as the entire contents will be deleted after the script is run."
    Write-Host "If this folder does not already exist, then this script will create it."
    Write-Host "This folder should be used ONLY for the temporary storage of the Key Vault secrets."
    Write-Host "Only Continue if you are happy for the contents of " $outputFolder " to be deleted."
    $continueCheck = Read-Host "Continue: Y/N?"
    }
    until ($continueCheck -match "Y" -or $continueCheck -match "N" )

    if ($continueCheck -match "Y")
    {
    Write-Host "##################################################################################"
    Write-Host "Continuing with script."
    Write-Host "##################################################################################" 
    }
    elseif ($continueCheck -match "N")
    {
    Write-Host "##################################################################################"
    Write-Host "Please update the folder path value, and then re-run the PowerShell Script"
    Write-Host "Terminating Script"
    Write-Host "##################################################################################"
    Break
    }

if (-NOT (Test-Path -Path $outputFolder))
{
    New-Item -ItemType Directory -Force -Path $outputFolder
    Write-Host "############################################################################"
    Write-Host "Folder path " $outputFolder " did not exist - This has now been created."
    Write-Host "############################################################################"
}
Else {
    Write-Host "##################################################################################"
    Write-Host "This folder path "$outputFolder " already exists. Continue using this folder?"
    Write-Host "Warning! All Contents Of Folder Will Be Deleted At End Of Script"
    Write-Host "##################################################################################"

    do {
    $continueCheck = Read-Host "Continue: Y/N?"
    }
    until ($continueCheck -match "Y" -or $continueCheck -match "N" )

    if ($continueCheck -match "Y")
    {
    Write-Host "##################################################################################"
    Write-Host "Continuing with folder path "$outputFolder ". Clearing contents of folder."
    Write-Host "##################################################################################"
    Remove-Item -Path ($outputFolder + '*.*') -Force
    }
    elseif ($continueCheck -match "N")
    {
    Write-Host "##################################################################################"
    Write-Host "Please update the folder path value, and then re-run the PowerShell Script"
    Write-Host "Terminating Script"
    Write-Host "##################################################################################"
    Break
    }
}

# Get all of the secrets in $vaultName key vault and store them in .txt files in the $outputFolder
Connect-AzAccount -Tenant $exportTenantID -Subscription $exportSubscription -Credential $Credential

# Checks if the Key Vault exists in the source subscription. If Not, prompts the user to enter correct name.
Do {

$secrets = Get-AzKeyVaultSecret -VaultName $exportVaultName -ErrorVariable vaultError -ErrorAction SilentlyContinue
    if ($vaultError -like 'The remote name could not be resolved:*')
        {
        Write-Host "#### ERROR ####"
        Write-Host $vaultError
        Write-Host "###############"

        Write-Host "The specified Key Vault name does not exist in the source subscription!"
        Write-Host "Please enter the correct Key Vault name, or press Enter to exit."

        $exportVaultName = Read-Host "Enter correct Key Vault Name: (Leave empty and press Enter to Exit)"
        if (!$exportVaultName)
            {
            Write-Host "Terminating Script"
            Break
            }

        }
}
While ($vaultError -like 'The remote name could not be resolved:*')


Write-Host "###################################"
Write-Host "Collecting Secrets. Please wait..."
Write-Host "###################################"

foreach ($secret in $secrets)
{
    $secretKey = Get-AzKeyVaultSecret -VaultName $exportVaultName -Name $secret.Name
    $secretKey = $secretKey.SecretValueText
    Add-Content -Path ($outputFolder + $secret.Name + ".txt") -Value $secretKey

}

# Logs in to destination (import) subscription
Connect-AzAccount -Tenant $importTenantID -Subscription $importSubscription -Credential $Credential

# Checks to see whether Key Vault already exists with this name, if not, prompts to create it.
$vaultNameCheck = Get-AzKeyVault -VaultName $importVaultName
if (!$vaultNameCheck){
    Write-Host "Key Vault" $importVaultName " does not exist. Do you want to create this Key Vault? Choosing No will terminate the script."
    
    do {
    $continueCheck = Read-Host "Create Key Vault: Y/N?"
    }
    until ($continueCheck -match "Y" -or $continueCheck -match "N" )

    if ($continueCheck -match "Y")
    {
    Write-Host "##################################################################################"
    Write-Host "Creating Key Vault: " $importVaultName
    Write-Host "##################################################################################"
    New-AzKeyVault -VaultName $importVaultName -ResourceGroupName $importResourceGroup -Location $importlocation

    Connect-AzureAD -TenantId $importTenantID  -Credential $Credential
    $filter = "startswith(UserPrincipalName, '" + $env:USERNAME + "')"
    $objectID = (Get-AzureADUser -Filter $filter).ObjectId

    Write-Host "##################################################################################"
    Write-Host "Setting Access Policy on Key Vault: " $importVaultName
    Write-Host "Note: If anyone other than yourself requiresaccess to the vault, you will need to add them seperately."
    Write-Host "##################################################################################"
    Set-AzKeyVaultAccessPolicy -VaultName $importVaultName -ObjectId $objectID -PermissionsToSecrets restore,purge,recover,set,backup,get,delete,list -PassThru

    }
    elseif ($continueCheck -match "N")
    {
    Write-Host "##################################################################################"
    Write-Host "Terminating Script & Deleting Secrets from " $outputFolder
    Write-Host "##################################################################################"
    Remove-Item -Path ($outputFolder + '*.*') -Force
    Break
    }
}
else {
    Write-Host "Key Vault" $importVaultName " already exists. Do you want to import the secrets into this Key Vault? Choosing No will terminate the script."
    
    do {
    $continueCheck = Read-Host "Import Secrets: Y/N?"
    }
    until ($continueCheck -match "Y" -or $continueCheck -match "N" )

    if ($continueCheck -match "Y")
    {
    Write-Host "##################################################################################"
    Write-Host "Importing Secrets into: " $importVaultName
    Write-Host "##################################################################################" 
    }
    elseif ($continueCheck -match "N")
    {
    Write-Host "##################################################################################"
    Write-Host "Terminating Script & Deleting Secrets from " $outputFolder
    Write-Host "##################################################################################"
    Remove-Item -Path ($outputFolder + '*.*') -Force
    Break
    }
}

Write-Host "##################################################################################"
Write-Host "Importing secrets from " $outputFolder " in to Key Vault: " $importVaultName
Write-Host "##################################################################################"

# For each secret in the $outputFolder, import the secret into the new KeyVault
$files = Get-ChildItem $outputFolder
foreach ($file in $files)
{
$keyname = $file.name -replace '.txt',''
$secretKey = Get-Content -Path ($outputFolder + $file)
$secretKey = ConvertTo-SecureString -String $secretKey -AsPlainText -Force
Set-AzKeyVaultSecret -VaultName $importVaultName -Name $keyname -SecretValue $secretKey
}

# Empties the $outputFolder
Write-Host "##################################################################################"
Write-Host "Secrets have been imported to" $importVaultName ". Deleting Secrets from " $outputFolder
Write-Host "##################################################################################"

Remove-Item -Path ($outputFolder + '*.*') -Force

Write-Host "##################################################################################"
Write-Host "Script Complete"
Write-Host "##################################################################################"
Read-Host "Press any key to exit."