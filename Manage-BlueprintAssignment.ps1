<#
.SYNOPSIS
This Script will help you to update or assign blueprint when you have dozens of subscription to manage. The script will register the Blueprint provider if needed.
.DESCRIPTION
Warning: Before using this script make sure you're in the same configuration where your Blueprint is published at the Management group level not at the subscription level. The other important
point is that my governance blueprints are running under a user MSI.

This Script will help you to update or assign blueprint with Managed service Identity when you have dozens of subscription to manage. The script will register the Blueprint provider if needed.
This is an interractive script which will ask you on which subscriptions you want to work on. Then it will get the latest version available (V1.0, V2.4,..) for a blueprint published 
at the management group level and assign or update on the subscription with a specific Assignment name <Assignmentprefix>-<SubscriptionId>. Naming convention give you the possibility 
to Pester test your infra later.

.PARAMETER SubscriptionId
Specify the SubscriptionID
.PARAMETER ManagementGroupId
Specify the Management group Id where the blueprint has been published. Use (Get-AzManagementGroup).Name to get it.
.PARAMETER Assignmentprefix
Specify the Blueprint Assignment prefix. The Blueprint assignment name will be under the form <prefix>-<SubscriptionID>. In other words if your prefix is
mymandatoryBP the result will be mymandatoryBP-1234-2365...
.PARAMETER BlueprintName
Specify the Blueprint name you want to assign
.PARAMETER Location
Specify the location of the blueprint assignment
.PARAMETER UserMSIId
Specify the User MSI Id that we will use to enforce the blueprint parameters.
.PARAMETER Lock
Specify if your assignment can be overwritten totally (none), in do not delete mode or in read only. 
.EXAMPLE
$Splatting = @{
    SubscriptionID = 'Sub Id'
    ManagementGroupId = 'MG Id'
    Assignmentprefix = 'RO-MandatoryGovernance'
    BlueprintName = 'MandotoryBP'
    Location = 'East US'
    UserMSIId = '/subscriptions/<Sub Id>/resourceGroups/<Your RG>/providers/Microsoft.ManagedIdentity/userAssignedIdentities/<Your MSI Name>'
    Verbose = $true
}
Manage-BlueprintAssignment.ps1 @Splatting 
Will Assign a BP published at a MG level to a specific Subcription located under this MG in ReadOnly controlled with the User MSI with the assignment name RO-MandatoryGovernance-<Sub Id>
.EXAMPLE
$Splatting = @{
    SubscriptionID = 'Sub Id'
    ManagementGroupId = 'MG Id'
    Assignmentprefix = 'RO-MandatoryGovernance'
    BlueprintName = 'MandotoryBP'
    Location = 'East US'
    UserMSIId = '/subscriptions/<Sub Id>/resourceGroups/<Your RG>/providers/Microsoft.ManagedIdentity/userAssignedIdentities/<Your MSI Name>'
    Lock = 'AllResourcesDoNotDelete'
	Update = $true
    Verbose = $true
}
Manage-BlueprintAssignment.ps1 @Splatting

Will update the previously created assignment from readonly to do not delete. And if there is a new BP version since, will try to update the assignment with the latest available version.

.NOTES
VERSION HISTORY
1.0 | 2020/07/08 | Francois LEON
    initial version
POSSIBLE IMPROVEMENT
    Manage Parameter during assignment
    Delete Assignment
#>

[cmdletBinding()]
Param(
    [Parameter(Mandatory)]
    [guid] $SubscriptionID,
    [string] $ManagementGroupId,
    [Parameter(Mandatory)]
    [string] $Assignmentprefix,
    [Parameter(Mandatory)]
    [string] $BlueprintName,
    [ValidateSet('None', 'AllResourcesReadOnly', 'AllResourcesDoNotDelete')]
    [string]$Lock = 'AllResourcesReadOnly',
    [Parameter(Mandatory)]
    [string] $Location,
    [Parameter(Mandatory)]
    [string] $UserMSIId,
    [int]$Timeout = 120,
    [switch]$Update
)

Function Test-AZTBIsAzConnected { 
    <#
.SYNOPSIS
	This function prompt for your credentials if you are not already connected.
.DESCRIPTION
	This function prompt for your credentials if you are not already connected.                      
.NOTES
    AS IS - No Warranty
	Francois LEON
#>
    [CmdletBinding()]
    param()

    begin {
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN ] Starting Test-AZTBIsAzConnected"
        Write-Verbose "[$((Get-Date).TimeOfDay) pre-requisite ] Is pre-requisite OK?"
        if ((get-module az.* -ListAvailable -verbose:$false).count -eq 0) {
            Throw "AZ module is required, download it first"
        }
    }

    process {
        try {
            Write-Verbose "[$((Get-Date).TimeOfDay) Connection ] Are we already connected?"
            Get-AzSubscription | out-null
            Write-Verbose "[$((Get-Date).TimeOfDay) Connection ] It seems we do"
        }
        catch {
            Write-Verbose "[$((Get-Date).TimeOfDay) Connection ] It seems we don't"
            Connect-AzAccount 
        }
    }

    end {
        Write-Verbose "[$((Get-Date).TimeOfDay) END ] Ending Test-AZTBIsAzConnected"
    }
}

