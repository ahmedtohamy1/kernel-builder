#!/usr/bin/env bash
# Clone Kernel
git clone --depth=1 https://github.com/levi3609/kernel_xiaomi_sm8250 -b staging kernel
cp -r kbuild.sh kernel/
