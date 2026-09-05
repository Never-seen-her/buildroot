#!/bin/bash
# 文件: buildroot/board/eros/post-build.sh

set -x
# $1 是 Buildroot 传递给脚本的目标文件系统路径 (output/target)
TARGET_DIR="$1"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "SCRIPT_DIR:${SCRIPT_DIR} SCRIPT_DIR:${TARGET_DIR}"
#==========================================================
#           动态库 相关
#==========================================================
# 删除 Fortran 运行时库 (868KB)
#适用于科学计算和工程领域的高性能计算任务。
rm -f "${TARGET_DIR}/usr/lib/libgfortran.so"*

# 删除 OpenMP 库 (152KB)
#数学函数（sin, cos, sqrt等）
rm -f "${TARGET_DIR}/usr/lib/libgomp.so"*

# 如果你确定没有程序需要 libm，(624K)
# rm -f "${TARGET_DIR}/usr/lib/libm.so"*
# ==> ethtool 需要 libm.so.6, 所以不能删除

# 1.5M
#rm -rf "${TARGET_DIR}/usr/lib/libstdc++.so"*

#==========================================================
#           依赖固件
#==========================================================
# usb wifi
mkdir -p "${TARGET_DIR}/lib/firmware/rtw88"
cp -f "${SCRIPT_DIR}/package/wifi/rtw8723d_fw.bin" "${TARGET_DIR}/lib/firmware/rtw88/"

#==========================================================
#           etc 系统个性化配置 相关
#==========================================================
sh "${SCRIPT_DIR}/etc/profile_script" "${TARGET_DIR}"

#  增加远程ssh root 登陆权限
#sh "${SCRIPT_DIR}/etc/sshd_script" "${TARGET_DIR}"
#==========================================================
#           /etc/init.d 相关
#==========================================================
rm -f "${TARGET_DIR}/etc/init.d/S01seedrng"

#清理etc？？？  是否有其他方法，可以避免安装S11moduels
rm -rf "${TARGET_DIR}/etc/init.d/S11modules"

# ethernet ssh
cp -f "${SCRIPT_DIR}/etc/init.d/S40network" "${TARGET_DIR}/etc/init.d/S40network"
cp -f "${SCRIPT_DIR}/etc/init.d/S50sshd" "${TARGET_DIR}/etc/init.d/S50sshd"

# usb wifi
cp "${SCRIPT_DIR}/etc/wpa_supplicant.conf" "${TARGET_DIR}/etc/wpa_supplicant.conf"
cp -f "${SCRIPT_DIR}/etc/init.d/S60wifi" "${TARGET_DIR}/etc/init.d/S60wifi"



