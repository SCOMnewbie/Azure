Function Get-GCPAccessTokenFromAAD {
    <#
.SYNOPSIS
    This function will generate a Google Cloud Platform access token that represent service account identity to access GCP resources from an Azure Active Directory JWT.

.DESCRIPTION
   This function will generate a Google Cloud Platform access token that represent service account identity to access GCP resources from an Azure Active Directory JWT.

.PARAMETER WorkloadIdentityPoolProjectNumber
    Specify the project number of your GCP project which host the workload identoty pool resource. This is not the projectId!

.PARAMETER WorkloadIdentityPoolName
    Specify the workload identity pool name

.PARAMETER WorkloadIdentityPoolProviderName
    Specify the workload identity pool provider name

.PARAMETER ServiceAccountEmailAddress
    Specify the GCP service account you want to "impersonate"

.PARAMETER AADAccessToken
    Specify the Azure AD access token generated for this audience

.EXAMPLE
    # Gener
     $AADToken = Get-AccessTokenWithAzIdentity -Audience Custom -CustomScope "api://b86d723f-cbfe-42e4-a11b-8efb388befba"
     $splat = @{
        WorkloadIdentityPoolProjectNumber = "1002948414286"
        WorkloadIdentityPoolName = "aad-pool"
        WorkloadIdentityPoolProviderName = "aad-pool"
        ServiceAccountEmailAddress = "<myserviceaccount>@<myprojectid>.iam.gserviceaccount.com"
        AADAccessToken = $AADToken
     }
     Get-GCPAccessTokenFromAAD @splat
#>
    [CmdletBinding()]
    param (
        [parameter(Mandatory)]
        [string] $WorkloadIdentityPoolProjectNumber, #Not projectId ... yeah I know...
        [parameter(Mandatory)]
        [string] $WorkloadIdentityPoolName,
        [parameter(Mandatory)]
        [string] $WorkloadIdentityPoolProviderName,
        [parameter(Mandatory)]
        [string] $ServiceAccountEmailAddress,
        [parameter(Mandatory)]
        [string] $AADAccessToken
    )

    # Generate a token from the sts enpoint first
    $Body = [ordered]@{}
    $Body.Add('audience',"//iam.googleapis.com/projects/$($WorkloadIdentityPoolProjectNumber)/locations/global/workloadIdentityPools/$($WorkloadIdentityPoolName)/providers/$($WorkloadIdentityPoolProviderName)")
    $Body.Add('grantType','urn:ietf:params:oauth:grant-type:token-exchange')
    $Body.Add('requestedTokenType','urn:ietf:params:oauth:token-type:access_token')
    $Body.Add('scope','https://www.googleapis.com/auth/cloud-platform')
    $Body.Add('subjectTokenType','urn:ietf:params:oauth:token-type:jwt')
    $Body.Add('subjectToken',$AADAccessToken)

    $uri = "https://sts.googleapis.com/v1/token"
    $StsToken = Invoke-RestMethod -Method POST -Uri $uri -ContentType "application/json" -Body $($Body | ConvertTo-Json) -erroraction Stop | % access_token

    # Generate token as a GCP service account

    $uri = "https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/$($ServiceAccountEmailAddress):generateAccessToken"
    $headers = @{ "Authorization" = "Bearer $StsToken" }
    $body = @{'scope' = @("https://www.googleapis.com/auth/cloud-platform") } | ConvertTo-Json

    Invoke-RestMethod -Uri $uri -Headers $headers -Body $Body -ContentType "application/json" -Method POST | % accessToken
}