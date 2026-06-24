# Proxy Tether - Windows PowerShell (Full System)
# Jalankan sebagai Administrator untuk efek penuh (WinHTTP + Machine env vars)

$HTTP_PORT = 7890
$SOCKS_PORT = 7891

Write-Host "Masukkan IP Address (tekan enter untuk default: 127.0.0.1):"
$input_ip = Read-Host
if ([string]::IsNullOrWhiteSpace($input_ip)) {
    $IP = "127.0.0.1"
} else {
    $IP = $input_ip
}

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

function Set-ProxyEnvVars {
    param($proxyHttp, $proxySocks, [string]$Scope)
    [System.Environment]::SetEnvironmentVariable("HTTP_PROXY",  $proxyHttp,  $Scope)
    [System.Environment]::SetEnvironmentVariable("HTTPS_PROXY", $proxyHttp,  $Scope)
    [System.Environment]::SetEnvironmentVariable("ALL_PROXY",   $proxySocks, $Scope)
    [System.Environment]::SetEnvironmentVariable("http_proxy",  $proxyHttp,  $Scope)
    [System.Environment]::SetEnvironmentVariable("https_proxy", $proxyHttp,  $Scope)
    [System.Environment]::SetEnvironmentVariable("all_proxy",   $proxySocks, $Scope)
    [System.Environment]::SetEnvironmentVariable("NO_PROXY",    "localhost,127.0.0.1,::1", $Scope)
    [System.Environment]::SetEnvironmentVariable("no_proxy",    "localhost,127.0.0.1,::1", $Scope)
}

function Unset-ProxyEnvVars {
    param([string]$Scope)
    foreach ($var in @("HTTP_PROXY","HTTPS_PROXY","ALL_PROXY","http_proxy","https_proxy","all_proxy","NO_PROXY","no_proxy")) {
        [System.Environment]::SetEnvironmentVariable($var, $null, $Scope)
    }
}

function Set-Proxy {
    param($IP, $HTTP_PORT, $SOCKS_PORT)

    $proxyHttp  = "http://$IP`:$HTTP_PORT"
    $proxySocks = "socks5://$IP`:$SOCKS_PORT"
    $regPath    = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"

    # ── 1. WinInet Proxy (Browser, sebagian besar aplikasi GUI) ──
    Set-ItemProperty -Path $regPath -Name ProxyServer -Value "$IP`:$HTTP_PORT"
    Set-ItemProperty -Path $regPath -Name ProxyEnable -Value 1
    Set-ItemProperty -Path $regPath -Name ProxyOverride -Value "localhost;127.*;10.*;172.16.*;192.168.*;<local>"
    Write-Host "  ✓ WinInet proxy (Browser/GUI apps)"

    # ── 2. WinHTTP Proxy (Windows Services, Windows Update, .NET, WinRM) ──
    if ($isAdmin) {
        netsh winhttp set proxy proxy-server="$IP`:$HTTP_PORT" bypass-list="localhost;127.*;10.*;172.16.*;192.168.*" | Out-Null
        Write-Host "  ✓ WinHTTP proxy (Windows Services / System)"
    } else {
        Write-Host "  ⚠ WinHTTP dilewati (butuh Admin) — jalankan sebagai Administrator untuk coverage penuh"
    }

    # ── 3. Environment Variables - User scope ──
    Set-ProxyEnvVars -proxyHttp $proxyHttp -proxySocks $proxySocks -Scope "User"
    Write-Host "  ✓ User Environment Variables (semua terminal baru)"

    # ── 4. Environment Variables - Machine scope (semua user di PC) ──
    if ($isAdmin) {
        Set-ProxyEnvVars -proxyHttp $proxyHttp -proxySocks $proxySocks -Scope "Machine"
        Write-Host "  ✓ Machine Environment Variables (semua user)"
    } else {
        Write-Host "  ⚠ Machine env vars dilewati (butuh Admin)"
    }

    # ── 5. Terapkan ke sesi PowerShell saat ini ──
    $env:HTTP_PROXY  = $proxyHttp
    $env:HTTPS_PROXY = $proxyHttp
    $env:ALL_PROXY   = $proxySocks
    $env:http_proxy  = $proxyHttp
    $env:https_proxy = $proxyHttp
    $env:all_proxy   = $proxySocks
    $env:NO_PROXY    = "localhost,127.0.0.1,::1"
    $env:no_proxy    = "localhost,127.0.0.1,::1"
    Write-Host "  ✓ Sesi terminal saat ini"

    Write-Host ""
    Write-Host "✅ Proxy FULL SYSTEM aktif → $IP`:$HTTP_PORT (HTTP) | $IP`:$SOCKS_PORT (SOCKS5)"
    if (-not $isAdmin) {
        Write-Host "   💡 Tip: Jalankan sebagai Administrator untuk WinHTTP + Machine-level coverage"
    }
}

function Unset-Proxy {
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"

    # ── 1. Matikan WinInet ──
    Set-ItemProperty -Path $regPath -Name ProxyEnable -Value 0
    Set-ItemProperty -Path $regPath -Name ProxyServer  -Value ""
    Write-Host "  ✓ WinInet proxy dimatikan"

    # ── 2. Reset WinHTTP ──
    if ($isAdmin) {
        netsh winhttp reset proxy | Out-Null
        Write-Host "  ✓ WinHTTP proxy direset"
    } else {
        Write-Host "  ⚠ WinHTTP tidak direset (butuh Admin)"
    }

    # ── 3. Hapus env vars ──
    Unset-ProxyEnvVars -Scope "User"
    if ($isAdmin) {
        Unset-ProxyEnvVars -Scope "Machine"
        Write-Host "  ✓ Machine + User Environment Variables dihapus"
    } else {
        Write-Host "  ✓ User Environment Variables dihapus"
    }

    # ── 4. Bersihkan sesi saat ini ──
    foreach ($var in @("HTTP_PROXY","HTTPS_PROXY","ALL_PROXY","http_proxy","https_proxy","all_proxy","NO_PROXY","no_proxy")) {
        Remove-Item "env:$var" -ErrorAction SilentlyContinue
    }
    Write-Host "  ✓ Sesi terminal saat ini dibersihkan"

    Write-Host ""
    Write-Host "✅ Proxy FULL SYSTEM dimatikan"
}

while ($true) {
    Write-Host ""
    Write-Host "======================================"
    Write-Host "    MENU PROXY - FULL SYSTEM          "
    Write-Host " IP Saat Ini  : $IP                   "
    Write-Host " Mode Admin   : $(if ($isAdmin) { 'YA ✓' } else { 'TIDAK ⚠' })"
    Write-Host "======================================"
    Write-Host "1. Set Proxy (Full System)"
    Write-Host "2. Unset Proxy"
    Write-Host "3. Keluar"
    Write-Host "======================================"
    $menu = Read-Host "Pilih menu (1-3)"

    switch ($menu) {
        "1" { Set-Proxy -IP $IP -HTTP_PORT $HTTP_PORT -SOCKS_PORT $SOCKS_PORT }
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
