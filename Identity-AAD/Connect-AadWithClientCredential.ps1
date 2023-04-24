Function Get-AadTokenWithClientCredentialChain {
    <#
.SYNOPSIS
    The goal of this function is to generate an Azure AD access token using client credential flow with multiple secrets to simplify credential rotation.

.DESCRIPTION
    This function will store credentials in memory cache (through tokencache environment variable).

.PARAMETER ClientId
    Specify the clientId

.PARAMETER TenantId
    Specify the tenantId

.PARAMETER Scope
    Specify the scope you're trying to access. Make sure your scope is finnishing with /.default

.PARAMETER FirstSecret
    Specify the first secret of your clientId

.PARAMETER SecondSecret
    Specify the second secret of your clientId

.PARAMETER ForceRefresh
    Specify you don't want to use the cache

.EXAMPLE
     Get-AccessTokenWithAzIdentity -Audience Keyvault

.EXAMPLE
     $Splatting = @{
        ClientId = "d6fxxxxx-xxxx-xxxx-xxxx-xxxxfb692fdc"
        TenantId = "9fc48040-xxxx-xxxx-xxxx-ff17cbf04b20"
        Scope = "api://<your api exposed>/.default"
        FirstSecret = "app reg secret 1"
        SecondSecret = "app reg secret 2"
    }

    # [Environment]::SetEnvironmentVariable('tokencache',$null) 
    Get-AadTokenWithClientCredentialChain @Splatting #-ForceRefresh

.OUTPUTS
    String
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [guid]$ClientId,
        [Parameter(Mandatory = $true)]
        [guid]$TenantId,
        [Parameter(Mandatory = $true)]
        [ValidateScript({$_ -like '*/.default'})]
        [string]$Scope,
        [parameter(Mandatory = $true, ParameterSetName = 'Secret')]
        [string]$FirstSecret,
        [parameter(Mandatory = $true, ParameterSetName = 'Secret')]
        [string]$SecondSecret,
        [switch]$ForceRefresh
    )
    
    begin{
        Write-Verbose 'Get-AadTokenWithClientCredentialChain -Begin function'

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
         
            Write-Verbose 'New-ClientCredential - Begin function'
        
            # Force TLS 1.2.
            Write-Verbose 'New-ClientCredential - Force TLS 1.3'
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls13
        
            $headers = @{
                'Content-Type' = 'application/x-www-form-urlencoded'
            }
            
            #Let hit the token endpoint for this second call
            Write-Debug "New-ClientCredential - Contact Url https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
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
    
        function ConvertFrom-Jwt {
            [cmdletbinding()]
            param(
                [Parameter(Mandatory = $true)]
                [string]$Token
            )
    
            # Validate as per https://tools.ietf.org/html/rfc7519
            # Access and ID tokens are fine, Refresh tokens will not work
            $Token = $Token.replace('Bearer ','')
            if (!$Token.Contains('.') -or !$Token.StartsWith('eyJ')) { Write-Error 'Invalid token' -ErrorAction Stop }
    
            # Extract header and payload
            $tokenheader, $tokenPayload, $tokensignature = $Token.Split('.').Replace('-', '+').Replace('_', '/')[0..2]
    
            # Fix padding as needed, keep adding '=' until string length modulus 4 reaches 0
            while ($tokenheader.Length % 4) { Write-Debug 'Invalid length for a Base-64 char array or string, adding ='; $tokenheader += '=' }
            while ($tokenPayload.Length % 4) { Write-Debug 'Invalid length for a Base-64 char array or string, adding ='; $tokenPayload += '=' }
            while ($tokenSignature.Length % 4) { Write-Debug 'Invalid length for a Base-64 char array or string, adding ='; $tokenSignature += '=' }
    
            # Convert header from Base64 encoded string to PSObject all at once
            $header = [System.Text.Encoding]::ASCII.GetString([system.convert]::FromBase64String($tokenheader)) | ConvertFrom-Json
            Write-Debug 'Decoded header:`n$header'
    
            # Convert payload to string array
            $tokenArray = [System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($tokenPayload))
            Write-Debug 'Decoded array in JSON format:`n$tokenArray'
    
            # Convert from JSON to PSObject
            $tokobj = $tokenArray | ConvertFrom-Json
            Write-Debug 'Decoded Payload:'
    
            # Convert Expiry time to PowerShell DateTime
            $orig = (Get-Date -Year 1970 -Month 1 -Day 1 -Hour 0 -Minute 0 -Second 0 -Millisecond 0)
            $timeZone = Get-TimeZone
            $utcTime = $orig.AddSeconds($tokobj.exp)
            $hoursOffset = $timeZone.GetUtcOffset($(Get-Date)).hours #Daylight saving needs to be calculated
            $localTime = $utcTime.AddHours($hoursOffset)     # Return local time,
    
            # Time to Expiry
            $timeToExpiry = ($localTime - (Get-Date))
    
            [pscustomobject]@{
                Tokenheader         = $header
                TokenPayload        = $tokobj
                TokenSignature      = $tokenSignature
                TokenExpiryDateTime = $localTime
                TokentimeToExpiry   = $timeToExpiry
    
            }
        }
    }
    
    process{
        if(-not ($ForceRefresh.IsPresent)){
            if ([Environment]::GetEnvironmentVariable('tokencache')) {
                Write-Verbose 'Get-AadTokenWithClientCredentialChain - Cache found'
                if (($(ConvertFrom-Jwt -Token $([Environment]::GetEnvironmentVariable('tokencache'))).TokentimeToExpiry.TotalMinutes) -gt 5) {
                    Write-Verbose 'Get-AadTokenWithClientCredentialChain - Cache not expired, return it'
                    return [Environment]::GetEnvironmentVariable('tokencache')
                }
                else{
                    Write-Verbose 'Get-AadTokenWithClientCredentialChain - Token expired'
                }
            }
            else{
                Write-Verbose 'Get-AadTokenWithClientCredentialChain - Cache not found'
            }
        }
        
        if($ForceRefresh.IsPresent){
            Write-Verbose 'Get-AadTokenWithClientCredentialChain - Force refresh enabled'
        }
    
        try{
            Write-Verbose 'Get-AadTokenWithClientCredentialChain - Try with first secret'
            $Token = New-ClientCredential -ClientId $ClientId.Guid -TenantId $TenantId.Guid -Scope $Scope -secret $FirstSecret -ErrorAction Stop | % access_token
            Write-Verbose 'Get-AadTokenWithClientCredentialChain - Token received, cache it for next run'
            [Environment]::SetEnvironmentVariable('tokencache',$Token)
            return [Environment]::GetEnvironmentVariable('tokencache')
        }
        catch{
            Write-Verbose 'Get-AadTokenWithClientCredentialChainl - Try with second secret'
            $Token = New-ClientCredential -ClientId $ClientId.Guid -TenantId $TenantId.Guid -Scope $Scope -secret $SecondSecret -ErrorAction Stop | % access_token
            Write-Verbose 'Get-AadTokenWithClientCredentialChain - Token received, cache it for next run'
            [Environment]::SetEnvironmentVariable('tokencache',$Token)
            return [Environment]::GetEnvironmentVariable('tokencache')
        }
    }

    end{
        Write-Verbose 'Get-AadTokenWithClientCredentialChain - End function'
    }
}