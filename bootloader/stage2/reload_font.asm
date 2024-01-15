;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

; Use:
; nasm - http://www.nasm.us/

; 16 Bitowy kod programu
[BITS 16]

stage2_reload_font:
	; załaduj własną czcionkę do przestrzeni BIOSu
	mov	ax,	0x1110
	mov	bx,	0x1000	; bh, wysokość znaku (16 pikseli)
	mov	cx,	256	; ilość znaków do załadowania
	xor	dx,	dx	; rozpocząć od pierwszego
	mov	bp,	matrix_font
	int	0x10

	; powrót z procedury
	ret
