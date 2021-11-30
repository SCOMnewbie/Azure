using namespace System.Net

# The goal of this function is to initialize the dataset we will consume in the whole pipeline and populate a queue with the dataset. 
# We can imagine (not in this case) grabbing information from the query parameter / Body from the request too to add stuff to the dataset we will consume later.

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "Create a new event in the Q"

#Variables initialization # Change with your values here
$TemplateSpecSubscriptionId = '<TemplateSpecs Subscription Id>'
$TemplateSpecRGName = 'DemoACIMgmt'
$TemplateSpecName = 'DemoACI-TSpecs'
$TemplateSpecVersion = '1.0'
$outputQueueName = initjob

# We can also imagine to take dynamic parameters

$Data = @{
    ___NextStageFunctionUrl = "https://<your webapp>.azurewebsites.net/api/Stage2?code=<your code>" #
    ___ACITemplateSpecId = "/subscriptions/$TemplateSpecSubscriptionId/resourceGroups/$TemplateSpecRGName/providers/Microsoft.Resources/templateSpecs/$TemplateSpecName/versions/$TemplateSpecVersion"
    ___Imagename = "DemoACI6521675.azurecr.io/demo/demoacivariable:v1" # Image pulled to do the job
    ___ACRName = 'DemoACI6521675' # Registry name in my case an ACR
    ___ACRNameFullName = 'DemoACI6521675.azurecr.io'
    ___ACRRG = 'DemoACIMgmt' # RG where the ACR is located
    ___ACRSubscriptionId = $TemplateSpecSubscriptionId # In my case both template spec and ACR are located on the same subscription
    ___ContainerName = "demo-{0}" -f $((Get-Date).ToUniversalTime().ToString('yyyyMMddHHmmss')) # our container group will be named <demo-UTCformat>
    ___ACIRG = 'DemoACIInfra' # Our ACI deployments are separated from the mgmt resource group
    ___UserMSIResourceId = '/subscriptions/<User MSI subId>/resourceGroups/DemoACIMgmt/providers/Microsoft.ManagedIdentity/userAssignedIdentities/DemoACI-MSI'
}

# Create dataset in initjob Q
Push-OutputBinding -Name $outputQueueName -Value $Data

# Send a 202 for error handling
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::Accepted
    Body = "Execution accepted"
})
