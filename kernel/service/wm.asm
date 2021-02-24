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
	%include	"kernel/service/wm/config.asm"
	;-----------------------------------------------------------------------

;===============================================================================
kernel_wm:
	;-----------------------------------------------------------------------
	; inicjalizacja środowiska produkcyjnego
	;-----------------------------------------------------------------------
	%include	"kernel/service/wm/init.asm"

.loop:
	;-----------------------------------------------------------------------
	; sprawdź zdarzenia od myszki i klawiatury
	;-----------------------------------------------------------------------
	call	kernel_wm_event

	;-----------------------------------------------------------------------
	; sprawdź, które obiekty aktualizowały ostatnio swoją zawartość
	;-----------------------------------------------------------------------
	call	kernel_wm_object

	;-----------------------------------------------------------------------
	; przetwórz wszystkie zarejestrowane strefy
	;-----------------------------------------------------------------------
	call	kernel_wm_zone

	;-----------------------------------------------------------------------
	; wypełnij wszystkie zarejestrowane fragmenty
	;-----------------------------------------------------------------------
	call	kernel_wm_fill

	;-----------------------------------------------------------------------
	; sprawdź położenie i stan kursora
	;-----------------------------------------------------------------------
	call	kernel_wm_cursor

	;-----------------------------------------------------------------------
	; synchronizuj zawartość bufora z pamięcią karty graficznej
	;-----------------------------------------------------------------------
	call	kernel_wm_flush

	;-----------------------------------------------------------------------
	; zwolnij pozostały czas procesora
	;-----------------------------------------------------------------------
	call	kernel_sleep

	; powróć do głównej pętli
	jmp	.loop

	;-----------------------------------------------------------------------
	%include	"kernel/service/wm/cursor.asm"
	%include	"kernel/service/wm/data.asm"
	%include	"kernel/service/wm/event.asm"
	%include	"kernel/service/wm/fill.asm"
	%include	"kernel/service/wm/flush.asm"
	%include	"kernel/service/wm/ipc.asm"
	%include	"kernel/service/wm/keyboard.asm"
	%include	"kernel/service/wm/merge.asm"
	%include	"kernel/service/wm/object.asm"
	%include	"kernel/service/wm/service.asm"
	%include	"kernel/service/wm/zone.asm"
	;-----------------------------------------------------------------------

kernel_wm_end:
;===============================================================================
