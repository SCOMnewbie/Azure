
function Split-Array {
    param($inArray,[int]$parts,[int]$size)
 
    if ($parts) {
        $PartSize = [Math]::Ceiling($inArray.count / $parts)
    }
    if ($size) {
        $PartSize = $size
        $parts = [Math]::Ceiling($inArray.count / $size)
    }

    $outArray = @()
    for ($i = 1; $i -le $parts; $i++) {
        $start = (($i - 1) * $PartSize)
        $end = (($i) * $PartSize) - 1
        if ($end -ge $inArray.count) { $end = $inArray.count }
        $outArray += ,@($inArray[$start..$end])
    }
    return ,$outArray

}
function Get-KeyvaultSecretValue {
    <#
    .SYNOPSIS
    This function will return the value of secret stored in a Keyvault from an access token.
    .DESCRIPTION
    https://docs.microsoft.com/fr-fr/rest/api/keyvault/getsecret/getsecret
    This function will return the value of secret stored in a Keyvault from an access token.
    .PARAMETER KeyVaultName
    Specify the name of your keyvault which is globally unique.
    .PARAMETER SecretName
    Specify the secret you try to extract.
    .PARAMETER KVapiversion
    Specify the version of the Keyvault API.
    .PARAMETER AccessToken
    Specify the AccessToken for the call.
    .EXAMPLE
    #Generate and Access token for the Keyvault audience first. For example the ARC agent:
    $KVToken = New-ARCAccessTokenMSI -Audience Keyvault
    Get-KeyvaultSecretValue -KeyVaultName <MyKeyvaultName> -SecretName <MySecretName> -AccessToken $KVToken
    Will return the value of the secret name MysecretName.
    .NOTES
    VERSION HISTORY
    1.0 | 2021/02/17 | Francois LEON
        initial version
    POSSIBLE IMPROVEMENT
        -
    #>
    [CmdletBinding()]
    param(
        [parameter(Mandatory)]
        [string]$KeyVaultName,
        [parameter(Mandatory)]
        [string]$SecretName,
        [parameter(Mandatory)]
        [string]$AccessToken,
        [string]$KVapiversion = '7.1'
    )

    # Force TLS 1.2.
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $headers = @{
        'Authorization' = "Bearer $AccessToken"
    }

    $uri = "https://$KeyVaultName.vault.azure.net/secrets/$SecretName`?api-version=$KVapiversion"

    $Params = @{
        Headers = $headers
        uri     = $uri
        Body    = $null
        method  = 'Get'
    }

    $response = Invoke-RestMethod @Params
    $response.value
}

