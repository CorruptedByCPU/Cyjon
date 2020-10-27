;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

	;-----------------------------------------------------------------------
	; stałe, zmienne, globalne, struktury, obiekty
	;-----------------------------------------------------------------------
	%include	"kernel/service/gui/config.asm"
	;-----------------------------------------------------------------------

kernel_gui:
	;-----------------------------------------------------------------------
	; inicjalizacja interfejsu graficznego
	;-----------------------------------------------------------------------
	%include	"kernel/service/gui/init.asm"

.loop:
	; sprawdż wiadomości przychodzące
	call	kernel_gui_ipc

	; sprawdź czy pasek zadań jest aktualny
	call	kernel_gui_taskbar

	; aktualizuj etykietę "zegar"
	call	kernel_gui_clock

	; powrót do głównej pętli
	jmp	.loop

	;-----------------------------------------------------------------------
	%include	"kernel/service/gui/data.asm"
	%include	"kernel/service/gui/clock.asm"
	%include	"kernel/service/gui/ipc.asm"
	%include	"kernel/service/gui/event.asm"
	%include	"kernel/service/gui/taskbar.asm"
	;-----------------------------------------------------------------------
	%include	"library/bosu.asm"
	%include	"library/font.asm"
	;-----------------------------------------------------------------------

	macro_debug	"kernel_gui"
