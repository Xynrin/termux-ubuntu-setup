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

    echo -e "  请选择要安装的软件："
    echo ""

    local install_browser="N"
    local install_vscode="N"
    local install_libreoffice="N"
    local install_localsend="N"

    if confirm "安装 Firefox ESR（浏览器）？" "Y"; then
        install_browser="Y"
    fi
    if confirm "安装 VS Code（代码编辑器）？" "Y"; then
        install_vscode="Y"
    fi
    if confirm "安装 LibreOffice（办公套件）？" "Y"; then
        install_libreoffice="Y"
    fi
    if confirm "安装 LocalSend（局域网文件传输）？" "Y"; then
        install_localsend="Y"
    fi

    if [[ "$install_browser" == "N" && "$install_vscode" == "N" && "$install_libreoffice" == "N" && "$install_localsend" == "N" ]]; then
        log_info "未选择任何软件，跳过"
        return 0
    fi

    echo ""

    # ---- Firefox ESR ----
    if [[ "$install_browser" == "Y" ]]; then
        install_browser_app
    fi

    # ---- VS Code ----
    if [[ "$install_vscode" == "Y" ]]; then
        install_vscode_app
    fi

    # ---- LibreOffice ----
    if [[ "$install_libreoffice" == "Y" ]]; then
        install_libreoffice_app
    fi

    # ---- LocalSend ----
    if [[ "$install_localsend" == "Y" ]]; then
        install_localsend_app
    fi

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
    log_info "启动方式: ${BOLD}proot-distro login --shared-tmp ubuntu -- bash -c 'export DISPLAY=:0; firefox-esr'${NC}"
    echo ""
}

# ---- 安装 VS Code ----
install_vscode_app() {
    log_info "正在安装 VS Code..."

    proot-distro login ubuntu -- bash -c "
        set -e
        export DEBIAN_FRONTEND=noninteractive

        # 安装依赖
        apt update -y
        apt install -y wget gpg apt-transport-https

        # 添加 Microsoft GPG 密钥和仓库
        mkdir -p /etc/apt/keyrings
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /etc/apt/keyrings/packages.microsoft.gpg 2>/dev/null
        echo 'deb [arch=arm64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main' > /etc/apt/sources.list.d/vscode.list

        # 安装 VS Code
        apt update -y
        apt install -y code || true

        # 如果上面的方式失败，尝试直接下载 .deb
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

    if proot-distro login ubuntu -- bash -c "command -v code &>/dev/null"; then
        log_ok "VS Code 安装成功"
        log_info "启动方式: ${BOLD}proot-distro login --shared-tmp ubuntu -- bash -c 'export DISPLAY=:0; code --no-sandbox'${NC}"
    else
        log_warn "VS Code 安装可能未成功，请手动在 Ubuntu 中执行: apt install code"
    fi
    echo ""
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
    log_info "启动方式: ${BOLD}proot-distro login --shared-tmp ubuntu -- bash -c 'export DISPLAY=:0; libreoffice'${NC}"
    echo ""
}

# ---- 安装 LocalSend ----
install_localsend_app() {
    log_info "正在安装 LocalSend..."

    local arch
    arch="$(get_arch)"

    proot-distro login ubuntu -- bash -c "
        set -e
        cd /tmp

        # 获取最新版本号
        LATEST_URL='https://api.github.com/repos/localsend/localsend/releases/latest'
        DOWNLOAD_URL=\$(curl -sL \$LATEST_URL | grep -oP 'browser_download_url.*?Linux-Portable-\$(uname -m).tar.gz' | head -1 | cut -d'\"' -f3)

        if [ -z \"\$DOWNLOAD_URL\" ]; then
            # 尝试 arm64 直接匹配
            DOWNLOAD_URL=\$(curl -sL \$LATEST_URL | grep -oP 'browser_download_url.*?arm64.*?tar.gz' | head -1 | cut -d'\"' -f3)
        fi

        if [ -n \"\$DOWNLOAD_URL\" ]; then
            wget -q \"\$DOWNLOAD_URL\" -O localsend.tar.gz
            mkdir -p /opt/localsend
            tar -xzf localsend.tar.gz -C /opt/localsend --strip-components=1
            rm -f localsend.tar.gz
            ln -sf /opt/localsend/LocalSend /usr/local/bin/localsend 2>/dev/null || true
            echo 'INSTALL_OK'
        else
            echo 'DOWNLOAD_FAILED'
        fi
    "

    log_ok "LocalSend 安装完成"
    log_info "启动方式: ${BOLD}proot-distro login --shared-tmp ubuntu -- bash -c 'export DISPLAY=:0; /opt/localsend/LocalSend'${NC}"
    echo ""
}
