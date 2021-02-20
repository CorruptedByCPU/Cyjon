;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
taris_level:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdx
	push	rsi
	push	rdi

	; ilość wymaganych linii do zwiększenia poziomu
	mov	eax,	dword [taris_lines]
	mov	ecx,	TARIS_LINES_PER_LEVEL
	xor	edx,	edx
	div	ecx

	; poziom nie zmienił się?
	cmp	dword [taris_level_current],	eax
	je	.end	; nie

	; aktualny poziom
	mov	dword [taris_level_current],	eax

	; aktualizuj aktualny poziom
	call	taris_interface_level

	; pobierz szybkość przemieszczania się bloków
	shl	eax,	STATIC_MULTIPLE_BY_2_shift
	mov	rsi,	taris_speed_table
	movzx	rax,	word [rsi + rax]

	; aktualizuj
	mov	qword [taris_microtime],	rax

.end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rax

	; powrót z procedury
	ret
