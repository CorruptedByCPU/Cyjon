;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; wejście:
;	rax - wartość
tm_percent:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rdx
	push	r8
	push	r9
	push	r10
	push	rax

	; pobierz informacje o przestrzeni pamięci RAM
	mov	ax,	KERNEL_SERVICE_SYSTEM_memory
	int	KERNEL_SERVICE

	; zamień wartość na procent bez reszty
	mov	rax,	qword [rsp]
	xor	edx,	edx
	mov	rcx,	100
	mul	rcx
	div	r8

	; zwróć wynik
	mov	qword [rsp],	rax

	; przywróć oryginalne rejestry
	pop	rax
	pop	r10
	pop	r9
	pop	r8
	pop	rdx
	pop	rcx

	; powrót z procedury
	ret
