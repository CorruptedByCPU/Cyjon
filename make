#!/bin/bash
#=================================================================================
# Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
#=================================================================================

# coloristics
green=$(tput setaf 2)
red=$(tput setaf 1)
default=$(tput sgr0)

AA="nasm"
A="nasm -p ./library/std.inc"
LD="ld.lld"
ISO="xorriso"
QEMU="qemu-system-x86_64"
LDFLAGS="-nostdlib -zmax-page-size=0x1000 -static -no-dynamic-linker"

# for clear view
clear

# external resources initialization
git submodule update --init

(cd limine && clang limine.c -o limine)
if [ "${1}" = "r" ] || [ ! -f ./foton/build/root.vfs ]; then (cd foton && ./make); fi

# check environment software, required!
ENV=true
echo -n "Cyjon environment: "
	type -a ${AA} &> /dev/null || (echo -en "\e[38;5;196m${AA}\e[0m" && ENV=false)
	type -a ${LD} &> /dev/null || (echo -en "\e[38;5;196m${LD}\e[0m" && ENV=false)
	type -a ${ISO} &> /dev/null || (echo -en "\e[38;5;196m${ISO}\e[0m" && ENV=false)
if [ "${ENV}" = false ]; then echo -e "\n[please install missing software]"; exit 1; else echo -e "\e[38;5;2m\xE2\x9C\x94\e[0m"; fi

# optional
type -a ${QEMU} &> /dev/null || echo -e "Optional \e[38;5;11m${QEMU}\e[0m not installed. ISO file will be generated regardless of that."

# remove all obsolete files, which could interference
rm -rf build && mkdir -p build/iso
rm -f bx_enh_dbg.ini	# just to make clean directory, if you executed bochs.sh

# build kernel file
${A} -f elf64 kernel/init.asm -o build/kernel.o || exit 1
${LD} build/kernel.o -o build/kernel -T tools/kernel.ld ${LDFLAGS} || exit 1;
strip -s build/kernel

# information
kernel_size=`ls -lh build/kernel | cut -d ' ' -f 5`
echo -e "${green}\xE2\x9C\x94${default}|Kernel|${kernel_size}" | awk -F "|" '{printf "%s  %-30s %s\n", $1, $2, $3 }'

# copy kernel file, external software and limine files onto destined iso folder
cp build/kernel tools/limine.conf limine/limine-bios.sys limine/limine-bios-cd.bin limine/limine-uefi-cd.bin build/iso
cp foton/build/root.vfs build/iso 2>/dev/null

# information
root_size=`ls -lh build/iso/root.vfs 2>&1 | cut -d ' ' -f 5`
if [ ! $? ]; then echo -ne "${red}\xE2\x9D\x8C"; else echo -ne "${green}\xE2\x9C\x94"; fi
echo -e "${default}|root.vfs|${root_size}" | awk -F "|" '{printf "%s  %-30s %s\n", $1, $2, $3 }'

# convert iso directory to iso file
xorriso -as mkisofs -b limine-bios-cd.bin -no-emul-boot -boot-load-size 4 -boot-info-table --efi-boot limine-uefi-cd.bin -efi-boot-part --efi-boot-image --protective-msdos-label build/iso -o build/cyjon.iso > /dev/null 2>&1

# install bootloader limine inside created
limine/limine bios-install build/cyjon.iso > /dev/null 2>&1
