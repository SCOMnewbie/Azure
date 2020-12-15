[cmdletbinding()]
param(
    [string]$UPN,
    [ValidateSet('me', 'memberof', 'directReports', 'manager')]
    [string]$Route
)

$ErrorActionPreference = 'Stop'

Add-Type -Path '.\Microsoft.IdentityModel.Clients.ActiveDirectory.dll'
Add-Type -Path '.\Microsoft.IdentityModel.Clients.ActiveDirectory.WindowsForms.dll'

#Known ID for Powershell shell
$clientId = "1950a258-227b-4e31-a9cf-717495945fc2"
#TenantID. Easy to find, for example with > https://login.windows.net/<your domain>.onmicrosoft.com/.well-known/openid-configuration
$tenantId = "<You're TenantId>"

$resourceId = 'https://graph.microsoft.com'
$login = "https://login.microsoftonline.com"

#This how you can request a token with an interractive form (ADAL) 
$promptBehavior = [Microsoft.IdentityModel.Clients.ActiveDirectory.PromptBehavior]::Auto
$authContext = New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext ("{0}/{1}" -f $login, $tenantId)
#Because why not
$redirectUri = New-Object system.uri("http://localhost")

#Here you should have your tokens (access + Id)
$authenticationResult = $authContext.AcquireToken($resourceId, $clientID, $redirectUri, $promptBehavior)

$token = $authenticationResult.AccessToken

#Create headers for future requests
$headers = @{
    "Authorization" = ("Bearer {0}" -f $token);
    "Content-Type"  = "application/json";
}

if ($route -eq "me") {
    $uri = $uri = "https://graph.microsoft.com/v1.0/me"
    $data = Invoke-RestMethod -Uri $uri -Headers $headers
}
else {
    $Uri = "https://graph.microsoft.com/v1.0/users/{0}/{1}" -f $UPN, $route
    $data = Invoke-RestMethod -Uri $uri -Headers $headers
}

return $data
