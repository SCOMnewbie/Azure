<#
.Synopsis
    Pester test to verify the content of the manifest and the documentation of each functions.
.Description
    Pester test to verify the content of the manifest and the documentation of each functions.
.NOTES
Thank you lazywinadmin, I've simply copy/paste your pester tests as a starting point.
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
$ManifestInformation = Import-module -Name $ManifestFile -PassThru
$ModuleInformation = Import-module -Name $ModuleFile -PassThru
#Is there an online module with higher version?
$AzureRMCompare = $((Compare-module -name AzureRM).UpdateNeeded)
# Get the functions present in the Manifest
$ExportedFunctions = $ModuleInformation.ExportedFunctions.Values.name
# Get the functions present in the Public folder
$PS1Functions = Get-ChildItem -path "$(Split-Path -Parent -Path (Split-Path -Parent -Path $MyInvocation.MyCommand.Definition))\public\*.ps1"

Describe "$ModuleName Module - Basic testing" {

    Context 'Module Version' {
        It 'AzureRM module Should be up to date' {$AzureRMCompare|Should be false}
    }
    Context 'Manifest' {
        It 'Should contains Author' {$ManifestInformation.Author|Should not BeNullOrEmpty}
        It 'Should contains Company Name' {$ManifestInformation.CompanyName|Should not BeNullOrEmpty}
        It 'Should contains Description' {$ManifestInformation.Description|Should not BeNullOrEmpty}
        It 'Should contains Copyright' {$ManifestInformation.Copyright|Should not BeNullOrEmpty}

        It 'Should have equal number of Function Exported and the PS1 files found' {
            $ExportedFunctions.count -eq $PS1Functions.count |Should BeGreaterthan 0}
        It "Compare the missing function" {
            if (-not($ExportedFunctions.count -eq $PS1Functions.count)) {
                $Compare = Compare-Object -ReferenceObject $ExportedFunctions -DifferenceObject $PS1Functions.basename
                $Compare.inputobject -join ',' |
                    Should BeNullOrEmpty
            }
        }
    }
}


# Testing the Module
Describe "$ModuleName Module - Help testing" {
    #$Commands = (get-command -Module ADSIPS).Name

    $ModuleExceptions = @("Compare-module")
    FOREACH ($c in $ExportedFunctions) {
        if ($c -notin $ModuleExceptions) {
            $Help = Get-Help -Name $c -Full
            $Notes = ($Help.alertSet.alert.text -split '\n')
            $FunctionContent = Get-Content function:$c
            $AST = [System.Management.Automation.Language.Parser]::ParseInput($FunctionContent, [ref]$null, [ref]$null)

            Context "$c - Help" {

                It "Synopsis" {$help.Synopsis| Should not BeNullOrEmpty}
                It "Description" {$help.Description| Should not BeNullOrEmpty}
                It "Notes - Author" {$Notes[0].trim()| Should Be "Francois LEON"}
                It "Notes - Site" {$Notes[1].trim()| Should Be "https://scomnewbie.wordpress.com/"}
                It "Notes - Github" {$Notes[2].trim() | Should Be "github.com/ScomNewbie"}

                #  minus the RiskMitigationParameters
                $RiskMitigationParameters = 'Whatif', 'Confirm'
                $HelpParameters = $help.parameters.parameter | Where-Object name -NotIn $RiskMitigationParameters

                # Parameters Description
                $HelpParameters| ForEach-Object {
                    It "Parameter $($_.Name) - Should contains description" {
                        $_.description | Should not BeNullOrEmpty
                    }
                }

                # Parameters separated by a space
                $ParamText = $ast.ParamBlock.extent.text -split '\r\n' # split on return
                $ParamText = $ParamText.trim()
                $ParamTextSeparator = $ParamText |select-string ',$' #line that finish by a ','

                if ($ParamTextSeparator) {
                    Foreach ($ParamLine in $ParamTextSeparator.linenumber) {
                        it "Parameter - Separated by space (Line $ParamLine)" {
                            #$ParamText[$ParamLine] -match '\s+' | Should Be $true
                            $ParamText[$ParamLine] -match '^$|\s+' | Should Be $true
                        }
                    }
                }
                    
                # Examples
                it "Example - Count should be greater than 0" {
                    $Help.examples.example.code.count | Should BeGreaterthan 0
                    $Help.examples | Should not BeNullOrEmpty
                }
            }
        }
    }
}