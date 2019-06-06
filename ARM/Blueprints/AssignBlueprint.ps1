$blueprintObject = Get-AzBlueprint -ManagementGroupId 'MSDN' -Name 'Governance'
$SubscriptionID = (Get-AzContext).Subscription.Id
New-AzBlueprintAssignment -Name "Governance" -Blueprint $blueprintObject -SubscriptionId $SubscriptionID -Location "East US 2" -Lock AllResourcesDoNotDelete