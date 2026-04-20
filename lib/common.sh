#!/usr/bin/env bash
# ============================================================
#  lib/common.sh - termux-ubuntu-setup 公共工具库
#  包含：颜色定义、动画效果、日志、通用函数
# ============================================================

# ---- 颜色定义 ----
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
BOLD='\033[1m'
DIM='\033[2m'
UNDERLINE='\033[4m'
NC='\033[0m' # No Color

# ---- 日志函数 ----
log_info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# ---- 动画：旋转加载器 ----
# 用法: show_spinner "正在安装..." <命令>
show_spinner() {
    local message="$1"
    shift
    local pid
    local spin_chars=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    local spin_colors=("${CYAN}" "${BLUE}" "${MAGENTA}" "${CYAN}" "${BLUE}" "${MAGENTA}" "${CYAN}" "${BLUE}" "${MAGENTA}" "${CYAN}")
    local i=0

    # 在后台运行命令
    "$@" &
    pid=$!

    # 隐藏光标
    tput civis 2>/dev/null

    # 循环显示动画
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r  ${spin_colors[$i]}${spin_chars[$i]}${NC} ${message}"
        sleep 0.1
        ((i = (i + 1) % ${#spin_chars[@]}))
    done

    # 恢复光标
    tput cnorm 2>/dev/null

    # 等待命令结束并获取退出码
    wait "$pid"
    local exit_code=$?

    # 清除当前行并显示结果
    printf "\r\033[K"
    if [ $exit_code -eq 0 ]; then
        log_ok "$message 完成"
    else
        log_error "$message 失败 (退出码: $exit_code)"
    fi

    # 不传播错误码，让调用方决定如何处理
    return 0
}

# ---- 动画：进度条 ----
# 用法: show_progress "描述" <总数> <当前数>
show_progress() {
    local label="$1"
    local total="$2"
    local current="$3"
    local percent=$((current * 100 / total))
    local filled=$((current * 30 / total))
    local empty=$((30 - filled))

    printf "\r  ${CYAN}${label}${NC} ["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "] ${BOLD}%3d%%${NC}" "$percent"

    if [ "$current" -ge "$total" ]; then
        echo ""
    fi
}

# ---- 动画：打字效果 ----
# 用法: typewriter "要显示的文字" [延迟秒数]
typewriter() {
    local text="$1"
    local delay="${2:-0.03}"
    for ((i = 0; i < ${#text}; i++)); do
        printf "%s" "${text:$i:1}"
        sleep "$delay"
    done
    echo ""
}

# ---- 动画：ASCII Logo ----
show_logo() {
    clear
    echo -e "${CYAN}"
    cat <<'EOF'
    ╔══════════════════════════════════════════════════╗
    ║                                                  ║
    ║   _   _                  ____  _                 ║
    ║  | | | | __ _ _ __   ___/ ___|| |__   __ _ _ __  ║
    ║  | |_| |/ _` | '_ \ / _ \___ \| '_ \ / _` | '__| ║
    ║  |  _  | (_| | | | |  __/___) | | | | (_| | |    ║
    ║  |_| |_|\__,_|_| |_|\___|____/|_| |_|\__,_|_|    ║
    ║                                                  ║
    ║         Ubuntu Desktop on Android                ║
    ║         One-Click Setup Script                   ║
    ║                                                  ║
    ╚══════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# ---- 动画：欢迎横幅 ----
show_welcome() {
    show_logo
    echo ""
    typewriter "  🚀 欢迎使用 Termux Ubuntu 一键配置工具！" 0.02
    echo ""
    typewriter "  📱 在你的 Android 手机上运行完整的 Ubuntu 桌面环境" 0.02
    echo ""
    echo -e "  ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# ---- 动画：完成庆祝 ----
show_complete() {
    echo ""
    echo -e "${GREEN}"
    cat <<'EOF'
    ╔══════════════════════════════════════════════════╗
    ║                                                  ║
    ║          ✨  安装完成！  ✨                       ║
    ║                                                  ║
    ║   现在你可以开始使用 Ubuntu 桌面环境了！          ║
    ║                                                  ║
    ╚══════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# ---- 动画：分隔线 ----
show_separator() {
    echo -e "  ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# ---- 确认函数 ----
confirm() {
    local message="$1"
    local default="${2:-Y}"
    local prompt

    if [[ "$default" =~ ^[Yy]$ ]]; then
        prompt="[Y/n]"
    else
        prompt="[y/N]"
    fi

    echo -en "  ${YELLOW}➜${NC} ${message} ${DIM}${prompt}${NC} "
    local answer
    read -r answer
    answer="${answer:-$default}"

    [[ "$answer" =~ ^[Yy]$ ]]
}

# ---- 选择菜单 ----
# 用法: show_menu "标题" 选项1 选项2 选项3 ...
# 返回选中的索引 (从1开始)
show_menu() {
    local title="$1"
    shift
    local options=("$@")
    local num_options=${#options[@]}

    echo -e "  ${BOLD}${CYAN}▸ ${title}${NC}"
    echo ""

    local i=1
    for option in "${options[@]}"; do
        echo -e "    ${BOLD}${WHITE}${i})${NC} ${option}"
        ((i++))
    done

    echo ""
    echo -en "  ${YELLOW}➜${NC} 请选择 [1-${num_options}]: "

    local choice
    while true; do
        read -r choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$num_options" ]; then
            echo "$choice"
            return
        fi
        echo -en "  ${RED}无效选择，请重新输入${NC} [1-${num_options}]: "
    done
}

# ---- 检查命令是否存在 ----
cmd_exists() {
    command -v "$1" &>/dev/null
}

# ---- 检查是否在 Termux 中运行 ----
check_termux() {
    if [ ! -d "/data/data/com.termux" ] && [ -z "$TERMUX_VERSION" ]; then
        log_error "此脚本必须在 Termux 环境中运行！"
        log_info "请从 GitHub 或 F-Droid 下载安装 Termux："
        echo -e "    ${CYAN}https://github.com/termux/termux-app/releases${NC}"
        echo -e "    ${CYAN}https://f-droid.org/packages/com.termux/${NC}"
        exit 1
    fi
}

# ---- 检查网络连接 ----
check_network() {
    log_info "检查网络连接..."
    if ping -c 1 -W 5 google.com &>/dev/null || ping -c 1 -W 5 baidu.com &>/dev/null; then
        log_ok "网络连接正常"
        return 0
    else
        log_error "网络连接失败，请检查网络设置"
        return 1
    fi
}

# ---- 检查存储权限 ----
check_storage() {
    if [ ! -d "$HOME/storage" ]; then
        log_warn "未检测到存储权限，正在请求..."
        termux-setup-storage 2>/dev/null || {
            log_error "无法获取存储权限"
            return 1
        }
    fi
    log_ok "存储权限正常"
}

# ---- 安全执行命令（带错误处理） ----
safe_run() {
    local desc="$1"
    shift
    log_info "$desc..."
    if "$@" 2>&1; then
        log_ok "$desc 完成"
        return 0
    else
        log_error "$desc 失败"
        return 1
    fi
}

# ---- 获取架构 ----
get_arch() {
    case "$(uname -m)" in
        aarch64|arm64) echo "arm64" ;;
        armv7l|armv8l) echo "arm" ;;
        x86_64)        echo "x86_64" ;;
        i686)          echo "x86" ;;
        *)             echo "unknown" ;;
    esac
}

# ---- 状态追踪 ----
STATE_FILE="/tmp/tus-state"

state_set() {
    local key="$1"
    local value="$2"
    mkdir -p "$(dirname "$STATE_FILE")"
    sed -i "/^${key}=/d" "$STATE_FILE" 2>/dev/null
    echo "${key}=${value}" >> "$STATE_FILE"
}

state_get() {
    local key="$1"
    local default="${2:-}"
    grep "^${key}=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "$default"
}

state_check() {
    local key="$1"
    grep -q "^${key}=1" "$STATE_FILE" 2>/dev/null
}
