#!/bin/bash
#===============================================================================
#Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
#===============================================================================

# clear debug log file
echo "" > serial.log

if [ -z "${1}" ]; then
	smp="2"
else
	smp="${1}"
fi

# run with specific configration
qemu-system-x86_64			\
	--enable-kvm			\
	-cpu max			\
	-smp ${smp}			\
	-m 128				\
	-cdrom build/cyjon.iso		\
	-netdev user,id=ethx		\
	-device e1000,netdev=ethx	\
	-rtc base=localtime 		\
	-serial file:serial.log

# show debug log
cat serial.log
