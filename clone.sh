#!/usr/bin/env bash
# Clone Kernel
git clone https://github.com/levi3609/nexus_kernel_xiaomi_sm8250.git -b sched-4 kernel
cp -r kbuild.sh kernel/
