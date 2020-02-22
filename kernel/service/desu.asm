;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

	;-----------------------------------------------------------------------
	; stałe, zmienne, globalne, struktury, obiekty
	;-----------------------------------------------------------------------
	%include	"kernel/service/desu/config.asm"
	;-----------------------------------------------------------------------

service_desu:
	;-----------------------------------------------------------------------
	; inicjalizacja środowiska produkcyjnego
	;-----------------------------------------------------------------------
	%include	"kernel/service/desu/init.asm"

.loop:
	;-----------------------------------------------------------------------
	; sprawdź stan klawiatury
	;-----------------------------------------------------------------------
	; call	service_desu_keyboard

	;-----------------------------------------------------------------------
	; sprawdź stan i położenie obiektu kursora
	;-----------------------------------------------------------------------
	call	service_desu_cursor

	;-----------------------------------------------------------------------
	; aktualizuj zawartość zmodyfikowanych obiektów w przestrzeni ekranu
	;-----------------------------------------------------------------------
	call	service_desu_object_flush

	;-----------------------------------------------------------------------
	; jeśli kursor został przemieszczony lub przysłonięty przez obiekt - wyświetl ponownie
	;-----------------------------------------------------------------------
	call	service_desu_cursor_flush

	call	service_desu_fill

	; powróć do głównej pętli
	jmp	.loop

	;-----------------------------------------------------------------------
	%include	"kernel/service/desu/data.asm"
	%include	"kernel/service/desu/zone.asm"
	; %include	"kernel/service/desu/panic.asm"
	%include	"kernel/service/desu/cursor.asm"
	%include	"kernel/service/desu/object.asm"
	%include	"kernel/service/desu/fill.asm"
	; %include	"kernel/service/desu/keyboard.asm"
	;-----------------------------------------------------------------------

service_desu_end:
