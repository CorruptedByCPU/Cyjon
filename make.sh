#!/bin/bash
#===============================================================================
#Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
#===============================================================================

clear

rm -rf build && mkdir build > /dev/null 2>&1
rm -rf iso && mkdir iso > /dev/null 2>&1

LDFLAGS="-nostdlib -zmax-page-size=0x1000 -static -no-dynamic-linker"

nasm -f elf64 kernel/init.asm -o build/kernel.o
ld build/kernel.o -o build/kernel -T linker.kernel
gzip -fk build/kernel

cp limine.cfg limine/limine.sys limine/limine-cd.bin limine/limine-cd-efi.bin iso/
cp build/kernel.gz iso/kernel

xorriso -as mkisofs -b limine-cd.bin -no-emul-boot -boot-load-size 4 -boot-info-table --efi-boot limine-cd-efi.bin -efi-boot-part --efi-boot-image --protective-msdos-label iso -o build/cyjon.iso > /dev/null 2>&1

(git submodule update --init && cd limine && make ) > /dev/null 2>&1
limine/limine-deploy build/cyjon.iso > /dev/null 2>&1

echo -e "\nbuild:"
ls -lah build/ | tail -n +4 | awk '//{printf "%16s %8s\n",$(NF),$5 }'
