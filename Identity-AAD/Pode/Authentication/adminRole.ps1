#Now we know this is a valid token let's validate the roles claim
$Authorized = $false
[array]$Roles = $DecodedToken.TokenPayload.roles
# you can use $using:var if you prefer
$Roles.ForEach({if($_ -eq 'admin'){$Authorized = $true}})

if(-not $Authorized){
    Write-verbose "You don't have the proper role assigned" # Debug
    Set-PodeResponseStatus -Code 401
    return $false
} # You don't have the app role in the access token > 401
else{   
        # This is what the Add-PodeAuth func will provide to the following protected Add-PodeRoute functions. you can add more properties if required.
        return @{ 'User' = @{
        'oid' = $($DecodedToken.TokenPayload.oid)
        'roles' =  $($DecodedToken.TokenPayload.roles)
        'name' = $($DecodedToken.TokenPayload.name)
        'token' = $token
        }
    }
}