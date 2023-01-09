<#
.SYNOPSIS
This function helps you to generate an Access Token for various audiences (Keyvault, Resource MAnager, Microsoft Graph, Storage Account) once your machine is enrolled in Azure ARC or not.
.DESCRIPTION
https://docs.microsoft.com/en-us/azure/azure-arc/servers/agent-overview
This function will use the local MSI endpoint generated during the agent installation to create an access token you will be able to use for various scopes. The idea behind this script is
to avoid having to set password/secret in your local dev machine/ pipeline runners to be passwordless from A to Z. 
.PARAMETER Audience
Specify the Audience you want to send the generated ccess Token to.
.PARAMETER FromARCVm
Specify if you run this command from an ARC VM.
.PARAMETER CustomScope
Specify the custom scope.
.EXAMPLE
#Generate an access token for Keyvault from an ARC machine
$KeyvaultToken = New-AccessTokenFromMSI -Audience Keyvault -FromARCVm
Will generate an access token to access your Keyvault.
.EXAMPLE
#Generate an access token for Keyvault from a native Azure VM
$KeyvaultToken = New-AccessTokenFromMSI -Audience Keyvault
Will generate an access token to access your Keyvault.
.EXAMPLE
#Generate an access token for a custom scope and call web api
$token = New-AccessTokenFromMSI -Audience Custom -CustomScope 'api://accc94e1-cd6f-4d80-ce41-1033d8545b6e' -FromARCVm
irm -Uri 'https://funwitharc.azurewebsites.net/api/HttpTrigger1' -Headers @{"Authorization"= "Bearer $token"} -Body @{"Name"="fanf"}
Will generate an access token and use it to access protected web api.
.NOTES
VERSION HISTORY
1.0 | 2021/02/17 | Francois LEON
    initial version - Tested on Windows machine
1.1 | 2021/02/25 | Francois LEON
    Make it linux compliant too
1.2 | 2021/11/30 | Francois LEON
    Rename the function
    Make it native MSI aware
1.3 | 2023/01/09 | Francois LEON
    Little refactor
    Add custom scope
    Add azure monitor scope
POSSIBLE IMPROVEMENT
    -
#>
Function New-AccessTokenFromMSI {
    [CmdletBinding()]
    param (
        [parameter(Mandatory)]
        [ValidateSet('Keyvault','ARM','GraphAPI','StorageAccount','Monitor','Custom')] #Add custom api later
        [string] $Audience,
        [string] $CustomScope = $null, #https:// ... should be used only with Custom Audience
        [switch] $FromARCVm #Is this command executed from ARC machine or Azure VM directly?
    )

    if ([int]$PSVersionTable.PSVersion.Major -ne 7) {
        throw 'This is a Powershell 7 function only...'
    }

    if ($FromARCVm) {
        $MSIEndpoint = 'http://localhost:40342/metadata/identity/oauth2/token?api-version=2020-06-01'
    }
    else {
        $MSIEndpoint = 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01' #According https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/how-to-use-vm-token#get-a-token-using-powershell
    }
    
    switch ($Audience) {
        'Keyvault' { $EncodedURI = [System.Web.HttpUtility]::UrlEncode("https://vault.azure.net");break }
        'ARM' { $EncodedURI = [System.Web.HttpUtility]::UrlEncode("https://management.azure.com");break }
        'GraphAPI' { $EncodedURI = [System.Web.HttpUtility]::UrlEncode("https://graph.microsoft.com");break }
        'StorageAccount' { $EncodedURI = [System.Web.HttpUtility]::UrlEncode("https://storage.azure.com");break }
        'Monitor' { $EncodedURI = [System.Web.HttpUtility]::UrlEncode("https://monitor.azure.com");break }
        default {$EncodedURI = [System.Web.HttpUtility]::UrlEncode($CustomScope) }
    }

    $AudienceURI = "{0}&resource={1}" -f $MSIEndpoint,$EncodedURI

    if ($FromARCVm) {
        #Define token path depending on the OS
        if ($IsLinux) {
            # Add user ubuntu to himds group
            # sudo usermod -a -G himds ubuntu
            # Add himds read + execution permission to /var/opt/azcmagent/tokens directory 
            # sudo chmod g+rx /var/opt/azcmagent/tokens
            [string] $ARCTokensPath = '/var/opt/azcmagent/tokens' #Require read access to /var/opt/azcmagent/tokens
        }
        else {
            [string] $ARCTokensPath = 'C:\ProgramData\AzureConnectedMachineAgent\Tokens'
        }
        $ARCTokensPath = Join-Path $ARCTokensPath -ChildPath '*.key'

        #Why 4 ? Why not
        for ($i = 0; $i -lt 4; $i++) {
            try {
                $Headers = @{
                    Metadata      = 'true'
                    #Construct the path where the AT will be generated
                    Authorization = "Basic $(Get-Content -Path $ARCTokensPath -ErrorAction SilentlyContinue)"
                }
                $response = Invoke-RestMethod -Uri $AudienceURI -Headers $Headers -ErrorAction SilentlyContinue
                break
            }
            catch {
                $i++
                Start-Sleep -Millisecond 100
            }
        }
        if ($response) {
            return $response.access_token
        }
        else {
            Throw('No access token received')
        }
    }
    else{
        #Means from Azure VM directly
        $Headers = @{
            Metadata      = 'true'
        }
        try{
            $response = Invoke-RestMethod -Uri $AudienceURI -Headers $Headers -ErrorAction stop
            $response.access_token
        }
        catch{
            Throw('No access token received')
        }
    }
}