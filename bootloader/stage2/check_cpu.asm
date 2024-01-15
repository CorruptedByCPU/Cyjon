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

stage2_check_cpu:
	; sprawdź czy procesor obsługuje tryb 64 bitowy
	mov	eax,	0x80000000	; procedura - pobierz numer najwyższej dostępnej procedury
	cpuid	; wykonaj

	cmp	eax,	0x80000000	; spradź czy istnieją procedury powyżej 80000000h
	jbe	.error	; jeśli nie, koniec

	mov	eax,	0x80000001	; procedura - pobierz informacja o procesorze i poszczególnych funkcjach
	cpuid	; wykonaj

	bt	edx,	29	; sprawdź czy wspierany jest tryb 64 bitowy (29 bit "lm" LongMode, rejestru edx)
	jnc	.error	; jeśli nie, koniec

	; procesor wspiera tryb 64-bitowy

	; powrót z procedury
	ret

.error:
	; brak procesora 64 Bitowego
	mov	si,	text_error_no_cpu
	call	stage2_print_16bit

	; zatrzymaj dalsze wykonywanie kodu
	jmp	$

text_error_no_cpu	db	"No 64 Bit instructions available on this CPU!", VARIABLE_ASCII_CODE_TERMINATOR
