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
.EXAMPLE
#Generate an access token for Keyvault from an ARC machine
$KeyvaultToken = New-AccessTokenFromMSI -Audience Keyvault -FromARCVm
Will generate an access token to access your Keyvault.
.EXAMPLE
#Generate an access token for Keyvault from a native Azure VM
$KeyvaultToken = New-AccessTokenFromMSI -Audience Keyvault
Will generate an access token to access your Keyvault.
.NOTES
VERSION HISTORY
1.0 | 2021/02/17 | Francois LEON
    initial version - Tested on Windows machine
1.1 | 2021/02/25 | Francois LEON
    Make it linux compliant too
1.2 | 2021/11/30 | Francois LEON
    Rename the function
    Make it native MSI aware
POSSIBLE IMPROVEMENT
    Is ARC detected
#>
Function New-AccessTokenFromMSI {
    [CmdletBinding()]
    param (
        [parameter(Mandatory)]
        [ValidateSet('Keyvault','ARM','GraphAPI','StorageAccount')] #Add custom api later
        [string] $Audience,
        [switch]$FromARCVm #Is this command executed from ARC machine or Azure VM directly?

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
        'Keyvault' { $AudienceURI = "$MSIEndpoint&resource=https%3A%2F%2Fvault.azure.net";break }
        'ARM' { $AudienceURI = "$MSIEndpoint&resource=https%3A%2F%2Fmanagement.azure.com";break }
        'GraphAPI' { $AudienceURI = "$MSIEndpoint&resource=https%3A%2F%2Fgraph.microsoft.com";break }
        'StorageAccount' { $AudienceURI = "$MSIEndpoint&resource=https%3A%2F%2Fstorage.azure.com" }
    }

    if ($FromARCVm) {
        #Define token path depending on the OS
        if ($IsLinux) {
            [string] $ARCTokensPath = '/var/opt/azcmagent/tokens'
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
