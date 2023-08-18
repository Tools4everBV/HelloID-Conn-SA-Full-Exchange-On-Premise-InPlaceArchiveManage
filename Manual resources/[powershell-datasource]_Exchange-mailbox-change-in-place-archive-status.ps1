    $status = $false
    if($datasource.selectedmailbox.Archive -eq "Enabled") {
        $status = $true
    }
    $returnObject = [Ordered]@{
        enabled = $status 
    }    
    Write-Output $returnObject   

