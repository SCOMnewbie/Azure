function Get-VMInfo {
    param(
        [parameter(Mandatory = $true)]
        [String]
        $ResourceGroupName,
        [parameter(Mandatory = $true)]
        [String]
        $VMName
    )
    
    $object = az vm show -d -g $ResourceGroupName -n $VMName | ConvertFrom-Json
    return $object
}

