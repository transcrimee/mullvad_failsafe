try {
    # 1. Resolve IPs (Stop if DNS fails)
    $ips = (Resolve-DnsName -Name "am.i.mullvad.net" -ErrorAction Stop).IPAddress
    
    # 2. Create the specific 'Allow' rule
    New-NetFirewallRule -DisplayName "Mullvad-Allow" -Direction Outbound -RemoteAddress $ips -Action Allow -ErrorAction Stop
    
    # 3. Engage the Kill Switch
    Set-NetFirewallProfile -Profile Domain, Private, Public -DefaultOutboundAction Block
    Write-Host "Failsafe Active: Only am.i.mullvad.net is accessible." -ForegroundColor Cyan
}
catch {
    Write-Error "Failsafe failed to engage safely: $($_.Exception.Message)"
    # Emergency Reset: Ensure we aren't stuck in a 'Block' state if the rules didn't apply right
    Set-NetFirewallProfile -Profile Domain, Private, Public -DefaultOutboundAction Allow
}
finally {
    Write-Host "Configuration attempt complete."
}