;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
taris_redraw:
	; zachowaj oryginalne rejestry
	push	rax
	push	rsi

	; wyczyść przestrzeń roboczą
	macro_library	LIBRARY_STRUCTURE_ENTRY.rgl_clear

	; wyświetl przestrzeń gry
	call	taris_show_playground

	; wyświetl blok na nowej pozycji
	call	taris_show_block

	; synchronizacja zawartości z przestrzenią roboczą
	macro_library	LIBRARY_STRUCTURE_ENTRY.rgl_flush

	; aktualizuj zawartość okna
	mov	al,	KERNEL_WM_WINDOW_update
	mov	rsi,	taris_window
	or	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags],	LIBRARY_BOSU_WINDOW_FLAG_visible | LIBRARY_BOSU_WINDOW_FLAG_flush
	int	KERNEL_WM_IRQ

	; przywróć oryginalne rejestry
	pop	rsi
	pop	rax

	; powrót z podprocedury
	ret

;===============================================================================
taris_redraw_no_lines:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rsi
	push	rdi

	; sprawdź kolejno wiersze, czy są pełne
	mov	cl,	TARIS_PLAYGROUND_HEIGHT_brick
	mov	rdi,	taris_brick_platform_end

.loop:
	; ustaw wskaźnik na ostatni wiersz
	sub	rdi,	STATIC_WORD_SIZE_byte

.check:
	; wiersz jest pełny?
	cmp	word [rdi],	TARIS_PLAYGROUND_FULL_bits
	jne	.no

	; zachowaj ilość pozostałych wierszy
	push	rcx
	push	rdi	; i aktualny wskaźnik wiersza

	; wskaźnik źródłowy na poprzedni wiersz
	mov	rsi,	rdi
	sub	rsi,	STATIC_WORD_SIZE_byte

.move:
	; przesuń wiersze
	movsw

	; ustaw wskaźniki na następne wiersze do przesunięcia
	sub	rsi,	STATIC_DWORD_SIZE_byte
	sub	rdi,	STATIC_DWORD_SIZE_byte

	; przesunięto wszystkie?
	dec	cl
	jnz	.move	; nie

	; przywróć ilość pozostałych wierszy
	pop	rdi	; i aktualny wskaźnik wiersza
	pop	rcx

	; sprawdź raz jeszcze aktualny wiersz
	jmp	.check

.no:
	; pozostały wiersze do sprawdzenia?
	dec	cl
	jnz	.loop	; tak

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret
