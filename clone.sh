#!/usr/bin/env bash
# Clone Kernel
git clone --depth=1 https://github.com/Poco-F3-Trees/kernel_xiaomi_sm8250.git -b staging kernel
cp -r kbuild.sh kernel/
