<#
    Quick function to get an access token for a specific scope (graph.microsoft.com in this case) with a User Managed Identity from an Azure function. 
    You can do the same with a System Managed Identity if you remove the client Id part in the query.
#>

using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

#https://docs.microsoft.com/en-us/azure/app-service/overview-managed-identity?tabs=dotnet
#$resourceURI = "https://vault.azure.net"
$resourceURI = 'https://graph.microsoft.com'
$clientId = '<User MSI Client Id>'
$ApiVersion = '2019-08-01'

$tokenAuthURI = $env:IDENTITY_ENDPOINT + "?api-version=$ApiVersion&client_id=$clientId&resource=$resourceURI"
$Headers = @{
    'Metadata'          = "true"
    'X-IDENTITY-HEADER' = $($env:IDENTITY_HEADER)
}
$tokenResponse = Invoke-RestMethod -Method Get -Headers $Headers -Uri $tokenAuthURI

#$AccessToken = "Bearer " + $tokenResponse.Access_Token
$Headers = @{
    'Authorization' = $($tokenResponse.Access_Token)
    "Content-Type"  = 'application/json'
}

#Dummy URL for testing need read access to directory
$GraphURI = 'https://graph.microsoft.com/v1.0/users/e1c84191-e794-5894-8dce-4864gf85'
Invoke-RestMethod -uri $GraphURI -Method Get -Headers $Headers