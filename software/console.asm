;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

	;-----------------------------------------------------------------------
	; stałe, zmienne, globalne, struktury, obiekty
	;-----------------------------------------------------------------------
	%include	"software/console/config.asm"
	;-----------------------------------------------------------------------

console:
	; inicjalizacja przestrzeni konsoli
	%include	"software/console/init.asm"

	; zatrzymaj dalsze wykonywanie kodu
	jmp	$
