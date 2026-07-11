#!/bin/bash
# 如果任何命令执行失败，立即停止脚本运行
set -e 

# ========================================================
# 基础环境准备 (无论从哪一步开始都需要执行)
# ========================================================
echo -e "\e[33m[INFO] 正在优化系统内核参数以防止 Inotify 报错...\e[0m"
sudo sysctl -n -w fs.inotify.max_user_watches=524288
echo -e "\e[32m Initializing PetaLinux environment... \e[0m"

# 可以修改为适合自己系统的路径 
# Can be modified to a path suitable for one's own system
source /opt/pkg/petalinux/settings.sh
# source /tools/Xilinx/Vivado/2020.1/settings64.sh #当pl端bit无法打包至boot是再使用bootgen

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

# ========================================================
# 步骤选择菜单
# ========================================================
echo -e "\e[36m"
echo "=========================================================="
echo "请选择起始步骤 (将从该步骤开始执行直到结束):"
echo "0.  离线包路径检查"
echo "1.  PetaLinux 项目初始化 (会删除旧工程!)"
echo "2.  PetaLinux 项目配置 (HW Description)"
echo "3.  创建开机自启应用 (autostart)"
echo "4.  PetaLinux rootfs 项目配置"
echo "5.  PetaLinux 设备树替换"
echo "6.  PetaLinux build (整体编译)"
echo "7.  打包 BOOT.bin"
echo "8.  在线构建 SDK (需联网) (可跳过)"
echo "9.  安装 SDK (至 sdk 目录) (可跳过)"
echo "10. 提示设置QT Creator 工具链"
echo "=========================================================="
echo -e "\e[0m"

read -p "输入步骤编号 (0-10): " START_STEP

# 验证输入是否为数字
if ! [[ "$START_STEP" =~ ^[0-9]+$ ]] || [ "$START_STEP" -gt 10 ]; then
    echo -e "\e[31m错误: 输入无效，请输入 0 到 10 之间的数字。\e[0m"
    exit 1
fi

# ========================================================
# 目录状态自动纠正
# ========================================================
# 如果从第2步及以后开始，必须确保处于 petalinux 目录内
if [ "$START_STEP" -ge 2 ]; then
    if [ -d "$SCRIPT_DIR/petalinux" ]; then
        cd "$SCRIPT_DIR/petalinux"
        echo -e "\e[35m[INFO] 已自动进入工程目录: $(pwd)\e[0m"
    else
        echo -e "\e[31m错误: 找不到 petalinux 文件夹，请先执行步骤 1。\e[0m"
        exit 1
    fi
fi

# ========================================================
# 0. 离线包路径检查
# ========================================================
if [ "$START_STEP" -le 0 ]; then
    echo -e "\e[34m>>> 步骤 0: 正在检查离线包路径...\e[0m"
    BASE_PACK="$SCRIPT_DIR/Pack/petalinux_offline_pkg"
    PATHS=(
        "$BASE_PACK/sstate_aarch64_2020.1"
        "$BASE_PACK/downloads_2020.1"
        "$BASE_PACK/linux-xlnx-xlnx_v2020.1"
        "$BASE_PACK/u-boot-xlnx-xilinx-v2020.1"
    )

    for path in "${PATHS[@]}"; do
        if [ ! -d "$path" ]; then
            echo "********************************************************"
            echo "错误: 未检测到必要路径: $path"
            echo "请参考$BASE_PACK/README.md 下载并解压相关离线包。"
            echo "********************************************************"
            read -p "请处理后再按回车继续，或按 Ctrl+C 退出..."
        else
            echo "检测到 $path [OK]"
        fi
    done
fi

# ========================================================
# 1. PetaLinux 项目初始化
# ========================================================
if [ "$START_STEP" -le 1 ]; then
    echo -e "\e[34m>>> 步骤 1: 重新配置项目...\e[0m"
    cd "$SCRIPT_DIR"
    rm -rf ./petalinux
    petalinux-create -t project -n petalinux --template zynqMP
    cd ./petalinux/
fi

