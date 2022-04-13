# Load assembly
[System.Collections.Generic.List[string]] $RequiredAssemblies = New-Object System.Collections.Generic.List[string]
(gci -path $psscriptroot -File '*.dll' | % FullName).foreach({$RequiredAssemblies.Add($_)})
try {
    Add-Type -Path $RequiredAssemblies | Out-Null
}
catch { throw }

# ClientSecret Auth (non interractive flow)
$ClientId = "c5883c0b-c0bb-46a7-8ff8-c2a3bc5776ff"
$TenantId = "e192cada-a04d-4cfc-8b90-d14338b2c7ec"
$ClientSecret = "hgk7Q~U....j.6x4zeK"
[string[]] $Scopes = 'api://c97157...c-1edfc125e262/.default'

# Build de confidential app with client_credential flow (ClientId/ClientSecret/TenantId)
$app =  [Microsoft.Identity.Client.ConfidentialClientApplicationBuilder]::Create($ClientId).WithClientSecret($ClientSecret).WithTenantId($TenantId).Build()
# The library use an in memory cache (recommended to damon app)
$ReturnToken=$app.AcquireTokenForClient($Scopes).ExecuteAsync().Result
#$ReturnToken=$app.AcquireTokenForClient($Scopes).WithForceRefresh($true).ExecuteAsync().Result