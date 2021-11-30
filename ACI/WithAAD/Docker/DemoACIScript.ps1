# This script is just a demo where we will explain variables.

# Load modules
import-module MSAL.PS
import-module '.\loadme.psd1'

# Create a bunch of new variables with all environment variable wich start with a specific prefix. Bydefault ___ (3 underscores)
New-VariableFactoryFromEnvVariable

#Fetch a token with the user MSI
Write-host "Fetch an access token to access KeyVault resource with ACI user managed identity (application context)"
irm -Uri 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net' -Method get -Headers @{Metadata = 'true'} | select -ExpandProperty Access_token | Set-Variable kvToken
$plainPwd = Get-KeyvaultSecretValue -KeyVaultName $___KeyvaultName -SecretName $___secretToFetch -AccessToken $kvtoken

$plainPwd

#Re-hydrate our PSCredential. This will represent the service account used to play with graph API
Write-host "Re-hydrate service account credentials"
$password = ConvertTo-SecureString -String $plainPwd -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential($___USERNAME,$password)

# Now we generate a token for our service account in charge of "doing things"
# We can't have interraction here, ROPC flow is the only way.
Write-host "Generate an access token to access graph API .default scope (user context with delegated permission)"
if($___tenantid){
    $Token = Get-MsalToken -ClientId $___appId -TenantId $___tenantid -Scopes 'https://graph.microsoft.com/.default' -RedirectUri 'http://localhost' -UserCredential $cred | select -ExpandProperty AccessToken
}
else{
    # Use common tenantId instead (Multi tenants app)
    $Token = Get-MsalToken -ClientId $___appId -Scopes 'https://graph.microsoft.com/.default' -RedirectUri 'http://localhost' -UserCredential $cred | select -ExpandProperty AccessToken
}

$Token

$Headers = @{
    'Authorization' = "Bearer $Token"
    'Content-Type'  = 'application/json'
}

Write-host "Let's call the me route to get the current context"
# Here you can imagine all your script actions
Get-GraphAPIMe -Headers $headers

#Once the job done, this is where we will callback our orchestration function but this time we can't just use the URL, even with the code
# We will use OAUTH2 instead to generate a access token only for our service account.
# Be aware that conditional access can hit you. Make sure you take this into account.

if($___tenantid){
    $token = Get-MsalToken -ClientId $___azFuncFrontEndAppid -RedirectUri $___azFuncFrontEndRedirectURI -TenantId $___tenantid -Scopes $___azFuncBackendExposedScope  -UserCredential $creds #Same creds from KV extracted earlier ROPC
}
else{
    # Use common tenantId instead (Multi tenants app)
    $token = Get-MsalToken -ClientId $___azFuncFrontEndAppid -RedirectUri $___azFuncFrontEndRedirectURI -Scopes $___azFuncBackendExposedScope  -UserCredential $creds #Same creds from KV extracted earlier ROPC
}

$Headers = @{
    'Authorization' = $("Bearer " + $token.AccessToken)
    'Content-Type'  = 'application/json'
}

$token

Write-host "Let's now create a an hashtable from prefixes variables"
# Let's circle back where we grab all variables with a specific prefix (by default ___) and convert it into an hashtable
$Data = New-HashtableFactory

# Execute the function to send back the state to the orchestrator but this time with autorization header.
Invoke-RestMethod -Method Post -Uri $___NextStageFunctionUrl -Body $(ConvertTo-Json $data -Depth 99) -Headers $Headers
