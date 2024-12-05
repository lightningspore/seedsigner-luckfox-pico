#!/usr/bin/env sh
#
# Copy individual image files from build machine to local
# My ARM mac was struggling to build images for it, so I build it on an available
# X86/X64 machine that I can SSH into
# But it would be better if it was all local 

scp ai-box:/home/skorn/Documents/repos/luckfox-pico/output/image/boot.img .
scp ai-box:/home/skorn/Documents/repos/luckfox-pico/output/image/env.img .
scp ai-box:/home/skorn/Documents/repos/luckfox-pico/output/image/idblock.img .
scp ai-box:/home/skorn/Documents/repos/luckfox-pico/output/image/oem.img .
scp ai-box:/home/skorn/Documents/repos/luckfox-pico/output/image/rootfs.img .
scp ai-box:/home/skorn/Documents/repos/luckfox-pico/output/image/uboot.img .
scp ai-box:/home/skorn/Documents/repos/luckfox-pico/output/image/userdata.img .
scp ai-box:/home/skorn/Documents/repos/luckfox-pico/output/image/.env.txt .
