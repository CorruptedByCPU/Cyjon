; ;===============================================================================
; ; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; ; GPL-3.0 License
; ;
; ; Main developer:
; ;	Andrzej Adamczyk
; ;===============================================================================
;
; ;===============================================================================
; cat_text:
; 	; zachowaj rozmiar pliku
; 	mov	rbx,	rcx
;
; 	; wyświetl kolejno Bajty z pliku
; 	mov	ax,	KERNEL_SERVICE_VIDEO_char
; 	mov	ecx,	STATIC_TRUE	; po jednym znaku
; 	mov	rsi,	rdi	; ustaw wskaźnik źródłowy na początek wczytanego pliku
;
; .loop:
; 	; pobierz kod ASCII
; 	mov	dl,	byte [rsi]
;
; 	; znak drukowalny?
; 	cmp	dl,	STATIC_SCANCODE_TILDE
; 	ja	.no	; nie
; 	cmp	dl,	STATIC_SCANCODE_SPACE
; 	jae	.yes	; tak
;
; 	; znak nowej linii?
; 	cmp	dl,	STATIC_SCANCODE_NEW_LINE
; 	je	.yes	; tak, wyświetl
;
; 	; znak karetki?
; 	cmp	dl,	STATIC_SCANCODE_ENTER
; 	je	.yes	; tak, wyświetl
;
; .no:
; 	; zamień na znak kropki
; 	mov	dl,	"."
;
; .yes:
; 	; wyświetl
; 	int	KERNEL_SERVICE
;
; 	; pozostała zawartość pliku?
; 	inc	rsi
; 	dec	rbx
; 	jnz	.loop	; tak
;
; 	; koniec programu
; 	jmp	cat.end