# ========================================================
# 2. PetaLinux 项目配置
# ========================================================
if [ "$START_STEP" -le 2 ]; then
    echo -e "\e[34m>>> 步骤 2: 硬件描述配置...\e[0m"
    gnome-terminal -- bash -c "
        echo '===== petalinux-config 配置助手 =====';
        echo '请等待 misc/config System Configuration 界面'
        echo '请按照以下顺序配置 保存后再退出';
        echo '====================================';
        echo 'Auto Config Settings';
        echo '  [*] kernel autoconfig';
        echo '  [*] u-boot autoconfig';
        echo 'Image Packaging Configuration';
        echo '	Root filesysteam type';
        echo '		EXT4 (SD/eMMC/SATA/USB)';
        echo '	(/dev/mmcblk1p2) Device node of SD device';
        echo '	Root filesystem format';
        echo '		cpio cpio.gz cpio.gz.u-boot tar.gz jffs2 ext4';
        echo 'Yocto Settings';
        echo '	[ ] Enable Network sstate feeds';
        echo '	[*] Enable BB NO NETWORK'; 
        echo '	Local sstate feeds settings';
        echo '		local sstate feeds url';
        echo '			${SCRIPT_DIR}/Pack/petalinux_offline_pkg/sstate_aarch64_2020.1/aarch64';
        echo '	Add pre-mirror url';
        echo '		pre-mirror url path';
        echo '			file://${SCRIPT_DIR}/Pack/petalinux_offline_pkg/downloads_2020.1/downloads';
        echo 'Linux Components Selection';
        echo '	linux-kernel (linux-xlnx)';
        echo '		(X) ext-local-src';
        echo '	External linux-kernel local source settings';
        echo '		()  External linux-kernel local source path (NEW)';
        echo '			${SCRIPT_DIR}/Pack/petalinux_offline_pkg/linux-xlnx-xlnx_v2020.1';
        echo '	u-boot (u-boot-xlnx)';
        echo '		(X) ext-local-src';
        echo '	External u-boot local source settings';
        echo '		()  External u-boot local source path (NEW)';
        echo '			${SCRIPT_DIR}/Pack/petalinux_offline_pkg/u-boot-xlnx-xilinx-v2020.1';
        echo '====================================';
        read -p '配置完成后，按回车键关闭此窗口，或直接点击窗口叉号关闭：' temp;
    "
    petalinux-config --get-hw-description ../hardware/
    rm -f bitbake.lock || true
fi

# ========================================================
# 3. 创建开机自启应用
# ========================================================
if [ "$START_STEP" -le 3 ]; then
    echo -e "\e[34m>>> 步骤 3: 创建并使能 autostart 脚本...\e[0m"
    # 检查是否已存在该 app，防止重复创建报错
    if [ ! -d "./project-spec/meta-user/recipes-apps/autostart" ]; then
        petalinux-create -t apps --template install --name autostart --enable
    fi
    cp -rf ../Pack/autostart ./project-spec/meta-user/recipes-apps/
    cp -rf ../Pack/user-rootfsconfig ./project-spec/meta-user/conf
    rm -f bitbake.lock || true
fi

# ========================================================
# 4. PetaLinux rootfs 项目配置
# ========================================================
if [ "$START_STEP" -le 4 ]; then
    echo -e "\e[34m>>> 步骤 4: RootFS 配置...\e[0m"
    gnome-terminal -- bash -c "
        echo '===== petalinux-config 配置助手 =====';
        echo '请等待 Configuration 界面'
        echo '请按照以下顺序配置 保存后再退出';
        echo '====================================';
        echo 'user packages';
        echo '	enable all package';
        echo 'Image Features';
        echo '	[*] ssh-server-dropbear';
        echo '	[ ] ssh-server-openssh ';
        echo '	[*] hwcodecs';
        echo '	[*] package-management';
        echo '	()    package-feed-uris (NEW)';
        echo '	-*- debug-tweaks';
        echo '	[*] auto-login ';
        echo 'Petalinux Package Groups';
        echo '	packagegroup-petalinux-qt    ';
        echo '		[*] populate_sdk_qt5    ';
        echo '====================================';
        read -p '配置完成后，按回车键关闭此窗口，或直接点击窗口叉号关闭：' temp;
    "
    petalinux-config -c rootfs
    rm -f bitbake.lock || true
fi

# ========================================================
# 5. 设备树更新
# ========================================================
if [ "$START_STEP" -le 5 ]; then
    echo -e "\e[34m>>> 步骤 5: 设备树更新...\e[0m"
    # gnome-terminal -- bash -c "
    #     echo '===== petalinux-config 配置助手 =====';
    #     echo '请等待 Kernel Configuration 界面'
    #     echo '请按照以下顺序配置 保存后再退出';
    #     echo '====================================';
    #     echo 'Kernel hacking';
    #     echo '  [ ] Filter access to /dev/mem';
    #     echo '====================================';
    #     read -p '配置完成后，按回车键关闭此窗口，或直接点击窗口叉号关闭：' temp;
    # "
    # petalinux-config -c kernel 
    cp -rf ../Pack/system-user.dtsi ./project-spec/meta-user/recipes-bsp/device-tree/files
    rm -f bitbake.lock || true
fi

# ========================================================
# 6. PetaLinux build
# ========================================================
if [ "$START_STEP" -le 6 ]; then
    echo -e "\e[34m>>> 步骤 6: 开始完整编译 (请耐心等待)...\e[0m"
    petalinux-build 
    rm -f bitbake.lock || true
fi

# ========================================================
# 7. 打包 BOOT.bin
# ========================================================
if [ "$START_STEP" -le 7 ]; then
    echo -e "\e[34m>>> 步骤 7: 打包 BOOT.bin...\e[0m"
    cp -rf ../Pack/linux.bif ./images/linux/
    #当pl端bit无法打包至boot是再使用bootgen
    #bootgen -image ./images/linux/linux.bif -arch zynqmp -o ./images/linux/BOOT.BIN -w on
    petalinux-package  --boot  --u-boot  --fpga  --fsbl  --force
    rm -f bitbake.lock || true
fi

