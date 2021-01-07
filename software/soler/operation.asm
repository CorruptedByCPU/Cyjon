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

	; modyfikacja wartości?
	cmp	ax,	STATIC_SCANCODE_DIGIT_0
	jb	.no_digit	; nie
	cmp	ax,	STATIC_SCANCODE_DIGIT_9
	ja	.no_digit	; nie

	; zamień scancode na cyfrę
	and	byte [rsp],	STATIC_BYTE_LOW_mask

	; domyślnie dołącz cyfrę do pierwszej wartości
	mov	rcx,	r10

	; wybrano operację?
	test	r12b,	r12b
	jz	.no_operation	; nie

	; dołącz cyfrę do drugiej wartości
	mov	rcx,	r11

.no_operation:
	; zmień podstawę wartości
	mov	eax,	STATIC_NUMBER_SYSTEM_decimal
	mul	rcx

	; kombinuj cyfrę z wartością
	movzx	ecx,	byte [rsp]
	add	rcx,	rax

	; wybrano operację?
	test	r12b,	r12b
	jz	.first	; nie

	; aktualizuj wartość
	mov	r11,	rcx

	; wykonano operację
	jmp	.end

.first:
	; aktualizuj wartość
	mov	r10,	rcx

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
	jne	.end	; nie

	; result

.add:
.sub:
.multiply:
.divide:
	; koniec obsługi operacji
	jmp	.end

;-------------------------------------------------------------------------------
.dot:
	; wartość pierwsza czy druga ?
	test	r12b,	r12b
	jnz	.dot_second	; druga wartość

	; oznacz flagą wartość ułamkową liczby
	or	r15b,	SOLER_INPUT_FLAG_float_first

	; koniec obsługi operacji
	jmp	.end

.dot_second:
	; oznacz flagą wartość ułamkową liczby
	or	r15b,	SOLER_INPUT_FLAG_float_second

;-------------------------------------------------------------------------------
.end:
	; przywróć oryginalne rejestry
	pop	rax

	; powrót z procedury
	ret
