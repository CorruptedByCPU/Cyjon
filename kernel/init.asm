;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

	;-----------------------------------------------------------------------
	; structures, definitions
	;-----------------------------------------------------------------------
	; library --------------------------------------------------------------
	%include	"library/elf.inc"
%include	"library/vfs.inc"
%include	"library/sys.inc"
	; driver ---------------------------------------------------------------
%include	"kernel/driver/ps2.inc"
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
%include	"kernel/task.inc"
	; kernel environment initialization routines ---------------------------
	%include	"kernel/init/acpi.inc"
%include	"kernel/init/ap.inc"
	%include	"kernel/init/limine.inc"
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
%include	"kernel/init/data.asm"
	;=======================================================================

; 64 bit code
[bits 64]

; information for linker
section .text
	;-----------------------------------------------------------------------
	; routines
	;-----------------------------------------------------------------------
	; library --------------------------------------------------------------
%include	"library/vfs.asm"
	%include	"library/elf.asm"
%include	"library/string/compare.asm"
%include	"library/string/length.asm"
%include	"library/string/word.asm"
	; drivers --------------------------------------------------------------
%include	"kernel/driver/ps2.asm"
%include	"kernel/driver/rtc.asm"
	%include	"kernel/driver/serial.asm"
	; kernel ---------------------------------------------------------------
%include	"kernel/exec.asm"
%include	"kernel/idt.asm"
%include	"kernel/io_apic.asm"
%include	"kernel/lapic.asm"
%include	"kernel/library.asm"
%include	"kernel/log.asm"
%include	"kernel/memory.asm"
%include	"kernel/page.asm"
%include	"kernel/rtc.asm"
%include	"kernel/service.asm"
%include	"kernel/storage.asm"
%include	"kernel/stream.asm"
%include	"kernel/syscall.asm"
%include	"kernel/task.asm"
	; kernel environment initialization routines ---------------------------
	%include	"kernel/init/environment.asm"
	%include	"kernel/init/limine.asm"
	%include	"kernel/init/memory.asm"
	%include	"kernel/init/acpi.asm"
	%include	"kernel/init/page.asm"
	%include	"kernel/init/gdt.asm"
	%include	"kernel/init/stream.asm"
%include	"kernel/init/idt.asm"
%include	"kernel/init/ap.asm"
%include	"kernel/init/cmd.asm"
%include	"kernel/init/daemon.asm"
%include	"kernel/init/exec.asm"
%include	"kernel/init/free.asm"
%include	"kernel/init/ipc.asm"
%include	"kernel/init/library.asm"
%include	"kernel/init/rtc.asm"
%include	"kernel/init/smp.asm"
%include	"kernel/init/storage.asm"
%include	"kernel/init/task.asm"
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

	; initialize stream set
	call	kernel_init_stream

; retrieve file to execute
call	kernel_init_cmd

; create Task queue
call	kernel_init_task

; configure RTC
call	kernel_init_rtc

; initialize PS2 keyboard/mouse driver
call	driver_ps2

; create interprocess communication system
call	kernel_init_ipc

; register all available data carriers
call	kernel_init_storage

; prepare library subsystem
call	kernel_init_library

; execute daemons
call	kernel_init_daemon

; execute init process
call	kernel_init_exec

	; below, initialization functions does not guarantee original registers preservation

; initialize other CPUs
jmp	kernel_init_smp
