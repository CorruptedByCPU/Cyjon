;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; wyjście:
;	rax - numer wylosowanego bloku
taris_random:
	; zachowaj oryginalne rejestry
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
	div	qword [taris_limit]

	; zwróć wynik
	mov	eax,	edx

	; przywróć oryginalne rejestry
	pop	rdx

	; powrót z procedury
	ret
