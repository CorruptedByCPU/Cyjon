;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================


kernel_acpi_standard		db	"RSDT (Root System Description Pointer) found.", STATIC_ASCII_TERMINATOR
kernel_acpi_extended		db	"XSDT (eXtended System Descriptor Table) found.", STATIC_ASCII_TERMINATOR
kernel_acpi_lapic		db	STATIC_ASCII_NEW_LINE, " LAPIC base address 0x", STATIC_ASCII_TERMINATOR
kernel_acpi_io_apic		db	STATIC_ASCII_NEW_LINE, " I/O APIC base address 0x", STATIC_ASCII_TERMINATOR

kernel_log_framebuffer		db	STATIC_ASCII_NEW_LINE, "Where are my testicles, Summer?", STATIC_ASCII_TERMINATOR
kernel_log_kernel		db	STATIC_ASCII_NEW_LINE, "To be, or not to be, that is the question.", STATIC_ASCII_TERMINATOR
kernel_log_memory		db	STATIC_ASCII_NEW_LINE, "Houston, we have a problem.", STATIC_ASCII_TERMINATOR
kernel_log_page			db	STATIC_ASCII_NEW_LINE, "Stuck In The Sound - Brother.", STATIC_ASCII_TERMINATOR
kernel_log_rsdp			db	STATIC_ASCII_NEW_LINE, "Hello Darkness, My Old Friend.", STATIC_ASCII_TERMINATOR
kernel_log_welcome		db	KERNEL_name, " (build v", KERNEL_version, ".", KERNEL_revision, " ", KERNEL_architecture, " ", KERNEL_language, ", compiled ", __DATE__, " ", __TIME__, ")", STATIC_ASCII_NEW_LINE, STATIC_ASCII_TERMINATOR

; align table
align	0x08,	db	0x00
kernel_limine_framebuffer_request:
	dq	LIMINE_FRAMEBUFFER_MAGIC
	dq	0	; revision
	dq	EMPTY	; response

; align table
align	0x08,	db	0x00
kernel_limine_kernel_file_request:
	dq	LIMINE_KERNEL_FILE_MAGIC
	dq	0	; revision
	dq	EMPTY	; response

; align table
align	0x08,	db	0x00
kernel_limine_kernel_file_address_request:
	dq	LIMINE_KERNEL_ADDRESS_REQUEST
	dq	0	; revision
	dq	EMPTY	; response

; align table
align	0x08,	db	0x00
kernel_limine_memmap_request:
	dq	LIMINE_MEMMAP_MAGIC
	dq	0	; revision
	dq	EMPTY	; response

; align table
align	0x08,	db	0x00
kernel_limine_rsdp_request:
	dq	LIMINE_RSDP_MAGIC
	dq	0	; revision
	dq	EMPTY	; response