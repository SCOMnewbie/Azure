<#
.SYNOPSIS
This function helps you to get a required code to complete an authorization code flow.
.DESCRIPTION
https://docs.microsoft.com/fr-fr/azure/active-directory/develop/v2-oauth2-auth-code-flow
WARNING: The Authorization Code flow is a MSAL confidential flow. In other words, Client secret will be required and this script should be used for a backend app where secret can be secured. 
By default Powershell is not capable of managing a webview, which is a mandatory piece in this flow, which is why we have to play with System.Windows.Forms. The goal of this webview is to listen 
what Azure AD will reply to you (the code) once the authentication is done by the Identity Provider (login, password, MFA, ...).
Why this script? Because in conjunction with MSAL.PS, we will be able to receive both an Id and and Access token for the requested scopes. The Id token help you to manage authorization later in your app.
IMPORTANT: This script is working with V2 Microsoft Identity endpoint only (single tenant, Multiple tenants, Work or school and Microsoft Account).
.PARAMETER Clientid
Specify the Clientid of your confidential app.
.PARAMETER RedirectUri
Specify the RedirectUri of your backend application.
.PARAMETER Scope
Specify the Scope of your application. Default values are optional, but it's a good starting point for later usage.
.PARAMETER TenantId
Specify the TenantId
.PARAMETER Prompt
Specify the Prompt behavior
.EXAMPLE
$Splatting = @{
    Clientid = "fca4cdf3-031d-..."
    RedirectUri = "https://localhost:44321/"
    TenantId = "e114cada-..."
    }
$codeInfo = Get-AuthorizationCodeFlowSingleOrg @Splatting
$Clientsecret = Read-Host -AsSecureString
Get-MsalToken @Splatting -AuthorizationCode $codeInfo.Code -ClientSecret $Clientsecret

Will give you both an Id and an access token for the requested scopes.

.NOTES
VERSION HISTORY
1.0 | 2020/10/29 | Francois LEON
    initial version
POSSIBLE IMPROVEMENT
    Verify with common/organizations endpoint instead of single tenantId
#>
function Get-AuthorizationCodeFlowSingleOrg{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory)]  
        [guid]$Clientid,
        [Parameter(Mandatory)]
        [string]$RedirectUri,
        [string]$Scope = "openid offline_access user.read",
        [Parameter(Mandatory)]
        [guid]$TenantId,
        [Parameter()]  
        [ValidateSet('login','none','consent','select_account')]
        [string]$Prompt = "select_account"
    )
    
    # Force TLS 1.2.
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Add-Type -AssemblyName System.Windows.Forms
    
    $RedirectUriEncoded =  [System.Web.HttpUtility]::UrlEncode($RedirectUri)
    $ScopeEncoded = [System.Web.HttpUtility]::UrlEncode($Scope)
        
    $Url = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/authorize?response_type=code&client_id=$ClientID&redirect_uri=$RedirectUriEncoded&scope=$ScopeEncoded&prompt=$Prompt"
    
    $Form = New-Object -TypeName System.Windows.Forms.Form -Property @{Width=440;Height=640}
    $Web  = New-Object -TypeName System.Windows.Forms.WebBrowser -Property @{Width=420;Height=600;Url=($url -f ($Scope -join "%20")) }
    $DocComp  = {
        $Global:uri = $web.Url.AbsoluteUri        
        if ($Global:uri -match "error=[^&]*|code=[^&]*") {$form.Close() }
    }
    $web.ScriptErrorsSuppressed = $true
    $web.Add_DocumentCompleted($DocComp)
    $form.Controls.Add($web)
    $form.Add_Shown({$form.Activate()})
    $form.ShowDialog() | Out-Null
    
    $queryOutput = [System.Web.HttpUtility]::ParseQueryString($web.Url.Query)
    
    [PSCustomObject]@{
        Code = $queryOutput['code']
        session_state = $queryOutput['session_state']
    }
}
