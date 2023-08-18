$VerbosePreference = "SilentlyContinue"
$InformationPreference = "Continue"
$WarningPreference = "Continue"

# variables configured in form
$UserPrincipalName = $form.gridmailbox.Userprincipalname
$InPlaceArchive = $form.checkboxArchive

# Connect to Exchange
try {
    $adminSecurePassword = ConvertTo-SecureString -String "$ExchangeAdminPassword" -AsPlainText -Force
    $adminCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ExchangeAdminUsername, $adminSecurePassword
    $sessionOption = New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck
    $exchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $exchangeConnectionUri -Credential $adminCredential -SessionOption $sessionOption -ErrorAction Stop 
    #-AllowRedirection
    $session = Import-PSSession $exchangeSession -DisableNameChecking -AllowClobber
    Write-Information "Successfully connected to Exchange using the URI [$exchangeConnectionUri]" 
    
    $Log = @{
        Action            = "UpdateAccount" # optional. ENUM (undefined = default) 
        System            = "Exchange On-Premise" # optional (free format text) 
        Message           = "Successfully connected to Exchange using the URI [$exchangeConnectionUri]" # required (free format text) 
        IsError           = $false # optional. Elastic reporting purposes only. (default = $false. $true = Executed action returned an error) 
        TargetDisplayName = $exchangeConnectionUri # optional (free format text) 
        TargetIdentifier  = $([string]$session.GUID) # optional (free format text) 
    }
    #send result back  
    Write-Information -Tags "Audit" -MessageData $log
}
catch {
    Write-Error "Error connecting to Exchange using the URI [$exchangeConnectionUri]. Error: $($_.Exception.Message)"
    $Log = @{
        Action            = "UpdateAccount" # optional. ENUM (undefined = default) 
        System            = "Exchange On-Premise" # optional (free format text) 
        Message           = "Failed to connect to Exchange using the URI [$exchangeConnectionUri]." # required (free format text) 
        IsError           = $true # optional. Elastic reporting purposes only. (default = $false. $true = Executed action returned an error) 
        TargetDisplayName = $exchangeConnectionUri # optional (free format text) 
        TargetIdentifier  = $([string]$session.GUID) # optional (free format text) 
    }
    #send result back  
    Write-Information -Tags "Audit" -MessageData $log
}

$ParamsGetMailbox = @{
    Identity = $UserPrincipalName
}
$mailBox = Invoke-Command -Session $exchangeSession -ErrorAction Stop -ScriptBlock {
    Param ($ParamsGetMailbox)
    Get-Mailbox @ParamsGetMailbox
} -ArgumentList $ParamsGetMailbox


if ($InPlaceArchive -eq 'true') {     
    try {
        $ParamsSetMailbox = @{
            Identity = $($mailbox.DistinguishedName)
        }
        $null = Invoke-Command -Session $exchangeSession -ErrorAction Stop -ScriptBlock {
            Param ($ParamsSetMailbox)
            Enable-Mailbox @ParamsSetMailbox -Archive
        } -ArgumentList $ParamsSetMailbox
        

        Write-Information "Successfully set In-Place Archive for mailbox [$UserPrincipalName]"
        $Log = @{
            Action            = "UpdateAccount" # optional. ENUM (undefined = default) 
            System            = "Exchange On-Premise" # optional (free format text) 
            Message           = "Successfully set In-Place Archive for mailbox [$UserPrincipalName]." # required (free format text) 
            IsError           = $false # optional. Elastic reporting purposes only. (default = $false. $true = Executed action returned an error) 
            TargetDisplayName = $UserPrincipalName # optional (free format text) 
            TargetIdentifier  = $([string]$mailBox.GUID) # optional (free format text) 
        }
        #send result back  
        Write-Information -Tags "Audit" -MessageData $log 
    }
    catch {
        Write-Error "Failed to set In-Place Archive for mailbox [$UserPrincipalName].  Error: $($_.Exception.Message)"
        $Log = @{
            Action            = "UpdateAccount" # optional. ENUM (undefined = default) 
            System            = "Exchange On-Premise" # optional (free format text) 
            Message           = "Failed to set In-Place Archive for mailbox [$UserPrincipalName]." # required (free format text) 
            IsError           = $true # optional. Elastic reporting purposes only. (default = $false. $true = Executed action returned an error) 
            TargetDisplayName = $UserPrincipalName # optional (free format text) 
            TargetIdentifier  = $([string]$mailBox.GUID) # optional (free format text) 
        }
        #send result back  
        Write-Information -Tags "Audit" -MessageData $log
    }  
}

