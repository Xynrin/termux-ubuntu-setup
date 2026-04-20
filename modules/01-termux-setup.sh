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

    # 1. 导入 Termux 签名密钥（防止换源后 GPG 验证失败）
    log_info "导入 Termux 签名密钥..."
    wget -q https://termux.org/termux-signing-key.asc -O /tmp/termux-key.asc 2>/dev/null
    if [ -f /tmp/termux-key.asc ]; then
        apt-key add /tmp/termux-key.asc 2>/dev/null
        rm -f /tmp/termux-key.asc
        log_ok "签名密钥导入完成"
    else
        log_warn "签名密钥下载失败，跳过"
    fi

    # 2. 换源（使用 sed 注释原源，添加清华源）
    log_info "正在更换镜像源为清华源..."

    local sources_file="$PREFIX/etc/apt/sources.list"
    cp "$sources_file" "${sources_file}.bak" 2>/dev/null

    # 使用 sed 注释原有源，添加清华源（清华官方推荐方式）
    sed -i 's@^\(deb.*stable main\)$@#\1\ndeb https://mirrors.tuna.tsinghua.edu.cn/termux/apt/termux-main stable main@' "$sources_file" 2>/dev/null

    log_ok "镜像源更换完成"

    # 3. 更新包管理器（失败时回退默认源，不终止安装）
    echo ""
    if ! show_spinner "正在更新包管理器..." pkg update -y; then
        log_warn "包管理器更新失败，尝试恢复默认源..."
        cp "${sources_file}.bak" "$sources_file" 2>/dev/null
        if ! pkg update -y; then
            log_warn "包管理器更新仍然失败，继续安装..."
        fi
    fi

    # 4. 升级已安装的包（失败不终止）
    show_spinner "正在升级已安装的软件包..." pkg upgrade -y || {
        log_warn "软件包升级失败，继续安装..."
    }

    # 5. 启用必要仓库
    echo ""
    log_info "启用软件仓库..."
    pkg install -y x11-repo tur-repo &>/dev/null

    # 6. 安装必要工具
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

    # 7. 配置 PulseAudio（允许本地匿名连接）
    log_info "配置 PulseAudio 音频服务..."
    mkdir -p "$PREFIX/etc/pulse/default.pa.d"
    cat > "$PREFIX/etc/pulse/default.pa.d/remote-local.pa" <<'EOF'
load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1
EOF
    log_ok "PulseAudio 配置完成"

    # 8. 配置 runit 服务：pulseaudio
    log_info "配置后台服务..."
    setup_runit_service "pulseaudio" "pulseaudio --daemonize=no --system=no --exit-idle-time=-1 --fail --disallow-exit 2>&1"

    # 9. 配置 runit 服务：termux-x11
    setup_runit_service "termux-x11" "termux-x11 2>&1"

    # 10. 配置 runit 服务：dbus-daemon
    setup_runit_service "dbus-daemon" "dbus-daemon --nosyslog --nofork --system 2>&1"

    # 11. 配置 DBUS 环境变量
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

    # SVDIR 在安装 termux-services 后才可用，提供默认值
    local sv_dir="${SVDIR:-$PREFIX/var/service}"
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
