<#
#The goal of this function:
    - Generate variables based on dataset from the initjob queue
    - Fetch an access token for the "https://management.azure.com/" resource (thx system MSI)
    - Use the system MSI to fetch ACR credential.
    - Use system MSI to fetch template spec.
    - Deploy ACI using template spec in the deployinfra resource group

    Because in our dataset our keys are all prefixed with ___, the New-VariableFactory  function will create dynamic variables under the for $___<var>
    More info in the next script regarding the why

    DON'T FORGET TO ADD THE loadme module in your webapp!
#>

param([hashtable]$QueueItem, $TriggerMetadata)

#Generate all variables in memory. In this case will generate a lot of $___<variable>
New-VariableFactory -data $QueueItem

# Get MSI token for the "https://management.azure.com/" resource to deploy our container into ACI
$Scope = "https://management.azure.com/"
$tokenAuthUri = $env:IDENTITY_ENDPOINT + "?resource=$Scope&api-version=2019-08-01"
$response = Invoke-RestMethod -Method Get -Headers @{"X-IDENTITY-HEADER"="$env:IDENTITY_HEADER"} -Uri $tokenAuthUri -UseBasicParsing
$Token = $response.access_token

Write-Host "New order received..."

#Don't have to initialize anything, those variables comes from the initjob.
Write-Host "Get admin ACR credential with MSI"
$ACRInfo = Get-ACRCredential -registryName $___ACRName -resourceGroupName $___ACRRG -subscriptionId $___ACRSubscriptionId -AccessToken $token

# Here we use the same concept. Because there is nothing secret, why not just take all our dataset and format it in a specific form to expose them as env variable in the container.
Write-Host "Generate dynamic environment variables based on prefix (___ in this case) that we will pass to our ACI"
$EnvVars = New-ACIEnvGenerator -Variables $(Get-Variable -Name '___*' )

$splatting = @{
    Name = $___ContainerName
    ResourceGroupName = $___ACIRG
    TemplateSpecId = $___ACITemplateSpecId
    ContainerName = $___ContainerName
    ImageName = $___Imagename
    EnvironmentVariables = $EnvVars
    imageRegistryCredentialsServer = $___ACRNameFullName
    imageRegistryCredentialsUsername = $($ACRInfo.Username)
    imageRegistryCredentialsPassword = $(ConvertTo-SecureString $($ACRInfo.passwords[0].value) -AsPlainText)
    UserMSIResourceId = $___UserMSIResourceId
}

# Just deploy the ACI from template specs + lot of env variables exposed.
New-AzResourceGroupDeployment @splatting
