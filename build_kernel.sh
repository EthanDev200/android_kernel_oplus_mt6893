#!/bin/bash

# Configuration
ARCH=arm64
SUBARCH=arm64
DEFCONFIG=cupida_defconfig
TOOLCHAIN=${TOOLCHAIN:-$GITHUB_WORKSPACE/toolchain/proton-clang}
KBUILD_BUILD_USER=EthanDev200
KBUILD_BUILD_HOST=MT6893-Builder
BPF_REPO=https://github.com/EthanDev200/Bpf_kernel_oplus_MT6893
BPF_BRANCH=main

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

# Step 2: Supplement missing drvgen files
if [ ! -d "scripts/drvgen" ]; then
    echo "Download missing scripts/drvgen files"
    git clone --depth 1 --branch ${BPF_BRANCH} ${BPF_REPO} tmp_bpf_kernel
    cp -r tmp_bpf_kernel/scripts/drvgen scripts/
    rm -rf tmp_bpf_kernel
fi

# Step 3: Configure kernel
echo "Configuring kernel"
make ARCH=$ARCH O=out \
    CC="$CLANG" \
    HOSTCC=/usr/bin/gcc \
    HOSTCXX=/usr/bin/g++ \
    CROSS_COMPILE=aarch64-linux-gnu- \
    CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
    $DEFCONFIG

# Step 4: Build drvgen tool
echo "Build drvgen tool"
make ARCH=$ARCH O=out \
    CC="$CLANG" \
    HOSTCC=/usr/bin/gcc \
    HOSTCXX=/usr/bin/g++ \
    CROSS_COMPILE=aarch64-linux-gnu- \
    CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
    scripts/drvgen -j$(nproc --all)

# Step 5: Full kernel build include dtbs
echo "Start full kernel compilation"
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

# Check build result
if [ -f "out/arch/arm64/boot/Image.gz-dtb" ]; then
    echo "Build Success"
    echo "Output: out/arch/arm64/boot/Image.gz-dtb"
else
    echo "Build Failed"
    exit 1
fi