;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
soler_operation_insert:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rsi

	; komponuj obydwie wartości jeśli istnieją
	call	soler_operation_compose

	; wprowadzono pierwszą wartość?
	cmp	r11b,	STATIC_TRUE
	je	.first_exist	; tak

	; zaakceptuj pierwszą wartość

	; zamień ciąg wprowadzony przez użyszkodnika na wartość zmiennoprzecinkową
	movzx	ecx,	byte [soler_window.element_label_value_length]
	mov	rsi,	soler_window.element_label_value_string
	call	library_string_to_float

	; zachowaj wartość i podnieś flagę
	mov	qword [soler_value_first],	rax
	mov	r11b,	STATIC_TRUE

	; koniec operacji
	jmp	.end

.first_exist:
	; zaakceptuj drugą wartość

	; zamień ciąg wprowadzony przez użyszkodnika na wartość zmiennoprzecinkową
	movzx	ecx,	byte [soler_window.element_label_value_length]
	mov	rsi,	soler_window.element_label_value_string
	call	library_string_to_float

	; zachowaj wartość i podnieś flagę
	mov	qword [soler_value_second],	rax
	mov	r12b,	STATIC_TRUE

.end:
	; przywróć oryginalne rejestry
	pop	rsi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

	; debug
	macro_debug	"software: soler_operation_insert"

;===============================================================================
; wejście:
;	byte [soler_value_exec]
;	qword [soler_value_first]
;	qword [soler_value_second]
; wyjście:
;	qword [soler_value_first]
soler_operation_compose:
	; spełniono kryteria?

	; wybrano typ opreracji?
	cmp	byte [soler_value_exec],	STATIC_EMPTY
	je	.no_result	; nie

	; załadowano pierwszą wartość
	cmp	r11b,	STATIC_FALSE
	je	.no_result	; nie

	; załadowano drugą wartość?
	cmp	r12b,	STATIC_FALSE
	je	.no_result	; nie

	;-----------------------------------------------------------------------

	finit	; reset koprocesora
	fld	qword [soler_value_first]
	fld	qword [soler_value_second]

	; operacja dodawania?
	cmp	byte [soler_value_exec],	"+"
	jne	.no_add	; nie

	; wykonaj operację
	fadd

	; koniec operacji
	jmp	.result

.no_add:
	; operacja odejmowania?
	cmp	byte [soler_value_exec],	"-"
	jne	.no_sub	; nie

	; wykonaj operację
	fsub

	; koniec operacji
	jmp	.result

.no_sub:
	; operacja mnożenia?
	cmp	byte [soler_value_exec],	"*"
	jne	.no_multiply	; nie

	; wykonaj operację
	fmul

	; koniec operacji
	jmp	.result

.no_multiply:
	; operacja mnożenia?
	cmp	byte [soler_value_exec],	"/"
	jne	.no_result	; nie

	; wykonaj operację
	fdiv

.result:
	; zwróć wynik w pierwszej wartości zmiennoprzecinkowej
	fst	qword [soler_value_first]

	; druga wartość jest przeterminowana
	mov	r12b,	STATIC_FALSE

.no_result:
	; powrót z procedury
	ret

	; debug
	macro_debug	"software: soler_operation_compose"

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

	; przetworzyć?
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
	; załaduj wartość do zmiennej
	call	soler_operation_insert
	jc	.end	; brak przesłanej wartości

	; komponuj obydwie wartości jeśli istnieją
	call	soler_operation_compose

	; zachowaj znak operacji
	mov	byte [soler_value_exec],	"="

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
	; załaduj wartość do zmiennej
	call	soler_operation_insert
	jc	.end	; brak przesłanej wartości

	; zachowaj znak operacji
	mov	byte [soler_value_exec],	"+"

	; koniec procedury
	jmp	.end

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

	; debug
	macro_debug	"software: soler_operation"
