#!/usr/bin/env bash

 #
 # Script For Building Android Kernel

# Specify Kernel Directory
KERNEL_DIR="$(pwd)"

# Set if compiler toolchain is not in $PATH
BUILDTOOLS_PREFIX=$(pwd)/clang

# Specify linker.
# 'ld.lld'(default)
LINKER=ld.lld


DEVICE=$1

VERSION=BETA
if [ "${DEVICE}" = "alioth" ]; then
DEFCONFIG=vendor/alioth_defconfig
MODEL="Poco F3"
elif [ "${DEVICE}" = "lmi" ]; then
DEFCONFIG=lmi_defconfig
MODEL="Poco F2 Pro"
elif [ "${DEVICE}" = "apollo" ]; then
DEFCONFIG=apollo_defconfig
MODEL="Mi 10T Pro"
elif [ "${DEVICE}" = "munch" ]; then
DEFCONFIG=munch_defconfig
MODEL="Poco F4"
fi

# Files
IMAGE=$(pwd)/out/arch/arm64/boot/Image
DTBO=$(pwd)/out/arch/arm64/boot/dtbo.img
OUT_DIR=out/
dts_source=arch/arm64/boot/dts/vendor/qcom

# Verbose Build
VERBOSE=0

# Kernel Version
KERVER=$(make kernelversion)

COMMIT_HEAD=$(git log --oneline -1)

# Date and Time
DATE=$(TZ=Asia/Dhaka date +"%Y%m%d-%T")
TM=$(date +"%F%S")

# Specify Final Zip Name
ZIPNAME=N0K
FINAL_ZIP=${ZIPNAME}-${VERSION}-${DEVICE}-KERNEL-AOSP-${TM}.zip


# Specify compiler [ proton, nexus, aosp ]
COMPILER=neutron

# Clone ToolChain
function cloneTC() {
	
	case $COMPILER in
	
		zyc14old)
			git clone --depth=1  https://github.com/Poco-F3-Trees/zyc_clang-14 clang
			PATH="${KERNEL_DIR}/clang/bin:$PATH"
			;;
		
		nexus)
			git clone --depth=1  https://gitlab.com/Project-Nexus/nexus-clang.git clang
			PATH="${KERNEL_DIR}/clang/bin:$PATH"
			;;

		neutron)
			if [ ! -d clang ]; then
			mkdir clang && cd clang
			bash <(curl -s https://raw.githubusercontent.com/Neutron-Toolchains/antman/main/antman) -S
			PATH="${KERNEL_DIR}/clang/bin:$PATH"
			cd ..
			else
			echo "Neutron alreay cloned"
			fi
			;;

		nex14)
			git clone --depth=1  https://gitlab.com/Project-Nexus/nexus-clang.git -b nexus-14 clang
			PATH="${KERNEL_DIR}/clang/bin:$PATH"
			;;

		aosp)
			echo "* Checking if Aosp Clang is already cloned..."
			if [ -d clangB ]; then
	  		echo "××××××××××××××××××××××××××××"
	  		echo "  Already Cloned Aosp Clang"
	  		echo "××××××××××××××××××××××××××××"
			else
			export CLANG_VERSION="clang-r487747"
			echo "* It's not cloned, cloning it..."
        		mkdir clangB
        		cd clangB || exit
			wget -q https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/master/${CLANG_VERSION}.tgz
        		tar -xf ${CLANG_VERSION}.tgz
        		cd .. || exit
			git clone https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9.git --depth=1 gcc
			git clone https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9.git  --depth=1 gcc32
			fi
			PATH="${KERNEL_DIR}/clangB/bin:${KERNEL_DIR}/gcc/bin:${KERNEL_DIR}/gcc32/bin:${PATH}"
			;;
			
		zyc)
		    mkdir clang
            cd clang
		    wget https://raw.githubusercontent.com/ZyCromerZ/Clang/main/Clang-main-lastbuild.txt
		    V="$(cat Clang-main-lastbuild.txt)"
            wget -q https://github.com/ZyCromerZ/Clang/releases/download/17.0.0-$V-release/Clang-17.0.0-$V.tar.gz
	        tar -xf Clang-17.0.0-$V.tar.gz
	        cd ..
	        PATH="${KERNEL_DIR}/clang/bin:$PATH"
	        ;;

		*)
			echo "Compiler not defined"
			;;
	esac
}
        # Clone AnyKernel
      if [ ! -d "AnyKernel3" ]; then
    git clone --depth=1 https://github.com/levi3609/AnyKernel3 -b alioth AnyKernel3
      fi
	
