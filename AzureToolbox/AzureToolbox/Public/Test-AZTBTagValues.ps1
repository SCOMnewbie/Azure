Function Test-AZTBTagValues { 
    <#
.SYNOPSIS
	Function to validate Tag on a specific resource. This function return also the TAG list in correct syntax.
.DESCRIPTION
	Function to validate Tag on a specific resource. This function return also the TAG list in correct syntax.
.PARAMETER BillTo
    Specifies the name of the BillTo. This is a mandatory field based on a list of choices. All Management codes as to be pre-filled.
.PARAMETER Department
	Specifies the department. This is a mandatory field. Word in uppercase only between 4 and 11 characters without whitespace.
.PARAMETER Tier
    Specifies the tier. This is an mandatory field based on a list of choices.
.PARAMETER Environement
    Specifies the Environement. This is a mandatory field where you must have only a list of choices of your Environement.
.PARAMETER Owner
Specifies the Owner of the resource group. This is a mandatory field where you must specify a UPN.
.PARAMETER ApplicationName
    Specifies the applicationname. This is an optionnal field. The length should be between 4 and 20 characters with the first letter in Uppercase
    and the rest in lowercase without whitespace.
.EXAMPLE
	$params = @{
    'BillTo'='BillCode1'
	'Department'='TEST'
    'ApplicationName'='Myapps'
    'Environement'='PROD'
    'Tier'='Application Tier'
    'Owner'='francois.leon@company.com'
    }
    Test-AZTBTagValues @params
.EXAMPLE
    Test-AZTBTagValues -BillTo BillCode1 -Department TEST -Environement DEV -Tier 'Application Tier' -Owner francois.leon@company.com                             
.NOTES
	Francois LEON
	https://scomnewbie.wordpress.com/
	github.com/ScomNewbie
.LINK
	https://docs.microsoft.com/fr-fr/azure/architecture/cloud-adoption/appendix/azure-scaffold?toc=%2Fen-us%2Fazure%2Fazure-resource-manager%2Ftoc.json&bc=%2Fen-us%2Fazure%2Fbread%2Ftoc.json#resource-tags

    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName)] 
        [ValidateNotNullOrEmpty()]
        [ValidateSet("BillCode1", "BillCode2", IgnoreCase = $false)] 
        [String] 
        $BillTo 
        , 
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName)] 
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                if ( $((Get-Culture).TextInfo.ToUpper($_)) -cmatch '^[A-Z][A-Z0-9]{2,10}') {
                    $true
                }
                else {
                    throw 'Please provide a valid Department all in UpperCase and between 3 and 11 characters (ex TEAMX,FINANCE,RB6 )'
                }
            })] 
        [String]
        $Department  
        , 
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName)] 
        [ValidateNotNullOrEmpty()]
        [ValidateSet("PROD", "DEV", "UAT", IgnoreCase = $false)] 
        [string] 
        $Environement
        , 
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName)] 
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Web Tier", "Application Tier", "Database", IgnoreCase = $false)] 
        [string] 
        $Tier
        , 
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName)] 
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                #Not a perfect regex but will be OK because we will take the current UPN
                if ( $((Get-Culture).TextInfo.ToLower($_)) -match '^.+@.+\..+$') {
                    $true
                }
                else {
                    throw 'Please provide a valid address mail (UPN)'
                }
            })] 
        [String]
        $Owner
        , 
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]        
        [ValidateScript( {
                if ( $((Get-Culture).TextInfo.ToTitleCase($_)) -cmatch '^[A-Z][a-z0-9]{3,19}$') {
                    $true
                }
                else {
                    throw 'Please provide a valid application name. First letter UpperCase and the rest LowerCase. Between 4 and 20 characters (ex Myapp, Superapp )'
                }
            })] 
        [string] 
        $ApplicationName
    ) 
    Process { 

        $properties = @{
            'IsNamingvalid'   = $true
            'BillTo'          = $BillTo
            'Department'      = $((Get-Culture).TextInfo.ToUpper($Department))
            'Environement'    = $Environement
            'Tier'            = $Tier
            'Owner'           = $((Get-Culture).TextInfo.ToLower($Owner))
            'ApplicationName' = $((Get-Culture).TextInfo.ToTitleCase($ApplicationName))
        }
        New-Object -TypeName Psobject -Property $properties
        
    } 
}

