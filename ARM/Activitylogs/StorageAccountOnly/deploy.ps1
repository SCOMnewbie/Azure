
$TemplateInfo = @{
    Name               = 'DeployActivityLogs'
    Location           = 'eastus2'
    TemplateFile       = ".\azuredeploy.json"
    subscriptionId     = '<YourSubID>'
    resourcegroupname  = 'Test-DumpLogs'
    storageaccountname = 'testdumplogs'
}

New-AzDeployment @TemplateInfo -Verbose
