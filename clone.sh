#!/usr/bin/env bash
# Clone Kernel
git clone https://github.com/LOS-Sweet/kernel_xiaomi_sm8250.git -b staging kernel
cp -r kbuild.sh kernel/
