<#
.SYNOPSIS
This function helps you to generate an Access Token for various audiences (Keyvault, Resource MAnager, Microsoft Graph, Storage Account) once your machine is enrolled in Azure ARC.
.DESCRIPTION
https://docs.microsoft.com/en-us/azure/azure-arc/servers/agent-overview
This function will use the local MSI endpoint generated during the agent installation to create an access token you will be able to use for various scopes. The idea behind this script is
to avoid having to set password/secret in your local dev machine/ pipeline runners to be passwordless from A to Z. 
.PARAMETER ARCTokensPath
Specify the installation path of the ARC agent.
.PARAMETER Audience
Specify the Audience you want to send the generated ccess Token to.
.EXAMPLE
#Generate aan access token for Keyvault 
$KeyvaultToken = New-ARCAccessTokenMSI -Audience Keyvault
Will generate an access token to access your Keyvault.
.NOTES
VERSION HISTORY
1.0 | 2021/02/17 | Francois LEON
    initial version - Tested on Windows machine
POSSIBLE IMPROVEMENT
    # Make it Linux compatible
    #Is ARC detected
    # Is port listening
    # Get Arc installation path
#>
Function New-ARCAccessTokenMSI {
    [CmdletBinding()]
    param (
        [parameter(Mandatory=$false)]
        [string] $ARCTokensPath = 'C:\ProgramData\AzureConnectedMachineAgent\Tokens',
        [parameter(Mandatory)]
        [ValidateSet('Keyvault','ARM','GraphAPI','StorageAccount')]
        [string] $Audience
    )

    $LocalMSIEndpoint = "http://localhost:40342/metadata/identity/oauth2/token?api-version=2020-06-01"

    switch ($Audience) {
        "Keyvault" {$AudienceURI = "$LocalMSIEndpoint&resource=https%3A%2F%2Fvault.azure.net";break  }
        "ARM" {$AudienceURI = "$LocalMSIEndpoint&resource=https%3A%2F%2Fmanagement.azure.com";break  }
        "GraphAPI" {$AudienceURI = "$LocalMSIEndpoint&resource=https%3A%2F%2Fgraph.microsoft.com";break  }
        "StorageAccount" {$AudienceURI = "$LocalMSIEndpoint&resource=https%3A%2F%2Fstorage.azure.com"}
    }

    #Why 4 ? Why not
    for ($i = 0; $i -lt 4; $i++) {
        try{
            $Headers = @{
                Metadata="true"
                #Construct the path where the AT will be generated
                Authorization="Basic $(Get-Content -Path $(Join-Path $ARCTokensPath "*.key") -ErrorAction SilentlyContinue)"
            }
            $response = Invoke-RestMethod -Uri $AudienceURI -Headers $Headers -ErrorAction SilentlyContinue
            break
        }
        catch{
            $i++
            Start-Sleep -Millisecond 100
        }
    }
    if($response){
        return $response.access_token
    }
    else{
        Throw("No access token received")
    }
}
