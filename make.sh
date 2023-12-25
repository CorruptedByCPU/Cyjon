#!/bin/bash
#===============================================================================
#Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
#===============================================================================

clear

/bin/bash prepare.sh

cp ../fern-night/build/system.gz iso

xorriso -as mkisofs -b limine-cd.bin -no-emul-boot -boot-load-size 4 -boot-info-table --efi-boot limine-cd-efi.bin -efi-boot-part --efi-boot-image --protective-msdos-label iso -o build/cyjon.iso > /dev/null 2>&1

(git submodule update --init && cd limine && make ) > /dev/null 2>&1
limine/limine-deploy build/cyjon.iso > /dev/null 2>&1

echo -e "build:"
ls -lah build/ | tail -n +4 | awk '//{printf "%16s %8s\n",$(NF),$5 }'
