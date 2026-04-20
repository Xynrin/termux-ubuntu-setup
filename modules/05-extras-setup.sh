#!/usr/bin/env bash
# ============================================================
#  modules/05-extras-setup.sh - 辅助功能
#  功能：中文字体 + 快捷方式图标 + neofetch 欢迎信息
# ============================================================

setup_extras() {
    echo ""
    show_separator
    echo -e "  ${BOLD}${CYAN}🎨 第五步：安装字体和辅助功能${NC}"
    show_separator
    echo ""

    if ! state_check "ubuntu_setup"; then
        log_error "请先完成 Ubuntu 安装（第二步）"
        return 1
    fi

    # 1. 安装中文字体
    install_chinese_fonts

    # 2. 配置 neofetch 欢迎信息
    setup_neofetch

    # 3. 创建 Termux:Widget 快捷方式图标
    setup_widget_icons

    state_set "extras_setup" "1"
    echo ""
    log_ok "辅助功能配置完成！"
}

# ---- 安装中文字体 ----
install_chinese_fonts() {
    echo ""
    log_info "正在安装中文字体..."

    proot-distro login ubuntu -- bash -c "
        set -e
        export DEBIAN_FRONTEND=noninteractive

        apt update -y

        # 安装中文字体
        apt install -y --no-install-recommends \
            fonts-wqy-zenhei \
            fonts-wqy-microhei \
            fonts-noto-cjk \
            fonts-noto-cjk-extra \
            fonts-noto-color-emoji \
            fonts-freefont-ttf

        # 更新字体缓存
        fc-cache -fv 2>/dev/null || true

        apt clean
    "

    log_ok "中文字体安装完成"
}

# ---- 配置 neofetch 欢迎信息 ----
setup_neofetch() {
    echo ""
    log_info "配置 neofetch 欢迎信息..."

    local username
    username="$(state_get "ubuntu_user" "user")"

    # 在 Ubuntu 用户目录下配置 .bashrc
    proot-distro login ubuntu -- bash -c "
        set -e

        # 为用户配置 neofetch
        USER_HOME=/home/${username}

        # 添加 neofetch 到 .bashrc（如果尚未添加）
        if ! grep -q 'neofetch' \${USER_HOME}/.bashrc 2>/dev/null; then
            echo '' >> \${USER_HOME}/.bashrc
            echo '# neofetch - 系统信息展示' >> \${USER_HOME}/.bashrc
            echo 'if command -v neofetch &>/dev/null; then' >> \${USER_HOME}/.bashrc
            echo '    neofetch' >> \${USER_HOME}/.bashrc
            echo 'fi' >> \${USER_HOME}/.bashrc
        fi

        chown ${username}:${username} \${USER_HOME}/.bashrc 2>/dev/null || true
    "

    log_ok "neofetch 配置完成"
}

# ---- 创建 Termux:Widget 快捷方式图标 ----
setup_widget_icons() {
    echo ""
    log_info "创建快捷方式..."

    mkdir -p "$HOME/.shortcuts/tasks"

    # 停止桌面快捷方式
    cat > "$HOME/.shortcuts/tasks/stop-desktop.sh" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
# Termux:Widget 快捷方式 - 停止桌面
sv down termux-x11 2>/dev/null || true
sv down pulseaudio 2>/dev/null || true
echo "桌面环境已停止"
EOF
    chmod +x "$HOME/.shortcuts/tasks/stop-desktop.sh"

    # 进入 Ubuntu 快捷方式
    cat > "$HOME/.shortcuts/tasks/enter-ubuntu.sh" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
# Termux:Widget 快捷方式 - 进入 Ubuntu
proot-distro login ubuntu
EOF
    chmod +x "$HOME/.shortcuts/tasks/enter-ubuntu.sh"

    log_ok "快捷方式创建完成"
    echo ""
    log_info "快捷方式说明："
    echo -e "    ${CYAN}• start-desktop.sh${NC}  - 启动桌面环境"
    echo -e "    ${CYAN}• stop-desktop.sh${NC}   - 停止桌面环境"
    echo -e "    ${CYAN}• start-vscode.sh${NC}   - 启动 VS Code"
    echo -e "    ${CYAN}• enter-ubuntu.sh${NC}   - 进入 Ubuntu 命令行"
    echo ""
    log_info "使用方法：安装 Termux:Widget App 后，在桌面小组件中即可看到快捷方式"
    echo -e "    ${DIM}下载地址: https://f-droid.org/packages/com.termux.widget/${NC}"
}
