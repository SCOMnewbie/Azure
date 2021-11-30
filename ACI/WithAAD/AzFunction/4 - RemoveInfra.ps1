# Input bindings are passed in via param block.
param([hashtable] $QueueItem, $TriggerMetadata)

# Get MSI token for the "https://management.azure.com/" resource
$Scope = "https://management.azure.com/"
$tokenAuthUri = $env:IDENTITY_ENDPOINT + "?resource=$Scope&api-version=2019-08-01"
$response = Invoke-RestMethod -Method Get -Headers @{"X-IDENTITY-HEADER"="$env:IDENTITY_HEADER"} -Uri $tokenAuthUri -UseBasicParsing
$Token = $response.access_token

# Create variables based on queueitem received.
New-VariableFactory -data $QueueItem

Write-host "Remove infra based on runId: $___runId"

$___ACRSubscriptionId
$___ACIRG
$___ContainerName

$Splatting = @{
    containerGroupName = $___ContainerName
    resourceGroupName = $___ACIRG
    subscriptionId = $___ACRSubscriptionId
    AccessToken = $Token
}

Remove-ContainerGroup @Splatting

# Now we have variable, let's clean the infra.
# https://docs.microsoft.com/en-us/rest/api/container-instances/container-groups/delete
