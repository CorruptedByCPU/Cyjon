;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

%define	VARIABLE_PANIC	VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, "System wstrzymany.", VARIABLE_ASCII_CODE_TERMINATOR

; Use:
; nasm - http://www.nasm.us/

text_kernel_welcome				db	"Uruchamiam Cyjon OS!", VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_TERMINATOR

; błędy jądra systemu
text_kernel_panic_binary_memory_map_fail	db	"Nie udalo sie utworzyc Binarnej Mapy Pamieci.", VARIABLE_PANIC
text_kernel_panic_cpu_interrupt			db	"CPU: Nieobsluzony wyjatek.", VARIABLE_PANIC
text_kernel_panic_hardware_interrupt		db	"CPU: Nieobsluzone przerwanie sprzetowe.", VARIABLE_PANIC
text_kernel_panic_software_interrupt		db	"CPU: Niedozwolone dzialanie.", VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_TERMINATOR
text_kernel_panic_gdt				db	"GDT: Brak wolnej przestrzeni pamieci.", VARIABLE_PANIC
text_kernel_panic_page_pml4			db	"PML4: Przepelnienie tablicy.", VARIABLE_PANIC
text_kernel_panic_sheduler_no_memory		db	"SHEDULER: Brak wolnej przestrzeni pamieci.", VARIABLE_PANIC

; ogólne informacje
text_binary_memory_map_available_memory		db	" Dostepna wolna pamiec: ", VARIABLE_ASCII_CODE_TERMINATOR

; informacje sterowników
text_vfs_ready					db	" Wirtualny system plikow, gotowy.", VARIABLE_ASCII_CODE_RETURN
text_vfs_fail					db	"VFS: Nie mozna zainicjalizowac systemu plikow.", VARIABLE_PANIC
text_vfs_no_memory				db	"VFS: Brak wystarczajacej ilosci pamieci.", VARIABLE_PANIC
text_nic_i8254x					db	" Kontroler sieci Intel 82540EM, MAC ", VARIABLE_ASCII_CODE_TERMINATOR
text_ide_found					db	" Znaleziono dyski ATA:", VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_TERMINATOR
text_ide_serial					db	", sn: ", VARIABLE_ASCII_CODE_TERMINATOR
text_ide_size					db	", rozmiar ", VARIABLE_ASCII_CODE_TERMINATOR

text_bytes					db	" Bajtow", VARIABLE_ASCII_CODE_TERMINATOR

; błędy procesów
text_process_prohibited_operation		db	"Niedozwolona operacja, proces zniszczony.", VARIABLE_ASCII_CODE_RETURN

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
