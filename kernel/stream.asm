;===============================================================================
; Copyright (C) by blackdev.org
;===============================================================================

KERNEL_STREAM_FLAG_data		equ	00000001b	; istnieją dane w potoku
KERNEL_STREAM_FLAG_full		equ	00000010b	; w strumieniu nie ma miejsca

struc	KERNEL_STREAM_STRUCTURE_ENTRY
	.address		resb	8
	.data:
	.start			resb	2
	.end			resb	2
	.reserved		resb	2
	.flags			resb	1
	.semaphore		resb	1
	.SIZE:
endstruc

kernel_stream_semaphore		db	STATIC_FALSE

kernel_stream_address		dq	STATIC_EMPTY

kernel_stream_out_default	dq	STATIC_EMPTY

;===============================================================================
; wyjście:
;	Flaga CF, jeśli brak miejsca
;	rsi - identyfikator potoku
kernel_stream:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rdi
	push	rsi

	; początek tablicy potoków
	mov	rsi,	qword [kernel_stream_address]

	; zablokuj dostęp do modyfikacji tablicy potoków
	macro_lock	kernel_stream_semaphore, 0

.reload:
	; rozmiar fragmentu tablicy w potokach
	mov	rcx,	( STATIC_PAGE_SIZE_byte / KERNEL_STREAM_STRUCTURE_ENTRY.SIZE) - 0x01

.search:
	; wolny potok?
	cmp	qword [rsi + KERNEL_STREAM_STRUCTURE_ENTRY.address],	STATIC_EMPTY
	je	.found	; tak

	; przesuń wskaźnik na następny potok w tablicy
	add	rsi,	KERNEL_STREAM_STRUCTURE_ENTRY.SIZE

	; koniec fragmentu tablicy potoków?
	dec	rcx
	jnz	.search	; nie

	; zachowaj adres aktualnego fragmentu tablicy potoków
	and	si,	STATIC_PAGE_mask
	mov	rcx,	rsi

	; pobierz adres następnego fragmentu tablicy
	mov	rsi,	qword [rsi + STATIC_STRUCTURE_BLOCK.link]

	; całkowity koniec tablicy potoków?
	cmp	rsi,	qword [kernel_stream_address]
	jne	.search	; nie

	; przygotuj rozszerzenie tablicy
	call	kernel_memory_alloc_page
	jc	.error	; brak wolnej przestrzeni

	; wyczyść przestrzeń
	call	kernel_page_drain

	; podłącz przestrzeń pod tablicę potoków
	mov	qword [rcx + STATIC_STRUCTURE_BLOCK.link],	rdi

	; ustaw wskaźnik następnego fragmentu tablicy na początek
	mov	qword [rdi + STATIC_STRUCTURE_BLOCK.link],	rsi

	; kontynuuj w nowym fragmencie tablicy
	mov	rsi,	rdi
	jmp	.reload

.error:
	; flaga, nie znaleziono wolnego potoku
	stc

	; koniec procedury
	jmp	.end

.found:
	; przygotuj przestrzeń pod potok
	call	kernel_memory_alloc_page
	jc	.error	; brak wolnej przestrzeni

	; wyczyść przestrzeń potoku
	call	kernel_page_drain

	; zachowaj adres przestrzeni potoku
	mov	qword [rsi + KERNEL_STREAM_STRUCTURE_ENTRY.address],	rdi

	; wyczyść wskaźniki początku końca danych w potoku
	mov	dword [rsi + KERNEL_STREAM_STRUCTURE_ENTRY.data],	STATIC_EMPTY

	; zresetuj flagi stanu potoku
	mov	byte [rsi + KERNEL_STREAM_STRUCTURE_ENTRY.flags],	STATIC_EMPTY

	; odblokuj dostęp do potoku
	mov	byte [rsi + KERNEL_STREAM_STRUCTURE_ENTRY.semaphore],	STATIC_FALSE

	; zwróć "identyfikator" potoku
	mov	qword [rsp],	rsi

.end:
	; odblokuj dostęp do modyfikacji tablicy potoków
	mov	byte [kernel_stream_semaphore],	STATIC_FALSE

	; przywróć oryginalne rejestry
	pop	rsi
	pop	rdi
	pop	rcx

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	rsi - identyfikator potoku
kernel_stream_release:
	; zachowaj oryginalne rejestry
	push	rdi

	; zwolnij przestrzeń potoku
	mov	rdi,	qword [rsi + KERNEL_STREAM_STRUCTURE_ENTRY.address]
	call	kernel_memory_release_page

	; zwolnij wpis w tablicy potoków
	mov	qword [rsi + KERNEL_STREAM_STRUCTURE_ENTRY.address],	STATIC_EMPTY

	; przywróć oryginalne rejestry
	pop	rdi

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	rbx - identyfikator strumienia
;	rcx - rozmiar bufora docelowego
;	rdi - wskaźnik docelowy danych
; wyjście:
;	rcx - ilość przesłanych danych
kernel_stream_in:
	; zachowaj oryginalne rejestry
	push	rax
	push	rdx
	push	rsi
	push	rdi
	push	r8
	push	rcx

