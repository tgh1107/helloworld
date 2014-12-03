#!/bin/bash
#set -e

#
# This script builds all components in Sigma Design's SMP Linux SDK release 
# Command 
#    ./build_all_xxx_xxx.bash
# can be exeucted in a directory where packages (tarballs) for all the 
# components are available.
# If you have all packages available on a website you can use command
#    ./build_all_xxx_xxx.bash --download-url <url>
# This script will try to download if the tarballs are not in the current 
# directory.
#
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# It is the customer's obligation to get the cross compile toolchain.
# Sigma recommends codesourcery arm-none-linux-gnueabi 2013.11 (gcc 4.8.1) 
#
# buildroot package can be configured to download toolchain during building
# This can be manually enabled through make menuconfig
# Toolchain -> Toolchain -> Sourcery Codebench ARM 2013.11
# This build script does the same by modifying .config with sed directly.
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

# This script generates a file "source_all.env"
# upon successful execution.
#    source source_all.env 
# can be used to setup a manual build environment


# package download URL
PACKAGE_URL=""
if [ _"$1" = _"--download-url" ] ; then
PACKAGE_URL="$2"
fi

SOURCEALLFILE="source_all.env"

# Assuming the current directory is the project directory
PROJDIR=$(pwd)

# packages are re-ordered in the following array at 6.1.4 release 
# These are tarball names:
declare -a sigma_packages
sigma_packages=(                          \
cpukeys_2014-08-11.tgz                    \
sigma-buildroot_2012.02-22.tgz            \
sigma-linux_3.4-29.tgz                    \
mrua_SMP8756_6_1_5_porting.tgz      \
mruafw_SMP8756_6_1_5_prod.tgz       \
smpoutd_1-2-rc12.tgz                      \
sigma-directfb_1-2-rc12.tgz               \
mali_r3p2-01rel2-1-8756.tgz               \
sapi_1-2-rc12.tgz                         \
sigma-gstreamer_1-2-rc12.tgz              \
sigma-qtwebkit_1-2-rc12.tgz               \
xos3P38_8756.0160.tgz                    \
ipustage0_0x81-8756.tgz                   \
smp87xx_phyblock_generator_v0x04.tar.bz2  \
smp87xx_thimble_0x17.tgz                  \
sigma-uboot_2014.04-r001.tgz              \
smp87xx_upgrader_1.6.tgz                  \
)

# These are link names: we use links to access packages, 
# so we can change link to a different version if needed
declare -a links_to_packages
links_to_packages=(    \
cpukeys                \
buildroot              \
linux                  \
mrua                   \
mruafw                 \
smpoutd                \
directfb               \
mali                   \
sapi                   \
gstreamer              \
qtwebkit               \
xos                    \
ipustage0              \
phyblock               \
thimble                \
uboot                  \
upgrader               \
)

pkg_cnt=${#sigma_packages[@]}

#
# This function is for creating a clean start
# DO NOT CALL if you have any changes in your source tree
function clean_link_and_source_tree
{
    for (( i=0; i<${pkg_cnt}; i++ )); do
	echo "rm ${links_to_packages[$i]}"
	rm ${links_to_packages[$i]}
	echo "rm -rf ${sigma_packages[$i]%%.tgz}"
	rm -rf ${sigma_packages[$i]%%.tgz}
    done
}
# DO NOT USE THIS OPTION if you have any changes in your source tree
if [ _"$1" = _"--clean" ] && [ _"$2" = _"--sure" ] &&  [ _"$3" = _"--very-sure" ] ; then
    echo "removing build trees ..." 
    clean_link_and_source_tree
    rm ${SOURCEALLFILE}
    echo "done"
    exit 0
fi


# Use this option to skip the package ckeck and move on to build 
if [ _"$1" = _"--skip-package-check" ] ; then
    echo "skip package and link check and move on to package build directly ..." 
else
#
# check to make sure all packages are in place
#
for (( i=0; i<${pkg_cnt}; i++ )); do
    #echo "${links_to_packages[$i]} --> ${sigma_packages[$i]}"

    if [ -e ${links_to_packages[$i]} ]; then
        # if link and linked component exists, no question ask
	ti=${links_to_packages[$i]} #temp index
	echo "found ${links_to_packages[$i]} --> ${sigma_packages[$i]%%.tgz}"
	continue
    else
        # either link is missing, or linked package is not there
	if [ -L  ${links_to_packages[$i]} ]; then
            # link exist, but dangling
	    if [ "$(basename $(readlink -f ${links_to_packages[$i]}))" !=  "${sigma_packages[$i]%%.tgz}" ]; then
                # user did not link to the default pakcage, let it be
		echo "unchanged link ${links_to_packages[$i]} pointing to non-default package $(readlink -f ${links_to_packages[$i]})" 
		continue
	    else
		rm ${links_to_packages[$i]}
	    fi
	fi
        # if only the package does not exist, try to create the package
	if [ ! -e ${sigma_packages[$i]%%.tgz} ]; then
	    if [ ! -e ${sigma_packages[$i]} ]; then
   	        # if the tarball is not there, try to download
		echo "package ${sigma_packages[$i]} is missing"
                if [ ! -z ${PACKAGE_URL} ]; then
		    echo "downloading from ${PACKAGE_URL}"
		    echo wget "${PACKAGE_URL}${sigma_packages[$i]}" || echo "download failed"
		    wget "${PACKAGE_URL}${sigma_packages[$i]}" || echo "download failed"
                fi
		if [ ! -e ${sigma_packages[$i]} ]; then
                    echo "package ${sigma_packages[$i]} is required"
                    exit
                fi
	    fi
	    # if tarball is there, untar
	    if [ -e ${sigma_packages[$i]} ]; then
		echo tar xf ${sigma_packages[$i]}
		tar xf ${sigma_packages[$i]}
	    fi
	fi
	if [ ! -e ${sigma_packages[$i]%%.tgz} ]; then
            # check again, if package still does not exit, warn
	    echo "Cannot link to ${sigma_packages[$i]%%.tgz}, link \"${links_to_packages[$i]}\" will not be created"
	else
            # if package is created, make the link
	    echo ln -s ${sigma_packages[$i]%%.tgz} ${links_to_packages[$i]}
	    ln -s ${sigma_packages[$i]%%.tgz} ${links_to_packages[$i]}
	fi
    fi
done
fi

function pound_banner
{
echo 
echo
echo "################################################################################"
echo "#"
echo "# $1"
echo "#"
echo "################################################################################"
}

function pound_separator
{
echo "################################################################################"
echo
echo
}


#
# A file source_all is created to create build environment in the current shell
#
cat << EOF > ${SOURCEALLFILE}
# This is an automatically generated env file
# This file is created upon successful execution of build script
#     $0
# Users can use command
#     source ${SOURCEALLFILE}
# to create a manual build environment for all packages
# in case any package needs to be customized and rebuilt.

EOF

echo >> ${SOURCEALLFILE}
echo "PROJDIR=${PROJDIR}" >> ${SOURCEALLFILE} 
echo >> ${SOURCEALLFILE}


#
# cpukeys
#
pound_banner cpukeys
cd ${PROJDIR}/cpukeys
    ./set_sigma_key_8756.sh  #Set Sigma OEM ID to the key package
    source CPU_KEYS_xload3.env  # this env is needed for all security stages
    pushd xload3_tools/openssl/
        if [ $(uname -m) == "x86_64" ]; then
            make -f Makefile.dynamic
        else
            make
        fi
    popd
cd ${PROJDIR} # done with cpukeys

echo "pushd \${PROJDIR}/cpukeys/" >> ${SOURCEALLFILE}
echo "source CPU_KEYS_xload3.env" >> ${SOURCEALLFILE}
echo "popd" >> ${SOURCEALLFILE}
echo >> ${SOURCEALLFILE}
pound_separator


#
# buildroot
#
# buildroot contains the rootfs for Linux kernel.  During
# building, the kernel needs to insert modules into rootfs, 
# to buildroot needs to be made again after kernel modules 
# are installed.
# buildroot environment is the base for building other packages
# almost all hosts tools are from buildroot package.
pound_banner buildroot
cd ${PROJDIR}/buildroot
    cp configs/sigma_defconfig .config
    if [ -z $(which arm-none-linux-gnueabi-gcc) ] ; then
        #if no toolchain supplied, reconfigure buildroot to download codesourcery (gcc 4.8.1)
#        sed -i -e "s/# BR2_TOOLCHAIN_EXTERNAL_CODESOURCERY_ARM201311 is not set/BR2_TOOLCHAIN_EXTERNAL_CODESOURCERY_ARM201311=y/" .config
#        sed -i -e 's/BR2_TOOLCHAIN_EXTERNAL_CODESOURCERY_TOOLCHAIN=y/# BR2_TOOLCHAIN_EXTERNAL_CODESOURCERY_TOOLCHAIN is not set\nBR2_TOOLCHAIN_EXTERNAL_DOWNLOAD=y\n# BR2_TOOLCHAIN_EXTERNAL_PREINSTALLED is not set\nBR2_TOOLCHAIN_HAS_GCC_BUG_58595=y\nBR2_TOOLCHAIN_HAS_GCC_BUG_58854=y\n# BR2_INIT_SYSTEMD is not set\n# BR2_PACKAGE_MMC_UTILS is not set\n# BR2_PACKAGE_WESTON is not set\n# BR2_PACKAGE_DVB_APPS is not set\n# BR2_PACKAGE_W_SCAN is not set\n# BR2_PACKAGE_NFTABLES is not set\n# BR2_PACKAGE_TVHEADEND is not set\n# BR2_PACKAGE_SMACK is not set/' .config
        sed -i -e "s/# BR2_TOOLCHAIN_EXTERNAL_CODESOURCERY_ARM201203 is not set/BR2_TOOLCHAIN_EXTERNAL_CODESOURCERY_ARM201203=y/" .config
        sed -i -e "s/BR2_TOOLCHAIN_SIGMADESIGNS_SDK=y/# BR2_TOOLCHAIN_SIGMADESIGNS_SDK is not set\nBR2_TOOLCHAIN_EXTERNAL_DOWNLOAD=y/" .config
    fi
    make oldconfig
    make

    if [ -e output/rootfs-path.env ]; then 
	source output/rootfs-path.env  # this is needed for all other packages
	# WARNING: environment variables defined in rootfs-path.env are all absolution patch
        # this env file will not work if you rename the project path
    else
	echo "output/rootfs-path.env is not available, building buildroot failed."
	exit 1
    fi
cd ${PROJDIR} #done with buildroot

echo "pushd \${PROJDIR}/buildroot/output/" >> ${SOURCEALLFILE}
echo "source rootfs-path.env" >> ${SOURCEALLFILE}
echo "popd" >> ${SOURCEALLFILE}
echo >> ${SOURCEALLFILE}
pound_separator



#
# linux
#
# Linux kernel relies on the rootfs offered by the buildroot package
#
pound_banner linux
cd ${PROJDIR}/linux 
    cp arch/arm/configs/8756_defconfig .config
    make oldconfig
    make
    make modules
    make modules_install
	pushd ${PROJDIR}/buildroot
	make
	popd
    make uImage # raw kernel image, can be loaded through uboot
    make uImage-linux-xload #creates a signed xload image, signing requires cpukeys
    if [ -e arch/arm/boot/uImage-linux-xload ]; then 
        export UCLINUX_KERNEL=$(pwd)
    else
	echo "arch/arm/boot/uImage-linux-xload is not available, building Linux failed."
	exit 1
    fi
cd ${PROJDIR} #done with linux

echo "pushd \${PROJDIR}/linux/" >> ${SOURCEALLFILE}
echo "export UCLINUX_KERNEL=\$(pwd)" >> ${SOURCEALLFILE}
echo "popd" >> ${SOURCEALLFILE}
echo >> ${SOURCEALLFILE}
pound_separator


#
# mrua
# 
# mrua is core of Sigma's media driver. firmware package (mruafw) is also
# part of the mrua package
pound_banner mrua
cd ${PROJDIR}/mrua
    source build.env
    make # binary are saved into subdirectory "package"
cd ${PROJDIR} #done with mrua

echo "pushd \${PROJDIR}/mrua/" >> ${SOURCEALLFILE}
echo "source build.env" >> ${SOURCEALLFILE}
echo "popd" >> ${SOURCEALLFILE}
echo >> ${SOURCEALLFILE}
pound_separator




#
# smpoutd
# 
# This is Sigma's output daemon
# This package depends mrua, RUA_DIR is mrua source tree
pound_banner smpoutd
cd ${PROJDIR}/smpoutd
    if [ ! $(which cmake) ]; then 
	echo "no cmake"
	# Please note that newer cmake is required, version 2.8.7 and 2.8.8 are tested
    fi
    #export MRUA_SRC_DIR=$RUA_DIR
    source build.env
    make
cd ${PROJDIR}  #done with smpoutd

echo "pushd \${PROJDIR}/smpoutd/" >> ${SOURCEALLFILE}
echo "source build.env" >> ${SOURCEALLFILE}
echo "popd" >> ${SOURCEALLFILE}
echo >> ${SOURCEALLFILE}
pound_separator



#
# mali
# 
# mali is the gpu driver.  It is a prebuilt package
# nothing to be done
# This package does not offer header files for OpenGL ES
# development, instead, there is a SDK package from ARM
# that offers header files.  
# This package contains prebuilt libraries only.
#
pound_banner mali
cd ${PROJDIR}/mali
    echo "mali is a binary package"
    find .
    export LIB_DIR=$(pwd)/lib/
cd ${PROJDIR} #done with mali

echo "pushd \${PROJDIR}/mali/" >> ${SOURCEALLFILE}
echo "export LIB_DIR=\$(pwd)/lib/" >> ${SOURCEALLFILE}
echo "popd" >> ${SOURCEALLFILE}
echo >> ${SOURCEALLFILE}
pound_separator



#
# sigma-directfb
# 
# sigma-directfb relies on mrua and smpoutd
pound_banner directfb
cd ${PROJDIR}/directfb
    source build.env
    make
cd ${PROJDIR}  #done with directfb

echo "pushd \${PROJDIR}/directfb/" >> ${SOURCEALLFILE}
echo "source build.env" >> ${SOURCEALLFILE}
echo "popd" >> ${SOURCEALLFILE}
echo >> ${SOURCEALLFILE}
pound_separator



#
# sapi
# 
# sapi relies on mrua, smpoutd, directfb
pound_banner sapi
cd ${PROJDIR}/sapi
    source build.env
    make
    # build example applications
    pushd sapi-examples
    make
    popd
cd ${PROJDIR} #done with sapi

echo "pushd \${PROJDIR}/sapi/" >> ${SOURCEALLFILE}
echo "source build.env" >> ${SOURCEALLFILE}
echo "popd" >> ${SOURCEALLFILE}
echo >> ${SOURCEALLFILE}
pound_separator



#
# sigma-gstreamer
# 
# gstreamer relies on mrua, smpoutd, directfb, sapi
pound_banner gstreamer
cd ${PROJDIR}/gstreamer
    source build.env
    make essential gstsmp
cd ${PROJDIR}  #done with gstreamer

echo "pushd \${PROJDIR}/gstreamer/" >> ${SOURCEALLFILE}
echo "source build.env" >> ${SOURCEALLFILE}
echo "popd" >> ${SOURCEALLFILE}
echo >> ${SOURCEALLFILE}
pound_separator




#
# sigma-qtwebkit
# 
pound_banner qtwebkit
cd ${PROJDIR}/qtwebkit
    source build.env
    make essential 
cd ${PROJDIR} #done with qtwebkit

echo "pushd \${PROJDIR}/qtwebkit/" >> ${SOURCEALLFILE}
echo "source build.env" >> ${SOURCEALLFILE}
echo "popd" >> ${SOURCEALLFILE}
echo >> ${SOURCEALLFILE}
pound_separator



#
# xos
#
# xos is a binary prebuild package
# nothing needs to be done
# offers no header or library
pound_banner xos
cd ${PROJDIR}/xos
    echo "xos is a binary package"
    find .
cd ${PROJDIR} #done with xos

echo "#xos is a binary package" >> ${SOURCEALLFILE}
echo >> ${SOURCEALLFILE}
pound_separator



#
# ipustage0
#
# "ipu stage 0" is a prebuilt binary package
# nothing needs to be done
# offers no header or library
pound_banner ipustage0
cd ${PROJDIR}/ipustage0
    echo "ipustage0 is a binary package"
    find .
cd ${PROJDIR} #done with ipustage0

echo "#ipustage0 is a binary package" >> ${SOURCEALLFILE}
echo >> ${SOURCEALLFILE}
pound_separator



#
# phyblock
#
# phyblock contains reference XXENV configuration files (xxenv), along with scripts
# to assist in constructing a physical block image (ipublock0)
pound_banner phyblock
cd ${PROJDIR}/phyblock
    # generate XXENV binary:
    make config=xos/xboot3/xxenv/1162-E2_xxenv.config \
         outfile=1162-E2_xxenv.bin \
         xxenv_img
    # Generate phyblock0 image:
    make xos3=$(pwd)/../xos/xos3P38_8756.0160.xload3 xxenv=$(pwd)/1162-E2_xxenv.bin s0=$(pwd)/../ipustage0/ipu_stage0_0x81_8756.0161.xload3 phyblock0
cd ${PROJDIR} # done with phyblock

echo "#phyblock generator is a script package" >> ${SOURCEALLFILE}
echo >> ${SOURCEALLFILE}
pound_separator



#
# thimble
#
pound_banner thimble
cd ${PROJDIR}/thimble
    make ref_config=SMP8756.config \
         patch=xos/xboot2/xmasboot/configs/1162-E2_eMMC.config.patch \
         outfile=1162-E2_eMMC.config \
         xenv_cfg
    # customize your ZXENV config file, then create the ZXENV binary
    make config=1162-E2_eMMC.config \
         outfile=1162-E2_eMMC.bin \
         xenv_bin
    # build and sign the final thimble package
    make thimble
cd ${PROJDIR} #done with thimble

echo "#thimble has no env file" >> ${SOURCEALLFILE}
echo >> ${SOURCEALLFILE}
pound_separator



#
# uboot
#
# uboot build relies on the tools from buildroot and 
# signing requires cpukey for a specific chip 
pound_banner uboot
cd ${PROJDIR}/uboot
    source smp87xx-arm.env
    make sd87xx_config
    make
    make xload #create uboot xload file
cd ${PROJDIR}

echo "pushd \${PROJDIR}/uboot/" >> ${SOURCEALLFILE}
#echo "#not sourcing env for uboot" >> ${SOURCEALLFILE}
echo "source smp87xx-arm.env" >> ${SOURCEALLFILE}
echo "popd" >> ${SOURCEALLFILE}
echo >> ${SOURCEALLFILE}
pound_separator


#
# upgrader
#
# upgrader packages  
#  
pound_banner upgrader
cd ${PROJDIR}/upgrader
    #./build_upgrader.bash -id <BOARD_ID> -phy <PHYBLOCK> -stage1 <STAGE1> \
    #    -zxenv <ZXENV> -U <UBOOT> -K <KERNEL>
    ./build_upgrader.bash \
        -id 1162-E2 \
        -phy ${PROJDIR}/phyblock/phyblock0.bin \
        -stage1 ${PROJDIR}/thimble/thimble_armor.0075.xload3 \
        -zxenv ${PROJDIR}/thimble/1162-E2_eMMC.bin \
        -U ${PROJDIR}/uboot/xload/uimage-uboot-xload \
        -K ${PROJDIR}/linux/arch/arm/boot/uImage-linux-xload
cd ${PROJDIR}

echo "#upgrader has no env file" >> ${SOURCEALLFILE}
echo >> ${SOURCEALLFILE}
pound_separator



#
# sdk output
#
pound_banner SDK_OUTPUT 
mkdir -p ${PROJDIR}/SDK_OUTPUT
	cp -rf ${PROJDIR}/phyblock/phyblock0.bin ${PROJDIR}/SDK_OUTPUT
	cp -rf ${PROJDIR}/thimble/thimble_armor.0075.xload3 ${PROJDIR}/SDK_OUTPUT
	cp -rf ${PROJDIR}/thimble/1162-E2_eMMC.bin ${PROJDIR}/SDK_OUTPUT
	cp -rf ${PROJDIR}/uboot/xload/uimage-uboot-xload ${PROJDIR}/SDK_OUTPUT
	cp -rf ${PROJDIR}/linux/arch/arm/boot/uImage-linux-xload ${PROJDIR}/SDK_OUTPUT
	cp -rf ${PROJDIR}/linux/arch/arm/boot/uImage ${PROJDIR}/SDK_OUTPUT
cd ${PROJDIR}/SDK_OUTPUT
	echo ">>>>> create boot and kernel image <<<<<"
	cat thimble_armor.0075.xload3 /dev/zero | dd bs=1024 count=256 of=thimble_armor.0075.xload3.padded
	cat uimage-uboot-xload /dev/zero | dd bs=1024 count=256 of=uimage-uboot-xload.padded
	cat 1162-E2_eMMC.bin /dev/zero |  dd bs=1024 count=128 of=1162-E2_eMMC.bin.padded
	
	
	cat phyblock0.bin phyblock0.bin thimble_armor.0075.xload3.padded thimble_armor.0075.xload3.padded 1162-E2_eMMC.bin.padded 1162-E2_eMMC.bin.padded uimage-uboot-xload.padded > BOOT-UBOOT-IMAGE.bin
	
	cat phyblock0.bin phyblock0.bin thimble_armor.0075.xload3.padded thimble_armor.0075.xload3.padded 1162-E2_eMMC.bin.padded 1162-E2_eMMC.bin.padded > BOOT-IMAGE.bin
	
	cat uimage-uboot-xload.padded > UBOOT-IMAGE.bin
	
	cat uImage-linux-xload > KERNEL-IMAGE.bin
	echo ">>>>> create boot and kernel image successful <<<<<"
echo "#upgrader has no env file" >> ${SOURCEALLFILE}
echo >> ${SOURCEALLFILE}
pound_separator

if [ -e "${SOURCEALLFILE}" ]; then
    echo "----------------------------------------"
    echo "env file \"${SOURCEALLFILE}\" is created"
    echo "----------------------------------------"
else
    echo "Did not create \"${SOURCEALLFILE}\""
fi

