function Get-LatestImagesList {
    param(
        [parameter(Mandatory = $true)]
        [ValidateSet("MicrosoftWindowsDesktop", "MicrosoftWindowsServer", "MicrosoftVisualStudio", "OpenLogic", "Canonical")]
        [String]
        $Publisher
    )
    
    $Object = az vm image list --publisher $Publisher --query "[?version=='latest'].{sku:sku,urnAlias:urnAlias}" -o json | ConvertFrom-Json
    return $object
}

