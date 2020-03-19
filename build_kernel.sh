#!/bin/bash
##
#  Copyright (C) 2015, Samsung Electronics, Co., Ltd.
#  Written by System S/W Group, S/W Platform R&D Team,
#  Mobile Communication Division.
##

set -e -o pipefail

export CROSS_COMPILE=../../../prebuilts/gcc/linux-x86/arm/arm-eabi-4.8/bin/arm-eabi-
# export CROSS_COMPILE=/home/jedld/linaro/toolchain/bin/arm-linux-gnueabihf-
export ARCH=arm

PLATFORM=sc8830
DEFCONFIG=gtexslte_defconfig

DTS_FILES=".sprd-scx35l_sharkls_gtexslte_rev00.dtb.dts .sprd-scx35l_sharkls_gtexslte_rev01.dtb.dts .sprd-scx35l_sharkls_gtexslte_rev02.dtb.dts .sprd-scx35l_sharkls_gtexslte_rev03.dtb.dts"

KERNEL_PATH=$(pwd)
MODULE_PATH=../../../out/target/product/gtexslte/root/lib/modules
EXTERNAL_MODULE_PATH=${KERNEL_PATH}/external_module

JOBS=`grep processor /proc/cpuinfo | wc -l`

function build_kernel() {
	make ${DEFCONFIG}
	make headers_install
	make -j${JOBS}
	make modules
	make dtbs
	./scripts/mkdtimg.sh -o dt.img -ks $KERNEL_PATH -ko $KERNEL_PATH -i $DTS_FILES
	make -C ${EXTERNAL_MODULE_PATH}/wifi KDIR=${KERNEL_PATH}

	[ -d ${MODULE_PATH} ] && rm -rf ${MODULE_PATH}
	mkdir -p ${MODULE_PATH}

	find ${KERNEL_PATH}/drivers -name "*.ko" -exec cp -f {} ${MODULE_PATH} \;
	find -L ${EXTERNAL_MODULE_PATH} -name "*.ko" -exec cp -f {} ${MODULE_PATH} \;
}

function clean() {
	[ -d ${MODULE_PATH} ] && rm -rf ${MODULE_PATH}
	make distclean
}

function main() {
	[ "${1}" = "Clean" ] && clean || build_kernel
}

main $@
