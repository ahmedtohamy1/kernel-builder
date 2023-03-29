#!/usr/bin/env bash
# Clone Kernel
git clone --depth=1 https://github.com/Jasmine-Trees/Realking_kernel_sm8250.git -b alioth kernel
cp -r kbuild.sh kernel/