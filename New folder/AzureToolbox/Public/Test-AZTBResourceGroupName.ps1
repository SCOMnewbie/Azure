Function Test-AZTBResourceGroupName { 
    <#
.SYNOPSIS
	Function to validate and output the resource group name 
.DESCRIPTION
	Function to validate and output the resource group name. A resource group must always finish with -rg
.PARAMETER ServiceShortName
    Specifies the name of the Service name in a short version. This is a mandatory field. The length should be between 4 and 20 characters with the first letter in Uppercase
    and the rest in lowercase without whitespace.
.PARAMETER Environment
    Specifies the Environement. This is a mandatory field where you must have only a list of choices of your Environement.
.EXAMPLE
	$params = @{
    'ServiceShortName'='Myservicename'
    'Environement'='PROD'
    }
    Test-AZTBResourceGroupName @params
.EXAMPLE
    Test-AZTBResourceGroupName -ServiceShortName Myservicename -Environement DEV                             
.NOTES
	Francois LEON
	https://scomnewbie.wordpress.com/
	github.com/ScomNewbie
.LINK
	https://docs.microsoft.com/en-us/azure/architecture/best-practices/naming-conventions

    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName)] 
        [ValidateNotNullOrEmpty()]
        [ValidateSet("PROD", "DEV", "UAT")] 
        [string] 
        $Environment
        , 
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName)] 
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                if ( $((Get-Culture).TextInfo.ToTitleCase($_)) -cmatch '^[A-Z][a-z0-9]{3,19}$') {
                    $true
                }
                else {
                    throw 'Please provide a valid service short name. First letter UpperCase and the rest LowerCase. Between 4 and 20 characters (ex Myservice, Superapp )'
                }
            })] 
        [string] 
        $ServiceShortName
    ) 
    Process { 

        $ServiceShortName = $((Get-Culture).TextInfo.ToTitleCase($ServiceShortName))
        $Environment = $Environment.ToLower()
        $ResourceGroupName = "$ServiceShortName-$Environment-rg"
        $properties = @{
            'IsNamingvalid'     = $true
            'ResourceGroupName' = $ResourceGroupName
        }
        New-Object -TypeName Psobject -Property $properties
        
    } 
}