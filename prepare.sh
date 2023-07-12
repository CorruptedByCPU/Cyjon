#!/bin/bash
#===============================================================================
#Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
#===============================================================================

git submodule update --init

rm -f bx_enh_dbg.ini
rm -rf build && mkdir build > /dev/null 2>&1
rm -rf iso && mkdir iso > /dev/null 2>&1

LDFLAGS="-nostdlib -zmax-page-size=0x1000 -static -no-dynamic-linker"

nasm -f elf64 kernel/init.asm -o build/kernel.o
ld build/kernel.o -o build/kernel -T linker.kernel
gzip -fk build/kernel

rm -f build/*.o

cp limine.cfg limine/limine.sys limine/limine-cd.bin limine/limine-cd-efi.bin iso/
cp build/kernel.gz iso
