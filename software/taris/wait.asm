;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
taris_wait:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdx
	push	rsi

	; pobierz aktualny microtime systemu
	mov	ax,	KERNEL_SERVICE_SYSTEM_time
	int	KERNEL_SERVICE

	; odczekaj określoną ilość czasu
	mov	rcx,	qword [taris_microtime]
	add	rcx,	rax

	; wskaźnik do sturktury okna
	mov	rsi,	taris_window

.loop:
	; sprawdź przychodzące zdarzenia
	macro_library	LIBRARY_STRUCTURE_ENTRY.bosu_event
	jnc	.no_event	; brak wyjątku

	; sprawdź typ klawisza i wykonaj przypisaną akcję
	call	taris_keyboard
	jc	.end	; odłóż blok na miejsce

	; usuń informację o klawiszu
	xor	dx,dx

.no_event:
	; zwolnij pozostały czas procesora
	mov	ax,	KERNEL_SERVICE_PROCESS_release
	int	KERNEL_SERVICE

	; pobierz aktualny microtime systemu
	mov	ax,	KERNEL_SERVICE_SYSTEM_time
	int	KERNEL_SERVICE

	; odczekano sugerowany dostęp czasu?
	cmp	rax,	rcx
	jbe	.loop	; nie

.end:
	; przywróć oryginalne rejestry
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rax

	; powrót z procedury
	ret
