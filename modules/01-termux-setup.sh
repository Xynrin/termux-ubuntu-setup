#!/usr/bin/env bash
# ============================================================
#  modules/01-termux-setup.sh - Termux 基础配置
#  功能：换源、更新、安装工具、配置 PulseAudio/X11 服务
# ============================================================

setup_termux() {
    echo ""
    show_separator
    echo -e "  ${BOLD}${CYAN}📦 第一步：配置 Termux 基础环境${NC}"
    show_separator
    echo ""

    # 1. 换源
    if confirm "是否更换为国内镜像源？（推荐国内用户）" "Y"; then
        log_info "正在更换镜像源..."

        if cmd_exists termux-change-repo 2>/dev/null; then
            echo -e "  ${DIM}（请在弹出的对话框中选择一个国内镜像源）${NC}"
            sleep 1
            termux-change-repo
        else
            local sources_file="$PREFIX/etc/apt/sources.list"
            cp "$sources_file" "${sources_file}.bak" 2>/dev/null
            cat > "$sources_file" <<EOF
# Termux 清华大学镜像源
deb https://mirrors.tuna.tsinghua.edu.cn/termux/apt/termux-main stable main
EOF
        fi

        log_ok "镜像源更换完成"
    fi

    # 2. 更新包管理器
    echo ""
    show_spinner "正在更新包管理器..." pkg update -y

    # 3. 升级已安装的包
    show_spinner "正在升级已安装的软件包..." pkg upgrade -y

    # 4. 启用必要仓库
    echo ""
    log_info "启用软件仓库..."
    pkg install -y x11-repo tur-repo &>/dev/null

    # 5. 安装必要工具
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

    # 6. 配置 PulseAudio（允许本地匿名连接）
    log_info "配置 PulseAudio 音频服务..."
    mkdir -p "$PREFIX/etc/pulse/default.pa.d"
    cat > "$PREFIX/etc/pulse/default.pa.d/remote-local.pa" <<'EOF'
load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1
EOF
    log_ok "PulseAudio 配置完成"

    # 7. 配置 runit 服务：pulseaudio
    log_info "配置后台服务..."
    setup_runit_service "pulseaudio" "pulseaudio --daemonize=no --system=no --exit-idle-time=-1 --fail --disallow-exit 2>&1"

    # 8. 配置 runit 服务：termux-x11
    setup_runit_service "termux-x11" "termux-x11 2>&1"

    # 9. 配置 runit 服务：dbus-daemon
    setup_runit_service "dbus-daemon" "dbus-daemon --nosyslog --nofork --system 2>&1"

    # 10. 配置 DBUS 环境变量
    local dbus_sh="$PREFIX/etc/profile.d/dbus.sh"
    cat > "$dbus_sh" <<EOF
DBUS_SESSION_BUS_ADDRESS='unix:path=$PREFIX/var/run/dbus/system_bus_socket'; export DBUS_SESSION_BUS_ADDRESS
EOF
    # 使当前 shell 也生效
    # shellcheck disable=SC1090
    source "$dbus_sh" 2>/dev/null

    echo ""
    log_ok "Termux 基础环境配置完成！"
    state_set "termux_setup" "1"
}

# ---- 配置 runit 服务的辅助函数 ----
setup_runit_service() {
    local service_name="$1"
    local run_command="$2"

    local sv_dir="$SVDIR/$service_name"
    mkdir -p "$sv_dir/log"

    # 创建 run 脚本
    cat > "$sv_dir/run" <<EOF
#!/data/data/com.termux/files/usr/bin/sh
exec $run_command
EOF
    chmod u+x "$sv_dir/run"

    # 创建 log/run 脚本
    cat > "$sv_dir/log/run" <<EOF
#!/data/data/com.termux/files/usr/bin/sh
svlogger="$PREFIX/share/termux-services/svlogger"
exec "\${svlogger}" "\$@"
EOF
    chmod u+x "$sv_dir/log/run"

    # 启用服务
    if cmd_exists sv-enable 2>/dev/null; then
        sv-enable "$service_name" 2>/dev/null
    fi

    log_ok "服务 $service_name 配置完成"
}
