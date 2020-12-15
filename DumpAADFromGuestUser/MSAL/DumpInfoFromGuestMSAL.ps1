#Requires –Modules MSAL.PS
[cmdletbinding()]
param(
    [bool]$DevideCode,
    [string]$UPN,
    [ValidateSet('me', 'memberof', 'directReports', 'manager')]
    [string]$Route
)

$ClientId = "1950a258-227b-4e31-a9cf-717495945fc2" 
$TenantId = "<your TenantId>"
$RedirectUri = "http://localhost"

try {
    if ($DevideCode) {
        $Creds = Get-MsalToken -ClientId $ClientId -TenantId $TenantId -RedirectUri $RedirectUri -DeviceCode -ErrorAction stop
    }
    else {
        #Should generate an error id expired, refresh instead
        $Creds = Get-MsalToken -ClientId $ClientId -TenantId $TenantId -RedirectUri $RedirectUri -ErrorAction stop
    }
}
catch {
    #refresh
    $Creds = Get-MsalToken -ClientId $clientID -TenantId $tenantId -RedirectUri $RedirectUri -Silent
}

$token = $creds.AccessToken

$headers = @{
    "Authorization" = ("Bearer {0}" -f $token);
    "Content-Type"  = "application/json";
}

if ($route -eq "me") {
    $uri = "https://graph.microsoft.com/v1.0/me"
    $data = Invoke-RestMethod -Uri $uri -Headers $headers
}
else {
    $Uri = "https://graph.microsoft.com/v1.0/users/{0}/{1}" -f $UPN, $route
    $data = Invoke-RestMethod -Uri $uri -Headers $headers
}

return $data