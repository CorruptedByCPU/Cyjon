;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

; Use:
; nasm - http://www.nasm.us/

; 64 Bitowy kod programu
[BITS 64]

elive:
;===============================================================================
	; sprawdź czy upłyneło 1000ms
	cmp	qword [variable_system_microtime],	VARIABLE_PIT_CLOCK_HZ
	jb	.no_second

	; zwiększ ilość sekund
	inc	qword [variable_system_uptime]

	; zmniejsz mikrotime
	sub	qword [variable_system_microtime],	VARIABLE_PIT_CLOCK_HZ

;-------------------------------------------------------------------------------
	; raz na sekunde przełącz widoczność kursora (mryganie)
	cmp	byte [variable_cursor_blink],	VARIABLE_TRUE
	je	.cursor_show

	; ukryj kursor
	mov	byte [variable_cursor_blink],	VARIABLE_TRUE
	call	cyjon_screen_cursor_lock
	jmp	.no_second

.cursor_show:
	; pokaż kursor
	mov	byte [variable_cursor_blink],	VARIABLE_FALSE
	call	cyjon_screen_cursor_unlock

.no_second:
;===============================================================================
	; nieskończona pętla
	jmp	elive
