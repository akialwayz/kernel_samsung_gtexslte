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

[ ! -z "$KERNEL_PATH" ] && cd $KERNEL_PATH
KERNEL_PATH=$(pwd)

MODULE_PATH=../../../out/target/product/gtexslte/system/lib/modules
REC_MODULE_PATH=../../../out/target/product/gtexslte/recovery/root/lib/modules
EXTERNAL_MODULE_PATH=${KERNEL_PATH}/external_module

JOBS=`grep processor /proc/cpuinfo | wc -l`

function make_conf() {
    make -j${JOBS} ${DEFCONFIG}
}

function build_modules(){
	make -j${JOBS} headers_install
	make -j${JOBS} modules
	make -j${JOBS} -C ${EXTERNAL_MODULE_PATH}/wifi KDIR=${KERNEL_PATH}

	[ -d ${MODULE_PATH} ] && rm -rf ${MODULE_PATH}
	mkdir -p ${MODULE_PATH}
	[ -d ${REC_MODULE_PATH} ] && rm -rf ${REC_MODULE_PATH}
	mkdir -p ${REC_MODULE_PATH}

	#find ${KERNEL_PATH}/drivers -name "*.ko" -exec cp -vf {} ${MODULE_PATH} \;
	find drivers -name "*.ko" -exec cp -vf {} ${MODULE_PATH} \;
	find -L ${EXTERNAL_MODULE_PATH} -name "*.ko" -exec cp -vf {} ${MODULE_PATH}  \;
	#find ${KERNEL_PATH}/drivers -name "*.ko" -exec cp -vf {} ${REC_MODULE_PATH} \;
	find drivers -name "*.ko" -exec cp -vf {} ${REC_MODULE_PATH} \;
	find -L ${EXTERNAL_MODULE_PATH} -name "*.ko" -exec cp -vf {} ${REC_MODULE_PATH} \;
}

function build_kernel() {
	make -j${JOBS}
	build_modules
	make -j${JOBS} dtbs
	./scripts/mkdtimg.sh -o dt.img -ks $KERNEL_PATH -ko $KERNEL_PATH -i $DTS_FILES
}

function clean() {
	echo CLEANING
	[ -d ${MODULE_PATH} ] && rm -rf ${MODULE_PATH}
	make -j${JOBS} distclean
}

function main() {
	case "$1" in
	    clean-modules) clean && make_conf && build_modules ;;
	    Clean|clean) clean ;;
	    modules) make_conf && build_modules ;;
	    *) make_conf && build_kernel ;;
	esac
}

main "$@"
