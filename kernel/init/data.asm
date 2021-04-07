;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

; nagłówek poszukiwany przez program rozruchowy Zero
align	STATIC_QWORD_SIZE_byte	; wyrównaj nagłówek do pełnego adresu
kernel_header:
						db	"Z E R O "	; czysta magija
						dq	init		; wskaźnik do głównej procedury jądra systemu

kernel_init_string_name				db	KERNEL_name
kernel_init_string_name_end:

kernel_init_string_error_memory			db	"Error: Memory map damaged.", STATIC_SCANCODE_TERMINATOR
kernel_init_string_error_memory_low		db	"Error: Not enough memory.", STATIC_SCANCODE_TERMINATOR
kernel_init_string_error_acpi_header		db	"Error: RSDP/XSDP not found.", STATIC_SCANCODE_TERMINATOR
kernel_init_string_error_acpi			db	"Error: RSDT/XSDT not recognized.", STATIC_SCANCODE_TERMINATOR
kernel_init_string_error_apic			db	"Error: APIC not found.", STATIC_SCANCODE_TERMINATOR
kernel_init_string_error_ioapic			db	"Error: I/O APIC not found.", STATIC_SCANCODE_TERMINATOR

kernel_init_string_serial			db	"COM1: initialized.", STATIC_SCANCODE_TERMINATOR
kernel_init_string_video_address		db	STATIC_SCANCODE_NEW_LINE, "Video: Memory location 0x", STATIC_SCANCODE_TERMINATOR
kernel_init_string_ahci_address			db	STATIC_SCANCODE_NEW_LINE, "AHCI: HBA Registers 0x", STATIC_SCANCODE_TERMINATOR

kernel_init_string_value_cache	TIMES	21	db	STATIC_EMPTY

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
						dq	kernel_vfs
						dq	kernel_vfs_end - kernel_vfs
						db	21
						db	"[virtual file system]"
						dq	kernel_gc
						dq	kernel_gc_end - kernel_gc
						db	19
						db	"[garbage collector]"
						dq	kernel_wm
						dq	kernel_wm_end - kernel_wm
						db	16
						db	"[window manager]"
						dq	kernel_gui
						dq	kernel_gui_end - kernel_gui
						db	24
						db	"[graphic user interface]"

						; koniec usług
						dq	STATIC_EMPTY

kernel_init_vfs_directory_structure:
						dw	KERNEL_VFS_FILE_MODE_USER_full_control | KERNEL_VFS_FILE_MODE_GROUP_execute_or_traverse | KERNEL_VFS_FILE_MODE_OTHER_execute_or_traverse
						db	0x04
						db	"/bin"
						dw	KERNEL_VFS_FILE_MODE_USER_full_control | KERNEL_VFS_FILE_MODE_GROUP_execute_or_traverse | KERNEL_VFS_FILE_MODE_OTHER_execute_or_traverse
						db	0x04
						db	"/etc"
						dw	KERNEL_VFS_FILE_MODE_USER_full_control | KERNEL_VFS_FILE_MODE_GROUP_execute_or_traverse | KERNEL_VFS_FILE_MODE_OTHER_execute_or_traverse
						db	0x04
						db	"/dev"
						dw	KERNEL_VFS_FILE_MODE_USER_full_control | KERNEL_VFS_FILE_MODE_GROUP_execute_or_traverse | KERNEL_VFS_FILE_MODE_OTHER_execute_or_traverse
						db	0x04
						db	"/var"

						; koniec struktury katalogów
						dw	STATIC_EMPTY

