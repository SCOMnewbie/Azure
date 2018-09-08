Function Test-AZTBVMName { 
    <#
.SYNOPSIS
	Function to validate and return the name of a VM name 
.DESCRIPTION
    Function to validate and return the name of a VM name. A VM should always finish by -vmxx wher the xx is the number of the VM. The total length of the machine name has to be 15 where 6 digits are reserved.
    For now we have the same 15 limit characters for Linux machines too.
.PARAMETER Name
    Specify the name of the VM. A short name is strongly recomanded (<=5 characters). This is a mandatory field. The length should be between 3 and 6 characters with the first letter in Uppercase
    and the rest in lowercase without whitespace.
.PARAMETER Role
    Specify the role of the VM.A short description is strongly recomanded (<=4 characters) like sql,file,iis,apch,bck... This is a mandatory field. The length should be between 2 and 5 characters with all characters in lowercase without whitespace.
.PARAMETER RessourceGroup
    Specify the resource group where belongs la VM.
.EXAMPLE
$params = @{
'Name'='Profx'
'role'='bck'
'RessourceGroup' = 'MyRG'
}
Test-AZTBVMName @params
.EXAMPLE
    Test-AZTBVMName -Name Mysrv -role file -RessourceGroup MyRG                           
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
                if ( $_ -cmatch '^[A-Z][a-z]{1,5}') {
                    $true
                }
                else {
                    throw 'Please provide a shorter name or make sure the first letter is UpperCase and the rest LowerCase. Between 2 and 6 characters (ex Sr, Mysrv, Mail,... )'
                }
            })] 
        [string] 
        $Name
        , 
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName)] 
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                if ( $_ -cmatch '^[a-z]{2,4}') {
                    $true
                }
                else {
                    throw 'Please provide a shorter role and make sure that everything is in lowercase. Between 2 and 4 characters (ex sql,file,bck...)'
                }
            })] 
        [string] 
        $Role
        , 
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName)] 
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                if ( $(Get-AzureRmResourceGroup -Name $_) -ne $null) {
                    $true
                }
                else {
                    throw 'Please provide a valid resource group name'
                }
            })] 
        [string] 
        $ResourceGroupName
    ) 
    Process { 

        #At this moment, the resource Group is validated
        $VMNamefilter = "$Name-$role-vm*"
        Test-AZTBIsConnected
        $VMNames = get-azurermvm -ResourceGroupName $ResourceGroupName | Where-Object {$_.Name -like $VMNamefilter} | Select-Object -ExpandProperty name | Sort-Object
        
        if ($VMNames -ne $null) {
            #Means that there is already some VM like 01,02...
            $VMIndexes = @()
            Foreach ($VMName in $VMNames) {
                [int]$VMNameLength = $($VMName.length) - 2
                #A VM can be between 01 and 99
                $VMIndexes += $VMName.tostring().Substring($VMNameLength, 2)   
            }

            #$array = @(01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 14)
            if ($($VMIndexes.Length) -gt 99) {
                Write-error "Already 99 instances with this name not managed" -ea Stop
            }
            
            #Test if a previously VM has been deleted
            for ($i = 1; $i -le $VMIndexes.Length; $i++) { 
                if ($i -ne [int]$VMIndexes[$i - 1]) {
                    #Careful ordered 
                    $NextAvailableNameIs = $i
                    break
                }
            }

            #If no VM deleted, we just add 1 to the suit of VMs
            if ($NextAvailableNameIs -eq $null) {
                $NextAvailableNameIs = $($VMIndexes.Length) + 1
            }

            $NextAvailableNameIs = "{0:D2}" -f $NextAvailableNameIs
            
            $properties = @{
                'IsNamingvalid' = $true
                'VMName'        = "$Name-$role-vm$NextAvailableNameIs"
            }
            New-Object -TypeName Psobject -Property $properties
        }
        else {
            #Means that it will be the first vm
            $properties = @{
                'IsNamingvalid' = $true
                'VMName'        = "$Name-$role-vm01"
            }
            New-Object -TypeName Psobject -Property $properties

        }    
    } 
}