# ========================================================
# 8. 在线构建 SDK
# ========================================================
if [ "$START_STEP" -le 8 ]; then
    echo -e "\e[34m>>> 步骤 8: 联网构建 SDK...\e[0m"
    read -p "本次是否构建SDK y/n: " PASS_SDK
    if [ "$PASS_SDK" = "n" ] || [ "$PASS_SDK" = "N" ]; then
        echo -e "\e[33m跳过 SDK 构建...\e[0m"
    else
        gnome-terminal -- bash -c "
            echo '===== petalinux-config 配置助手 =====';
            echo '请等待 Configuration 界面'
            echo '请按照以下顺序配置 保存后再退出';
            echo '====================================';
            echo 'Yocto Setting';
            echo '	[*] Enable Network sstate feeds';
            echo '	[ ] Enable BB No NETWORK';
            echo '====================================';
            read -p '配置完成后，按回车键关闭此窗口，或直接点击窗口叉号关闭：' temp;
        "
        petalinux-config
        petalinux-build --sdk 
        rm -f bitbake.lock || true
    fi
fi

# ========================================================
# 9. 安装 SDK
# ========================================================
if [ "$START_STEP" -le 9 ]; then
    echo -e "\e[34m>>> 步骤 9: 安装 SDK 到 sdk 目录...\e[0m"
    read -p "本次是否安装SDK y/n: " PASS_SDK
    if [ "$PASS_SDK" = "n" ] || [ "$PASS_SDK" = "N" ]; then
        echo -e "\e[33m跳过 SDK 安装...\e[0m"
    else
        mkdir -p ./sdk/image ./sdk/root
        # 自动确认安装路径
        sh ./images/linux/sdk.sh -d ./sdk -y
    fi
fi

# ========================================================
# 10. 提示设置QT Creator 工具链
# ========================================================
if [ "$START_STEP" -le 10 ]; then
    echo -e "\e[34m>>> 步骤 10: 提示设置 QT Creator 工具链...\e[0m"
    echo -e "\e[37m - \e[30;43mTools -> Options -> Build& Run\e[37;49m \e[0m"
    echo -e "\e[37m   - \e[30;43mQt Versions -> Add...\e[37;49m : 添加qmake文件 \e[30;42m$SCRIPT_DIR/petalinux/sdk/sysroots/x86_64-petalinux-linux/usr/bin/qmake\e[37;49m \e[0m"
    echo -e "\e[37m   - \e[30;43mCompilers -> Add\e[37;49m \e[0m"
    echo -e "\e[37m     - \e[30;43mGCC\e[37;49m \e[0m"
    echo -e "\e[37m       - \e[30;43mC\e[37;49m : \e[0m"
    echo -e "\e[37m         - Name 为 \e[30;43mzynqMP_OBOGX_GCC\e[37;49m \e[0m"
    echo -e "\e[37m         - Compiler path 选择 \e[30;42m$SCRIPT_DIR/petalinux/sdk/sysroots/x86_64-petalinux-linux/usr/bin/aarch64-xilinx-linux/aarch64-xilinx-linux-gcc\e[37;49m 后 Apply \e[0m"
    echo -e "\e[37m       - \e[30;43mC++\e[37;49m : \e[0m"
    echo -e "\e[37m         - Name 为 \e[30;43mzynqMP_OBOGX_C++\e[37;49m \e[0m"
    echo -e "\e[37m         - Compiler path 选择 \e[30;42m$SCRIPT_DIR/petalinux/sdk/sysroots/x86_64-petalinux-linux/usr/bin/aarch64-xilinx-linux/aarch64-xilinx-linux-g++\e[37;49m 后 Apply \e[0m"
    echo -e "\e[37m   - \e[30;43mDebuggers -> Add\e[37;49m : \e[0m"
    echo -e "\e[37m     - Name 为 \e[30;43mzynqMP_OBOGX_gdb\e[37;49m \e[0m"
    echo -e "\e[37m     - path 选择 \e[30;42m$SCRIPT_DIR/petalinux/sdk/sysroots/x86_64-petalinux-linux/usr/bin/aarch64-xilinx-linux/aarch64xilinx-linux-gdb\e[37;49m 后 Apply \e[0m"
    echo -e "\e[37m   - \e[30;43mKits -> Add\e[37;49m: \e[0m"
    echo -e "\e[37m     - Name 为 \e[30;43mzynqMP_OBOGX\e[37;49m \e[0m"
    echo -e "\e[37m     - Device type 选择 \e[30;43mGeneric Linux Device\e[37;49m \e[0m"
    echo -e "\e[37m     - Compiler C 选择 \e[30;43mzynqMP_OBOGX_GCC\e[37;49m \e[0m"
    echo -e "\e[37m     - Compiler C++ 选择 \e[30;43mzynqMP_OBOGX_C++\e[37;49m \e[0m"
    echo -e "\e[37m     - Debugger 选择 \e[30;43mzynqMP_OBOGX_gdb\e[37;49m \e[0m"
    echo -e "\e[37m     - Qt version 选择 \e[30;43mQt 5.13.2(System)\e[37;49m 后 Apply \e[0m"   
fi