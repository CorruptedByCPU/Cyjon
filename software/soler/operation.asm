;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
soler_operation:
	; ; sprawdź klawisz z klawiatury numerycznej
	; call	soler_numlock
	;
	; ; suma operacji?
	; cmp	ax,	"+"
	; je	.operation	; tak
	;
	; ; różnica operacji?
	; cmp	ax,	"-"
	; je	.operation	; tak
	;
	; ; iloczyn operacji?
	; cmp	ax,	"*"
	; je	.operation	; tak
	;
	; ; iloraz operacji?
	; cmp	ax,	"/"
	; je	.operation	; tak
	;
	; ; modyfikacja wartości?
	; cmp	ax,	STATIC_SCANCODE_DIGIT_0
	; jb	.loop	; nie
	; cmp	ax,	STATIC_SCANCODE_DIGIT_9
	; ja	.loop	; nie
	;
	; .operation:
	; ; wykonaj operację
	; call	soler_operation
	;
	; ; powrót do głównej pętli
	; jmp	.loop


	; powrót z procedury
	ret
