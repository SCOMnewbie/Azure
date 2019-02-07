function Get-LocationList {
    
    az account list-locations --query "[].name" -o tsv
}


