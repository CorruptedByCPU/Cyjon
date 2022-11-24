;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

%define	LIMINE_COMMON_MAGIC		0xc7b1dd30df4c8b88, 0x0a82e883a194f07b
%define	LIMINE_FRAMEBUFFER_MAGIC	LIMINE_COMMON_MAGIC, 0x9d5827dcd881dd75, 0xa3148604f6fab11b
%define	LIMINE_MEMMAP_MAGIC		LIMINE_COMMON_MAGIC, 0x67cf3d9d378a806f, 0xe304acdfc50c3c62
%define	LIMINE_RSDP_MAGIC		LIMINE_COMMON_MAGIC, 0xc5e77b6b397e7b43, 0x27637845accdcf3c

%define	LIMINE_MEMMAP_USABLE			0
%define	LIMINE_MEMMAP_RESERVED			1
%define	LIMINE_MEMMAP_ACPI_RECLAIMABLE		2
%define	LIMINE_MEMMAP_ACPI_NVS			3
%define	LIMINE_MEMMAP_BAD_MEMORY		4
%define	LIMINE_MEMMAP_BOOTLOADER_RECLAIMABLE	5
%define	LIMINE_MEMMAP_KERNEL_AND_MODULES	6
%define	LIMINE_MEMMAP_FRAMEBUFFER		7

struc	LIMINE_FRAMEBUFFER
	.address		resq	1
	.width			resq	1
	.height			resq	1
	.pitch			resq	1
	.bpp			resw	1
	.unused_by_cyjon:
endstruc

struc	LIMINE_FRAMEBUFFER_RESPONSE
	.revision		resq	1
	.framebuffer_count	resq	1
	.framebuffer		resq	1

struc	LIMINE_FRAMEBUFFER_REQUEST
	.id			resq	4
	.revision		resq	1
	.response		resq	1
endstruc

struc	LIMINE_MEMMAP_ENTRY
	.base			resq	1
	.length			resq	1
	.type			resq	1
	.SIZE:
endstruc

struc	LIMINE_MEMMAP_RESPONSE
	.revision		resq	1
	.entry_count		resq	1
	.entry			resq	1

struc	LIMINE_MEMMAP_REQUEST
	.id			resq	4
	.revision		resq	1
	.response		resq	1
endstruc

struc	LIMINE_RSDP_RESPONSE
	.revision		resq	1
	.address		resq	1
endstruc

struc	LIMINE_RSDP_REQUEST
	.id			resq	4
	.revision		resq	1
	.response		resq	1
endstruc