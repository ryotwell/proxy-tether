#!/bin/bash

echo "Masukkan IP Address (tekan enter untuk default: 127.0.0.1):"
read input_ip
IP=${input_ip:-127.0.0.1}

HTTP_PORT=7890
SOCKS_PORT=7891

while true; do
    echo ""
    echo "============================="
    echo "       MENU PROXY Wi-Fi      "
    echo " IP Saat Ini: $IP            "
    echo "============================="
    echo "1. Set Proxy"
    echo "2. Unset Proxy"
    echo "3. Keluar"
    echo "============================="
    read -p "Pilih menu (1-3): " menu

    case $menu in
        1)
            networksetup -setwebproxy "Wi-Fi" "$IP" "$HTTP_PORT"
            networksetup -setsecurewebproxy "Wi-Fi" "$IP" "$HTTP_PORT"
            networksetup -setsocksfirewallproxy "Wi-Fi" "$IP" "$SOCKS_PORT"
            
            # Pastikan proxy state-nya ON
            networksetup -setwebproxystate "Wi-Fi" on
            networksetup -setsecurewebproxystate "Wi-Fi" on
            networksetup -setsocksfirewallproxystate "Wi-Fi" on
            
            echo "✅ Proxy berhasil diaktifkan ke $IP"
            ;;
        2)
            networksetup -setwebproxystate "Wi-Fi" off
            networksetup -setsecurewebproxystate "Wi-Fi" off
            networksetup -setsocksfirewallproxystate "Wi-Fi" off
            
            echo "✅ Proxy berhasil dimatikan"
            ;;
        3)
            echo "Keluar dari program..."
            exit 0
            ;;
        *)
            echo "❌ Pilihan tidak valid."
            ;;
    esac
done