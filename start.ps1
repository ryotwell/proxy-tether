# Proxy Tether - Windows PowerShell Version

$HTTP_PORT = 7890
$SOCKS_PORT = 7891

Write-Host "Masukkan IP Address (tekan enter untuk default: 127.0.0.1):"
$input_ip = Read-Host
if ([string]::IsNullOrWhiteSpace($input_ip)) {
    $IP = "127.0.0.1"
} else {
    $IP = $input_ip
}

function Set-Proxy {
    param($IP, $HTTP_PORT)

    $proxyServer = "$IP`:$HTTP_PORT"
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"

    Set-ItemProperty -Path $regPath -Name ProxyServer -Value $proxyServer
    Set-ItemProperty -Path $regPath -Name ProxyEnable -Value 1

    # Set system-wide environment variables for CLI tools
    [System.Environment]::SetEnvironmentVariable("HTTP_PROXY",  "http://$proxyServer", "User")
    [System.Environment]::SetEnvironmentVariable("HTTPS_PROXY", "http://$proxyServer", "User")
    [System.Environment]::SetEnvironmentVariable("ALL_PROXY",   "socks5://$IP`:$SOCKS_PORT", "User")

    # Apply in current session as well
    $env:HTTP_PROXY  = "http://$proxyServer"
    $env:HTTPS_PROXY = "http://$proxyServer"
    $env:ALL_PROXY   = "socks5://$IP`:$SOCKS_PORT"

    Write-Host "✅ Proxy berhasil diaktifkan ke $IP"
}

function Unset-Proxy {
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"

    Set-ItemProperty -Path $regPath -Name ProxyEnable -Value 0
    Set-ItemProperty -Path $regPath -Name ProxyServer  -Value ""

    [System.Environment]::SetEnvironmentVariable("HTTP_PROXY",  $null, "User")
    [System.Environment]::SetEnvironmentVariable("HTTPS_PROXY", $null, "User")
    [System.Environment]::SetEnvironmentVariable("ALL_PROXY",   $null, "User")

    $env:HTTP_PROXY  = $null
    $env:HTTPS_PROXY = $null
    $env:ALL_PROXY   = $null

    Write-Host "✅ Proxy berhasil dimatikan"
}

while ($true) {
    Write-Host ""
    Write-Host "============================="
    Write-Host "       MENU PROXY Wi-Fi      "
    Write-Host " IP Saat Ini: $IP            "
    Write-Host "============================="
    Write-Host "1. Set Proxy"
    Write-Host "2. Unset Proxy"
    Write-Host "3. Keluar"
    Write-Host "============================="
    $menu = Read-Host "Pilih menu (1-3)"

    switch ($menu) {
        "1" { Set-Proxy -IP $IP -HTTP_PORT $HTTP_PORT }
        "2" { Unset-Proxy }
        "3" {
            Write-Host "Keluar dari program..."
            exit 0
        }
        default {
            Write-Host "❌ Pilihan tidak valid."
        }
    }
}
