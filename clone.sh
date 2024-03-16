#!/usr/bin/env bash
# Clone Kernel
git clone https://github.com/sm8250-stuffs/kernel_xiaomi_sm8250 --depth 1 -b ksu kernel
cp -r kbuild.sh kernel/
