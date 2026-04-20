# termux-ubuntu-setup

> 在 Android 手机上通过 Termux 运行完整的 Ubuntu 桌面环境

一键配置脚本，帮助你在 Android 设备上快速搭建 Ubuntu + Xfce4 桌面环境，无需 Root 权限。

## ✨ 功能特性

- 🚀 **一键安装** - 一条命令完成所有配置
- 📱 **图形桌面** - 完整的 Xfce4 桌面环境
- 🖥️ **Termux-X11** - 高性能原生显示方案（非 VNC）
- 🔧 **交互式菜单** - 可选择安装任意组件
- 🎨 **安装动画** - 精美的终端动画效果
- 📦 **应用预装** - VS Code、LibreOffice、LocalSend
- 🔤 **中文字体** - 完整中文显示支持
- ⚡ **快捷方式** - 支持 Termux:Widget 一键启动
- 🔊 **音频支持** - PulseAudio 音频配置

## 📸 截图

<!-- 在此处添加截图 -->
<!-- ![桌面截图](screenshots/desktop.png) -->

## 📋 前置要求

| 要求 | 说明 |
|------|------|
| **Android** | 8.0 及以上版本 |
| **Termux** | 从 GitHub Releases 或 F-Droid 安装 |
| **Termux:X11** | 从 GitHub Releases 下载安装 |
| **存储空间** | 至少 5GB 可用空间 |
| **网络** | 稳定的网络连接 |

> ⚠️ **不要使用 Google Play 版本的 Termux**（已过时且不再维护）

## 🚀 快速开始

### 一键安装（推荐）

在 Termux 中执行以下命令：

```bash
curl -fsSL https://raw.githubusercontent.com/Xynrin/termux-ubuntu-setup/main/install | bash
```

### 手动安装

```bash
# 1. 克隆项目
git clone https://github.com/Xynrin/termux-ubuntu-setup.git
cd termux-ubuntu-setup

# 2. 运行安装脚本
bash install
```

## 📖 使用说明

### 安装流程

安装脚本提供交互式菜单，你可以选择：

| 选项 | 功能 | 说明 |
|------|------|------|
| `1` | 一键全部安装 | 按顺序执行所有安装步骤 |
| `2` | 配置 Termux | 换源、更新、安装基础工具 |
| `3` | 安装 Ubuntu | 通过 proot-distro 安装 Ubuntu |
| `4` | 安装桌面环境 | Xfce4 + Termux-X11 |
| `5` | 安装应用软件 | VS Code、LibreOffice、LocalSend |
| `6` | 安装字体 | 中文字体和辅助功能 |
| `7` | 启动桌面 | 直接启动 Xfce 桌面 |
| `0` | 退出 | 退出脚本 |

### 启动桌面

安装完成后，使用以下任一方式启动桌面：

**方式 1：命令行启动**
```bash
~/start-desktop.sh
```

**方式 2：使用 `tus` 命令**
```bash
tus
# 然后选择 7 启动桌面
```

**方式 3：Termux:Widget 快捷方式**
- 安装 [Termux:Widget](https://f-droid.org/packages/com.termux.widget/)
- 在桌面添加 Widget，点击快捷方式即可

### 启动应用

```bash
# 启动 VS Code
proot-distro login --shared-tmp ubuntu -- bash -c 'export DISPLAY=:0; code --no-sandbox'

# 启动 LibreOffice
proot-distro login --shared-tmp ubuntu -- bash -c 'export DISPLAY=:0; libreoffice'

# 进入 Ubuntu 命令行
proot-distro login ubuntu
```

## 📁 项目结构

```
termux-ubuntu-setup/
├── install                  # 一键安装入口
├── LICENSE                  # MIT 许可证
├── README.md                # 项目文档
├── lib/
│   └── common.sh            # 公共工具库（颜色、动画、日志）
└── modules/
    ├── 01-termux-setup.sh   # Termux 基础配置
    ├── 02-ubuntu-setup.sh   # Ubuntu 安装与配置
    ├── 03-desktop-setup.sh  # 桌面环境 + Termux-X11
    ├── 04-software-setup.sh # 应用软件安装
    └── 05-extras-setup.sh   # 中文字体 + 快捷方式
```

## ❓ 常见问题

### Q: Termux:X11 App 在哪里下载？

从 GitHub Releases 下载：https://github.com/termux/termux-x11/releases

选择最新的 `app-arm64-v8a-release.apk` 安装。

### Q: 安装后桌面黑屏？

1. 确保先在 Termux 中运行 `~/start-desktop.sh`
2. 然后打开 Termux:X11 App
3. 如果仍然黑屏，尝试重启 Termux 后重试

### Q: VS Code 无法启动？

VS Code 在 proot 环境中需要 `--no-sandbox` 参数，请使用脚本提供的启动方式。

### Q: 如何卸载？

```bash
# 删除 Ubuntu
proot-distro remove ubuntu

# 删除项目
rm -rf ~/termux-ubuntu-setup

# 删除快捷命令
rm -f $PREFIX/bin/tus
```

### Q: 支持哪些 Android 版本？

推荐 Android 8.0 及以上。Android 7.0 可能也可以运行，但未经过测试。

### Q: 为什么不用 VNC？

Termux-X11 方案直接使用 Android 的显示服务，性能远优于 VNC，延迟更低，操作更流畅。

## 🔧 技术栈

- **Termux** - Android 终端模拟器
- **proot-distro** - Linux 发行版管理工具
- **Termux-X11** - 原生 X11 显示服务
- **Xfce4** - 轻量级桌面环境
- **PulseAudio** - 音频服务
- **runit** - 服务管理

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 提交 Pull Request

## 📄 许可证

本项目基于 [MIT License](LICENSE) 开源。

## 🙏 致谢

- [Termux](https://github.com/termux/termux-app) - Android 终端模拟器
- [proot-distro](https://github.com/termux/proot-distro) - Linux 发行版管理
- [Termux-X11](https://github.com/termux/termux-x11) - X11 显示服务
- [Xfce](https://xfce.org/) - 轻量级桌面环境
