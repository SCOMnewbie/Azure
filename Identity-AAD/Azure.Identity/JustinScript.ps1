#requires -module Az.Accounts
using namespace Azure.Identity
using namespace Azure.Core
using namespace Azure.Core.Diagnostics
using namespace Microsoft.Azure.Commands.Common.Authentication.Abstractions
function Get-AzAppToken {
	<#
  .NOTES
  Implementation of https://docs.microsoft.com/en-us/dotnet/api/overview/azure/identity-readme
  #>
	[CmdletBinding(DefaultParameterSetName = 'Service')]
	param(
		#The scope(s) that you wish to connect to. Defaults to Microsoft Graph limited to just the current user info.
		[String[]]$Scope = 'https://graph.microsoft.com/.default',
		#The tenant ID to authenticate against other than the user default. Useful for B2B accounts
		[String]$TenantId = $null,
		#The app ID to use. This will be intelligently selected based on the scope if not specified
		[String]$AppId,
		#The order in which to search for tokens
		[ValidateSet(
			'Environment',
			'ManagedIdentity',
			'VisualStudioCode',
			'VisualStudio',
			'AzureCLI',
			'AzurePowerShell'
		)]
		[String[]]$TokenSearchOrder = @(
			'Environment'
			'ManagedIdentity'
			'VisualStudioCode'
			'VisualStudio'
			'AzureCLI'
			'AzurePowerShell'
		)
	)
	begin {
		# Quickly load Az.Accounts if it isn't already
		$null = try {
			[DefaultAzureCredential]::new()
		} catch {
			Import-Module Az.Accounts
			[DefaultAzureCredential]::new()
		}

		[TokenCredential[]]$TokenProviders = $TokenSearchOrder.ForEach{
			switch ($PSItem) {
				'Environment' { [EnvironmentCredential]::new() }
				'ManagedIdentity' { [ManagedIdentityCredential]::new($AppId) }
				'VisualStudioCode' {
					[VisualStudioCodeCredential]::new(
						# [VisualStudioCodeCredentialOptions]@{TenantId = $TenantId }
					)
				}
				'VisualStudio' {
					[VisualStudioCredential]::new(
						# [VisualStudioCredentialOptions]@{TenantId = $TenantId }
					)
				}
				'AzureCLI' { [AzureCliCredential]::new() }
				'AzurePowerShell' { [AzurePowerShellCredential]::new() }
			}
		}

		$TokenGenerator = [ChainedTokenCredential]::new($TokenProviders)

		#Enable Logging
		$logger = if ($DebugPreference -eq 'Continue') {
			[AzureEventSourceListener]::CreateConsoleLogger('Verbose')
		}
	}

	process {
		[TokenRequestContext]$Context = [TokenRequestContext]::new($Scope, $null, $null, $TenantId)
		$token = $TokenGenerator.GetToken($Context)
		if ($token.token) {
			$decodedToken = $token.token | ConvertFrom-JWT -Verbose:$false
			[String]$fetchedTokenMessage = 'Fetched token for user {0} ({1}) in tenant {2} using app {3} ({4}) for {5} with scopes {6}' -f `
				$decodedToken.name,
			$decodedToken.unique_name,
			$decodedToken.tid,
			$decodedToken.app_displayname,
			$decodedToken.appid,
			$decodedToken.aud,
			$decodedToken.scp
			Write-Verbose $fetchedTokenMessage
		}
		return $token
	}

	end {
		if ($logger) { $logger.Dispose() }
	}
}

function ConvertFrom-JWT {
	<#
    .DESCRIPTION
    Decodes a JWT token. This was taken from link below. Thanks to Vasil Michev.
    .LINK
    https://www.michev.info/Blog/Post/2140/decode-jwt-access-and-id-tokens-via-powershell
    #>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory, ValueFromPipeline)][string]$Token
	)
	process {

		#Validate as per https://tools.ietf.org/html/rfc7519
		#Access and ID tokens are fine, Refresh tokens will not work
		if (-not $Token.Contains('.') -or -not $Token.StartsWith('eyJ')) {
			throw 'Invalid token. A valid JWT token base64 string starts with "eyj"'
		}

		#Header
		$tokenheader = $Token.Split('.')[0].Replace('-', '+').Replace('_', '/')

		#Fix padding as needed, keep adding "=" until string length modulus 4 reaches 0
		while ($tokenheader.Length % 4) {
			Write-Verbose 'Invalid length for a Base-64 char array or string, adding ='
			$tokenheader += '='
		}

		Write-Verbose "Base64 encoded (padded) header: $tokenheader"

		#Convert from Base64 encoded string to PSObject all at once
		Write-Verbose 'Decoded header:'
		$header = ([Text.Encoding]::ASCII.GetString([Convert]::FromBase64String($tokenheader)) | ConvertFrom-Json)

		#Payload
		$tokenPayload = $Token.Split('.')[1].Replace('-', '+').Replace('_', '/')

		#Fix padding as needed, keep adding "=" until string length modulus 4 reaches 0
		while ($tokenPayload.Length % 4) {
			Write-Verbose 'Invalid length for a Base-64 char array or string, adding ='
			$tokenPayload += '='
		}

		Write-Verbose "Base64 encoded (padded) payoad: $tokenPayload"

		$tokenByteArray = [Convert]::FromBase64String($tokenPayload)
		$tokenArray = ([Text.Encoding]::ASCII.GetString($tokenByteArray) | ConvertFrom-Json)

		#Converts $header and $tokenArray from PSCustomObject to Hashtable so they can be added together.
		#I would like to use -AsHashTable in convertfrom-json. This works in pwsh 6 but for some reason Appveyor isnt running tests in pwsh 6.


		$result = [Collections.Generic.SortedDictionary[String, String]]::new()
		$header.psobject.properties | ForEach-Object { $result[$_.Name] = $_.Value }
		$tokenArray.psobject.properties | Where-Object name -NotMatch 'xms_st' | ForEach-Object { $result[$_.Name] = $_.Value }
		return $result
	}
}


# $ExchangeSessionParams = @{
#   ConnectionUri    = 'https://outlook.office365.com/PowerShell-LiveId?BasicAuthToOAuthConversion=true'
#   Authentication   = 'Basic'
#   AllowRedirection = $true
#   Credential       = [PSCredential]::new("OAuthUser@$tenantId", $token)
# }
# $session = New-PSSession @ExchangeSessionParams
# Import-PSSession $session