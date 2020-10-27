;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

KERNEL_STREAM_FLAG_meta		equ	00000001b	; meta dane są aktualne

struc	KERNEL_STREAM_STRUCTURE_ENTRY
	.address		resb	8
	.data:
	.start			resb	2
	.end			resb	2
	.free			resb	2
	.flags			resb	1
	.semaphore		resb	1
	.meta			resb	KERNEL_STREAM_META_SIZE_byte
	.SIZE:
endstruc

kernel_stream_semaphore		db	STATIC_FALSE

kernel_stream_address		dq	STATIC_EMPTY

kernel_stream_out_default	dq	STATIC_EMPTY

;===============================================================================
; wyjście:
;	Flaga CF, jeśli brak miejsca
;	rsi - identyfikator strumienia
kernel_stream:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rdi
	push	rsi

	; początek tablicy strumieni
	mov	rsi,	qword [kernel_stream_address]

	; zablokuj dostęp do modyfikacji tablicy strumieni
	macro_lock	kernel_stream_semaphore, 0

.reload:
	; ilość strumieni w tablicy
	mov	rcx,	( STATIC_PAGE_SIZE_byte / KERNEL_STREAM_STRUCTURE_ENTRY.SIZE) - 0x01

.search:
	; strumień wolny?
	cmp	qword [rsi + KERNEL_STREAM_STRUCTURE_ENTRY.address],	STATIC_EMPTY
	je	.found	; tak

	; przesuń wskaźnik na następny strumień w tablicy
	add	rsi,	KERNEL_STREAM_STRUCTURE_ENTRY.SIZE

	; koniec strumieni w tablicy?
	dec	rcx
	jnz	.search	; nie

	; zachowaj adres aktualnej częśći tablicy strumieni
	and	si,	STATIC_PAGE_mask
	mov	rcx,	rsi

	; pobierz adres następnej części tablicy
	mov	rsi,	qword [rsi + STATIC_STRUCTURE_BLOCK.link]

	; całkowity koniec tablicy strumieni?
	cmp	rsi,	qword [kernel_stream_address]
	jne	.search	; nie

	; przygotuj rozszerzenie tablicy
	call	kernel_memory_alloc_page
	jc	.error	; brak wolnej przestrzeni

	; wyczyść przestrzeń
	call	kernel_page_drain

	; podłącz przestrzeń pod tablicę strumieni
	mov	qword [rcx + STATIC_STRUCTURE_BLOCK.link],	rdi

	; ustaw wskaźnik następnej częśći tablicy na początek
	mov	qword [rdi + STATIC_STRUCTURE_BLOCK.link],	rsi

	; kontynuuj w nowej części tablicy
	mov	rsi,	rdi
	jmp	.reload

.error:
	; flaga, nie znaleziono wolnego strumienia
	stc

	; koniec procedury
	jmp	.end

.found:
	; przygotuj przestrzeń pod strumień
	mov	ecx,	KERNEL_STREAM_SIZE_byte >> STATIC_DIVIDE_BY_PAGE_shift
	call	kernel_memory_alloc
	jc	.error	; brak wolnej przestrzeni

	; wyczyść przestrzeń strumienia
	call	kernel_page_drain_few

	; zachowaj adres przestrzeni strumienia
	mov	qword [rsi + KERNEL_STREAM_STRUCTURE_ENTRY.address],	rdi

	; wyczyść wskaźniki początku końca danych w strumieniu
	mov	dword [rsi + KERNEL_STREAM_STRUCTURE_ENTRY.data],	STATIC_EMPTY

	; strumień nie posiada danych
	mov	word [rsi + KERNEL_STREAM_STRUCTURE_ENTRY.free],	KERNEL_STREAM_SIZE_byte

	; zresetuj flagi stanu strumienia
	mov	byte [rsi + KERNEL_STREAM_STRUCTURE_ENTRY.flags],	STATIC_EMPTY

	; odblokuj dostęp do strumienia
	mov	byte [rsi + KERNEL_STREAM_STRUCTURE_ENTRY.semaphore],	STATIC_FALSE

	; zwróć "identyfikator" strumienia
	mov	qword [rsp],	rsi

.end:
	; odblokuj dostęp do modyfikacji tablicy strumieni
	mov	byte [kernel_stream_semaphore],	STATIC_FALSE

	; przywróć oryginalne rejestry
	pop	rsi
	pop	rdi
	pop	rcx

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	rdi - identyfikator strumienia
kernel_stream_release:
	; zachowaj oryginalne rejestry
	push	rdi

	; zwolnij przestrzeń strumienia
	mov	rdi,	qword [rdi + KERNEL_STREAM_STRUCTURE_ENTRY.address]
	call	kernel_memory_release_page

	; przywróć oryginalne rejestry
	pop	rdi

	; zwolnij wpis w tablicy strumieni
	mov	qword [rdi + KERNEL_STREAM_STRUCTURE_ENTRY.address],	STATIC_EMPTY

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	rbx - identyfikator strumienia
;	rcx - rozmiar bufora docelowego
;	rdi - wskaźnik docelowy danych
; wyjście:
;	rcx - ilość przesłanych danych
kernel_stream_receive:
	; zachowaj oryginalne rejestry
	push	rax
	push	rdx
	push	rsi
	push	rdi
	push	r8
	push	rcx

	; zablokuj dostęp do strumienia
	macro_lock	rbx, KERNEL_STREAM_STRUCTURE_ENTRY.semaphore

	; w strumieniu znajdują się dane?
	cmp	word [rbx + KERNEL_STREAM_STRUCTURE_ENTRY.free],	KERNEL_STREAM_SIZE_byte
	je	.end	; nie

	; zresetuj akumulator
	xor	al,	al

	; pobierz aktualny wskaźnik początku danych strumienia
	movzx	edx,	word [rbx + KERNEL_STREAM_STRUCTURE_ENTRY.start]

	; ustaw wskaźnik docelowy w przestrzeni strumienia
	mov	rsi,	qword [rbx + KERNEL_STREAM_STRUCTURE_ENTRY.address]

	; zresetuj ilość przesłanych danych do procesu
	xor	r8,	r8

