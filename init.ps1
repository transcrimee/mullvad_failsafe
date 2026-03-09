try {
    Write-Host "Restoring network access..." -ForegroundColor Cyan

    # 1. Reset the global outbound policy to 'Allow' (Default Windows behavior)
    Set-NetFirewallProfile -Profile Domain, Private, Public -DefaultOutboundAction Allow -ErrorAction Stop
    Write-Host "[OK] Global outbound policy set to Allow." -ForegroundColor Green

    # 2. Remove the specific allow rule created for Mullvad (if it exists)
    $ruleName = "Mullvad-Allow"
    if (Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue) {
        Remove-NetFirewallRule -DisplayName $ruleName
        Write-Host "[OK] Custom rule '$ruleName' removed." -ForegroundColor Green
    } else {
        Write-Host "[!] Custom rule '$ruleName' not found; skipping removal." -ForegroundColor Yellow
    }

    Write-Host "Internet access has been fully restored." -ForegroundColor White -BackgroundColor Blue
}
catch {
    Write-Error "Failed to restore network settings: $($_.Exception.Message)"
}
finally {
    Write-Host "Task complete."
}