$TenantID = "" ## The Tenant ID which the Subscription is inside of.
$Subscription = "" ## The Subscription ID, that the storage Tables will be created in.

# Get a reference to our workspace. To get that we will need to know the resource group and workspace names
$workspaceName = ''
$resourceGroupName = ''

#$username = Read-Host ("Enter Azure Username")
#$pwd = Read-Host ("Enter Azure Password for " + $username) -AsSecureString
#$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, $pwd

#Connect-AzAccount -Tenant $TenantID -Subscription $Subscription -Credential $Credential

$context = Get-AzContext
$profile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
$profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($profile)
$token = $profileClient.AcquireAccessToken($context.Subscription.TenantId)
$authHeader = @{
    'Content-Type'  = 'application/json'
    'Authorization' = 'Bearer ' + $token.AccessToken 
}

     
#Create the URL to get all the cases
$subscriptionId = (Get-AzContext).Subscription.Id
$incidentUrl = "https://management.azure.com/subscriptions/$($subscriptionId)/resourceGroups/$($resourceGroupName)"
$incidentUrl += "/providers/Microsoft.OperationalInsights/workspaces/$($workspaceName)/providers/Microsoft.SecurityInsights/"
$incidentUrl += "cases?api-version=2019-01-01-preview"
#Get all the cases (or at least the top 200)
$incidents = (Invoke-RestMethod -Method "Get" -Uri $incidentUrl -Headers $authHeader ).value

#Write-Host $incidents
 
#Get the Log Analytics workspace
$workspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $resourceGroupName -Name $workspaceName
#$workspaceID = ""
#write-host $workspace
#You would most likely add a time filter here and store the last used time to
#make sure you don't add multiple comments to the same incident (not that it
# would hurt anything if you did)
$query = 'SecurityAlert
| summarize arg_max(TimeGenerated, *) by SystemAlertId
| where SystemAlertId in("138d79fb-72b5-482b-b8d6-XXXXXXX")'
#Run the query against the Log Analytics workspace
$queryResults = Invoke-AzOperationalInsightsQuery -Workspace $workspace -Query $query
#Each $result will be a MCAS alert
foreach ($result in $queryResults.Results) { 
    Write-Host "result Variable"
    Write-Host $result
    #Get the incident (AKA case) from the list
    Write-Host "####### Incidents Varialble #########"
    Write-Host $incidents.Length
    $incident = $incidents | Where-Object {$_.properties.relatedAlertIds -eq $result.SystemAlertId}
    #Write-Host "incident Variable"
    #Write-Host $incident
    #If there is a match (it could be the incident is not in the first 200) add the comment
    if ($null -ne $incident)
{

        $incidentName = ($incident.name)
        Write-Host "########## incidentName Variable ###########"
        Write-Host $incidentName
        }
}
