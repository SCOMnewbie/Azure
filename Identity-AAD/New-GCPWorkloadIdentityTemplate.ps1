function New-GCPWorkloadIdentityTemplate {
    <#
    .SYNOPSIS
    This function will create 2 files used to connect with workload identity (identity federation) to gcp using the gcloud cli. This command should work on both Windows and Linux.
    .DESCRIPTION
    https://cloud.google.com/iam/docs/workload-identity-federation-with-other-clouds#create_a_credential_configuration
    This function will bootstrap 2 files that you can use to connect to gcp.
    .PARAMETER FolderPath
    Specify the folder where the files will be generated.
    .PARAMETER ProjectNumber
    Specify the projectNumber where your workload identity pool is created.
    .PARAMETER ServiceAccountEmail
    Specify the email of your service account.
    .PARAMETER WorkloadIdentityPoolName
    Specify the Workload Identity pool you'r trying to connect.
    .PARAMETER ProviderName
    Specify the Providername within the Workload Identoty pool you're trying to connect
    .PARAMETER ServiceAccountEmail
    Specify the email of your service account.
    .PARAMETER AccessToken
    Specify the AccessToken for the call.
    .EXAMPLE
    $HashArguments = @{
    ProjectNumber = "12345678"
    WorkloadIdentityPoolName = 'mywip'
    ProviderName = 'myprovider'
    ServiceAccountEmail = "<myserviceccount>@<my project name>.iam.gserviceaccount.com"
    AccessToken = "eyJ0eXAiOiJKV1QiLCJhbGci..." #In this case Azure AD token
    }
    New-GCPWorkloadIdentityTemplate @HashArguments
    gcloud auth login --cred-file="gcpconfig.json" -q
    gcloud projects list --format=json # should work
    Will generate 2 files in the current directory to authenticate to gcloud cli ad then list projects
    .NOTES
    VERSION HISTORY
    1.0 | 2023/02/25 | Francois LEON
        initial version
    POSSIBLE IMPROVEMENT
        -
    #>
    [CmdletBinding()]
    param(
        [ValidateScript({
                if (Test-Path $_) { $true }
                else { throw "Path $_ is not valid" }
            })]
        [String]$FolderPath,
        [parameter(Mandatory)]
        [string]$ProjectNumber,
        [parameter(Mandatory)]
        [string]$WorkloadIdentityPoolName,
        [parameter(Mandatory)]
        [string]$ProviderName,
        [parameter(Mandatory)]
        [ValidatePattern('^.*\.iam\.gserviceaccount\.com$')]
        [string]$ServiceAccountEmail,
        [parameter(Mandatory)]
        [string]$AccessToken
    )
    
    #Ordered otherwise the gcloud cli become crazy ...
    $ConfigFile = [ordered]@{
        type                              = 'external_account'
        audience                          = $('//iam.googleapis.com/projects/{0}/locations/global/workloadIdentityPools/{1}/providers/{2}' -f $ProjectNumber,$ProviderName,$WorkloadIdentityPoolName)
        subject_token_type                = 'urn:ietf:params:oauth:token-type:jwt'
        token_url                         = 'https://sts.googleapis.com/v1/token'
        service_account_impersonation_url = $('https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/{0}:generateAccessToken' -f $ServiceAccountEmail)
        credential_source                 = @{
            file   = 'gcpAccessToken.json'
            format = @{
                type                     = 'json'
                subject_token_field_name = 'access_token'
            }
        }
    }

    $GCPAccessTokenFile = @{
        'access_token' = $AccessToken
    }
    
    if ($FolderPath) {
        $ConfigFile | ConvertTo-Json -Depth 99 | Out-File -FilePath $(Join-Path -Path $FolderPath 'gcpconfig.json') -Force
        $GCPAccessTokenFile | ConvertTo-Json | Out-File -FilePath $(Join-Path -Path $FolderPath 'gcpAccessToken.json') -Force
    }
    else {
        $ConfigFile | ConvertTo-Json -Depth 99 | Out-File -FilePath $(Join-Path -Path $PWD 'gcpconfig.json') -Force
        $GCPAccessTokenFile | ConvertTo-Json | Out-File -FilePath $(Join-Path -Path $PWD 'gcpAccessToken.json') -Force
    }  
}
