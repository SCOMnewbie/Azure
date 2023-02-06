# https://learn.microsoft.com/en-us/rest/api/storageservices/list-blobs?tabs=azure-ad
function Get-StorageBlobs {
    param(
        [string]$StorageAccount,
        [string]$Container,
        [string]$AccessToken
    )

    #	https://myaccount.blob.core.windows.net/mycontainer?restype=container&comp=list
    $URL = "https://{0}.blob.core.windows.net/{1}?restype=container&comp=list" -f $StorageAccount,$Container
    $url
    $Headers = @{
        'Authorization'          = $('Bearer ' + $AccessToken)
        'x-ms-date'                   = $((Get-Date).ToUniversalTime().toString('r'))
        'x-ms-version'           = '2021-08-06'
    }

    #Thanks the weird encoding pb whre the answer start with ï»¿<?xml ...
    [xml]$((Invoke-RestMethod -Uri $URL -Headers $Headers).substring(3))
}