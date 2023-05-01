;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

kernel_acpi_standard		db	"RSDT (Root System Description Pointer) found."
kernel_acpi_standard_end:
kernel_acpi_extended		db	"XSDT (eXtended System Descriptor Table) found."
kernel_acpi_extended_end:
kernel_acpi_lapic		db	STATIC_ASCII_NEW_LINE, " LAPIC base address 0x"
kernel_acpi_lapic_end:
kernel_acpi_io_apic		db	STATIC_ASCII_NEW_LINE, " I/O APIC base address 0x"
kernel_acpi_io_apic_end:

kernel_log_framebuffer		db	STATIC_ASCII_NEW_LINE, "Where are my testicles, Summer?"
kernel_log_framebuffer_end:
kernel_log_prefix		db	STATIC_ASCII_NEW_LINE, "+"
kernel_log_prefix_end:
kernel_log_free			db	" KiB released.", STATIC_ASCII_NEW_LINE
kernel_log_free_end:
kernel_log_kernel		db	STATIC_ASCII_NEW_LINE, "To be, or not to be, that is the question."
kernel_log_kernel_end:
kernel_log_memory		db	STATIC_ASCII_NEW_LINE, "Houston, we have a problem."
kernel_log_memory_end:
kernel_log_page			db	STATIC_ASCII_NEW_LINE, "Stuck In The Sound - Brother."
kernel_log_page_end:
kernel_log_rsdp			db	STATIC_ASCII_NEW_LINE, "Hello Darkness, My Old Friend."
kernel_log_rsdp_end:
kernel_log_smp			db	" AP(s) initialized."
kernel_log_smp_end:
kernel_log_storage		db	STATIC_ASCII_NEW_LINE, "Operation failed successfully."
kernel_log_storage_end:
kernel_log_system		db	STATIC_ASCII_NEW_LINE, "System disk [KiB]: "
kernel_log_system_end:
kernel_log_welcome		db	KERNEL_name, " (v", KERNEL_version, ".", KERNEL_revision, " ", KERNEL_architecture, " ", KERNEL_language, ", build on ", __DATE__, " ", __TIME__, ")", STATIC_ASCII_NEW_LINE
kernel_log_welcome_end:

kernel_smp_count		dq	EMPTY

kernel_exec_file_init		db	"wm"
kernel_exec_file_init_end:

kernel_daemon_file_gc		db	"gc.d"
kernel_daemon_file_gc_end:

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
kernel_limine_kernel_address_request:
	dq	LIMINE_KERNEL_ADDRESS_MAGIC
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

; align table
align	0x08,	db	0x00
kernel_limine_smp_request:
	dq	LIMINE_SMP_MAGIC
	dq	0	; revision
	dq	EMPTY	; response
	dq	EMPTY	; flags: do not emable X2APIC

; align table
align	0x08,	db	0x00
kernel_limine_module_request:
	dq	LIMINE_MODULE_MAGIC
	dq	0	; revision
	dq	EMPTY	; response