Function Use-AZTBCorrectContext { 
    <#
.SYNOPSIS
	This function will confirm that you're working in the correct context.
.DESCRIPTION
    This function will confirm that you're working in the correct context.
    This is an interractive function by default. SkipContextCheck can be used if you plan to skip the check.
.PARAMETER SkipContextCheck
Specify this switch if you don't want to confirm the context.           
.NOTES
    AS IS - No Warranty
	Francois LEON
#>
    [CmdletBinding()]
    param(
        [switch]$SkipContextCheck
    )

    begin {
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN ] Starting Use-AZTBCorrectContext"
        Test-AZTBIsAzConnected
    }

    process {
        
        if (! $SkipContextCheck) {
            Write-Verbose "[$((Get-Date).TimeOfDay) Context ] Get current context"
            $title = ''
            $msg = "You are connected with the context $((Get-AzContext).name) is that OK to continue with? (default Yes)" 
            
            $yes = New-Object Management.Automation.Host.ChoiceDescription '&Yes'
            $no = New-Object Management.Automation.Host.ChoiceDescription '&No'
            $options = [Management.Automation.Host.ChoiceDescription[]]($yes, $no)
            $default = 0  # $yes
            
            do {
                $response = $Host.UI.PromptForChoice($title, $msg, $options, $default)
                if ($response -eq 1) {
                    Write-Verbose "[$((Get-Date).TimeOfDay) Context ] User want to change the context"
                    Write-Output ""
                    Write-Output "Here your available subscription(s):"
                    Write-Output "#####################################"
    
                    Get-AzSubscription -OutVariable AvailableSubs | Format-Table Name, Id -AutoSize
    
                    Write-Output "#####################################"
                    Write-Output ""
                    do {
                        $SubId = Read-host "Paste the Id of the subscription you want to connect on..."
                        #Test to control the read-host
                        $Test = $AvailableSubs | Where-Object { $_.Id -eq $SubId }
                    }
                    until ($($Test.count) -eq 1)
                    Write-Verbose "[$((Get-Date).TimeOfDay) Context ] New context has been chosen"
                    #Sub choice validated
                    Select-AzSubscription $SubId -ErrorAction Stop | Out-Null
                    Write-Output ""
                    Write-Output "Your new context is now set as: $((Get-AzContext).name)"
                    Write-Verbose "[$((Get-Date).TimeOfDay) Context ] Working now on the selected context"
                }
            } until (($response -eq 0) -or ($response -eq 1))
        } 
        else {
            Write-Verbose "[$((Get-Date).TimeOfDay) Context ] User want to skip context check"
        }
    }

    end {
        Write-Verbose "[$((Get-Date).TimeOfDay) END ] Ending Use-AZTBCorrectContext"
    }
}


try {
    #To avoid having warning message when subscription become unaccessible
    $WarningPreference = 'SilentlyContinue'
    $ErrorActionPreference = "Stop"

    # Load dependencies
    Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN ] Starting Manage-Blueprint Script"
    Write-Verbose "[$((Get-Date).TimeOfDay) Script ] Loading modules..."

    Import-Module Az.Accounts -verbose:$false
    Import-Module Az.Resources -verbose:$false
    Import-Module Az.Blueprint -verbose:$false

    Use-AZTBCorrectContext

    Write-Verbose "[$((Get-Date).TimeOfDay) Script ] Test Blueprint provider exist..."
    try {
        $null = Get-AzBlueprint -ManagementGroupId $ManagementGroupId -Name $BlueprintName -ErrorAction stop
    }
    catch {
        Write-Verbose "[$((Get-Date).TimeOfDay) Script ] Register Blueprint provider..."
        Register-AzResourceProvider -ProviderNamespace Microsoft.Blueprint 
        Write-Verbose "[$((Get-Date).TimeOfDay) Script ] Let's sleep 30 seconds until the provider is registred..."
        Start-sleep -Seconds 30
    }

    Write-Verbose "[$((Get-Date).TimeOfDay) Script ] Get latest Blueprint version"
    $LatestBpVersion = (Get-AzBlueprint -ManagementGroupId $ManagementGroupId -Name $BlueprintName).Versions | Sort-Object -Descending -Top 1
    Write-Verbose "[$((Get-Date).TimeOfDay) Script ] Get related Blueprint object"
    $BpObject = Get-AzBlueprint -ManagementGroupId $ManagementGroupId -Name $BlueprintName -Version $LatestBpVersion

    if ($update) {
        $splating = @{
            Name                 = "$Assignmentprefix-$SubscriptionID"
            Blueprint            = $BpObject
            SubscriptionId       = $SubscriptionID
            Location             = $Location
            UserAssignedIdentity = $UserMSIId
            Lock                 = $Lock
        }

        Write-Verbose "[$((Get-Date).TimeOfDay) Script ] Update assignment of an existing Blueprint..."
        Set-AzBlueprintAssignment @splating
    }
    else {
        $splating = @{
            Name                 = "$Assignmentprefix-$SubscriptionID"
            Blueprint            = $BpObject
            SubscriptionId       = $SubscriptionID
            Location             = $Location
            UserAssignedIdentity = $UserMSIId
            Lock                 = $Lock
        }
    
        Write-Verbose "[$((Get-Date).TimeOfDay) Script ] New Blueprint assignment..."
        New-AzBlueprintAssignment @splating
    }#Means new assignment


    try {
        
        #Start a timer
        $timer = [Diagnostics.Stopwatch]::StartNew()
        #Get an online server in Exchange farm before the timeout
        Do {
            $ProvisioningState = Get-AzBlueprintAssignment -Name "$Assignmentprefix-$SubscriptionID" -SubscriptionId $SubscriptionID
            if ($timer.Elapsed.TotalSeconds -ge $Timeout) {
                throw "Timeout exceeded."
            }
            Start-Sleep -Seconds 2
        }Until($ProvisioningState.ProvisioningState -eq 'Succeed')
        
    }
    catch {
        Write-Error "Unable to get Provisionning state of $("$Assignmentprefix-$SubscriptionID"), go check manually"
    }
    finally {
        if (Test-Path -Path Variable:\timer) {
            $timer.Stop()
        }
    }
}
catch {
    Throw $_
}
