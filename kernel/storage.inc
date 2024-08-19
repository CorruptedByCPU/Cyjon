;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

%ifndef	KERNEL_STORAGE
	%define	KERNEL_STORAGE

	; ignore more storages than hard limit
	%define	KERNEL_STORAGE_limit		(STD_PAGE_byte / KERNEL_STRUCTURE_STORAGE.SIZE)

	; storage type:
	%define	KERNEL_STORAGE_TYPE_vfs		00000001b	; Virtual File System

	; storage class:
	%define	KERNEL_STORAGE_CLASS_block	00000001b	; whole storage
	%define	KERNEL_STORAGE_CLASS_partition	00000010b	; part of storage

	struc	KERNEL_STRUCTURE_STORAGE
		.device_type	resb	1
		.device_class	resb	1
		.device_block	resq	1	; first usable block of storage
		.device_byte	resq	1	; size of single BLOCK in Bytes;
		.device_length	resq	1	; size of storage CLASS in blocks
		.SIZE:
	endstruc
%endif