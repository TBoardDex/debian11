# Debian 11 (Bullseye) Rootfs — TBoard (RK3588S)

为 TBoard R5A (RK3588S) 构建基于 linaro 底包的 Debian 11 (Bullseye) ARM64 根文件系统，
仅提供 Xfce 桌面版，不再支持 Debian Server 构建。
板载 AIC8800 SDIO WiFi；UART H4 蓝牙已在 Debian 11 实板验证初始化、控制器上电、设备扫描
及手机、蓝牙键盘连接，并观察到 AVRCP/HID 输入设备注册
[蓝牙说明](bsp/wifibt/README.bluetooth.md)。

## 构建

推荐从 SDK 根目录使用统一入口：

```bash
./build.sh tboard-r5a_rk3588s_debian_xfce_defconfig
./build.sh all
```

已有 bootloader 和内核产物时，可单独重建 rootfs 并更新固件目录：

```bash
./build.sh debian
./build.sh firmware
```

SDK 入口使用 `VERSION=debug`，包含调试 overlay 和 glmark2。
rootfs 后处理会安装当前内核模块，需先完成相应内核的编译。
烧录时应配套更新 boot 和 rootfs，避免旧 `.ko` 与新内核不匹配。

也可直接调用本目录脚本。先在 SDK 根目录选择上述 Debian defconfig 并编译内核，
再进入 `debian11/` 执行：

```bash
# 1. 生成底包（已有 linaro-bullseye-alip-*.tar.gz 时可跳过）
RELEASE=bullseye TARGET=desktop ARCH=arm64 ./mk-base-debian.sh

# 2. 解包底包、应用 overlay 并安装软件，生成 binary-xfce/
ARCH=arm64 ./mk-rootfs-bullseye.sh
# 如需与 SDK 入口一致：VERSION=debug ARCH=arm64 ./mk-rootfs-bullseye.sh

# 3. 执行 Debian 和 SDK 后处理，直接生成 ext4 镜像
./mk-image.sh
```

直接调用 `mk-rootfs-bullseye.sh` 默认使用 `VERSION=release`，每次会清空并重建
`binary-xfce/`。`mk-image.sh` 默认打包该目录，不再生成 `linaro-rootfs.img` 中间镜像。

## 资源校验

只读资源校验（脚本/固件校验和、核心包架构）：

```bash
ARCH=arm64 ./debian11/check-resources.sh   # SDK 根目录执行
```

更新 bsp/ 或 overlay-firmware/ 内容后需刷新校验和：

```bash
(cd debian11 && find bsp overlay-firmware/lib/firmware/aic8800 -type f \
    ! -path bsp/SHA256SUMS -print0 | LC_ALL=C sort -z | xargs -0 sha256sum > bsp/SHA256SUMS)
```

## 产物

| 文件 | 说明 |
| --- | --- |
| binary-xfce/ | rootfs 工作目录 |
| tboard-debian11-xfce-rootfs.img | 最终 ext4 rootfs 镜像（烧写用） |
| ../output/debian-bullseye-xfce/images/rootfs.ext4 | SDK 构建生成的镜像链接 |
| ../output/firmware/rootfs.img | 执行 SDK rootfs 构建后生成的固件镜像链接 |
| linaro-bullseye-alip-*.tar.gz | linaro 底包，保留可避免重新下载 |

## 默认账号

- root / root
- tboard / tboard（普通用户，使用自己的密码执行 sudo）
- SSH 密码登录已开启（含 root）；SSH 主机密钥在启动服务前按需生成。
- 串口控制台和 LightDM 桌面登录均需账号密码，不启用自动登录。
