$TemplateInfo = @{
    Name                  = 'DeployActivityLogs'
    Location              = 'eastus2'
    TemplateFile          = ".\azuredeploy.json"
    TemplateParameterFile = ".\azuredeploy.parameters.json"
}

New-AzDeployment @TemplateInfo -Verbose