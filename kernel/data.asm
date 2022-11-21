;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

kernel_log_welcome	db	KERNEL_name, " (build v", KERNEL_version, ".", KERNEL_revision, " ", KERNEL_architecture, ", compiled ", __DATE__, " ", __TIME__, ")", STATIC_ASCII_NEW_LINE, STATIC_ASCII_TERMINATOR
kernel_log_framebuffer	db	"Where are my testicles, Summer?", STATIC_ASCII_NEW_LINE, STATIC_ASCII_TERMINATOR

align	0x08
kernel_limine_framebuffer_request:
	dq	LIMINE_FRAMEBUFFER_MAGIC
	dq	EMPTY