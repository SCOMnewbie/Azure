<#
.Synopsis
    Pester test to verify the function Test-AZTBAvailabilitySetName.
.Description
    Pester test to verify the function Test-AZTBAvailabilitySetName.

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

Describe "Test-AZTBAvailabilitySetName Function" {

    Context 'Function Output' {
        $params = @{
            'ServiceShortName' = 'My Service Name'
            'Environment'      = 'PROD'
        }

        It 'Bad ServiceShortName spelling should throw' {
            {Test-AZTBAvailabilitySetName @params }|Should throw
        }

        $params = @{
            'ServiceShortName' = 'MyServicename'
            'Environment'      = 'd e v'
        }

        It 'Bad environment spelling should throw' {
            {Test-AZTBAvailabilitySetName @params }|Should throw
        }

        $params = @{
            'ServiceShortName' = 'MyservICEname'
            'Environment'      = 'ProD'
        }

        It 'GOOD spelling should Be OK' {
            $Test = (Test-AZTBAvailabilitySetName @params).isNamingvalid
            $Test|Should be true
        }

        It 'Name should contain -as' {
            $Test = (Test-AZTBAvailabilitySetName @params).AvailabilitySetName
            $Test|Should beExactly "Myservicename-prod-as"
        }

    }
}
