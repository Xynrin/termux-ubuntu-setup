#!/usr/bin/env bash
# ============================================================
#  modules/02-ubuntu-setup.sh - Ubuntu 安装与配置
#  功能：通过 proot-distro 安装 Ubuntu、创建用户、系统配置
# ============================================================

setup_ubuntu() {
    echo ""
    show_separator
    echo -e "  ${BOLD}${CYAN}🐧 第二步：安装 Ubuntu 系统${NC}"
    show_separator
    echo ""

    # 1. 检查是否已安装
    if proot-distro list --installed 2>/dev/null | grep -qi "ubuntu"; then
        log_info "检测到 Ubuntu 已安装，跳过安装步骤"
        state_set "ubuntu_setup" "1"
        configure_ubuntu_system
        return 0
    fi

    # 2. 安装 Ubuntu
    log_info "正在通过 proot-distro 安装 Ubuntu..."
    log_warn "此过程需要下载约 800MB 数据，请耐心等待"
    echo ""

    if proot-distro install ubuntu; then
        log_ok "Ubuntu 安装完成"
    else
        log_error "Ubuntu 安装失败，请检查网络连接后重试"
        return 1
    fi

    # 3. 配置系统
    configure_ubuntu_system
}

configure_ubuntu_system() {
    echo ""
    log_info "正在配置 Ubuntu 系统..."

    # 使用默认用户名和密码
    local username="user"
    local password="1234"

    # 在 Ubuntu 中创建用户并配置系统
    log_info "正在初始化 Ubuntu 环境..."

    proot-distro login ubuntu -- bash -c "
        set -e

        # 更新系统
        apt update -y && apt upgrade -y

        # 安装必要工具
        apt install -y sudo dialog apt-utils pulseaudio-utils

        # 禁用 snap（proot 不支持）
        apt-get autopurge snapd -y 2>/dev/null || true
        mkdir -p /etc/apt/preferences.d
        cat > /etc/apt/preferences.d/nosnap.pref <<'SNAP'
Package: snapd
Pin: release *
Pin-Priority: -10
SNAP

        # 创建用户
        if ! id -u '${username}' &>/dev/null; then
            useradd -m -s /bin/bash '${username}'
            echo '${username}:${password}' | chpasswd
            usermod -aG sudo '${username}'
            echo '${username} ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
        fi

        # 配置时区
        ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime 2>/dev/null || true
        echo 'Asia/Shanghai' > /etc/timezone 2>/dev/null || true

        # 配置 locale
        apt install -y locales
        sed -i 's/# zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/' /etc/locale.gen 2>/dev/null || true
        sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen 2>/dev/null || true
        locale-gen 2>/dev/null || true

        # 配置 PulseAudio 客户端
        mkdir -p /etc/pulse/client.conf.d
        echo 'default-server = localhost' > /etc/pulse/client.conf.d/remote-local.conf

        # 清理缓存
        apt clean
    "

    if [ $? -eq 0 ]; then
        state_set "ubuntu_setup" "1"
        state_set "ubuntu_user" "$username"
        echo ""
        log_ok "Ubuntu 系统配置完成！"
        log_info "用户名: ${BOLD}${username}${NC}  密码: ${BOLD}${password}${NC}"
        log_warn "请登录后使用 passwd 命令修改密码"
    else
        log_error "Ubuntu 系统配置失败"
        return 1
    fi
}