.retry:
	; zablokuj dostęp do strumienia
	macro_lock	rbx, KERNEL_STREAM_STRUCTURE_ENTRY.semaphore

	; pobierz aktualny wskaźnik początku danych strumienia
	movzx	edx,	word [rbx + KERNEL_STREAM_STRUCTURE_ENTRY.start]

	; ustaw wskaźnik docelowy w przestrzeni strumienia
	mov	rsi,	qword [rbx + KERNEL_STREAM_STRUCTURE_ENTRY.address]

	; w strumieniu znajdują się dane?
	test	byte [rbx + KERNEL_STREAM_STRUCTURE_ENTRY.flags],	KERNEL_STREAM_FLAG_data
	jz	.end	; nie

	; zresetuj akumulator
	xor	al,	al

	; zresetuj ilość przesłanych danych do procesu
	xor	r8,	r8

.load:
	; ostatni przesłany znak to semafor?
	cmp	al,	STATIC_ASCII_NEW_LINE
	je	.close	; tak, zakończ przetwarzanie strumienia

	; pobierz wartość z strumienia
	mov	al,	byte [rsi + rdx]

	; załaduj do bufora procesu
	stosb

	; przesuń wskaźnik początku danych strumienia na następną pozycję
	inc	dx

	; koniec przestrzeni strumienia?
	cmp	dx,	STATIC_PAGE_SIZE_byte
	jne	.continue	; nie

	; ustaw wskaźnik końca przestrzeni danych strumienia na początek
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

	; przestrzeń strumienia jest pusta?
	cmp	dx,	word [rbx + KERNEL_STREAM_STRUCTURE_ENTRY.end]
	jne	.end	; nie

	; wyłącz flagę dane oraz pełny
	and	byte [rbx + KERNEL_STREAM_STRUCTURE_ENTRY.flags],	~KERNEL_STREAM_FLAG_data & ~KERNEL_STREAM_FLAG_full

	; zwróć ilość przesnałych danych
	mov	qword [rsp],	r8

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
;	rcx - ilość danych do przesłania
;	rsi - wskaźnik źródłowy danych
kernel_stream_out:
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
	; w potoku jest wolna przestrzeń?
	cmp	dx,	word [rbx + KERNEL_STREAM_STRUCTURE_ENTRY.start]
	jne	.insert	; tak

	; w strumieniu znajdują się dane?
	test	byte [rbx + KERNEL_STREAM_STRUCTURE_ENTRY.flags],	KERNEL_STREAM_FLAG_data
	jz	.insert	; nie

	; zachowaj aktualny wskaźnik końca danych strumienia
	mov	word [rbx + KERNEL_STREAM_STRUCTURE_ENTRY.end],	dx

	; podnieś flagę pełny w strumieniu
	or	byte [rbx + KERNEL_STREAM_STRUCTURE_ENTRY.flags],	KERNEL_STREAM_FLAG_full

	; odblokuj dostęp do potoku
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
	cmp	dx,	STATIC_PAGE_SIZE_byte
	jne	.continue	; nie

	; ustaw wskaźnik końca przestrzeni danych strumienia na początek
	xor	dx,	dx

	; podnieś flagę dane w strumieniu
	or	byte [rbx + KERNEL_STREAM_STRUCTURE_ENTRY.flags],	KERNEL_STREAM_FLAG_data

.continue:
	; koniec ciągu danych?
	dec	rcx
	jnz	.next	; nie, kontynuuj

	; zachowaj aktualny wskaźnik końca danych strumienia
	mov	word [rbx + KERNEL_STREAM_STRUCTURE_ENTRY.end],	dx

	; podnieś flagę danych w strumieniu
	or	byte [rbx + KERNEL_STREAM_STRUCTURE_ENTRY.flags],	KERNEL_STREAM_FLAG_data

.end:
	; odblokuj dostęp do potoku
	mov	byte [rbx + KERNEL_STREAM_STRUCTURE_ENTRY.semaphore],	STATIC_FALSE

	; przywróć oryginalne rejestry
	pop	rcx
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rax

	; powrót z procedury
	ret
