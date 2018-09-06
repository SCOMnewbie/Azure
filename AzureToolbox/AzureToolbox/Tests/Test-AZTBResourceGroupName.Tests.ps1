<#
.Synopsis
    Pester test to verify the function Test-AZTBResourceGroupName.
.Description
    Pester test to verify the function Test-AZTBResourceGroupName.

#>
[CmdletBinding()]
PARAM(
    $ModuleName = "AzureToolbox"
)


# Make sure one or multiple versions of the module are note loaded
Get-Module -Name $ModuleName | remove-module

# Find the Manifest file
$ManifestFile = "$(Split-Path -Parent -Path (Split-Path -Parent -Path $MyInvocation.MyCommand.Definition))\$ModuleName.psd1"
$ModuleFile = "$(Split-Path -Parent -Path (Split-Path -Parent -Path $MyInvocation.MyCommand.Definition))\$ModuleName.psm1"

# Import the module and store the information about the module
Import-module -Name $ManifestFile -PassThru
Import-module -Name $ModuleFile -PassThru

Describe "Test-AZTBResourceGroupName Function" {

    Context 'Function Output' {
        $params = @{
            'ServiceShortName' = 'MyServiceName'
            'Environement'     = 'PROD'
        }

        It 'Bad ServiceShortName spelling should throw' {
            {Test-AZTBResourceGroupName @params }|Should throw
        }

        $params = @{
            'ServiceShortName' = 'MyServicename'
            'Environement'     = 'prod'
        }

        It 'Bad environment spelling should throw' {
            {Test-AZTBResourceGroupName @params }|Should throw
        }

        $params = @{
            'ServiceShortName' = 'Myservicename'
            'Environement'     = 'PROD'
        }

        It 'GOOD spelling should Be OK' {
            $Test = (Test-AZTBResourceGroupName @params).isvalidated
            $Test|Should be true
        }

        It 'Name should contain -rg' {
            $Test = (Test-AZTBResourceGroupName @params).ResourceGroupName
            $Test|Should belike "*-rg"
        }

    }
}

