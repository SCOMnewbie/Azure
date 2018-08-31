Function Test-AZTBSubscriptionName { 
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)] 
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Ubisoft", "Longtail", "Guillemot", IgnoreCase = $false)] 
        [String] 
        $CompanyName 
        , 
        [Parameter(Mandatory = $true)] 
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            if( $_ -cmatch '^[A-Z][A-Z0-9]{2,10}')
            {
                $true
            }
            else
            {
                throw 'Please provide a valid Department all in UpperCase and between 3 and 11 characters (ex GNE,FINANCE,RB6 )'
            }
        })] 
        [String]
        $Department 
        , 
        [ValidateScript({
            if( $_ -cmatch '^[A-Z][a-z0-9]{3,19}')
            {
                $true
            }
            else
            {
                throw 'Please provide a valid ApplicationName. First letter UpperCase and the rest LowerCase. Between 4 and 20 characters (ex Myapp, Superapp )'
            }
        })] 
        [string] 
        $ApplicationName
        , 
        [Parameter(Mandatory=$true)] 
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