function New-ClientCredential {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true)]
        [guid]$ClientId,
        [Parameter(Mandatory = $true)]
        [guid]$TenantId,
        [Parameter(Mandatory = $true)]
        [string]$Scope,
        [parameter(Mandatory = $true, ParameterSetName = 'Secret')]
        [string]$Secret
    )
 
    Write-Verbose 'New-ClientCredential -Begin function'

    # Force TLS 1.2.
    Write-Verbose 'New-ClientCredential - Force TLS 1.2'
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $headers = @{
        'Content-Type' = 'application/x-www-form-urlencoded'
    }
    

    #Let hit the token endpoint for this second call
    Write-Verbose "New-ClientCredential - Contact Url https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
    $Params = @{
        Headers = $headers
        uri     = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
        Body    = $null
        method  = 'Post'
    }

    $BodyPayload = @{
        grant_type    = 'client_credentials'
        client_id     = $Clientid
        scope         = $Scope
        client_secret = $Secret
    }
    
    $Params.Body = $BodyPayload

    Write-Verbose 'New-ClientCredential - End function'

    Invoke-RestMethod @Params
}