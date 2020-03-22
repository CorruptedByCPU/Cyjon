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
	; sprawdź, które obiekty aktualizowały ostatnio swoją zawartość
	;-----------------------------------------------------------------------
	call	service_desu_object

	;-----------------------------------------------------------------------
	; sprawdź zdarzenia od myszki i klawiatury
	;-----------------------------------------------------------------------
	call	service_desu_event

	;-----------------------------------------------------------------------
	; przetwórz wszystkie zarejestrowane strefy
	;-----------------------------------------------------------------------
	call	service_desu_zone

	;-----------------------------------------------------------------------
	; wypełnij wszystkie zarejestrowane fragmenty
	;-----------------------------------------------------------------------
	call	service_desu_fill

	;-----------------------------------------------------------------------
	; sprawdź położenie i stan kursora
	;-----------------------------------------------------------------------
	call	service_desu_cursor

	; powróć do głównej pętli
	jmp	.loop

	;-----------------------------------------------------------------------
	%include	"kernel/service/desu/data.asm"
	%include	"kernel/service/desu/zone.asm"
	%include	"kernel/service/desu/cursor.asm"
	%include	"kernel/service/desu/object.asm"
	%include	"kernel/service/desu/fill.asm"
	%include	"kernel/service/desu/event.asm"
	;-----------------------------------------------------------------------
service_desu_end:
