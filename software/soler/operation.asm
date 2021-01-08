;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; wejście:
;	ax - wartość z klawiatury bądź myszki
soler_operation:
	; zachowaj oryginalne rejestry
	push	rax
	push	rsi

	; przetwarzany ciąg i jego rozmiar
	movzx	ecx,	byte [soler_window.element_label_value_length]
	mov	rsi,	soler_window.element_label_value_string

	; modyfikacja wartości?
	cmp	ax,	STATIC_SCANCODE_DIGIT_0
	jb	.no_digit	; nie
	cmp	ax,	STATIC_SCANCODE_DIGIT_9
	ja	.no_digit	; nie

.dot:
	; przecinek?
	cmp	ax,	","
	jne	.not_dot	; nie

	; wstawiono już przecinek?
	test	r10b,	r10b
	jz	.error	; tak, zignoruj

	; oznacz flagą wstawienie przecinka w liczbie
	mov	r10b,	STATIC_TRUE

.not_dot:
	; osiągnięto limit wejścia?
	cmp	cl,	SOLER_INPUT_VALUE_WIDTH_char
	jnb	.error	; tak, zignoruj cyfrę

	; dołącz cyfrę na koniec ciągu
	mov	byte [rsi + rcx],	al

	; rozmiar ciągu
	inc	byte [soler_window.element_label_value_length]

	; operacja wykonana
	clc

	; wykonano operację
	jmp	.end

.no_digit:
	; suma operacji?
	cmp	ax,	"+"
	je	.add	; tak

	; różnica operacji?
	cmp	ax,	"-"
	je	.sub	; tak

	; iloczyn operacji?
	cmp	ax,	"*"
	je	.multiply	; tak

	; iloraz operacji?
	cmp	ax,	"/"
	je	.divide	; tak

	; wstawić część ułamkową?
	cmp	ax,	","
	je	.dot	; tak

	; przerworzyć?
	cmp	ax,	"="
	je	.result	; tak

	; cofnij wartość?
	cmp	ax,	STATIC_SCANCODE_BACKSPACE
	je	.backspace	; tak

	; przetworzyć?
	cmp	ax,	STATIC_SCANCODE_RETURN
	jne	.error	; nie

;-------------------------------------------------------------------------------
.result:
	; koniec obsługi operacji
	jmp	.end

;-------------------------------------------------------------------------------
.backspace:
	; ciąg pusty?
	test	cl,	cl
	jz	.error	; tak

	; usuń ostatnią cyfrę (lub przecinek) z ciągu
	dec	cl

	; usuniętym znakiem jest przecinek?
	cmp	byte [rsi + rcx],	","
	jne	.backspace_ready	; nie

	; zwolnij flagę przecinka
	mov	r10b,	STATIC_FALSE

.backspace_ready:
	; aktulizuj rozmiar ciągu
	mov	byte [soler_window.element_label_value_length],	cl

	; koniec obsługi operacji
	jmp	.end

;-------------------------------------------------------------------------------
.add:

;-------------------------------------------------------------------------------
.sub:

;-------------------------------------------------------------------------------
.multiply:

;-------------------------------------------------------------------------------
.divide:
	; koniec obsługi operacji
	jmp	.end

;-------------------------------------------------------------------------------
.error:
	; nie wykonano operacji
	stc

;-------------------------------------------------------------------------------
.end:
	; przywróć oryginalne rejestry
	pop	rsi
	pop	rax

	; powrót z procedury
	ret
