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
	; sprawdź stan i położenie obiektu kursora
	;-----------------------------------------------------------------------
	call	service_desu_cursor

	;-----------------------------------------------------------------------
	; sprawdź, które obiekty aktualizowały ostatnio swoją zawartość
	;-----------------------------------------------------------------------
	call	service_desu_object

	;-----------------------------------------------------------------------
	; wypełnij wszystkie aktualizowane fragmenty ekranu
	;-----------------------------------------------------------------------
	call	service_desu_fill

	; powróć do głównej pętli
	jmp	.loop

	;-----------------------------------------------------------------------
	%include	"kernel/service/desu/data.asm"
	%include	"kernel/service/desu/zone.asm"
	%include	"kernel/service/desu/cursor.asm"
	%include	"kernel/service/desu/object.asm"
	%include	"kernel/service/desu/fill.asm"
	;-----------------------------------------------------------------------
service_desu_end:
