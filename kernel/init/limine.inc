;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

%define	LIMINE_COMMON_MAGIC		0xc7b1dd30df4c8b88, 0x0a82e883a194f07b
%define	LIMINE_FRAMEBUFFER_MAGIC	LIMINE_COMMON_MAGIC, 0x9d5827dcd881dd75, 0xa3148604f6fab11b

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