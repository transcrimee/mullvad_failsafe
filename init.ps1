try {
    # 0. Check for Admin Privileges immediately
    if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Error "Access Denied: Please run this script as Administrator."
        return
    }

    Write-Host "Restoring network access..." -ForegroundColor Cyan

    # 1. Reset the global outbound policy to 'Allow'
    Set-NetFirewallProfile -Profile Domain, Private, Public -DefaultOutboundAction Allow -ErrorAction Stop
    Write-Host "[OK] Global outbound policy set to Allow." -ForegroundColor Green

    # 2. Remove the specific Mullvad allow rule
    $ruleName = "Mullvad-Allow"
    if (Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue) {
        Remove-NetFirewallRule -DisplayName $ruleName -ErrorAction Stop
        Write-Host "[OK] Custom rule '$ruleName' removed." -ForegroundColor Green
    } else {
        Write-Host "[!] Custom rule '$ruleName' not found; skipping removal." -ForegroundColor Yellow
    }

    # 3. Clear DNS Cache
    # This fixes the "getaddrinfo failed" errors your Python script was seeing
    Clear-DnsClientCache
    Write-Host "[OK] DNS cache flushed." -ForegroundColor Green

    Write-Host "`nInternet access has been fully restored." -ForegroundColor White -BackgroundColor Blue
}
catch {
    Write-Error "Failed to restore network settings: $($_.Exception.Message)"
}
finally {
    Write-Host "Task complete."
}