kernel_init_vfs_files:
						dq	kernel_init_vfs_file_shell
						dq	kernel_init_vfs_file_shell_end - kernel_init_vfs_file_shell
						dw	KERNEL_VFS_FILE_MODE_USER_full_control | KERNEL_VFS_FILE_MODE_GROUP_execute_or_traverse | KERNEL_VFS_FILE_MODE_OTHER_execute_or_traverse
						db	10
						db	"/bin/shell"

						dq	kernel_init_vfs_file_hello
						dq	kernel_init_vfs_file_hello_end - kernel_init_vfs_file_hello
						dw	KERNEL_VFS_FILE_MODE_USER_full_control | KERNEL_VFS_FILE_MODE_GROUP_execute_or_traverse | KERNEL_VFS_FILE_MODE_OTHER_execute_or_traverse
						db	10
						db	"/bin/hello"

						dq	kernel_init_vfs_file_tm
						dq	kernel_init_vfs_file_tm_end - kernel_init_vfs_file_tm
						dw	KERNEL_VFS_FILE_MODE_USER_full_control | KERNEL_VFS_FILE_MODE_GROUP_execute_or_traverse | KERNEL_VFS_FILE_MODE_OTHER_execute_or_traverse
						db	7
						db	"/bin/tm"

						dq	kernel_init_vfs_file_console
						dq	kernel_init_vfs_file_console_end - kernel_init_vfs_file_console
						dw	KERNEL_VFS_FILE_MODE_USER_full_control | KERNEL_VFS_FILE_MODE_GROUP_execute_or_traverse | KERNEL_VFS_FILE_MODE_OTHER_execute_or_traverse
						db	12
						db	"/bin/console"

						dq	kernel_init_vfs_file_ls
						dq	kernel_init_vfs_file_ls_end - kernel_init_vfs_file_ls
						dw	KERNEL_VFS_FILE_MODE_USER_full_control | KERNEL_VFS_FILE_MODE_GROUP_execute_or_traverse | KERNEL_VFS_FILE_MODE_OTHER_execute_or_traverse
						db	7
						db	"/bin/ls"

						dq	kernel_init_vfs_file_cat
						dq	kernel_init_vfs_file_cat_end - kernel_init_vfs_file_cat
						dw	KERNEL_VFS_FILE_MODE_USER_full_control | KERNEL_VFS_FILE_MODE_GROUP_execute_or_traverse | KERNEL_VFS_FILE_MODE_OTHER_execute_or_traverse
						db	8
						db	"/bin/cat"

						dq	kernel_init_vfs_file_moko
						dq	kernel_init_vfs_file_moko_end - kernel_init_vfs_file_moko
						dw	KERNEL_VFS_FILE_MODE_USER_full_control | KERNEL_VFS_FILE_MODE_GROUP_execute_or_traverse | KERNEL_VFS_FILE_MODE_OTHER_execute_or_traverse
						db	9
						db	"/bin/moko"

						dq	kernel_init_vfs_file_soler
						dq	kernel_init_vfs_file_soler_end - kernel_init_vfs_file_soler
						dw	KERNEL_VFS_FILE_MODE_USER_full_control | KERNEL_VFS_FILE_MODE_GROUP_execute_or_traverse | KERNEL_VFS_FILE_MODE_OTHER_execute_or_traverse
						db	10
						db	"/bin/soler"

						dq	kernel_init_vfs_file_taris
						dq	kernel_init_vfs_file_taris_end - kernel_init_vfs_file_taris
						dw	KERNEL_VFS_FILE_MODE_USER_full_control | KERNEL_VFS_FILE_MODE_GROUP_execute_or_traverse | KERNEL_VFS_FILE_MODE_OTHER_execute_or_traverse
						db	10
						db	"/bin/taris"

						dq	kernel_init_vfs_file_mural
						dq	kernel_init_vfs_file_mural_end - kernel_init_vfs_file_mural
						dw	KERNEL_VFS_FILE_MODE_USER_full_control | KERNEL_VFS_FILE_MODE_GROUP_execute_or_traverse | KERNEL_VFS_FILE_MODE_OTHER_execute_or_traverse
						db	10
						db	"/bin/mural"

						dq	kernel_init_vfs_file_hostname
						dq	kernel_init_vfs_file_hostname_end - kernel_init_vfs_file_hostname
						dw	KERNEL_VFS_FILE_MODE_USER_read | KERNEL_VFS_FILE_MODE_USER_read | KERNEL_VFS_FILE_MODE_USER_read | KERNEL_VFS_FILE_MODE_OTHER_read
						db	13
						db	"/etc/hostname"

						dq	kernel_init_vfs_file_welcome
						dq	kernel_init_vfs_file_welcome_end - kernel_init_vfs_file_welcome
						dw	KERNEL_VFS_FILE_MODE_USER_read | KERNEL_VFS_FILE_MODE_USER_read | KERNEL_VFS_FILE_MODE_USER_read | KERNEL_VFS_FILE_MODE_OTHER_read
						db	16
						db	"/var/welcome.txt"


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
kernel_init_vfs_file_ls				incbin	"build/ls"
kernel_init_vfs_file_ls_end:
kernel_init_vfs_file_cat			incbin	"build/cat"
kernel_init_vfs_file_cat_end:
kernel_init_vfs_file_moko			incbin	"build/moko"
kernel_init_vfs_file_moko_end:
kernel_init_vfs_file_soler			incbin	"build/soler"
kernel_init_vfs_file_soler_end:
kernel_init_vfs_file_taris			incbin	"build/taris"
kernel_init_vfs_file_taris_end:
kernel_init_vfs_file_mural			incbin	"build/mural"
kernel_init_vfs_file_mural_end:

kernel_init_vfs_file_hostname			incbin	"fs/etc/hostname"
kernel_init_vfs_file_hostname_end:

kernel_init_vfs_file_welcome			incbin	"fs/var/welcome.txt"
kernel_init_vfs_file_welcome_end:

kernel_init_boot_file:
						incbin	"build/boot"
kernel_init_boot_file_end:

align	STATIC_QWORD_SIZE_byte,			db	STATIC_NOTHING
kernel_init_library_file			incbin	"build/library"
align	STATIC_QWORD_SIZE_byte,			db	STATIC_NOTHING
kernel_init_library_file_end:
