Function Test-AZTBIsConnected { 
    <#
.SYNOPSIS
	Function who prompt credentials if you are not already connected.
.DESCRIPTION
	Function who prompt credentials if you are not already connected.                         
.NOTES
	Francois LEON
	https://scomnewbie.wordpress.com/
	github.com/ScomNewbie
#>
    try {
        Get-AzureRmSubscription | out-null
    }
    catch {
        Connect-AzureRmAccount | out-null
    }
}
