Function Get-AccessTokenWithAzIdentity {
    <#
.SYNOPSIS
    Return an access token independently if you run this function from an Azure VM, an ACI container, an Azure function or an ARC for servers agent (Linux/Windows).

.DESCRIPTION
    Get-AccessTokenWithAzIdentity is a function that try to generate an access to access for specified audience on any Az compute resources. The function helps you to choose (storage, keyvault ...) but you can also specify yours
    with the CustomScope parameter (api://...)

.PARAMETER Audience
    Specify the audience you're trying to access

.PARAMETER CustomScope
    Specify the custom api scope you're trying to access

.EXAMPLE
     Get-AccessTokenWithAzIdentity -Audience Keyvault

.EXAMPLE
     Get-AccessTokenWithAzIdentity -Audience Custom -CustomScope "api://<your exposed api>"

.EXAMPLE
    Get-AccessTokenWithAzIdentity -Audience Keyvault -UserMSIClientId '12345678-0000-0000-0000-000000000000'

.OUTPUTS
    String
#>
    [CmdletBinding()]
    param (
        [parameter(Mandatory)]
        [ValidateSet('Keyvault','ARM','GraphAPI','Storage','Monitor', 'LogAnalytics','Custom')] #Add custom api later
        [string] $Audience,
        [string] $UserMSIClientId,
        [string] $CustomScope = $null #https:// ... should be used only with Custom Audience like api://<your api>
    )

    begin {
        ###Initialization phase###

        if ([int]$PSVersionTable.PSVersion.Major -ne 7) {
            throw 'This is a Powershell 7 function only...'
        }

        if ($Audience -eq 'Custom') {
            if ($null -eq $CustomScope) {
                Throw "CustomScope parameter should not be null when you're using Custom audience"
            }
        }

        $IsRunningOnAzFunctionApp = $false
        $IsRunningOnAzVMOrACI = $false
        $IsRunningOnARCForServers = $false

        switch ($Audience) {
            'Keyvault' { $EncodedURI = [System.Web.HttpUtility]::UrlEncode('https://vault.azure.net');break }
            'ARM' { $EncodedURI = [System.Web.HttpUtility]::UrlEncode('https://management.azure.com');break }
            'GraphAPI' { $EncodedURI = [System.Web.HttpUtility]::UrlEncode('https://graph.microsoft.com');break }
            'Storage' { $EncodedURI = [System.Web.HttpUtility]::UrlEncode('https://storage.azure.com');break }
            'Monitor' { $EncodedURI = [System.Web.HttpUtility]::UrlEncode('https://monitor.azure.com');break }
            'LogAnalytics' { $EncodedURI = [System.Web.HttpUtility]::UrlEncode('https://api.loganalytics.io');break }
            default { $EncodedURI = [System.Web.HttpUtility]::UrlEncode($CustomScope) }
        }

        $Headers = $null
        $Headers = @{
            'Metadata' = 'true'
        }

        ###Detection Phase###
        
        # Test Az function
        if ($env:FUNCTIONS_WORKER_RUNTIME -eq 'Powershell') {
            $IsRunningOnAzFunctionApp = $true
        }
        # Test Az VM or ACI
        elseif ($(try { Invoke-RestMethod -Uri 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01' -ErrorAction stop }catch { $_.ErrorDetails.Message }) -like '*required metadata header not specified*') {
            $IsRunningOnAzVMOrACI = $true
        }
        
        #Test ARC
        try {
            $null = Get-Process himds -ErrorAction stop
            $IsRunningOnARCForServers = $true
        }
        catch {
            $null
        }
    }
    process {

        if ($IsRunningOnAzFunctionApp) {
            Write-Verbose 'Is running on Azure function'
            $MSIEndpoint = "$($env:IDENTITY_ENDPOINT)?api-version=2019-08-01"
            $AudienceURI = '{0}&resource={1}' -f $MSIEndpoint,$([System.Web.HttpUtility]::UrlDecode($EncodedURI))
            Write-Host "Using uri: $AudienceURI"
            $Headers.Add('X-IDENTITY-HEADER' , $($env:IDENTITY_HEADER))

            #Why 4 ? Why not
            for ($i = 0; $i -lt 4; $i++) {
                try{$response = Invoke-RestMethod -Uri $AudienceURI -Headers $Headers -ErrorAction stop}catch{}
                if ($response) {
                    return $response.access_token
                }
                $i++
                Write-Verbose "wait 1 second..." #From time to time the IMDS don't reply
                Start-Sleep 1
            }
            
            Throw('No access token received')
        }
        elseif ($IsRunningOnAzVMOrACI) {
            Write-Verbose 'Is running on Azure VM or ACI'
            $MSIEndpoint = 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01' #According https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/how-to-use-vm-token#get-a-token-using-powershell
            $AudienceURI = '{0}&resource={1}' -f $MSIEndpoint,$EncodedURI
            Write-Verbose "Using uri: $AudienceURI"
            if($UserMSIClientId){
                $AudienceURI = '{0}&client_id={1}' -f $AudienceURI,$UserMSIClientId
            }
            #Why 4 ? Why not
            for ($i = 0; $i -lt 4; $i++) {
                try{$response = Invoke-RestMethod -Uri $AudienceURI -Headers $Headers -ErrorAction stop}catch{}
                if ($response) {
                    return $response.access_token
                }
                $i++
                Write-Verbose "wait 1 second..." #From time to time the IMDS don't reply
                Start-Sleep 1
            }
            
            Throw('No access token received')
        }
        elseif ($IsRunningOnARCForServers) {
            # Keep the generated token in a local cache. AAD does not like when you hammer the service from ARC servers.
            $MSIEndpoint = 'http://localhost:40342/metadata/identity/oauth2/token?api-version=2020-06-01'
            $AudienceURI = '{0}&resource={1}' -f $MSIEndpoint,$EncodedURI
            Write-Verbose "Using uri: $AudienceURI"
            if ($IsLinux) {
                Write-Verbose 'Is running on Linux ARC machine'
                # Add user ubuntu to himds group
                # sudo usermod -a -G himds ubuntu
                # Add himds read + execution permission to /var/opt/azcmagent/tokens directory 
                # sudo chmod g+rx /var/opt/azcmagent/tokens
                [string] $ARCTokensPath = '/var/opt/azcmagent/tokens' #Require read access to /var/opt/azcmagent/tokens
            }
            else {
                Write-Verbose 'Is running on Windows ARC machine'
                [string] $ARCTokensPath = 'C:\ProgramData\AzureConnectedMachineAgent\Tokens'
            }

            # Thi is where keys are generated
            $ARCTokensPath = Join-Path $ARCTokensPath -ChildPath '*.key'
            
            #Why 4 ? Why not
            for ($i = 0; $i -lt 4; $i++) {
                $Headers.Add('Authorization',$("Basic $(Get-Content -Path $ARCTokensPath -ErrorAction SilentlyContinue)"))
                try{$response = Invoke-RestMethod -Uri $AudienceURI -Headers $Headers -ErrorAction stop}catch{} #This is when the agent generate a new key stored in $ARCTokensPath
                
                if ($response) {
                    return $response.access_token
                }
                $Headers.Remove('Authorization')
                $i++
                Write-Verbose "wait 1 second..."
                Start-Sleep 1
            }

            Throw('No access token received')
        }
        else {
            Throw 'Unable to generate an access token and/or this usecase is not covered yet'
        }
    }
}