if ($InPlaceArchive -eq 'false') {
    try {
        $ParamsSetMailbox = @{
            Identity = $($mailbox.DistinguishedName)
        }
        $null = Invoke-Command -Session $exchangeSession -ErrorAction Stop -ScriptBlock {
            Param ($ParamsSetMailbox)
            Disable-Mailbox @ParamsSetMailbox -Archive -Confirm:$false
        } -ArgumentList $ParamsSetMailbox

        Write-Information "Successfully disabled In-Place Archive for mailbox [$UserPrincipalName]"
        $Log = @{
            Action            = "UpdateAccount" # optional. ENUM (undefined = default) 
            System            = "Exchange On-Premise" # optional (free format text) 
            Message           = "Successfully disabled In-Place Archive for mailbox [$UserPrincipalName]." # required (free format text) 
            IsError           = $false # optional. Elastic reporting purposes only. (default = $false. $true = Executed action returned an error) 
            TargetDisplayName = $UserPrincipalName # optional (free format text) 
            TargetIdentifier  = $([string]$mailBox.GUID) # optional (free format text) 
        }
        #send result back  
        Write-Information -Tags "Audit" -MessageData $log  
    }
    catch {
         Write-Error "Failed to disable In-Place Archive for mailbox [$UserPrincipalName].  Error: $($_.Exception.Message)"
        $Log = @{
            Action            = "UpdateAccount" # optional. ENUM (undefined = default) 
            System            = "Exchange On-Premise" # optional (free format text) 
            Message           = "Failed to disable In-Place Archive for mailbox [$UserPrincipalName]." # required (free format text) 
            IsError           = $true # optional. Elastic reporting purposes only. (default = $false. $true = Executed action returned an error) 
            TargetDisplayName = $UserPrincipalName # optional (free format text) 
            TargetIdentifier  = $([string]$mailBox.GUID) # optional (free format text) 
        }
        #send result back  
        Write-Information -Tags "Audit" -MessageData $log
    }  
}

# Disconnect from Exchange
try {
    Remove-PsSession -Session $exchangeSession -Confirm:$false -ErrorAction Stop
    Write-Information "Successfully disconnected from Exchange using the URI [$exchangeConnectionUri]"     
    $Log = @{
        Action            = "UpdateAccount" # optional. ENUM (undefined = default) 
        System            = "Exchange On-Premise" # optional (free format text) 
        Message           = "Successfully disconnected from Exchange using the URI [$exchangeConnectionUri]" # required (free format text) 
        IsError           = $false # optional. Elastic reporting purposes only. (default = $false. $true = Executed action returned an error) 
        TargetDisplayName = $exchangeConnectionUri # optional (free format text) 
        TargetIdentifier  = $([string]$session.GUID) # optional (free format text) 
    }
    #send result back  
    Write-Information -Tags "Audit" -MessageData $log
}
catch {
    Write-Error "Error disconnecting from Exchange.  Error: $($_.Exception.Message)"
    $Log = @{
        Action            = "UpdateAccount" # optional. ENUM (undefined = default) 
        System            = "Exchange On-Premise" # optional (free format text) 
        Message           = "Failed to disconnect from Exchange using the URI [$exchangeConnectionUri]." # required (free format text) 
        IsError           = $true # optional. Elastic reporting purposes only. (default = $false. $true = Executed action returned an error) 
        TargetDisplayName = $exchangeConnectionUri # optional (free format text) 
        TargetIdentifier  = $([string]$session.GUID) # optional (free format text) 
    }
    #send result back  
    Write-Information -Tags "Audit" -MessageData $log
}
<#----- Exchange On-Premises: End -----#>
