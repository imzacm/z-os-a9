#! /usr/bin/env bash

set -Eeuo pipefail

iso_dir="/tmp/z-os-iso"
[[ -d "$iso_dir" ]] && rm -rf "${iso_dir}"

iso_cfg_file="${iso_dir}/boot/grub/grub.cfg"
mkdir -p "$(dirname "${iso_cfg_file}")"

printf 'menuentry "%s" {\n    multiboot2 %s\n    boot\n}\n' Z-OS /boot/kernel.elf > "${iso_cfg_file}"
cp ./zig-out/bin/kernel.elf "${iso_dir}/boot/kernel.elf"

grub2-mkrescue -o ./zig-out/bin/z-os.iso "${iso_dir}"

qemu-system-i386 -cdrom ./zig-out/bin/z-os.iso \
    -no-reboot -no-shutdown \
    -monitor stdio \
    -m 5G
