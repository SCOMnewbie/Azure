<#
.SYNOPSIS
Script to detect within a list of subscriptions if a specific user has specific role granted with direct access or through group membership.
.DESCRIPTION
Script to detect within a list of subscriptions if a specific user has specific role granted with direct access or through group membership.
WARNING: Make sure your conected to the right tenant and you have read access ot the subcription.
.PARAMETER Usertofind
Specify the email address to find
.PARAMETER Subscriptions
Specify the List of subscriptions you want to browse
.PARAMETER Role
Specify the RBAC role you're looking for like Owner, Contributor, ..
.PARAMETER TenantId
Specify the tenantId
.EXAMPLE

$Subscriptions = @(
    "<subId 1>",
    "<subId 2>",
    "<subId 3>",
)

$Usertofind = 'myuser@mydomain.com'

.\Detect-RBACAssignment.ps1 -Subscriptions $Subscriptions -Usertofind $Usertofind -role Owner -TenantId <DirectoryId>

.NOTES
NO WARRANTY AS IS
VERSION HISTORY
1.0 | 2020/07/08 | Francois LEON
    initial version
POSSIBLE IMPROVEMENT
    Add an array of users to track
#>

[cmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [string] $Usertofind,
    [Parameter(Mandatory = $true)]
    [guid[]] $Subscriptions,
    [Parameter(Mandatory = $true)]
    [string] $Role,
    [Parameter(Mandatory = $true)]
    [guid]$TenantId

)

#$VerbosePreference = 'Continue'
$ErrorActionPreference = 'Stop'

Import-Module Az.Accounts -verbose:$false
Import-Module Az.Resources -verbose:$false

$AzureUsersNotFiltered = @()
#We don't want service principal, MSI account, ...
$InterrestingAssignments = @("User", "Group")

foreach ($Subscription in $Subscriptions) {
    Write-host "working on subscription $Subscription" -ForegroundColor Cyan
    $null = Select-AzSubscription -Subscription $Subscription -Tenant $TenantId
    $Assignments = Get-AzRoleAssignment -RoleDefinitionName $Role | Where-Object { $_.ObjectType -in $InterrestingAssignments }

    Foreach ($Assignment in $Assignments) {
        switch ($Assignment.ObjectType) {
            "User" {
                Write-Verbose "      User detected, add $($Assignment.SignInName) to AzureUsersNotFiltered array"
                if ($($Assignment.SignInName) -eq $Usertofind) {
                    Write-Host "   found!" -BackgroundColor Magenta
                }
                $AzureUsersNotFiltered += $Assignment.SignInName
                break
            }
            "Group" {
                $Groupmembers = Get-AzADGroupMember -GroupObjectId $Assignment.ObjectId
                if ($Groupmembers.count -gt 0) {
                    Write-Verbose "      Group detected, $($Groupmembers.count) users will be added to AzureUsersNotFiltered array"
                    $Groupmembers | Foreach-object { $AzureUsersNotFiltered += $_.UserPrincipalName ; if ($_.UserPrincipalName -eq $Usertofind) { Write-host "    Found in $($Assignment.DisplayName)" -BackgroundColor Magenta } }
                }
                else {
                    Write-Verbose "Group $($Assignment.DisplayName) is empty" 
                }
            }
        }
    }
}