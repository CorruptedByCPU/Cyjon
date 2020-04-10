;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

	;-----------------------------------------------------------------------
	; stałe, zmienne, globalne, struktury, obiekty
	;-----------------------------------------------------------------------
	%include	"software/console/config.asm"
	;-----------------------------------------------------------------------

console:
	; ; inicjalizacja przestrzeni konsoli
	%include	"software/console/init.asm"

	; zatrzymaj dalsze wykonywanie kodu
	jmp	$

	;-----------------------------------------------------------------------
	%include	"software/console/data.asm"
	%include	"software/console/clear.asm"
	;-----------------------------------------------------------------------
	%include	"library/bosu.asm"
	%include	"library/page_from_size.asm"
	;-----------------------------------------------------------------------
