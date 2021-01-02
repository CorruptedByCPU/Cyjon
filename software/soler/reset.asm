;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
soler_reset:
	; zachowaj oryginalne rejestry
	push	rax

	; przywróć oryginalne rejestry
	pop	rax

	; powrót z procedury
	ret