# Export Variables
function exports() {
	
        # Export KBUILD_COMPILER_STRING
        if [ -d ${KERNEL_DIR}/clang ];
           then
               export KBUILD_COMPILER_STRING=$(${KERNEL_DIR}/clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
        elif [ -d ${KERNEL_DIR}/gcc64 ];
           then
               export KBUILD_COMPILER_STRING=$("$KERNEL_DIR/gcc64"/bin/aarch64-elf-gcc --version | head -n 1)
        elif [ -d ${KERNEL_DIR}/clangB ];
            then
               export KBUILD_COMPILER_STRING=$(${KERNEL_DIR}/clangB/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
        fi
        
        # Export ARCH and SUBARCH
        export ARCH=arm64
        export SUBARCH=arm64
               
        # KBUILD HOST and USER
        export KBUILD_BUILD_HOST=Potato
        export KBUILD_BUILD_USER="nhAsif"
        
        # CI
        if [ "$CI" ]
           then
               
           if [ "$CIRCLECI" ]
              then
                  export KBUILD_BUILD_VERSION=${CIRCLE_BUILD_NUM}
                  export CI_BRANCH=${CIRCLE_BRANCH}
           elif [ "$DRONE" ]
	      then
		  export KBUILD_BUILD_VERSION=${DRONE_BUILD_NUMBER}
		  export CI_BRANCH=${DRONE_BRANCH}
           fi
		   
        fi
	export PROCS=$(nproc --all)
	export DISTRO=$(source /etc/os-release && echo "${NAME}")
	}

# Telegram Bot Integration

function post_msg() {
	curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
	-d chat_id="$chat_id" \
	-d "disable_web_page_preview=true" \
	-d "parse_mode=html" \
	-d text="$1"
	}

function push() {
	curl -F document=@$1 "https://api.telegram.org/bot$token/sendDocument" \
	-F chat_id="$chat_id" \
	-F "disable_web_page_preview=true" \
	-F "parse_mode=html" \
	-F caption="$2"
	}

# Compilation

METHOD=$2

function compile() {
START=$(date +"%s")
	# Push Notification
	post_msg "<b>$KBUILD_BUILD_VERSION CI Build Triggered</b>%0A<b>Docker OS: </b><code>$DISTRO</code>%0A<b>Kernel Version : </b><code>$KERVER</code>%0A<b>Date : </b><code>$(TZ=Europe/Lisbon date)</code>%0A<b>Device : </b><code>$MODEL [$DEVICE]</code>%0A<b>Pipeline Host : </b><code>$KBUILD_BUILD_HOST</code>%0A<b>Host Core Count : </b><code>$PROCS</code>%0A<b>Compiler Used : </b><code>$KBUILD_COMPILER_STRING</code>%0A<b>Branch : </b><code>$CI_BRANCH</code>%0A<b>Top Commit : </b><a href='$DRONE_COMMIT_LINK'>$COMMIT_HEAD</a>"
	
	#Compilation
	  MAKE+=(
	  CROSS_COMPILE=aarch64-linux-gnu- \
		CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
		CC=${BUILDTOOLS_PREFIX}/bin/clang \
		AR=${BUILDTOOLS_PREFIX}/bin/llvm-ar \
		AS=${BUILDTOOLS_PREFIX}/bin/llvm-as \
		OBJDUMP=${BUILDTOOLS_PREFIX}/bin/llvm-objdump \
		STRIP=${BUILDTOOLS_PREFIX}/bin/llvm-strip \
		NM=${BUILDTOOLS_PREFIX}/bin/llvm-nm \
		OBJCOPY=${BUILDTOOLS_PREFIX}/bin/llvm-objcopy \
		LD=${BUILDTOOLS_PREFIX}/bin/${LINKER} \
		LLVM=1 \
		LLVM_IAS=1
  )

	make O=out "${MAKE[@]}" $DEFCONFIG

	msg "|| Started Compilation ||"
	make -kj69 O=out \
		V=$VERBOSE \
		"${MAKE[@]}" 2>&1 | tee error.log
	
	
	# Verify Files
	if ! [ -a "$IMAGE" ];
	   then
	       push "error.log" "Build Throws Errors"
	       exit 1
	   else
	       post_msg " Kernel Compilation Finished. Started Zipping "
		   find ${OUT_DIR}/$dts_source -name '*.dtb' -exec cat {} + >${OUT_DIR}/arch/arm64/boot/dtb
		   DTB=$(pwd)/out/arch/arm64/boot/dtb
	fi
	}

# Zipping
function zipping() {
	# Copy Files To AnyKernel3 Zip
	mv $IMAGE AnyKernel3
    mv $DTBO AnyKernel3
    mv $DTB AnyKernel3

	# Zipping and Push Kernel
	cd AnyKernel3 || exit 1
        zip -r9 ${FINAL_ZIP} *
        MD5CHECK=$(md5sum "$FINAL_ZIP" | cut -d' ' -f1)
        push "$FINAL_ZIP" "Build took : $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s) | For <b>$MODEL ($DEVICE)</b> | <b>${KBUILD_COMPILER_STRING}</b> | <b>MD5 Checksum : </b><code>$MD5CHECK</code>"
		cd ..
        rm -rf AnyKernel3
        }

cloneTC
exports
compile
END=$(date +"%s")
DIFF=$(($END - $START))
zipping
