;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; wyjście:
;	bx - model wylosowanego bloku
;		^ rbx wszystkie możliwe obroty figury
;	r11d - kolor bloku
taris_random_block:
	; zachowaj oryginalne rejestry
	push	rax
	push	rdx

	; pobierz aktualny czas
	mov	ax,	KERNEL_SERVICE_SYSTEM_time
	int	KERNEL_SERVICE

	; modyfikuj ziarno o aktualny uptime systemu
	add	dword [taris_seed],	eax

	; pobierz pseudo losową wartość
	mov	eax,	dword [taris_seed]
	macro_library	LIBRARY_STRUCTURE_ENTRY.xorshift32

	; zachowaj wynik jako następne ziarno
	mov	dword [taris_seed],	eax

	; zwróć wartość z przedziału ilości dostępnych bloków
	xor	edx,	edx
	div	qword [taris_limit]

	; zachowaj numer bloku
	push	rdx

	; zwróć wynik
	mov	rbx,	taris_bricks
	mov	rbx,	qword [rbx + rdx * STATIC_QWORD_SIZE_byte]

	; przywróć numer bloku
	pop	rdx

	; pobierz kolor przypisany do bloku
	shl	rdx,	STATIC_MULTIPLE_BY_4_shift
	mov	r11,	taris_colors
	mov	r11d,	dword [r11 + rdx]

	; przywróć oryginalne rejestry
	pop	rdx
	pop	rax

	; powrót z procedury
	ret
