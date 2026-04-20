#!/usr/bin/env bash
# ============================================================
#  modules/03-desktop-setup.sh - 桌面环境配置
#  功能：安装 Xfce4 + Termux-X11 集成 + 创建启动脚本
# ============================================================

setup_desktop() {
    echo ""
    show_separator
    echo -e "  ${BOLD}${CYAN}🖥️  第三步：安装桌面环境${NC}"
    show_separator
    echo ""

    if ! state_check "ubuntu_setup"; then
        log_error "请先完成 Ubuntu 安装（第二步）"
        return 1
    fi

    # 1. 在 Ubuntu 中安装桌面环境
    log_info "正在安装 Xfce4 桌面环境..."
    log_warn "此过程需要下载较多数据，请耐心等待"
    echo ""

    proot-distro login ubuntu -- bash -c "
        set -e
        export DEBIAN_FRONTEND=noninteractive

        apt update -y
        apt install -y --no-install-recommends \
            xfce4 \
            xfce4-terminal \
            xfce4-whiskermenu-plugin \
            dbus-x11 \
            xorg \
            pavucontrol \
            dbus-user-session

        apt install -y --no-install-recommends \
            xfce4-panel-profiles \
            xfce4-notifyd \
            xfce4-taskmanager \
            thunar-archive-plugin \
            mousepad \
            ristretto

        apt clean
    "

    if [ $? -ne 0 ]; then
        log_error "桌面环境安装失败"
        return 1
    fi

    log_ok "Xfce4 桌面环境安装完成"

    # 2. 创建桌面启动脚本
    echo ""
    log_info "创建桌面启动脚本..."

    local start_desktop="$HOME/start-desktop.sh"
    cat > "$start_desktop" <<'DESKTOP_EOF'
#!/data/data/com.termux/files/usr/bin/bash
echo "正在启动桌面环境..."

# 启动服务（检查 sv 是否可用）
command -v sv >/dev/null 2>&1 && sv up termux-x11 2>/dev/null || true
sleep 2
command -v sv >/dev/null 2>&1 && sv up pulseaudio 2>/dev/null || true
command -v sv >/dev/null 2>&1 && sv up dbus-daemon 2>/dev/null || true

# 启动 Ubuntu 桌面
proot-distro login \
    --isolated \
    --bind /dev/null:/proc/sys/kernel/cap_last_cap \
    --shared-tmp \
    ubuntu \
    -- bash -c 'export DISPLAY=:0; dbus-launch --exit-with-session xfce4-session'
DESKTOP_EOF
    chmod +x "$start_desktop"

    # 3. 创建 Termux:Widget 快捷方式
    log_info "创建快捷方式..."
    mkdir -p "$HOME/.shortcuts/tasks"

    local shortcut="$HOME/.shortcuts/tasks/start-desktop.sh"
    cat > "$shortcut" <<'SHORTCUT_EOF'
#!/data/data/com.termux/files/usr/bin/bash
cd ~
command -v sv >/dev/null 2>&1 && sv up termux-x11 2>/dev/null || true
sleep 2
command -v sv >/dev/null 2>&1 && sv up pulseaudio 2>/dev/null || true
command -v sv >/dev/null 2>&1 && sv up dbus-daemon 2>/dev/null || true
proot-distro login --isolated --bind /dev/null:/proc/sys/kernel/cap_last_cap --shared-tmp ubuntu -- bash -c 'export DISPLAY=:0; dbus-launch --exit-with-session xfce4-session'
SHORTCUT_EOF
    chmod +x "$shortcut"

    # 4. 创建 VS Code 启动快捷方式
    local shortcut_vscode="$HOME/.shortcuts/tasks/start-vscode.sh"
    cat > "$shortcut_vscode" <<'VSCODE_EOF'
#!/data/data/com.termux/files/usr/bin/bash
cd ~
command -v sv >/dev/null 2>&1 && sv up termux-x11 2>/dev/null || true
sleep 1
proot-distro login --shared-tmp ubuntu -- bash -c 'export DISPLAY=:0; code --no-sandbox'
VSCODE_EOF
    chmod +x "$shortcut_vscode"

    # 5. 创建浏览器启动快捷方式
    local shortcut_browser="$HOME/.shortcuts/tasks/start-browser.sh"
    cat > "$shortcut_browser" <<'BROWSER_EOF'
#!/data/data/com.termux/files/usr/bin/bash
cd ~
command -v sv >/dev/null 2>&1 && sv up termux-x11 2>/dev/null || true
sleep 1
proot-distro login --shared-tmp ubuntu -- bash -c 'export DISPLAY=:0; firefox-esr'
BROWSER_EOF
    chmod +x "$shortcut_browser"

    state_set "desktop_setup" "1"

    echo ""
    log_ok "桌面环境配置完成！"
    echo ""
    log_info "启动方式："
    echo -e "    ${CYAN}1.${NC} 在 Termux 中执行: ${BOLD}~/start-desktop.sh${NC}"
    echo -e "    ${CYAN}2.${NC} 使用 Termux:Widget 快捷方式"
    echo -e "    ${CYAN}3.${NC} 打开 Termux:X11 App 连接桌面"
    echo ""
    log_warn "请确保已安装 Termux:X11 伴侣 App"
    echo -e "    ${DIM}下载地址: https://github.com/termux/termux-x11/releases${NC}"
}

# ---- 启动桌面（供主菜单调用） ----
launch_desktop() {
    if ! state_check "desktop_setup"; then
        log_error "请先完成桌面环境安装（第三步）"
        return 1
    fi

    log_info "正在启动桌面环境..."

    command -v sv >/dev/null 2>&1 && sv up termux-x11 2>/dev/null || true
    sleep 2
    command -v sv >/dev/null 2>&1 && sv up pulseaudio 2>/dev/null || true
    command -v sv >/dev/null 2>&1 && sv up dbus-daemon 2>/dev/null || true

    proot-distro login \
        --isolated \
        --bind /dev/null:/proc/sys/kernel/cap_last_cap \
        --shared-tmp \
        ubuntu \
        -- bash -c 'export DISPLAY=:0; dbus-launch --exit-with-session xfce4-session'
}