function Remove-ContainerGroup {
    [CmdletBinding()]
    param(
        [parameter(Mandatory)]
        [string]$containerGroupName,
        [parameter(Mandatory)]
        [string]$resourceGroupName,
        [parameter(Mandatory)]
        [string]$subscriptionId,
        [parameter(Mandatory)]
        [string]$AccessToken,
        [string]$apiversion = '2019-12-01'
    )

    # Force TLS 1.2.
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $headers = @{
        'Authorization' = "Bearer $AccessToken"
    }

    $uri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.ContainerInstance/containerGroups/$containerGroupName`?api-version=$apiversion"
    
    $Params = @{
        Headers = $headers
        uri     = $uri
        Body    = $null
        method  = 'Delete'
    }

    Invoke-RestMethod @Params
}

function New-VariableFactory {
    [CmdletBinding()]
    param(
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [hashtable]$data
    )
    # The goal of this function is to take an hashtable as parameter and convert it into several variables that I will call in various flows later
    process {
        foreach ($item in $data.GetEnumerator()) {
            try {
                Write-Verbose "New on key $($item.Key) with the value $($item.Value)"
                New-Variable -Name $($item.Key) -Value $($item.Value) -Scope 2 -ea stop      
            }
            catch {
                Write-Verbose "Set on key $($item.Key) with the value $($item.Value)"
                Set-Variable -Name $($item.Key) -Value $($item.Value) -Scope 2
            }
        }
    }
}

function New-HashtableFactory {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [ValidateNotNullOrEmpty()]
        [string]$prefix = '___'
    )
    # The goal of this function is to generate an hashtable with all "suffixed" variables
    begin {
        $output = @{}
        $pattern = "$prefix{0}" -f '*'

    }
    process {
        Get-Variable -Name $pattern | ForEach-Object { $output.add($_.Name,$_.value) }
    }
    end {
        return $output
    }
}
function New-VariableFactoryFromEnvVariable {
    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [string]$prefix = '___'
    )
    # The goal of this function is to take an hashtable as parameter and convert it into several variables that I will call in various flows later
    begin {
        $pattern = "$prefix{0}" -f '*'
    }
    process {
        $envVariables = Get-ChildItem env:
        $envVariables.Key | Where-Object { $_ -like $pattern } | ForEach-Object { New-Variable -Name $_ -Value $($envVariables | Where-Object key -EQ $_ | Select-Object -ExpandProperty value) -Scope 2 }
    }
}

function Get-ACRCredential {
    [CmdletBinding()]
    param(
        [parameter(Mandatory)]
        [string]$registryName,
        [parameter(Mandatory)]
        [string]$resourceGroupName,
        [parameter(Mandatory)]
        [string]$subscriptionId,
        [parameter(Mandatory)]
        [string]$AccessToken,
        [string]$apiversion = '2019-05-01'
    )

    # Force TLS 1.2.
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $headers = @{
        'Authorization' = "Bearer $AccessToken"
        'Content'         = 'application/json'
    }

    $uri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.ContainerRegistry/registries/$registryName/listCredentials?api-version=$apiversion"

    $Params = @{
        Headers = $headers
        uri     = $uri
        Body    = $null
        method  = 'Post'
    }

    Invoke-RestMethod @Params
}

function New-HashtableFactory {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [ValidateNotNullOrEmpty()]
        [string]$prefix = '___'
    )
    # The goal of this function is to generate an hashtable with all "suffixed" variables
    begin {
        $output = @{}
        $pattern = "$prefix{0}" -f '*'

    }
    process {
        Get-Variable -Name $pattern | ForEach-Object { $output.add($_.Name,$_.value) }
    }
    end {
        return $output
    }
}

function New-ACIEnvGenerator {
    [CmdletBinding()]
    [OutputType([array])]
    param(
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSVariable[]]$Variables
    )
    # The goal of this function is to generate an array of hashtable. This is a mandatory format for later usage.
    # How to use it: New-ACIEnvGenerator -Variables $(Get-Variable -Include var1,var2,var3)
    begin {
        $output = @()
    }

    process {
        foreach ($variable in $Variables) {
            $hashtable = @{}
            $hashtable['name'] = $(($variable.Name).tostring().toUpper())
            $hashtable['value'] = $variable.value
            $output += $hashtable
        }
    }

    end {
        return $output
    }
}

function Get-GraphAPIMe {
    #Useful to see who do the request
    [CmdletBinding()]
    param(
        [parameter(Mandatory)]
        $Headers
    )
    begin {
        $ErrorActionPreference = 'Silentlycontinue'
    }
    process {

        $Params = @{
            Headers     = $Headers
            uri         = "https://graph.microsoft.com/v1.0/me"
            Body        = $null
            method      = 'Get'
            ErrorAction = 'Stop'
        }

        Invoke-RestMethod @Params
    }
}

#From https://docs.microsoft.com/en-us/azure/azure-monitor/platform/data-collector-api
# Create the function to create the authorization signature
Function Build-Signature ($customerId, $sharedKey, $date, $contentLength, $method, $contentType, $resource)
{
    $xHeaders = "x-ms-date:" + $date
    $stringToHash = $method + "`n" + $contentLength + "`n" + $contentType + "`n" + $xHeaders + "`n" + $resource

    $bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
    $keyBytes = [Convert]::FromBase64String($sharedKey)

    $sha256 = New-Object System.Security.Cryptography.HMACSHA256
    $sha256.Key = $keyBytes
    $calculatedHash = $sha256.ComputeHash($bytesToHash)
    $encodedHash = [Convert]::ToBase64String($calculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $customerId,$encodedHash
    return $authorization
}


# Create the function to create and post the request
Function Post-LogAnalyticsData($customerId, $sharedKey, $body, $logType)
{
    $method = "POST"
    $contentType = "application/json"
    $resource = "/api/logs"
    $rfc1123date = [DateTime]::UtcNow.ToString("r")
    $contentLength = $body.Length
    $signature = Build-Signature `
        -customerId $customerId `
        -sharedKey $sharedKey `
        -date $rfc1123date `
        -contentLength $contentLength `
        -method $method `
        -contentType $contentType `
        -resource $resource
    $uri = "https://" + $customerId + ".ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01"

    $headers = @{
        "Authorization" = $signature
        "Log-Type" = $logType
        "x-ms-date" = $rfc1123date
        "time-generated-field" = $(Get-Date)
    }

    $response = Invoke-WebRequest -Uri $uri -Method $method -ContentType $contentType -Headers $headers -Body $body -UseBasicParsing
    return $response.StatusCode
}