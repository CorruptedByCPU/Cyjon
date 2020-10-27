;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

	;-----------------------------------------------------------------------
	; stałe, zmienne, globalne, struktury, obiekty, makra, nagłówki
	;-----------------------------------------------------------------------
	%include	"config.asm"	; globalne
	;-----------------------------------------------------------------------
	%include	"kernel/config.asm"	; lokalne
	;-----------------------------------------------------------------------
	%include	"kernel/macro/apic.asm"
	;-----------------------------------------------------------------------
	%include	"kernel/header/vfs.inc"
	%include	"kernel/header/service.inc"
	%include	"kernel/header/ipc.inc"
	%include	"kernel/header/stream.inc"
	%include	"kernel/header/wm.inc"
	%include	"kernel/header/task.inc"
	;-----------------------------------------------------------------------

; 64 bitowy kod inicjalizacyjny jądra systemu
[bits 64]

; położenie kodu jądra systemu w pamięci fizycznej
[org KERNEL_BASE_address]

init:
	;-----------------------------------------------------------------------
	; Init - inicjalizacja środowiska pracy jądra systemu
	;-----------------------------------------------------------------------
	%include	"kernel/init.asm"

kernel:
	; pobierz wskaźnik do aktualnego zadania (jądro) w kolejce
	call	kernel_task_active

	; wyłącz proces z obiegu
	and	word [rdi + KERNEL_TASK_STRUCTURE.flags],	~KERNEL_TASK_FLAG_active

	; czekaj na wywłaszczenie
	jmp	$

	;-----------------------------------------------------------------------
	; procedury, makra, dane, biblioteki, usługi - wszystko co niezbędne
	; do prawidłowej pracy jądra systemu
	;-----------------------------------------------------------------------
	%include	"kernel/macro/lock.asm"
	%include	"kernel/macro/debug.asm"
	%include	"kernel/macro/copy.asm"
	;-----------------------------------------------------------------------
	%include	"kernel/ipc.asm"
	%include	"kernel/panic.asm"
	%include	"kernel/page.asm"
	%include	"kernel/memory.asm"
	%include	"kernel/apic.asm"
	%include	"kernel/io_apic.asm"
	%include	"kernel/data.asm"
	%include	"kernel/idt.asm"
	%include	"kernel/task.asm"
;	%include	"kernel/thread.asm"
	%include	"kernel/vfs.asm"
	%include	"kernel/exec.asm"
	%include	"kernel/service.asm"
	%include	"kernel/stream.asm"
	%include	"kernel/sleep.asm"
	;-----------------------------------------------------------------------
	%include	"kernel/driver/rtc.asm"
	%include	"kernel/driver/ps2.asm"
	%include	"kernel/driver/pci.asm"
	%include	"kernel/driver/network/i82540em.asm"
	%include	"kernel/driver/storage/ide.asm"
	%include	"kernel/driver/serial.asm"
	;-----------------------------------------------------------------------
	%include	"kernel/service/gc.asm"
	%include	"kernel/service/wm.asm"
	%include	"kernel/service/gui.asm"
	%include	"kernel/service/network.asm"
	%include	"kernel/service/tx.asm"
	%include	"kernel/service/http.asm"
	;-----------------------------------------------------------------------
	%include	"library/color.asm"
	%include	"library/integer_to_string.asm"
	%include	"library/page_align_up.asm"
	%include	"library/page_from_size.asm"
	%include	"library/string_compare.asm"
	%include	"library/string_cut.asm"
	;-----------------------------------------------------------------------

; wyrównaj kod jądra systemu do pełnej strony
align	STATIC_PAGE_SIZE_byte

kernel_end:
