function Remove-AADGroupMember {
    <#
    .SYNOPSIS
    This function will remove user through their objectId from an AAD group.
    .DESCRIPTION
    This function will remove user through their objectId from an AAD group.
    The current API does not allow to pass multiple users to be removed in one call.
    This function will run using a deleguated API permission under a specific user service account.
    .PARAMETER UserId
    Specify the objectId of the user(s) you want to add.
    .PARAMETER GroupId
    Specify the group's objectId you want to target.
    .EXAMPLE

    Remove-AADGroupMember -UserId "e6f849d5-fb9a-4988-c3a0-b6cca90fc468" -groupid "55eb8a9a-e964-4781-9c98-56dd3393d5f4"

    Will assign a user with the userId "e6f849d5-fb9a-4988-c3a0-b6cca90fc468" from the group with the Id "55eb8a9a-e964-4781-9c98-56dd3393d5f4"

    .NOTES
    VERSION HISTORY
    1.0 | 2020/12/02 | Francois LEON
        initial version
    POSSIBLE IMPROVEMENT
        - Add more error control on users
    .LINK
    https://docs.microsoft.com/en-us/graph/api/group-delete-members
    #>
    [CmdletBinding()]
    param(
        [parameter(Mandatory)]
        [guid]
        $UserId,
        [parameter(Mandatory)]
        [guid]
        $GroupId,
        $Headers
    )
    begin {
        $ErrorActionPreference = 'Silentlycontinue'
    }
    process {
        try {
            $Params = @{
                Headers     = $Headers
                uri         = "https://graph.microsoft.com/V1.0/groups/$GroupId/members/$UserId/`$ref"
                Body        = $null
                method      = 'Delete'
                ErrorAction = 'Stop'
            }

            $response = (Invoke-RestMethod @Params).value
            return $response
        }
        catch {
            $_.Exception.Message
        }
    }
}
function Add-AADGroupMember {
    <#
    .SYNOPSIS
    This function will add user(s) through their objectId to a AAD group.
    .DESCRIPTION
    This function can add add an array of users. The current API allow to pass until 20 Ids per call, this function take care of the split. In toher words, you can provide more
    than 20 account per function call. This function will run using a deleguated API permission under a specific user service account.
    .PARAMETER UserId
    Specify the objectId of the user(s) you want to add.
    .PARAMETER GroupId
    Specify the group's objectId you want to target.
    .EXAMPLE

    $array = @("595f62b5-01d5-4ea1-bb8f-0537a955c7ca",
    "e6f909d5-fb9a-4988-c3a0-b6cca90fc468",
    "22e00212-cfe3-4ac6-a2b1-d47e0da407c5"
    )

    Add-AADGroupMember -UserId $array -groupid "55eb8a9a-e9fc-4781-9c98-56dd3393d5f4"

    Will assign 3 users to the group

    .NOTES
    VERSION HISTORY
    1.0 | 2020/12/02 | Francois LEON
        initial version
    POSSIBLE IMPROVEMENT
        - Add more error control on users
    .LINK
    https://docs.microsoft.com/en-us/graph/api/group-post-members
    #>
    [CmdletBinding()]
    param(
        [parameter(Mandatory)]
        [guid[]]
        $UserId,
        [parameter(Mandatory)]
        [guid]
        $GroupId,
        $Headers
    )
    begin {
        $ErrorActionPreference = 'Silentlycontinue'
    }
    process {

        $Params = @{
            ErrorAction = 'Stop'
            Headers     = $null
            uri         = $null
            Body        = $null
            Method      = $null
        }

        #Single call is different than multiple calls
        if ($UserId.Count -eq 1) {
            $Params.Headers = $Headers
            $MemberGraphURLs = "https://graph.microsoft.com/v1.0/directoryObjects/$UserId"

            $Params.Method = 'POST'
            $Params.uri = "https://graph.microsoft.com/v1.0/groups/$GroupId/members/`$ref"
            $BodyPayload = @{
                '@odata.id' = $MemberGraphURLs
            }
            $Params.Body = $BodyPayload | ConvertTo-Json
            try {
                Invoke-RestMethod @Params
            }
            catch {
                $_.Exception
            }
        }
        else {
            #We can't add more than 20 items per API call
            $UserId | Split-Array -Size 20 | ForEach-Object {
                $Params.Headers = $Headers
                $MemberGraphURLs = @()
                Foreach ($Id in $_) {
                    $MemberGraphURLs += "https://graph.microsoft.com/v1.0/directoryObjects/$id"
                }

                $Params.uri = "https://graph.microsoft.com/v1.0/groups/$GroupId"
                $Params.Method = 'PATCH'
                $BodyPayload = @{
                    'members@odata.bind' = $MemberGraphURLs
                }

                $Params.Body = $BodyPayload | ConvertTo-Json
                try {
                    Invoke-RestMethod @Params
                    #Let's wait few seconds to give AAD a breath
                    if ($UserId.count -gt 20) {
                        Start-Sleep -Seconds 4
                    }
                }
                catch {
                    $_.Exception
                }
            }
        }
    }
}
function Get-AADAppRoleAssignedTo {
    <#
    .SYNOPSIS
    This function will list all assignments to a specific  service principal (Enterprise App)
    .DESCRIPTION
    Important: The is a little bit of harcoded value because this module has been designed for a specific purpose but this function is easily extendable to generic usage.
    This function will list all assignments to a specific  service principal (Enterprise App). The function will run using a deleguated API permission under a specific user service account.
    .PARAMETER ServicePrincipalObjectId
    Specify the objectId of the service principal whou want to report.
    .EXAMPLE

    Get-AADAppRoleAssignedTo

    Will give you the assignemt(s) of the enterprise App.

    .NOTES
    VERSION HISTORY
    1.0 | 2020/12/02 | Francois LEON
        initial version
    POSSIBLE IMPROVEMENT
        -
    .LINK
    https://docs.microsoft.com/en-us/graph/api/serviceprincipal-list-approleassignedto
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory)]
        $ServicePrincipalObjectId,
        $Headers
    )

    $ErrorActionPreference = 'Silentlycontinue'

    $Params = @{
        Headers = $Headers
        uri     = "https://graph.microsoft.com/v1.0/servicePrincipals/$ServicePrincipalObjectId/appRoleAssignedTo?`$top=999&`$select=principalId"
        #uri     = "https://graph.microsoft.com/v1.0/servicePrincipals/$ServicePrincipalObjectId/appRoleAssignedTo"
        Body    = $null
        method  = 'Get'
    }

    $QueryResults = @()
    # Invoke REST method and fetch data until there are no pages left.
    do {
        $Results = Invoke-RestMethod @Params
        if ($Results.value) {
            $QueryResults += $Results.value
        }
        else {
            $QueryResults += $Results
        }
        $Params.uri = $Results.'@odata.nextlink'
    } until (!($Params.uri))

    # Return the result.
    $QueryResults
}
function Get-AADGroupMember {
    <#
    .SYNOPSIS
    This function will return all members of a group.
    .DESCRIPTION
    This function will return all members of a group.
    Bydefault the graph API is not able to give you more than 100 results per call. This function will use the @odata.nextlink property to return more than 100 members.
    The function will run using a deleguated API permission under a specific user service account.
    .PARAMETER GroupId
    Specify the objectId of a group.
    .EXAMPLE

    Get-AADGroupMember -GroupId "55eb8a9a-b4fc-4781-9c98-56df4393d5f4"

    Will return all members of a group.
    .NOTES
    VERSION HISTORY
    1.0 | 2020/12/02 | Francois LEON
        initial version
    POSSIBLE IMPROVEMENT
        -
    .LINK
    https://docs.microsoft.com/en-us/graph/api/group-list-members
    #>
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param(
        [parameter(Mandatory)]
        [guid]
        $GroupId,
        $Headers
    )
    begin {
        $ErrorActionPreference = 'Silentlycontinue'
    }
    process {

        $Params = @{
            Headers     = $Headers
            uri         = "https://graph.microsoft.com/v1.0/groups/$GroupId/members?`$top=99"
            Body        = $null
            method      = 'Get'
            ErrorAction = 'Stop'
        }

        $QueryResults = @()
        # Invoke REST method and fetch data until there are no pages left.
        do {
            $Results = Invoke-RestMethod @Params
            if ($Results.value) {
                $QueryResults += $Results.value
            }
            else {
                $QueryResults += $Results
            }
            $Params.uri = $Results.'@odata.nextlink'
        } until (!($Params.uri))

        # Return the result.
        $QueryResults
    }
}

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