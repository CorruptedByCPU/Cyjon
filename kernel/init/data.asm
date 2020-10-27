;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

kernel_init_string_name				db	KERNEL_name
kernel_init_string_name_end:

kernel_init_string_error_memory			db	"Error: Memory map damaged.", STATIC_ASCII_TERMINATOR
kernel_init_string_error_memory_low		db	"Error: Not enough memory.", STATIC_ASCII_TERMINATOR
kernel_init_string_error_acpi_header		db	"Error: RSDP/XSDP not found.", STATIC_ASCII_TERMINATOR
kernel_init_string_error_acpi			db	"Error: RSDT/XSDT not recognized.", STATIC_ASCII_TERMINATOR
kernel_init_string_error_apic			db	"Error: APIC not found.", STATIC_ASCII_TERMINATOR
kernel_init_string_error_ioapic			db	"Error: I/O APIC not found.", STATIC_ASCII_TERMINATOR

kernel_init_string_storage_ide_hd_path		db	"/dev/hd"
kernel_init_string_storage_ide_hd_letter	db	"a"
kernel_init_string_storage_ide_hd_end:

kernel_init_apic_semaphore			db	STATIC_FALSE
kernel_init_ioapic_semaphore			db	STATIC_FALSE
kernel_init_smp_semaphore			db	STATIC_FALSE
kernel_init_ap_semaphore			db	STATIC_FALSE
kernel_init_ap_count				db	STATIC_EMPTY

kernel_init_apic_id_highest			db	STATIC_EMPTY

kernel_init_services_list:
						dq	service_gc
						db	2
						db	"gc"
						dq	kernel_wm
						db	2
						db	"wm"
						dq	kernel_gui
						db	3
						db	"gui"
						; dq	service_tx
						; dq	service_network
						; dq	service_http

						; koniec usług
						dq	STATIC_EMPTY

kernel_init_vfs_directory_structure:
						db	0x04
						db	"/bin"
						db	0x04
						db	"/dev"

						; koniec struktury katalogów
						db	STATIC_EMPTY

kernel_init_vfs_files:
						dq	kernel_init_vfs_file_shell
						dq	kernel_init_vfs_file_shell_end - kernel_init_vfs_file_shell
						db	10
						db	"/bin/shell"

						dq	kernel_init_vfs_file_hello
						dq	kernel_init_vfs_file_hello_end - kernel_init_vfs_file_hello
						db	10
						db	"/bin/hello"

						dq	kernel_init_vfs_file_tm
						dq	kernel_init_vfs_file_tm_end - kernel_init_vfs_file_tm
						db	7
						db	"/bin/tm"

						dq	kernel_init_vfs_file_console
						dq	kernel_init_vfs_file_console_end - kernel_init_vfs_file_console
						db	12
						db	"/bin/console"

						; koniec listy plików
						dq	STATIC_EMPTY

kernel_init_vfs_file_shell			incbin	"build/shell"
kernel_init_vfs_file_shell_end:
kernel_init_vfs_file_hello			incbin	"build/hello"
kernel_init_vfs_file_hello_end:
kernel_init_vfs_file_tm				incbin	"build/tm"
kernel_init_vfs_file_tm_end:
kernel_init_vfs_file_console			incbin	"build/console"
kernel_init_vfs_file_console_end:

kernel_init_boot_file:
						incbin	"build/boot"
kernel_init_boot_file_end:
