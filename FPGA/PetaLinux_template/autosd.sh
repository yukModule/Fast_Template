#!/bin/bash
# 如果任何命令执行失败，立即停止脚本运行
set -e 
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

# 获取当前用户名
CURRENT_USER=$(whoami)

# 定义目标路径
DEST_PATH_FAT="/media/$CURRENT_USER/FAT"
DEST_PATH_EXT="/media/$CURRENT_USER/EXT"

# 检查目标文件夹是否存在（防止挂载失败时直接报错）
if [ -d "$DEST_PATH_FAT" ]; then
    echo "清空FAT分区内容...";
    sudo rm -rf $DEST_PATH_FAT/*
    echo "移动至FAT分区文件...";
    cp -rf "$SCRIPT_DIR/petalinux/images/linux/boot.scr" "$DEST_PATH_FAT"
    cp -rf "$SCRIPT_DIR/petalinux/images/linux/BOOT.BIN" "$DEST_PATH_FAT"
    cp -rf "$SCRIPT_DIR/petalinux/images/linux/image.ub" "$DEST_PATH_FAT"
    cp -rf "$SCRIPT_DIR/Pack/SD/"* "$DEST_PATH_FAT"
    chmod +x "$DEST_PATH_FAT/autostart.sh"
else
    echo "错误: 找不到挂载点 $DEST_PATH_FAT 请检查 SD 卡是否已挂载。"
    exit 1
fi

sudo  sync

if [ -d "$DEST_PATH_EXT" ]; then
    read -p "本次是否写入EXT分区 y/n: " PASS_SDK
    if [ "$PASS_SDK" = "n" ] || [ "$PASS_SDK" = "N" ]; then
        echo -e "\e[33m跳过 SDK 构建...\e[0m"
    else
        echo "清空EXT分区内容...";
        sudo rm -rf $DEST_PATH_EXT/*
        echo "解压 rootfs 到 EXT 分区...";
        sudo  tar  -zxvf  $SCRIPT_DIR/petalinux/images/linux/rootfs.tar.gz  -C  $DEST_PATH_EXT
        fi

else
    echo "错误: 找不到挂载点 $DEST_PATH_EXT 请检查 SD 卡是否已挂载。"
    exit 1
fi

echo "同步缓存数据到 SD 卡...";
sudo  sync

echo -e "\e[32m>>> 所有文件已成功复制到 SD 卡！\e[0m"