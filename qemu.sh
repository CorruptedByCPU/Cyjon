#!/bin/bash
#=================================================================================
# Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
#=================================================================================

# default CPUs amount: 2
SMP="${1}"
if [ -z "${SMP}" ]; then SMP="2"; fi

# default Memory size: 64 MiB
MEM="${2}"
if [ -z "${MEM}" ]; then MEM="64"; fi

qemu-system-x86_64				\
	--enable-kvm				\
	-cpu host				\
	-smp ${SMP}				\
	-m ${MEM}				\
	-hda build/disk_with_omega.raw		\
	-rtc base=localtime			\
	-serial stdio				\
	# -usb -device usb-mouse,id=mouse		\
	# -usb -device usb-kbd,id=keyboard	\
