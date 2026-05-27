#!/bin/bash

# Configuration
ARCH=arm64
SUBARCH=arm64
DEFCONFIG=cupida_defconfig
# 适配GitHub Actions工具链路径
TOOLCHAIN=${TOOLCHAIN:-$GITHUB_WORKSPACE/toolchain/proton-clang}
# 修改编译署名（自定义标识，可自行修改）
KBUILD_BUILD_USER=EthanDev200
KBUILD_BUILD_HOST=MT6893-Builder

# Cross tools variables using absolute paths
CLANG=$TOOLCHAIN/bin/clang
LD=$TOOLCHAIN/bin/ld.lld
AR=$TOOLCHAIN/bin/llvm-ar
NM=$TOOLCHAIN/bin/llvm-nm
OBJCOPY=$TOOLCHAIN/bin/llvm-objcopy
OBJDUMP=$TOOLCHAIN/bin/llvm-objdump
STRIP=$TOOLCHAIN/bin/llvm-strip

# Step 1: Clean out directory
echo "Cleaning out directory..."
rm -rf out

# Step 2: Configure and build host tools
echo "Step 1: Configuring and building scripts..."
make ARCH=$ARCH O=out \
    CC="$CLANG" \
    HOSTCC=/usr/bin/gcc \
    HOSTCXX=/usr/bin/g++ \
    CROSS_COMPILE=aarch64-linux-gnu- \
    CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
    $DEFCONFIG

make ARCH=$ARCH O=out \
    CC="$CLANG" \
    HOSTCC=/usr/bin/gcc \
    HOSTCXX=/usr/bin/g++ \
    CROSS_COMPILE=aarch64-linux-gnu- \
    CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
    scripts -j$(nproc --all)

# Step 3: Build the kernel using Toolchain
echo "Step 2: Compiling kernel with Proton Clang..."
make ARCH=$ARCH SUBARCH=$SUBARCH O=out \
    CC="$CLANG" \
    LD="$LD" \
    AR="$AR" \
    NM="$NM" \
    OBJCOPY="$OBJCOPY" \
    OBJDUMP="$OBJDUMP" \
    STRIP="$STRIP" \
    CROSS_COMPILE=aarch64-linux-gnu- \
    CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
    HOSTCC=/usr/bin/gcc \
    HOSTCXX=/usr/bin/g++ \
    -j$(nproc --all) 2>&1 | tee build.log

if [ -f "out/arch/arm64/boot/Image.gz-dtb" ]; then
    echo "--- Build Success ---"
    echo "Output: out/arch/arm64/boot/Image.gz-dtb"
else
    echo "--- Build Failed ---"
    exit 1
fi