# Input bindings are passed in via param block.
param($Timer)

#Azure function seems to have $error not empty by default (https://github.com/Azure/azure-functions-powershell-worker/issues/470)
$error.clear()

$context = get-azcontext
Write-Host "######   Working with Account $($context.Account.Id)"

$Query = @"
resources
| where type == "microsoft.compute/virtualmachines"
and isnotnull(tags['Shutdown-UTC-24:00'])
"@

$VMsToShutdown = Search-AzGraph -Query $Query
$ListOfVMsToShutdown =  New-Object System.Collections.Generic.List[System.Object]
$CurrentUTCDate = (get-date).ToUniversalTime().ToString("HH:mm")

#Foreach VM type where the tag is defined
Foreach ($VMToShutdown in $VMsToShutdown){
    $VMName = $VMToShutdown.Name
    $RG = $VMToShutdown.resourceGroup
    $SubId = $VMToShutdown.subscriptionId
    #Grab the customer shutdown time need
    $TimeToShutdown = $VMToShutdown.tags.'Shutdown-UTC-24:00'
    #To avoid missconfiguration (not idiot proof)
    if($TimeToShutdown -notmatch '^[012][0-9]:[0-9][0-9]$'){
        #Means the current tag value has not the valid format, let's skip it
        Write-Warning "The VM named $VMName hosted on resource group $RG of the subscription $SubId has a bad tag value"
        continue
    }
    #Now we have to test if the requested time belong to the current time chunk (The function run every 15 min)
    $TimeSpan = (New-TimeSpan -Start $CurrentUTCDate -End $TimeToShutdown).TotalMinutes
    if(($TimeSpan -lt 0) -AND ($TimeSpan -ge -15)){
        #Create our temp array of VMs to shutdown
        $VMInfo = [PSCustomObject]@{
            Name     = $VMName
            SubscriptionId = $SubId
            ResourceGroup = $RG
        }
        #Array of VMs we need to shutdown
        $ListOfVMsToShutdown.add($VMInfo)
     }
}

#Now that we have an array of VM to shutdown, let's proceed
# If you have multiple VM per sub, it's more efficent to do subscription batch instead of select-azsub for every VM
$Subscriptions = $ListOfVMsToShutdown.SubscriptionId | Select-Object -Unique
if($Subscriptions.count -eq 0){
    Write-Host "No VM to startup during this run $(Get-Date)"
}
Foreach($Subscription in $Subscriptions){
    Select-AzSubscription -Subscription $Subscription
    if(-not $?){
        #Try another item because something goes wrong with this sub
        write-error "Unable to connect to $Subscription let`'s switch to another subscription"
        Continue
    }

    $VMsToShutdownInThisSub = @()
    $VMsToShutdownInThisSub = $ListOfVMsToShutdown | Where-Object{$_.SubscriptionId -eq $Subscription}
    Foreach($VM in $VMsToShutdownInThisSub){
        for ($i = 0; $i -le 2; $i++) {
            Write-Host "Shutdown of VM $($VM.Name) from RG $($VM.ResourceGroup) of the subscription $Subscription in progress"
            $shutdownAction = Get-AzVM -ResourceGroupName $VM.ResourceGroup -Name $VM.Name | Stop-AzVM -NoWait -Force
            #Retry just in case something goes wrong
            if($ShutdownAction.IsSuccessStatusCode){
                Write-Host "Shutdown of VM $($VM.Name) from RG $($VM.ResourceGroup) of the subscription $Subscription succeed"
                Break
            }
            elseif(($ShutdownAction.IsSuccessStatusCode -eq $false) -AND ($i =2)){
                Write-Error "Unable to shutdown VM $($VM.Name) from RG $($VM.ResourceGroup) on the subcription $Subscription"
            }
        }
    }   
}

