> 该模板以在ZU3EG开发板中的PS端完成大恒驱动 QT的运行环境
>
> 相机驱动 https://gb.daheng-imaging.com/CN/Software/Cameras/Linux/Galaxy_Linux-arm64_Gige-U3_2.4.2507.8231.zi
>
> 开发环境 Ubuntu18 vitis_2020.1
>
> 目标环境 ZU3EG petaLinux

## 介绍

- 使用ZU3EG开发板,在其PS端运行PetaLinux操作系统
- 在操作系统中完成大恒相机的驱动 以及相机QT程序的运行
- 使用emio完成数据的PL-PS间回传的握手同步
- vivado工程与Qt源码暂不给出,仅提供top.xsa

## 快速开始

---

### 1. 初始化 petaLinux 工程

运行自动初始化脚本, 根据脚本提示进行配置

```
./autoinit.sh
```

该脚本自动创建 petaLinux 项目与 sdk 共11步 可自选开始步骤

0. 离线包路径检查
1. PetaLinux 项目初始化 (会删除旧工程!)
2. PetaLinux 项目配置 (HW Description)
3. 创建开机自启应用 (autostart)
4. PetaLinux rootfs 项目配置
5. PetaLinux 设备树替换
6. PetaLinux build (整体编译)
7. 打包 BOOT.bin
8. 在线构建 SDK (需联网) (可跳过)
9. 安装 SDK (至 sdk 目录) (可跳过)
10. 提示设置QT Creator 工具链

---

### 2. QT 交叉编译

激活 petaLinux 交叉编译环境

```
source  ./petalinux/sdk/environment-setup-aarch64-xilinx-linux
```

在项目路径解压并安装驱动

```
./Galaxy_camera.run
```

启动 QT 添加项目 `项目路径/QT/GxViewer` 编译器选择 **zynqMP_OBOGX**

更改 `GxViewer.pro` 中 LIBS 项的 `lib` 路径

右键左上角GxViewer文件夹 点击重新构建

---

### 3. 制作SD卡启动盘

将SD制作为两个格式的分区 **FAT** 和 **EXT4** 分别命名为 **FAT** 和 **EXT**

sudo 执行 autoSD.sh

```
sudo ./autoSD.sh
```

提示完成后再弹出SD卡

---

### 4. petaLinux 运行 QT 应用

SD模式启动开发板, 将恒大相机 鼠标 键盘 显示屏 连接至开发板再上电启动

在命令界面输入 即可启动

```
/media/sd-mmcblk1p1/GxViewer
```

---
