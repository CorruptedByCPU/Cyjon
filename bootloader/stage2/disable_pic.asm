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

stage2_disable_pic:
	; wyłączamy wszystkie przerwania sprzętowe (PIC)
	mov	al,	11111111b
	out	0xA1,	al
	out	0x21,	al

	; powrót z procedury
	ret
