#!/bin/bash

KERNEL_NAME="RedCherry-4.4.302-NokiaSDM660"
DATE=$(date +"%d-%m-%Y-%I-%M")
FINAL_ZIP=$KERNEL_NAME-$DATE.zip

# Clone the repos
clonning(){
    git clone --depth=1 https://github.com/Xiaomi-SD720G-Devices/AOSP-clang.git toolchains/clang
    git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9.git toolchains/arm64-gcc
    git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9.git toolchains/arm-gcc
    git clone --depth=1 https://github.com/userariii/AnyKernel3.git -b NokiaSDM660 toolchains/AnyKernel3
}
# Determine the number of threads for compilation
determine_threads() {
    echo -e "Determining no. of threads...\n"
    if [ "$(cat /sys/devices/system/cpu/smt/active)" = "1" ]; then
        export THREADS=$(expr $(nproc --all) \* 2)
    else
        export THREADS=$(nproc --all)
    fi
    echo -e "No. of threads: $THREADS\n"
}

# Clean the build environment
clean_build_environment() {
    echo -e "Cleaning the build environment...\n"
    make O=out clean
    make O=out mrproper
    echo -e "Done!\n"
}

# Configure the kernel
configure_kernel() {
    echo -e "Configuring the kernel...\n"
    make O=out ARCH=arm64 nokia_defconfig
    echo -e "Done!\n"
}

# Build the kernel
build_kernel() {
    echo -e "Building the kernel...\n"
    PATH="$(pwd)/toolchains/clang/bin:$(pwd)/toolchains/arm64-gcc/bin:$(pwd)/toolchains/arm-gcc/bin:${PATH}" \
    make -j $THREADS O=out \
        ARCH=arm64 \
        CC=clang \
        CLANG_TRIPLE=aarch64-linux-gnu- \
        CROSS_COMPILE=aarch64-linux-android- \
        CROSS_COMPILE_ARM32=arm-linux-androideabi-
    echo -e "Kernel build completed!\n"
}

# Package the kernel into a zip file
package_kernel() {
    echo -e "Packing the kernel into a zip file using AnyKernel3...\n"
    local kernel_image="$(pwd)/out/arch/arm64/boot/Image.gz-dtb"
    local anykernel_dir="$(pwd)/toolchains/AnyKernel3"
    local kernel_builds_dir="$(pwd)/KERNEL_BUILDS"

    cp $kernel_image $anykernel_dir/
    cd && mkdir -p $kernel_builds_dir
    cd $anykernel_dir
    zip -r9 UPDATE-AnyKernel2.zip * -x README UPDATE-AnyKernel2.zip
    mv $anykernel_dir/UPDATE-AnyKernel2.zip $kernel_builds_dir/$FINAL_ZIP
    rm -rf $anykernel_dir/Image.gz-dtb
    cd ../..
    echo -e "Done!\n"
}

# Main function
main() {
    clonning
    determine_threads
    clean_build_environment
    configure_kernel
    build_kernel
    package_kernel
}

main