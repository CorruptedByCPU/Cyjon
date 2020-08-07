;===============================================================================
; Copyright (C) by blackdev.org
;===============================================================================

KERNEL_STREAM_FLAG_data		equ	00000001b	; istnieją dane w potoku

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
;	rbx - identyfikator potoku
;	rcx - rozmiar bufora docelowego
;	rdi - wskaźnik docelowy danych
; wyjście:
;	rcx - ilość danych przesłanych
kernel_stream_in:
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
	push	rsi
	push	rdi
	push	rcx

.try:
	; zablokuj dostęp do potoku
	macro_lock	rbx, KERNEL_STREAM_STRUCTURE_ENTRY.semaphore

	; pobierz wskaźnik końca danych potoku
	mov	ax,	word [rbx + KERNEL_STREAM_STRUCTURE_ENTRY.end]

	; w potoku jest wolna przestrzeń?
	cmp	ax,	word [rbx + KERNEL_STREAM_STRUCTURE_ENTRY.start]
	jne	.entry	; tak

	; istnieją dane w potoku?
	test	byte [rbx + KERNEL_STREAM_STRUCTURE_ENTRY.flags],	KERNEL_STREAM_FLAG_data
	jz	.entry	; nie

	; odblokuj dostęp do potoku
	mov	byte [rbx + KERNEL_STREAM_STRUCTURE_ENTRY.semaphore],	STATIC_FALSE

	; spróbuj raz jeszcze
	jmp	.try

.entry:
	xchg	bx,bx

	; ustaw wskaźnik docelowy przestrzeń potoku
	mov	rdi,	qword [rbx + KERNEL_STREAM_STRUCTURE_ENTRY.address]

	;-----------------------------------------------------------------------

.save:
	; zawinąć przestrzeń danych potoku?
	cmp	ax,	STATIC_PAGE_SIZE_byte
	je	.roll

.end:
	; odblokuj dostęp do potoku
	mov	byte [rbx + KERNEL_STREAM_STRUCTURE_ENTRY.semaphore],	STATIC_FALSE

	; przywróć oryginalne rejestry
	pop	rcx
	pop	rdi
	pop	rsi
	pop	rax

	; powrót z procedury
	ret
