function Get-LocationList {
    
    $Object = az account list-locations | ConvertFrom-Json
    return $Object
}


