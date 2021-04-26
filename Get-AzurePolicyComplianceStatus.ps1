
function Get-AzurePolicyComplianceStatus {
    <#
    .SYNOPSIS
    The goal of this function is to quickly give you compliance status of a specific policy assign to multiple of subscriptions within a management group.
    .DESCRIPTION
    When you have to deal with a lot of subscriptions, using the set-azcontext is really inefficient. Using this method, you can get the result quickly in one API call.
    .PARAMETER TenantId
    Specify the TenanId you want to target.
    .PARAMETER PolicyDefinitionName
    Specify the PolicyDefinitionName you want to get the status of.
    .PARAMETER AccessToken
    Specify the AccessToken used to execute the query.

    .EXAMPLE
    PS> $AccessToken = az account get-access-token --resource "https://management.azure.com"  | ConvertFrom-Json | select -ExpandProperty accessToken
    PS> $Compliancestatus = Get-AzurePolicyComplianceStatus -AccessToken $AccessToken -PolicyDefinitionName '670a3e57-dcc3-6a8a-813f-e2669ee2f23e' -TenantId 'MyTenant'
    PS> $Compliancestatus | select subscriptionId, managementGroupIds, complianceState, iscompliant

    will tell you quickly the compliance status of a specific policy definition assignment within a MG

    .NOTES
    VERSION HISTORY
    1.0 | 2021/04/21 | Francois LEON
        initial version
    POSSIBLE IMPROVEMENT
        -
    .LINK
    https://docs.microsoft.com/en-us/rest/api/policy/policystates/listqueryresultsformanagementgroup
    #>
    [CmdletBinding()]
    param (
        #[parameter(Mandatory)]
        [string] $TenantId,
        [string] $PolicyDefinitionName,
        [string] $AccessToken
    )

    #$AccessToken = az account get-access-token --resource "https://management.azure.com"  | ConvertFrom-Json | select -ExpandProperty accessToken
    if ($AccessToken -notmatch '^Bearer\s*') {
        #We add the Bearer if it has been forgotten
        $AccessToken = "Bearer $AccessToken"
    }

    $Headers = @{
        'Authorization' = $AccessToken
        "Content-Type"  = 'application/json'
    }

    $Params = @{
        Headers     = $Headers
        uri         = "https://management.azure.com/providers/Microsoft.Management/managementGroups/$TenantId/providers/Microsoft.PolicyInsights/policyStates/latest/queryResults?api-version=2019-10-01&`$filter=policyDefinitionName eq `'$PolicyDefinitionName`'"
        Body        = $null
        method      = 'POST'
        ErrorAction = 'Stop'
    }

    $QueryResults = @()
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

    $QueryResults    
}