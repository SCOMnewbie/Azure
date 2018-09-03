Function Test-AZTBSubscriptionName { 
    <#
.SYNOPSIS
	Function to validate Subscription Name
.DESCRIPTION
	Function to validate Subscription Name
.PARAMETER CompanyName
    Specifies the name of the company. This is a mandatory field where you must have only a list of choices of your companies.
.PARAMETER Department
	Specifies the department. This is a mandatory field. Word in uppercase only between 4 and 11 characters without whitespace.
.PARAMETER ApplicationName
    Specifies the applicationname. This is an optionnal field. The length should be between 4 and 20 characters with the first letter in Uppercase
    and the rest in lowercase without whitespace.
.PARAMETER Environement
Specifies the Environement. This is a mandatory field where you must have only a list of choices of your Environement.
.EXAMPLE
	$params = @{
    'CompanyName'='Company';
	'Department'='RB6';
    'ApplicationName'='Myapps';
    'Environement'='PROD'
    }
    Test-AZTBSubscriptionName @params
.EXAMPLE
    Test-AZTBSubscriptionName -CompanyName 'Subcompany' -Deparment 'TEAMX' -Environement 'DEV'                              
.NOTES
	Francois LEON
	https://scomnewbie.wordpress.com/
	github.com/ScomNewbie
.LINK
	https://docs.microsoft.com/en-us/azure/architecture/best-practices/naming-conventions#naming-subscriptions
#>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName)] 
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Company", "Subcompany", IgnoreCase = $false)] 
        [String] 
        $CompanyName 
        , 
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName)] 
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                if ( $_ -cmatch '^[A-Z][A-Z0-9]{2,10}') {
                    $true
                }
                else {
                    throw 'Please provide a valid Department all in UpperCase and between 3 and 11 characters (ex TEAMX,FINANCE,RB6 )'
                }
            })] 
        [String]
        $Department 
        , 
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName)] 
        [ValidateScript( {
                if ( $_ -cmatch '^[A-Z][a-z0-9]{3,19}') {
                    $true
                }
                else {
                    throw 'Please provide a valid ApplicationName. First letter UpperCase and the rest LowerCase. Between 4 and 20 characters (ex Myapp, Superapp )'
                }
            })] 
        [string] 
        $ApplicationName
        , 
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName)] 
        [ValidateNotNullOrEmpty()]
        [ValidateSet("PROD", "DEV", "UAT", IgnoreCase = $false)] 
        [string] 
        $Environement
    ) 
    Process { 
        Write-Verbose "Start validate subscriptionName"
        $true
        Write-Verbose "End validate subscriptionName"
    } 
}

<#
$params = @{
    'CompanyName'='Company';
	'Department'='rB6';
    'ApplicationName'='Myapps';
    'Environement'='PROD'
}
Test-AZTBSubscriptionName @params
#>