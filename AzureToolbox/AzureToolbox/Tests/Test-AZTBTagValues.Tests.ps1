<#
.Synopsis
    Pester test to verify the function Test-AZTBTagValues.
.Description
    Pester test to verify the function Test-AZTBTagValues.

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

Describe "Test-AZTBTagValues Function" {

    Context 'Function Output' {
        $params = @{
            'BillTo'          = 'billCode1'
            'Department'      = 'TEST'
            'ApplicationName' = 'Myapps'
            'Environement'    = 'PROD'
            'Tier'            = 'Application Tier'
            'Owner'           = 'francois.leon@company.com'
        }

        It 'Bad BillTo spelling should throw' {
            {Test-AZTBTagValues @params }|Should throw
        }

        $params = @{
            'BillTo'          = 'BillCode1'
            'Department'      = 'tEST'
            'ApplicationName' = 'Myapps'
            'Environement'    = 'PROD'
            'Tier'            = 'Application Tier'
            'Owner'           = 'francois.leon@company.com'
        }

        It 'Bad department spelling should throw' {
            {Test-AZTBTagValues @params }|Should throw
        }

        $params = @{
            'BillTo'          = 'BillCode1'
            'Department'      = 'TEST'
            'ApplicationName' = 'myapps'
            'Environement'    = 'PROD'
            'Tier'            = 'Application Tier'
            'Owner'           = 'francois.leon@company.com'
        }

        It 'Bad applicationName spelling should throw' {
            {Test-AZTBTagValues @params }|Should throw
        }

        $params = @{
            'BillTo'          = 'BillCode1'
            'Department'      = 'TEST'
            'ApplicationName' = 'Myapps'
            'Environement'    = 'ROD'
            'Tier'            = 'Application Tier'
            'Owner'           = 'francois.leon@company.com'
        }

        It 'Bad Environement spelling should throw' {
            {Test-AZTBTagValues @params }|Should throw
        }

        $params = @{
            'BillTo'          = 'BillCode1'
            'Department'      = 'TEST'
            'ApplicationName' = 'Myapps'
            'Environement'    = 'PROD'
            'Tier'            = 'Application'
            'Owner'           = 'francois.leon@company.com'
        }

        It 'Bad Tier spelling should throw' {
            {Test-AZTBTagValues @params }|Should throw
        }

        $params = @{
            'BillTo'          = 'BillCode1'
            'Department'      = 'TEST'
            'ApplicationName' = 'Myapps'
            'Environement'    = 'PROD'
            'Tier'            = 'Application Tier'
            'Owner'           = 'francois.leon@company'
        }

        It 'Bad Owner spelling should throw' {
            {Test-AZTBTagValues @params }|Should throw
        }

        $params = @{
            'BillTo'          = 'BillCode1'
            'Department'      = 'TEST'
            'ApplicationName' = 'Myapps'
            'Environement'    = 'PROD'
            'Tier'            = 'Application Tier'
            'Owner'           = 'francois.leon@company.com'
        }

        It 'GOOD spelling should Be OK' {
            $Test = (Test-AZTBTagValues @params).isvalid
            $Test|Should be true
        }
    }
}