.load:
	; przesłano znak nowej linii?
	cmp	al,	STATIC_ASCII_NEW_LINE
	je	.close	; tak

	; pobierz wartość z strumienia
	mov	al,	byte [rsi + rdx]

	; załaduj do bufora procesu
	stosb

	; przesuń wskaźnik początku danych strumienia na następną pozycję
	inc	dx

	; koniec przestrzeni strumienia?
	cmp	dx,	KERNEL_STREAM_SIZE_byte
	jne	.continue	; nie

	; przestaw wskaźnik początku przestrzeni danych strumienia
	xor	dx,	dx

.continue:
	; ilość przesłanych danych do bufora procesu
	inc	r8

	; przesłano wymaganą ilość?
	dec	rcx
	jz	.close	; tak

	; koniec danych w strumieniu?
	cmp	dx,	word [rbx + KERNEL_STREAM_STRUCTURE_ENTRY.end]
	jne	.load	; nie

.close:
	; zachowaj aktualną pozycję początku strumienia
	mov	word [rbx + KERNEL_STREAM_STRUCTURE_ENTRY.start],	dx

	; zwróć ilość przesnałych danych
	mov	qword [rsp],	r8

	; aktualna ilość wolnego miejsca w strumieniu
	add	word [rbx + KERNEL_STREAM_STRUCTURE_ENTRY.free],	r8w

.end:
	; odblokuj dostęp do potoku
	mov	byte [rbx + KERNEL_STREAM_STRUCTURE_ENTRY.semaphore],	STATIC_FALSE

	; przywróć oryginalne rejestry
	pop	rcx
	pop	r8
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	rbx - identyfikator potoku
;	cx - ilość danych do przesłania
;	rsi - wskaźnik źródłowy danych
kernel_stream_insert:
	; zachowaj oryginalne rejestry
	push	rax
	push	rdx
	push	rsi
	push	rdi
	push	rcx

.retry:
	; zablokuj dostęp do potoku
	macro_lock	rbx, KERNEL_STREAM_STRUCTURE_ENTRY.semaphore

	; pobierz aktualny wskaźnik końca danych strumienia
	movzx	edx,	word [rbx + KERNEL_STREAM_STRUCTURE_ENTRY.end]

	; ustaw wskaźnik docelowy w przestrzeni strumienia
	mov	rdi,	qword [rbx + KERNEL_STREAM_STRUCTURE_ENTRY.address]

.next:
	; w strumieniu jest wystarczająco wolnej przestrzeni?
	cmp	cx,	word [rbx + KERNEL_STREAM_STRUCTURE_ENTRY.free]
	jbe	.insert	; tak

	; odblokuj dostęp do strumienia
	mov	byte [rbx + KERNEL_STREAM_STRUCTURE_ENTRY.semaphore],	STATIC_FALSE

	; spróbuj raz jeszcze
	jmp	.retry

.insert:
	; pobierz wartość z ciągu
	lodsb

	; zachowaj w strumieniu
	mov	byte [rdi + rdx],	al

	; przesuń wskaźnik końca danych strumienia na następną pozycję
	inc	dx

	; koniec przestrzeni strumienia?
	cmp	dx,	KERNEL_STREAM_SIZE_byte
	jne	.continue	; nie

	; ustaw wskaźnik końca przestrzeni danych strumienia na początek
	xor	dx,	dx

.continue:
	; koniec ciągu danych?
	dec	rcx
	jnz	.next	; nie, kontynuuj

	; zachowaj aktualny wskaźnik końca danych strumienia
	mov	word [rbx + KERNEL_STREAM_STRUCTURE_ENTRY.end],	dx

	; pozostała ilość wolnego miejsca w strumieniu
	pop	rcx
	sub	word [rbx + KERNEL_STREAM_STRUCTURE_ENTRY.free],	cx

	; wyłącz flagę: meta
	and	byte [rbx + KERNEL_STREAM_STRUCTURE_ENTRY.flags],	~KERNEL_STREAM_FLAG_meta

.end:
	; odblokuj dostęp do potoku
	mov	byte [rbx + KERNEL_STREAM_STRUCTURE_ENTRY.semaphore],	STATIC_FALSE

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rax

	; powrót z procedury
	ret
