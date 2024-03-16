#!/usr/bin/env bash
# Clone Kernel
git clone https://github.com/levi3609/kernel_xiaomi_sm8250-redline --depth 1 -b aosp-14 kernel
cp -r kbuild.sh kernel/
