#!/bin/bash
#===============================================================================
#Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
#===============================================================================

rm -f bx_enh_dbg.ini
rm -rf build && mkdir build > /dev/null 2>&1
rm -rf iso && mkdir iso > /dev/null 2>&1

# I use programs from Fern-Night, to make sure they are compatible with Cyjon
# rm -rf system && mkdir system > /dev/null 2>&1

LDFLAGS="-nostdlib -zmax-page-size=0x1000 -static -no-dynamic-linker"

nasm -f elf64 kernel/init.asm -o build/kernel.o
ld build/kernel.o -o build/kernel -T linker.kernel
gzip -fk build/kernel

#lib=""
#for shared in `(cd system && ls lib* > /dev/null 2>&1)`; do lib="${lib} -l${shared:3:$(expr ${#shared} - 6)}"; done

#if [ `ls software | grep asm$ | wc -l` -ne 0 ]; then
#	for software in `(cd software && ls *.asm)`; do
#		name=`echo $software | cut -d '.' -f 1`
#		nasm -f elf64 software/${name}.asm -o build/${name}.o || exit 1
#		ld --as-needed -L./system build/${name}.o -o system/${name} ${lib} -T linker.software ${LDFLAGS}
#	done
#fi

rm -f build/*.o

git submodule update --init

cp limine.cfg limine/limine.sys limine/limine-cd.bin limine/limine-cd-efi.bin iso/
cp build/kernel.gz iso
