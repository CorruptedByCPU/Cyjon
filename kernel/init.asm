;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

	;----------------------------------------------------------------------
	; library as build-in
	;----------------------------------------------------------------------
	%include	"library/string.asm"

	;-----------------------------------------------------------------------
	; structures, definitions
	;-----------------------------------------------------------------------
	; library --------------------------------------------------------------
	%include	"library/elf.inc"
	%include	"library/vfs.inc"
%include	"library/sys.inc"
	; driver ---------------------------------------------------------------
	%include	"kernel/driver/rtc.inc"
	; kernel ---------------------------------------------------------------
	%include	"kernel/config.inc"
%include	"kernel/exec.inc"
%include	"kernel/io_apic.inc"
	%include	"kernel/ipc.inc"
%include	"kernel/lapic.inc"
%include	"kernel/library.inc"
%include	"kernel/page.inc"
%include	"kernel/storage.inc"
%include	"kernel/stream.inc"
	%include	"kernel/vfs.inc"
	%include	"kernel/task.inc"
	;----------------------------------------------------------------------
	; variables, structures, definitions of kernel environment initialization
	;----------------------------------------------------------------------
	%include	"kernel/init/acpi.inc"
	%include	"kernel/init/limine.inc"	; there is no limine.h for Assembly
	%include	"kernel/init/ap.inc"
	;=======================================================================

; we are using Position Independed Code
default	rel

; main initialization procedure of kernel environment
global	_entry

; information for linker
section	.data
	;-----------------------------------------------------------------------
	; variables, constants
	;-----------------------------------------------------------------------
%include	"kernel/data.asm"
	;=======================================================================

; 64 bit code
[bits 64]

; information for linker
section .text
	;-----------------------------------------------------------------------
	; routines
	;-----------------------------------------------------------------------
	; library --------------------------------------------------------------
	%include	"library/elf.asm"
	; drivers --------------------------------------------------------------
	%include	"kernel/driver/rtc.asm"
	%include	"kernel/driver/serial.asm"
	; kernel ---------------------------------------------------------------
; %include	"kernel/exec.asm"
	%include	"kernel/idt.asm"
%include	"kernel/io_apic.asm"
%include	"kernel/lapic.asm"
; %include	"kernel/library.asm"
%include	"kernel/log.asm"
%include	"kernel/memory.asm"
%include	"kernel/page.asm"
; %include	"kernel/service.asm"
	%include	"kernel/storage.asm"
%include	"kernel/stream.asm"
; %include	"kernel/syscall.asm"
%include	"kernel/task.asm"
	%include	"kernel/vfs.asm"
	%include	"kernel/time.asm"
	; kernel environment initialization routines ---------------------------
	%include	"kernel/init/environment.asm"
	%include	"kernel/init/limine.asm"
	%include	"kernel/init/memory.asm"
	%include	"kernel/init/acpi.asm"
	%include	"kernel/init/page.asm"
	%include	"kernel/init/gdt.asm"
	%include	"kernel/init/idt.asm"
	%include	"kernel/init/stream.asm"
	%include	"kernel/init/task.asm"
	%include	"kernel/init/ipc.asm"
	%include	"kernel/init/storage.asm"
	%include	"kernel/init/vfs.asm"
; %include	"kernel/init/cmd.asm"
; %include	"kernel/init/daemon.asm"
; %include	"kernel/init/exec.asm"
; %include	"kernel/init/free.asm"
; %include	"kernel/init/library.asm"
; %include	"kernel/init/smp.asm"
	%include	"kernel/init/ap.asm"
	;=======================================================================

;------------------------------
; ^ files for refactorization -
; 	^ files already done  -
;------------------------------
; debug -
;--------

; our mighty init
_entry:
	; DEBUG ---------------------------------------------------------------

	; initialize default debug output
	call	driver_serial_init

	; check passed variables/structures by Limine bootloader
	call	kernel_init_limine

	; BASE ----------------------------------------------------------------

	; initialize global kernel environment variables/functions/rountines
	call	kernel_init_environment

	; from now on, register R8 will contain pointer to global kernel environment variables/functions/rountines, up to end of initialization

	; create binary memory map
	call	kernel_init_memory

	; from now on, register R9 will contain pointer to binary memory map, up to end of initialization

	; parse ACPI tables
	call	kernel_init_acpi

	; recreate kernel's paging structures
	call	kernel_init_page

	; reload new kernel environment paging array
	mov	rax,	~KERNEL_PAGE_mirror	; physical address
	and	rax,	qword [r8 + KERNEL.page_base_address]
	mov	cr3,	rax

	; set new stack pointer
	mov	rsp,	KERNEL_STACK_pointer

	; create Global Descriptor Table
	call	kernel_init_gdt

	; create Interrupt Descriptor Table
	call	kernel_init_idt

	; ESSENTIAL -----------------------------------------------------------

	; configure RTC
	call	driver_rtc_init

	; initialize stream set
	call	kernel_init_stream

	; create Task queue and insert kernel into it
	call	kernel_init_task

	; create interprocess communication system
	call	kernel_init_ipc

	; register all available data carriers
	call	kernel_init_storage

	; initialize VFS directory
	call	kernel_init_vfs

	; create library management space
	; call	kernel_init_library

	; load basic list of modules
	; call	kernel_init_module

	; execute first process
	; call	kernel_init_cmd

	; EXTRA ---------------------------------------------------------------

	; initialize other CPUs
	; call	kernel_init_smp

	; some clean up
	; call	kernel_init_clean

	; FINISH --------------------------------------------------------------

	; reload BSP configuration
	jmp	kernel_init_ap