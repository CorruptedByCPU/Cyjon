#!/bin/bash
#===============================================================================
#Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
#===============================================================================

qemu-system-x86_64		\
	-s -S			\
	--enable-kvm		\
	-cpu max		\
	-smp 2			\
	-m 128			\
	-cdrom build/cyjon.iso	\
	-rtc base=localtime 	\
	-serial file:serial.log &

sleep 1

./r2.sh

