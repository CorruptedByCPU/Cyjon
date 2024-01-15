;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

; Use:
; nasm - http://www.nasm.us/

; 64 bitowy kod programu
[BITS 64]

;===============================================================================
; procedura przetwarza rozmiar na typ
; IN:
;	rax	- rozmiar w Bajtach
;
; OUT:
;	rax	- rozmiar skonwertowany do ostatniego typu
;	rsi	- wskaźnik do tekstu określającego typ
;
; wszystkie rejestry zachowane
library_translate_size_and_type:
	mov	rsi,	text_bytes

	; rozmiar w Bajtach?
	cmp	rax,	VARIABLE_1024
	jb	.end

	shr	rax,	VARIABLE_DIVIDE_BY_1024	; zamień na KiB
	mov	rsi,	text_kib

	; rozmiar w KiB?
	cmp	rax,	VARIABLE_1024
	jb	.end

	shr	rax,	VARIABLE_DIVIDE_BY_1024	; zamień na MiB
	mov	rsi,	text_mib

	; rozmiar w MiB?
	cmp	rax,	VARIABLE_1024
	jb	.end

	shr	rax,	VARIABLE_DIVIDE_BY_1024	; zamień na GiB
	mov	rsi,	text_gib

	; rozmiar w GiB?
	cmp	rax,	VARIABLE_1024
	jb	.end

	shr	rax,	VARIABLE_DIVIDE_BY_1024	; zamień na TiB
	mov	rsi,	text_tib

.end:
	; powrót z procedury
	ret
