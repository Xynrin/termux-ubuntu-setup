#!/usr/bin/env bash
# ============================================================
#  modules/04-software-setup.sh - 应用软件安装
#  功能：Firefox ESR + VS Code + LibreOffice + LocalSend
# ============================================================

setup_software() {
    echo ""
    show_separator
    echo -e "  ${BOLD}${CYAN}🔧 第四步：安装应用软件${NC}"
    show_separator
    echo ""

    if ! state_check "ubuntu_setup"; then
        log_error "请先完成 Ubuntu 安装（第二步）"
        return 1
    fi

    # 全部默认安装，无需交互
    install_browser_app
    install_vscode_app
    install_libreoffice_app
    install_localsend_app

    state_set "software_setup" "1"
    echo ""
    log_ok "应用软件安装完成！"
}

# ---- 安装 Firefox ESR ----
install_browser_app() {
    log_info "正在安装 Firefox ESR..."

    proot-distro login ubuntu -- bash -c "
        set -e
        export DEBIAN_FRONTEND=noninteractive

        apt update -y
        apt install -y --no-install-recommends firefox-esr
        apt clean
    "

    log_ok "Firefox ESR 安装成功"
}

# ---- 安装 VS Code ----
install_vscode_app() {
    log_info "正在安装 VS Code..."

    proot-distro login ubuntu -- bash -c "
        set -e
        export DEBIAN_FRONTEND=noninteractive

        apt update -y
        apt install -y wget gpg apt-transport-https

        mkdir -p /etc/apt/keyrings
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /etc/apt/keyrings/packages.microsoft.gpg 2>/dev/null
        echo 'deb [arch=arm64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main' > /etc/apt/sources.list.d/vscode.list

        apt update -y
        apt install -y code || true

        if ! command -v code &>/dev/null; then
            cd /tmp
            wget -q 'https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-arm64' -O code.deb 2>/dev/null
            if [ -f code.deb ]; then
                dpkg -i code.deb 2>/dev/null || apt install -f -y 2>/dev/null
                rm -f code.deb
            fi
        fi

        apt clean
    "

    log_ok "VS Code 安装成功"
}

# ---- 安装 LibreOffice ----
install_libreoffice_app() {
    log_info "正在安装 LibreOffice..."

    proot-distro login ubuntu -- bash -c "
        set -e
        export DEBIAN_FRONTEND=noninteractive

        apt update -y
        apt install -y --no-install-recommends libreoffice-calc libreoffice-writer libreoffice-impress libreoffice-draw
        apt clean
    "

    log_ok "LibreOffice 安装成功"
}

# ---- 安装 LocalSend ----
install_localsend_app() {
    log_info "正在安装 LocalSend..."

    proot-distro login ubuntu -- bash -c "
        set -e
        cd /tmp

        LATEST_URL='https://api.github.com/repos/localsend/localsend/releases/latest'
        DOWNLOAD_URL=\$(curl -sL \$LATEST_URL | grep -oP 'browser_download_url.*?Linux-Portable-\$(uname -m).tar.gz' | head -1 | cut -d'\"' -f3)

        if [ -z \"\$DOWNLOAD_URL\" ]; then
            DOWNLOAD_URL=\$(curl -sL \$LATEST_URL | grep -oP 'browser_download_url.*?arm64.*?tar.gz' | head -1 | cut -d'\"' -f3)
        fi

        if [ -n \"\$DOWNLOAD_URL\" ]; then
            wget -q \"\$DOWNLOAD_URL\" -O localsend.tar.gz
            mkdir -p /opt/localsend
            tar -xzf localsend.tar.gz -C /opt/localsend --strip-components=1
            rm -f localsend.tar.gz
            ln -sf /opt/localsend/LocalSend /usr/local/bin/localsend 2>/dev/null || true
        fi
    "

    log_ok "LocalSend 安装完成"
}
