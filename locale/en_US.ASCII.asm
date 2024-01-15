;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

%define	VARIABLE_PANIC	VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, "System halted.", VARIABLE_ASCII_CODE_TERMINATOR

; Use:
; nasm - http://www.nasm.us/

;text_kernel_welcome				db	"!", '"', "#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~", VARIABLE_ASCII_CODE_TERMINATOR
text_kernel_welcome				db	"Running Cyjon OS!", VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_TERMINATOR

; błędy jądra systemu
text_kernel_panic_binary_memory_map_fail	db	"Failed to create Binary Memory Map.", VARIABLE_PANIC
text_kernel_panic_cpu_interrupt			db	"CPU: Unhandled interrupt.", VARIABLE_PANIC
text_kernel_panic_hardware_interrupt		db	"CPU: Unhandled Hardware interrupt.", VARIABLE_PANIC
text_kernel_panic_software_interrupt		db	"CPU: Illegal operation.", VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_TERMINATOR
text_kernel_panic_gdt				db	"GDT: No free memory.", VARIABLE_PANIC
text_kernel_panic_page_pml4			db	"PML4: Table overload.", VARIABLE_PANIC
text_kernel_panic_sheduler_no_memory		db	"SHEDULER: No Free memory.", VARIABLE_PANIC

; ogólne informacje
text_binary_memory_map_available_memory		db	" Available free memory: ", VARIABLE_ASCII_CODE_TERMINATOR

; informacje sterowników
text_vfs_ready					db	" Virtual File System, ready.", VARIABLE_ASCII_CODE_RETURN
text_vfs_fail					db	"VFS: Can't initialize file system.", VARIABLE_PANIC
text_vfs_no_memory				db	"VFS: There is not enough memory.", VARIABLE_PANIC
text_nic_i8254x					db	" Network controller Intel 82540EM, MAC ", VARIABLE_ASCII_CODE_TERMINATOR
text_ide_found					db	" Found ATA drives:", VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_TERMINATOR
text_ide_serial					db	", sn: ", VARIABLE_ASCII_CODE_TERMINATOR
text_ide_size					db	", size ", VARIABLE_ASCII_CODE_TERMINATOR

text_bytes					db	" Bytes", VARIABLE_ASCII_CODE_TERMINATOR

; błędy procesów
text_process_prohibited_operation		db	"Prohibited operation, process destroyed.", VARIABLE_ASCII_CODE_RETURN

; błędy procesora
text_cpu_exception_0				db	"Divice-by-zero Error :O", VARIABLE_ASCII_CODE_RETURN
text_cpu_exception_1				db	"Debug", VARIABLE_ASCII_CODE_RETURN
text_cpu_exception_2				db	"Non-maskable Interrupt", VARIABLE_ASCII_CODE_RETURN
text_cpu_exception_3				db	"Breakpoint", VARIABLE_ASCII_CODE_RETURN
text_cpu_exception_4				db	"Overflow", VARIABLE_ASCII_CODE_RETURN
text_cpu_exception_5				db	"Bound Range Exceeded", VARIABLE_ASCII_CODE_RETURN
text_cpu_exception_6				db	"Invalid Opcode :/", VARIABLE_ASCII_CODE_RETURN
text_cpu_exception_7				db	"Device Not Available", VARIABLE_ASCII_CODE_RETURN
text_cpu_exception_8				db	"Double Fault :)", VARIABLE_ASCII_CODE_RETURN
text_cpu_exception_9				db	"Coprocessor Segment Overrun", VARIABLE_ASCII_CODE_RETURN
text_cpu_exception_10				db	"Invalid TSS", VARIABLE_ASCII_CODE_RETURN
text_cpu_exception_11				db	"Segment Not Present", VARIABLE_ASCII_CODE_RETURN
text_cpu_exception_12				db	"Stack-Segment Fault", VARIABLE_ASCII_CODE_RETURN
text_cpu_exception_13				db	"General Protection Fault :|", VARIABLE_ASCII_CODE_RETURN
text_cpu_exception_14				db	"Page Fault :[", VARIABLE_ASCII_CODE_RETURN
text_cpu_exception_16				db	"x87 Floating-Point Exception", VARIABLE_ASCII_CODE_RETURN
text_cpu_exception_17				db	"Alignment Check", VARIABLE_ASCII_CODE_RETURN
text_cpu_exception_18				db	"Machine Check", VARIABLE_ASCII_CODE_RETURN
text_cpu_exception_19				db	"SIMD Floating-Point Exception", VARIABLE_ASCII_CODE_RETURN
text_cpu_exception_20				db	"Virtualization Exception", VARIABLE_ASCII_CODE_RETURN
text_cpu_exception_30				db	"Security Exception O_o", VARIABLE_ASCII_CODE_RETURN
