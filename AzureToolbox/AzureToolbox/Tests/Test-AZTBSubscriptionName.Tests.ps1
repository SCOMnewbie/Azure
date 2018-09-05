<#
.Synopsis
    Pester test to verify the function Test-AZTBSubscriptionName.
.Description
    Pester test to verify the function Test-AZTBSubscriptionName.

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

Describe "Test-AZTBSubscriptionName Function" {

    Context 'Function Output' {
        $params = @{
            'CompanyName'     = 'company';
            'Department'      = 'rB6';
            'ApplicationName' = 'Myapps';
            'Environement'    = 'PROD'
        }

        It 'Bad company spelling should throw' {
            {Test-AZTBSubscriptionName @params }|Should throw
        }

        $params = @{
            'CompanyName'     = 'Company';
            'Department'      = 'rB6';
            'ApplicationName' = 'Myapps';
            'Environement'    = 'PROD'
        }

        It 'Bad department spelling should throw' {
            {Test-AZTBSubscriptionName @params }|Should throw
        }

        $params = @{
            'CompanyName'     = 'Company';
            'Department'      = 'RB6';
            'ApplicationName' = 'myapps';
            'Environement'    = 'PROD'
        }

        It 'Bad applicationName spelling should throw' {
            {Test-AZTBSubscriptionName @params }|Should throw
        }

        $params = @{
            'CompanyName'     = 'Company';
            'Department'      = 'RB6';
            'ApplicationName' = 'myapps';
            'Environement'    = 'PRO'
        }

        It 'Bad Environament spelling should throw' {
            {Test-AZTBSubscriptionName @params }|Should throw
        }

        $params = @{
            'CompanyName'     = 'Company';
            'Department'      = 'RB6';
            'ApplicationName' = 'Myapps';
            'Environement'    = 'PROD'
        }

        It 'GOOD spelling should Be OK' {
            $Test = Test-AZTBSubscriptionName @params
            $Test|Should be true
        }
    }
}

