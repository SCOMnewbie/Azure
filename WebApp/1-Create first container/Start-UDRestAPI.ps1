$Endpoint = New-UDEndpoint -Url "/helloworld" -Method "GET" -Endpoint {
    [PSCustomObject]@{ MachineNAme = [Environment]::MachineName } | ConvertTo-Json
}
Start-UDRestApi -Endpoint $Endpoint -port 80 -wait