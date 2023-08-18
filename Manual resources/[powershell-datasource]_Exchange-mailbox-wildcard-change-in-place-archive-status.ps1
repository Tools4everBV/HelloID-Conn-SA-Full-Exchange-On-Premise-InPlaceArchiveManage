<#----- Exchange On-Premises: Exchange-mailbox-change-primary-address-get-mailbox-----#>
# Connect to Exchange
try {
    $adminSecurePassword = ConvertTo-SecureString -String "$ExchangeAdminPassword" -AsPlainText -Force
    $adminCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ExchangeAdminUsername, $adminSecurePassword
    $sessionOption = New-PSSessionOption -SkipCACheck -SkipCNCheck #-SkipRevocationCheck
    $exchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $ExchangeConnectionUri -Credential $adminCredential -SessionOption $sessionOption -Authentication Kerberos -ErrorAction Stop #-AllowRedirection
    Write-Information "Successfully connected to Exchange using the URI [$ExchangeConnectionUri]"
} catch {
    Write-Information "Error connecting to Exchange using the URI [$exchangeConnectionUri]"
    Write-Information "Failed to connect to Exchange using the URI [$exchangeConnectionUri]"
    Write-Error "$($_.Exception.Message)"
    throw $_
}

try {
    $searchValue = $dataSource.searchMailbox
    $searchQuery = "*$searchValue*"
    $searchOUs = $ExchangeSearchOU

    if ([string]::IsNullOrWhiteSpace($searchValue)) {
        Write-Information "Geen Searchvalue"
        return
    } else {
        $ParamsGetMailbxox = @{
            OrganizationalUnit = $searchOUs
            Filter = "{Alias -like '$searchQuery' -or name -like '$searchQuery' -or displayname -like '$searchQuery'}"            
        }
        Write-Information "SearchQuery: $($ParamsGetMailbxox.Filter)"

        $mailBoxes = Invoke-Command -Session $exchangeSession -ScriptBlock {
            Param ($ParamsGetMailbxox)
            Get-Mailbox @ParamsGetMailbxox 
        } -ArgumentList $ParamsGetMailbxox | Select DisplayName, UserPrincipalName, DistinguishedName, Alias, ArchiveStatus, ArchiveGuid

        $mailboxes = $mailboxes | Sort-Object -Property DisplayName
        $resultCount = @($mailboxes).Count        
        Write-Information "Result count: $resultCount"

        if ($resultCount -gt 0) {
            foreach ($mailbox in $mailboxes) {
                $archiveStatus = 'Enabled'
                if($mailbox.ArchiveGuid -eq '00000000-0000-0000-0000-000000000000'){
                    $archiveStatus = 'Disabled'
                }
                $returnObject = @{DisplayName = $mailbox.DisplayName; UserPrincipalName = $mailbox.UserPrincipalName; Alias = $mailbox.Alias; DistinguishedName = $mailbox.DistinguishedName ; Archive= $archiveStatus }
                Write-Output $returnObject
            }
        }
    }
} catch {
    Write-Error "Error searching AD user [$searchValue]. Error: $($_.Exception.Message)"
}

# Disconnect from Exchange
try {
    Remove-PSSession -Session $exchangeSession -Confirm:$false -ErrorAction Stop
    Write-Information "Successfully disconnected from Exchange"
} catch {
    Write-Error "Error disconnecting from Exchange"
    Write-Error "$($_.Exception.Message)"
    throw $_
}
<#----- Exchange On-Premises: End -----#>


