<#
    The goal of this script is to show a way to use the Graph batch endpoint. It can be interresting when you have a big amount of request to
    manage. Instead of doing a lot of back and forth, yu can ask Graph to do the work for you.    

    Make sure you have MSAL.PS installed > install-module MSAL.PS

    This script will:
    1. List all groups assigned to a specific Enterprise app (more than 3000 groups in my case)
    2. Split them, send them into to graph batch endpoint
    3. Merge the responses and compare with Current group we want to "sync"
    4. Add/Remove differences

    Follow the comments and it should be OK to understand.

#>

# Load functions in memory
import-module ".\loadme.psm1",MSAL.PS

#Initialize variables
$appId = '<your appId>'
$tenantId = '<your tenantId>'
$serviceAccountName = "serviceaccount@<your domain>.onmicrosoft.com" # Can be something else than serviceaccount of course
$serviceAccountPassword = '<Service account password>'
$enterpriseAppObjectId = '<Enterprise App ObjectId where all groups are assigned>'
$currentGroupToSyncObjectId = '<The group object Id you want to populate>'  # This represents our dynamic DL

# Don't need to touch the rest of the script

# Generate Pscredential
$password = ConvertTo-SecureString -String $ServiceAccountPassword -AsPlainText -Force
$creds = New-Object System.Management.Automation.PSCredential($ServiceAccountName,$password)


# Fetch an access token for the 'https://graph.microsoft.com/.default' scope.
# Thank to MSAL.PS, here we use ROPC flow to get our token
$token = Get-MsalToken -ClientId $appId -TenantId $tenantId -Scopes 'https://graph.microsoft.com/.default' -RedirectUri 'http://localhost' -UserCredential $creds | select -ExpandProperty AccessToken

$Headers = @{
    'Authorization' = "Bearer $Token"
    'Content-Type'  = 'application/json'
}

$start = Get-Date

# Fetch the 3000+ groups assigned to the enterprise app
$assignegroups = Get-AADAppRoleAssignedTo -Headers $Headers -ServicePrincipalObjectId $enterpriseAppObjectId | select-object -ExpandProperty principalId
# Slice it in 20 items chunks > 20 size max per batch
$splittedArrays = Split-Array -inArray $assignegroups -size 20

$batchUrl = "https://graph.microsoft.com/v1.0/`$batch"

# This array will contain the result of each chunk we've generated previously
$BigBatchAnswers= @()
# Each batch should have a request Ids
[int]$requestId = 1

# Here we simply create a json format request to be accepted by the batch endpoint and then send it to the endpoint
foreach($splittedArray in $splittedArrays){
    
    # Batch endpoint is waiting for an array
    $myBatchRequests = @()

    #This is where we can have until 20 items (chunk) per batch. Here we start to format the future request
    foreach($item in $splittedArray){
        $myRequest = [pscustomobject][ordered]@{ 
            id     = $requestID
            method = "GET"
            url    = "/groups/$item/members?`$select=userPrincipalName,Id&`$top=999"
        }
        $myBatchRequests += $myRequest
        $requestID ++
    }

    # We create an hashtable with all formated 20 items max
    $allBatchRequests =  [pscustomobject][ordered]@{ 
        requests = $myBatchRequests
    }

    # Convert it to json
    $batchBody = $allBatchRequests | ConvertTo-Json

    # Here we simply ask Graph batch endpoint to work on a "batch" of 20 items for us. In other words 20 groups within the 3000+
    $getBatchRequests = Invoke-RestMethod -Method Post -Uri $batchUrl -Body $batchBody -headers $Headers
    #Add each graph batch response to this array.
    $bigBatchAnswers += $getBatchRequests
}

# At this stage, we've sent 150+ requests to batch endpoint, it's time to fetch the results.

# This array will contain all users located in all groups assigned to enterprise app. In my case more than 15k+
$bigQueryResults = [System.Collections.ArrayList]::new()

foreach($bigBatchAnswer in $bigBatchAnswers){
    # Let's run through each batch
    foreach($response in $($bigBatchAnswer.responses)){
        # Here we should have between 1 and 20 items
        if($response.status -eq 200){
            # From here we should have a bunch of users.
            # IMPORTANT: This is the tricky part compared to when you fetch data from your machine. The first invoke-restmethod is made by the Graph batch endpoint and only if
            # you need paging '@odata.nextLink' (more than 999 users in a group), in this case we will fetch locally, we won't ask batch again.

            $QueryResults = @()

            if($response.body.'@odata.nextLink'){

                $Params = @{
                    Headers     = $Headers
                    uri         = $null
                    Body        = $null
                    method      = 'Get'
                    ErrorAction = 'Stop'
                }

                # Load first values and then go fetch the other data from paging
                $QueryResults += $response.body.value | Select-Object Id,userPrincipalName
                $Params.uri = $response.body.'@odata.nextlink'
                do {
                    try{$Results = Invoke-RestMethod @Params}
                    catch{throw}
                    #Add new values
                    $QueryResults += $Results.value | Select-Object Id,userPrincipalName
                    $params.Uri = $Results.'@odata.nextLink'

                } until (-not $Params.uri)
            }
            else{
                # No paging here just take the value directly
                $QueryResults += $response.body.value | Select-Object Id,userPrincipalName
            }

            # With or without nextlink, we don't care we just dump the result in the big collection
            $QueryResults.ForEach({[void]$BigQueryResults.Add($_)})

        }
        else{
            Write-Warning "Response other than 200 code: $response"
        }
    }
}

# Let's now filter our big flat array to remove duplicates
$FinalResult = $BigQueryResults | Select-Object userPrincipalName,Id -Unique

# Get members of the group we want to update
$CurrentDLMembers = Get-AADGroupMember -GroupId $currentGroupToSyncObjectId -Headers $Headers

# Do we have to do a full sync?
$Fullsync = $false
try { $Compare = Compare-Object -ReferenceObject $CurrentDLMembers.Id -DifferenceObject $finalResult.Id }catch { $Fullsync = $true }

#Full sync means only add
if ($Fullsync) {
    Foreach ($Item in $finalResult) {
        try {
            Add-AADGroupMember -UserId $Item.Id -GroupId $currentGroupToSyncObjectId -Headers $Headers
        }
        catch {
            Write-Error "Unable to add member: $($Item.Id) to the group"
            $_.Exception
        }
    }
}
else {
    if ($Compare) {
        Foreach ($Item in $Compare) {
            if ($Item.SideIndicator -eq '=>') {
                try {
                    Add-AADGroupMember -UserId $Item.InputObject -GroupId $currentGroupToSyncObjectId -Headers $Headers
                    Write-Output "Add user $($Item.InputObject) to the group"
                }
                catch {
                    Write-Error "Unable to add the member: $($Item.InputObject) to the group"
                    $_.Exception
                }
            }
            else {
                #Remove
                try {
                    Remove-AADGroupMember -UserId $Item.InputObject -GroupId $currentGroupToSyncObjectId -Headers $Headers
                    Write-Output "Remove user $($Item.InputObject) from the group"
                }
                catch {
                    Write-Error "Unable to remove the member: $($Item.InputObject) to the group"
                    $_.Exception
                }
            }
        }
    }
    else{
        Write-Output 'Group already up to date no action taken'
    }
}

$end = Get-Date

New-TimeSpan -Start $start -End $end
