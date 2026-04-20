#!/usr/bin/env bash
# ============================================================
#  modules/01-termux-setup.sh - Termux 基础配置
#  功能：更新包管理器、安装工具、配置 PulseAudio
# ============================================================

setup_termux() {
    echo ""
    show_separator
    echo -e "  ${BOLD}${CYAN}📦 第一步：配置 Termux 基础环境${NC}"
    show_separator
    echo ""

    # 1. 更新包管理器（使用默认源，失败不终止）
    log_info "正在更新包管理器..."
    pkg update -y 2>&1 | tail -3 || {
        log_warn "包管理器更新失败，继续安装..."
    }

    # 2. 升级已安装的包（失败不终止）
    log_info "正在升级已安装的软件包..."
    pkg upgrade -y 2>&1 | tail -3 || {
        log_warn "软件包升级失败，继续安装..."
    }

    # 3. 启用必要仓库
    echo ""
    log_info "启用软件仓库..."
    pkg install -y x11-repo tur-repo &>/dev/null

    # 4. 安装必要工具
    echo ""
    log_info "正在安装必要工具..."
    local essential_packages=(
        "proot"
        "proot-distro"
        "termux-x11-nightly"
        "pulseaudio"
        "wget"
        "curl"
        "git"
        "tar"
        "gzip"
        "bzip2"
        "unzip"
        "ca-certificates"
        "openssh"
        "nano"
        "vim"
        "htop"
        "neofetch"
        "termux-services"
    )

    local total=${#essential_packages[@]}
    local current=0

    for pkg in "${essential_packages[@]}"; do
        ((current++))
        show_progress "安装工具包" "$total" "$current"
        pkg install -y "$pkg" &>/dev/null
    done

    echo ""

    # 5. 配置 PulseAudio（允许本地匿名连接）
    log_info "配置 PulseAudio 音频服务..."
    mkdir -p "$PREFIX/etc/pulse/default.pa.d"
    cat > "$PREFIX/etc/pulse/default.pa.d/remote-local.pa" <<'EOF'
load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1
EOF
    log_ok "PulseAudio 配置完成"

    # 6. 配置 DBUS 环境变量
    log_info "配置 DBUS 环境变量..."
    local dbus_sh="$PREFIX/etc/profile.d/dbus.sh"
    mkdir -p "$PREFIX/etc/profile.d"
    cat > "$dbus_sh" <<EOF
DBUS_SESSION_BUS_ADDRESS='unix:path=$PREFIX/var/run/dbus/system_bus_socket'; export DBUS_SESSION_BUS_ADDRESS
EOF
    log_ok "DBUS 配置完成"

    echo ""
    log_ok "Termux 基础环境配置完成！"
    state_set "termux_setup" "1"
}
