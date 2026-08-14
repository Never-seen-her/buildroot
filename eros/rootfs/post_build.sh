#!/bin/bash
# 文件: buildroot/board/eros/post-build.sh

# $1 是 Buildroot 传递给脚本的目标文件系统路径 (output/target)
TARGET_DIR="$1"

# 删除 Fortran 运行时库 (868KB)
#适用于科学计算和工程领域的高性能计算任务。
rm -f "${TARGET_DIR}/usr/lib/libgfortran.so"*
echo "Removed libgfortran"

# 删除 OpenMP 库 (152KB)
#数学函数（sin, cos, sqrt等）
rm -f "${TARGET_DIR}/usr/lib/libgomp.so"*
echo "Removed libgomp"

# 如果你确定没有程序需要 libm，(624K)
rm -f "${TARGET_DIR}/usr/lib/libm.so"*
echo "Removed libm"

# 1.5M
rm -rf "${TARGET_DIR}/usr/lib/libstdc++.so"*
echo "Removed C++ libraries"


#清理etc？？？  是否有其他方法，可以避免安装S11moduels
rm -rf "${TARGET_DIR}/etc/init.d/S11modules"
echo "Removed S11modules"

# 更多的清理规则可以按需添加...
# 例如: rm -rf "${TARGET_DIR}/usr/share/doc"

