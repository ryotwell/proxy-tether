#!/bin/bash

echo "Masukkan IP Address (tekan enter untuk default: 127.0.0.1):"
read input_ip
IP=${input_ip:-127.0.0.1}

HTTP_PORT=7890
SOCKS_PORT=7891

PROXY_MARKER="# >>> proxy-tether >>>"
PROXY_MARKER_END="# <<< proxy-tether <<<"

set_proxy() {
    # ── 1. Set proxy ke SEMUA network interface (Wi-Fi, Ethernet, USB, dsb) ──
    echo "  Mengatur proxy untuk semua interface jaringan..."
    networksetup -listallnetworkservices | tail -n +2 | while IFS= read -r SERVICE; do
        # Lewati baris header dan service yang disabled (diawali *)
        case "$SERVICE" in "An asterisk"*|\**|"") continue ;; esac

        networksetup -setwebproxy            "$SERVICE" "$IP" "$HTTP_PORT"  2>/dev/null
        networksetup -setsecurewebproxy      "$SERVICE" "$IP" "$HTTP_PORT"  2>/dev/null
        networksetup -setsocksfirewallproxy  "$SERVICE" "$IP" "$SOCKS_PORT" 2>/dev/null
        networksetup -setwebproxystate           "$SERVICE" on 2>/dev/null
        networksetup -setsecurewebproxystate     "$SERVICE" on 2>/dev/null
        networksetup -setsocksfirewallproxystate "$SERVICE" on 2>/dev/null
        echo "    ✓ $SERVICE"
    done

    # ── 2. Export env vars untuk sesi terminal saat ini ──
    export HTTP_PROXY="http://$IP:$HTTP_PORT"
    export HTTPS_PROXY="http://$IP:$HTTP_PORT"
    export ALL_PROXY="socks5://$IP:$SOCKS_PORT"
    export http_proxy="http://$IP:$HTTP_PORT"
    export https_proxy="http://$IP:$HTTP_PORT"
    export all_proxy="socks5://$IP:$SOCKS_PORT"
    export NO_PROXY="localhost,127.0.0.1,::1"
    export no_proxy="localhost,127.0.0.1,::1"

    # ── 3. Persist ke shell profile agar terminal baru juga pakai proxy ──
    PROXY_BLOCK="$PROXY_MARKER
export HTTP_PROXY=\"http://$IP:$HTTP_PORT\"
export HTTPS_PROXY=\"http://$IP:$HTTP_PORT\"
export ALL_PROXY=\"socks5://$IP:$SOCKS_PORT\"
export http_proxy=\"http://$IP:$HTTP_PORT\"
export https_proxy=\"http://$IP:$HTTP_PORT\"
export all_proxy=\"socks5://$IP:$SOCKS_PORT\"
export NO_PROXY=\"localhost,127.0.0.1,::1\"
export no_proxy=\"localhost,127.0.0.1,::1\"
$PROXY_MARKER_END"

    for PROFILE in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.zshenv"; do
        if [ -f "$PROFILE" ]; then
            # Hapus block lama jika ada
            sed -i '' "/$PROXY_MARKER/,/$PROXY_MARKER_END/d" "$PROFILE" 2>/dev/null
        fi
        echo "$PROXY_BLOCK" >> "$PROFILE"
    done

    echo ""
    echo "✅ Proxy FULL SYSTEM aktif → $IP:$HTTP_PORT (HTTP) | $IP:$SOCKS_PORT (SOCKS5)"
    echo "   • Semua network interface  : ✓"
    echo "   • Terminal (sesi ini)      : ✓"
    echo "   • Terminal (sesi baru)     : ✓ (disimpan ke .zshrc/.bashrc)"
}

unset_proxy() {
    # ── 1. Matikan proxy di semua interface ──
    echo "  Menonaktifkan proxy dari semua interface jaringan..."
    networksetup -listallnetworkservices | tail -n +2 | while IFS= read -r SERVICE; do
        case "$SERVICE" in "An asterisk"*|\**|"") continue ;; esac

        networksetup -setwebproxystate           "$SERVICE" off 2>/dev/null
        networksetup -setsecurewebproxystate     "$SERVICE" off 2>/dev/null
        networksetup -setsocksfirewallproxystate "$SERVICE" off 2>/dev/null
        echo "    ✓ $SERVICE"
    done

    # ── 2. Unset env vars sesi saat ini ──
    unset HTTP_PROXY HTTPS_PROXY ALL_PROXY NO_PROXY
    unset http_proxy https_proxy all_proxy no_proxy

    # ── 3. Hapus dari shell profile ──
    for PROFILE in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.zshenv"; do
        if [ -f "$PROFILE" ]; then
            sed -i '' "/$PROXY_MARKER/,/$PROXY_MARKER_END/d" "$PROFILE" 2>/dev/null
        fi
    done

    echo ""
    echo "✅ Proxy FULL SYSTEM dimatikan"
    echo "   • Semua network interface  : ✓"
    echo "   • Terminal (sesi ini)      : ✓"
    echo "   • Terminal (sesi baru)     : ✓ (dihapus dari .zshrc/.bashrc)"
}

while true; do
    echo ""
    echo "============================="
    echo "    MENU PROXY - FULL SYSTEM "
    echo " IP Saat Ini: $IP            "
    echo "============================="
    echo "1. Set Proxy (Full System)"
    echo "2. Unset Proxy"
    echo "3. Keluar"
    echo "============================="
    read -p "Pilih menu (1-3): " menu

    case $menu in
        1) set_proxy ;;
        2) unset_proxy ;;
        3)
            echo "Keluar dari program..."
            exit 0
            ;;
        *)
            echo "❌ Pilihan tidak valid."
            ;;
    esac
done