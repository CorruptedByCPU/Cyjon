;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
taris_points:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rsi
	push	rdi

	; usuń z przestrzeni gry wszystkie bloki które tworzą ciągłą linię poziomą
	call	taris_points_calculate

	; zlicz ilość skasowanych inii
	add	dword [taris_lines],	eax

	; sprawdź czy zwiększyć poziom gry
	call	taris_level

	; użyszkodnik zarobił punkty?
	test	rax,	rax
	jz	.end	; nie

	; aktualizuj ilość linii
	call	taris_interface_lines

	; poierz ilość zarobionych punktów
	mov	rsi,	taris_points_table
	mov	eax,	dword [rsi + rax * STATIC_DWORD_SIZE_byte]

	; przelicz punkty względem aktualnego poziomu
	mov	ecx,	dword [taris_level_current]
	inc	ecx
	mul	ecx

	; dodaj do ogólnej puli
	add	dword [taris_points_total],	eax

	; aktualizuj ilość punktów
	call	taris_interface_points
	jc	.end	;

	; aktualizuj zawartość okna
	mov	al,	KERNEL_WM_WINDOW_update
	mov	rsi,	taris_window
	or	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags],	LIBRARY_BOSU_WINDOW_FLAG_visible | LIBRARY_BOSU_WINDOW_FLAG_flush
	int	KERNEL_WM_IRQ

.end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
; wyjście:
;	rax - ilość usuniętych linii
taris_points_calculate:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rsi
	push	rdi

	; domyślnie brak usuniętych linii
	xor	eax,	eax

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

	; linia usunięta
	inc	rax

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

	; powrót z procedury
	ret
