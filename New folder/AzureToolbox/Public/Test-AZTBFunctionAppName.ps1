Function Test-AZTBFunctionAppName { 
    <#
.SYNOPSIS
	Function to validate and output the function app name 
.DESCRIPTION
	Function to validate and output the function app name. A function name must finish with -func
.PARAMETER FunctionShortName
    Specifies the name of the function name in a short version. This is a mandatory field. The length should be between 4 and 20 characters with the first letter in Uppercase
    and the rest in lowercase without whitespace.
.EXAMPLE
	$params = @{
    'FunctionShortName'='Myservicename'
    }
    Test-AZTBFunctionAppName @params
.EXAMPLE
    Test-AZTBFunctionAppName -FunctionShortName MyFunctionname                             
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
        [ValidateScript( {
                if ( $((Get-Culture).TextInfo.ToTitleCase($_)) -cmatch '^[A-Z][a-z0-9]{3,19}$') {
                    $true
                }
                else {
                    throw 'Please provide a valid service short name. First letter UpperCase and the rest LowerCase. Between 4 and 20 characters (ex Myservice, Superapp )'
                }
            })] 
        [string] 
        $FunctionShortName
    ) 
    Process { 

        $FunctionShortName = $((Get-Culture).TextInfo.ToTitleCase($FunctionShortName))
        $FunctionOutput = "$FunctionShortName-func"
        $properties = @{
            'IsNamingvalid' = $true
            'FunctionName'  = $FunctionOutput
        }
        New-Object -TypeName Psobject -Property $properties  
    } 
}

Test-AZTBFunctionAppName -FunctionShortName 'fdsfsdFSDFSfsdf'