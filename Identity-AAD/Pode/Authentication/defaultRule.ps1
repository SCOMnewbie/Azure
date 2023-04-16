param($token)

try{
    $DecodedToken = ConvertFrom-Jwt -Token $token -erroraction stop
}
catch{
    Set-PodeResponseStatus -Code 403
    return $null
}


    #Validate audience
if($DecodedToken.Tokenpayload.aud -ne (Get-PodeConfig).Audience){
    Set-PodeResponseStatus -Code 403
    return $null
}

# IMPORTANT: Validate token signature
try{
    $null = Test-AADJWTSignature -Token $token -TenantId (Get-PodeConfig).TenantId -erroraction stop  
}
catch{
    Set-PodeResponseStatus -Code 403
    $_ | Write-PodeErrorLog -Level Verbose
    # authentication failed
    return $null
}# If token not compliant with alg,typ,exp,iss and signature (offline) > 403