Import-Module -Name Pode
Import-Module -Name ValidateAadJwt
Import-Module -Name MSAL.PS


#############################################################################################################
####################                     CLAIM VALIDATION PART                           ####################
#############################################################################################################
# Define all role/scp/other claims you want to validate from your API (can be anything)
# In this case, I want to validate only the role claim.
# IMPORTANT you must always keep the defaultRulesPath, this one verify the "basics to accept a token" + offine token signature check
$defaultRulesPath = Join-Path -Path 'Authentication' -ChildPath 'defaultRule.ps1'
#Change value below following you need
$nonAdminRolePath = Join-Path -Path 'Authentication' -ChildPath 'nonAdminRole.ps1'
$adminRolePath = Join-Path -Path 'Authentication' -ChildPath 'adminRole.ps1'

# Depending on the various cases you want to manage, add more scriptblock below. Here 2 roles, 2 scriptblocks
$nonAdminSb = [scriptblock]::Create(@((Get-content -Path $defaultRulesPath -Raw),(Get-content -Path $nonAdminRolePath -Raw)) -join "`r`n`r`n")
$adminUserSb = [scriptblock]::Create(@((Get-content -Path $defaultRulesPath -Raw),(Get-content -Path $adminRolePath -Raw)) -join "`r`n`r`n")

#############################################################################################################

Start-PodeServer {

#region Middleware
    
    # Configure your CORS rules here. Change * to your frontend url for more serious scenario 
    Add-PodeMiddleware -Name 'MandatoryAuthorizationHeader' -ScriptBlock {
        Add-PodeHeader -Name 'Access-Control-Allow-Origin' -Value '*'
        Add-PodeHeader -Name 'Access-Control-Allow-Methods' -Value 'GET, OPTIONS'
        Add-PodeHeader -Name 'Access-Control-Allow-Headers' -Value 'Content-Type,Authorization'

        return $true
    }

    # Declare all schemes for both authentication and authorization. 
    New-PodeAuthScheme -Bearer | Add-PodeAuth -Name 'NonAdmin' -Sessionless -ScriptBlock $nonAdminSb
    New-PodeAuthScheme -Bearer | Add-PodeAuth -Name 'Admin' -Sessionless -ScriptBlock $adminUserSb

    # Allow the option method in each route
    Add-PodeRoute -Method Options -Path * -ScriptBlock {
        return $true
    }

#endregion

#region PODE config
    #Redirect errors to terminal. Cool to have logs redirected to containers logs for tracking
    New-PodeLoggingMethod -Terminal | Enable-PodeRequestLogging
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging -Levels Error, Warning
    
    # Configure Pode to listen on 8080 in HTTP (with localhost, you "break" Docker)
    Add-PodeEndpoint -Address * -Port 8080 -Protocol Https -Certificate './cert.pem' -CertificateKey './key.pem'

#endregion

#region Anonymous routes
    Add-PodeRouteGroup -Routes {

        Add-PodeRoute -Method Get -Path '/health' -ScriptBlock {
            #https://badgerati.github.io/Pode/Tutorials/Authentication/Overview/#users
            Write-PodeJsonResponse -Value @{ 'Message' = 'Everything is fine!'}
        }

    }

#endregion

#region Admin role required routes
    ############################################
    #######   admin_user role required   #######
    ############################################
    Add-PodeRouteGroup -Authentication 'Admin' -Routes {

        Add-PodeRoute -Method Get -Path '/api/onbehalfflow' -ScriptBlock {
            $config = Get-PodeConfig
            $api01ClientId = $config.Audience
            $api01ClientSecret = ConvertTo-SecureString -String $($config.Secret) -AsPlainText -Force
            $api01TenantId = $config.TenantId
            $Api03Scope = $config.Api03Scope

            $token = Get-MsalToken -ClientId $api01ClientId -ClientSecret $api01ClientSecret -Scopes $Api03Scope -UserAssertion $($WebEvent.Auth.User.token) -TenantId $api01TenantId | % Accesstoken
            #write-host $token
            $r = irm -Uri "http://api03.francecentral.azurecontainer.io:8080/api/onbehalfflow" -Method Get -Headers @{'Authorization' = "Bearer $Token"}
            Write-PodeJsonResponse -Value @{ 'Response' = $r }
        }

        Add-PodeRoute -Method Get -Path '/api/whoamiadmin' -ScriptBlock {
            Write-PodeJsonResponse -Value @{ 'Response' = "Hi $($WebEvent.Auth.User.name) from api01 (admin) with role: $($WebEvent.Auth.User.roles)" }
        }
    }
#endregion

#region Regular role required routes
    Add-PodeRouteGroup -Authentication 'NonAdmin' -Routes {
        
        Add-PodeRoute -Method Get -Path '/api/whoami' -ScriptBlock {
            # Will poke Graph to get user emails (delegated)
            Write-PodeJsonResponse -Value @{ 'Message' = "Hi $($WebEvent.Auth.User.name) from api01 (non admin) with role: $($WebEvent.Auth.User.roles)" }
        }

        Add-PodeRoute -Method Get -Path '/api/nbgroupiown' -ScriptBlock {
            $config = Get-PodeConfig
            $api01ClientId = $config.Audience
            $api01ClientSecret = ConvertTo-SecureString -String $($config.Secret) -AsPlainText -Force
            $api01TenantId = $config.TenantId

            $Token = Get-MsalToken -ClientId $api01ClientId -ClientSecret $api01ClientSecret -TenantId $api01TenantId -Scopes 'User.Read.All' -UserAssertion $($WebEvent.Auth.User.token) | % Accesstoken
            $Headers = @{
                'ConsistencyLevel' = 'eventual'
                'Authorization'    = "Bearer $token"
            }
            $r = irm -Uri "https://graph.microsoft.com/v1.0/users/$($WebEvent.Auth.User.oid)/ownedObjects/microsoft.graph.group/`$count" -Headers $Headers
            Write-PodeJsonResponse -Value @{ 'Response' = $r } #$r.value | ConvertTo-Json -Depth 99
        }
    }
#endregion
}
