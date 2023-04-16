#Now we know this is a valid token let's validate the roles claim
$Authorized = $false
[array]$Roles = $DecodedToken.TokenPayload.roles
$Roles.ForEach({if($_ -eq 'nonAdmin'){$Authorized = $true}})

if(-not $Authorized){
    Set-PodeResponseStatus -Code 401
    return $false
} # You don't have the app role in the access token > 401
else{
        return @{ 'User' = @{
        'oid' = $($DecodedToken.TokenPayload.oid)
        'roles' =  $($DecodedToken.TokenPayload.roles)
        'name' = $($DecodedToken.TokenPayload.name)
        'token' = $token
        }
    }
}