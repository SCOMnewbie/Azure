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
function Get-KeyvaultSecretValue {
    [CmdletBinding()]
    param(
        [parameter(Mandatory)]
        [string]$KeyVaultName,
        [parameter(Mandatory)]
        [string]$SecretName,
        [parameter(Mandatory)]
        [string]$AccessToken,
        [string]$KVapiversion = "7.1"
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