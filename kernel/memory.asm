;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

KERNEL_MEMORY_HIGH_mask			equ	0xFFFF000000000000
KERNEL_MEMORY_HIGH_REAL_address		equ	0xFFFF800000000000
KERNEL_MEMORY_HIGH_VIRTUAL_address	equ	KERNEL_MEMORY_HIGH_REAL_address - KERNEL_MEMORY_HIGH_mask

KERNEL_MEMORY_MAP_SIZE_page		equ	0x01	; domyślny rozmiar 4088 Bajtów (~128 MiB możliwej przestrzeni do opisania)

kernel_memory_map_address		dq	STATIC_EMPTY
kernel_memory_map_address_end		dq	STATIC_EMPTY

kernel_memory_lock_semaphore		db	STATIC_FALSE

;===============================================================================
; wejście:
;	rbp - ilość stron zarezerwowanych, z których procedura powinna skorzystać
; wyjście:
;	Flaga CF, jeśli brak danej przestrzeni
;	rdi - wskaźnik BEZWZGLĘDNY przydzielonej przestrzeni o rozmiarze 4 KiB
kernel_memory_alloc_page_internal:
	; zachowaj oryginalne rejestry
	push	rsi

	; skorzystaj z binarnej mapy pamięci jądra systemu
	mov	rsi,	qword [kernel_memory_map_address]

	; uzyskaj wyłączny dostęp do binarnej mapy pamięci jądra systemu
	call	kernel_memory_lock

	; wykorzystać stronę zarezerwowaną?
	test	rbp,	rbp
	jz	.unreserved	; nie

	; ilość stron zarezerwowanych
	dec	rbp	; mniejsz o jedną

	; ilość stron dostępnych
	inc	qword [kernel_page_free_count]	; zwiększ o jedną

	; wykorzystano zarezerwowaną stronę
	dec	qword [kernel_page_reserved_count]
	jns	.unreserved	; opracja poprawna

	; błąd krytyczny
	xchg	bx,bx

	nop

	; zatrzymaj dalsze wykonywanie kodu
	jmp	$

.unreserved:
	; pobierz adres wolnej strony
	call	kernel_memory_alloc_page
	jc	.error	; brak dostępnych stron

	; zwolnij dostęp do binarnej mapy pamięci jądra systemu
	mov	byte [kernel_memory_lock_semaphore],	STATIC_FALSE

	; koryguj adres na bezwzględny
	add	rdi,	KERNEL_BASE_address

.error:
	; przywróć oryginalne rejestry
	pop	rsi

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	rcx - rozmiar przestrzeni w stronach
; wyjście:
;	Flaga CF, jeśli brak danej przestrzeni
;	rdi - wskaźnik BEZWZGLĘDNY do udostępnionej przestrzeni
kernel_memory_alloc_space_internal:
	; zachowaj oryginalne rejestry
	push	rsi

	; skorzystaj z binarnej mapy pamięci jądra systemu
	mov	rsi,	qword [kernel_memory_map_address]

	; uzyskaj wyłączny dostęp do binarnej mapy pamięci jądra systemu
	call	kernel_memory_lock

	; pobierz adres dostępnej przestrzeni
	call	kernel_memory_alloc_space
	jc	.error	; brak dostępnej przestrzeni o podanym rozmiarze

	; ilość dostępnych stron zmniejsz o rozmiar przestrzeni
	sub	qword [kernel_page_free_count],	rcx

	; zwolnij dostęp do binarnej mapy pamięci jądra systemu
	mov	byte [kernel_memory_lock_semaphore],	STATIC_FALSE

	; koryguj adres na bezwzględny
	add	rdi,	KERNEL_BASE_address

.error:
	; przywróć oryginalne rejestry
	pop	rsi

	; powrót z procedury
	ret

;===============================================================================
kernel_memory_lock:
	; zablokuj dostęp do binarnej mapy pamięci
	macro_close	kernel_memory_lock_semaphore, 0

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	rsi - wskaźnik do binarnej mapy pamięci
; wyjście:
;	Flaga CF, jeśli brak danej przestrzeni
;	rdi - wskaźnik WZGLĘDNY do udostępnionej przestrzeni o rozmiarze 4 KiB
kernel_memory_alloc_page:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rsi

	; możliwe jest przydzielenie strony?
	cmp	qword [kernel_page_free_count],	STATIC_EMPTY
	je	.error	; nie

	; ilość możliwych stron do przydzielenia
	dec	qword [kernel_page_free_count]	; zmniejsz o jedną

	; ilość bitów na blok binarnej mapy pamięci
	mov	rcx,	STATIC_STRUCTURE_BLOCK.link << STATIC_MULTIPLE_BY_8_shift

	; zresetuj wskaźnik dostępnej strony
	xor	edi,	edi

.search:
	; znaleziono wolną stronę?
	bt	qword [rsi],	rdi
	jc	.found	; tak

	; przesuń wskaźnik na następny bit
	inc	rdi

	; koniec bloku binarnej mapy?
	cmp	rdi,	rcx
	jne	.search	; nie

	; błąd krytyczny
	xchg	bx,bx

	nop

	; zatrzymaj dalsze wykonywanie kodu
	jmp	$

.found:
	; wyłącz bit reprezentujący stronę
	btr	qword [rsi],	rdi

	; zwróć WZGLĘDNY adres strony
	shl	rdi,	STATIC_MULTIPLE_BY_PAGE_shift

	; zakończ procedurę
	jmp	.end

.error:
	; flaga, błąd
	stc

.end:
	; przywróć oryginalne rejestry
	pop	rsi
	pop	rcx

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	rcx - rozmiar przestrzeni w stronach
;	rsi - wskaźnik do binarnej mapy pamięci
; wyjście:
;	Flaga CF, jeśli brak danej przestrzeni
;	rdi - wskaźnik WZGLĘDNY do udostępnionej przestrzeni o rozmiarze w RCX
kernel_memory_alloc_space:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rdx
	push	rsi
	push	rcx

	; zresetuj numer pierwszego bitu poszukiwanej przestrzeni
	mov	rax,	STATIC_MAX_unsigned

	; ilość bitów na blok binarnej mapy pamięci
	mov	rcx,	STATIC_STRUCTURE_BLOCK.link << STATIC_MULTIPLE_BY_8_shift

.reload:
	; ilość bitów wchodzących w skład ropatrywanej przestrzeni
	xor	edx,	edx

.search:
	; sprawdź następną stronę
	inc	rax

	; koniec bitów w bloku binarnej mapy pamięci?
	cmp	rax,	rcx
	je	.error	; tak

	; znaleziono wolną stronę?
	bt	qword [rsi],	rax
	jnc	.search	; nie

	; numer pierwszego bitu wchodzącego w skład poszukiwanej przestrzeni
	mov	rbx,	rax

.check:
	; sprawdź następną stronę
	inc	rax

	; zalicz aktualną stronę do poszukiwanej przestrzeni
	inc	rdx

	; znaleziono całkowity rozmiar przestrzeni
	cmp	rdx,	qword [rsp]
	je	.found	; tak

	; koniec bitów w bloku binarnej mapy pamięci?
	cmp	rax,	rcx
	je	.error	; tak

	; następna strona wchodząca w skład poszukiwanej przestrzeni?
	bt	qword [rsi],	rax
	jc	.check	; tak

	; rozpatrywana przestrzeń jest niepełna, znajdź nową
	jmp	.reload

.error:
	; flaga, błąd
	stc

	; koniec procedury
	jmp	.end

.found:
	; zapamiętaj numer pierwszej strony przestrzeni
	mov	rax,	rbx

.lock:
	; zwolnij kolejne strony wchodzące w skład znalezionej przestrzeni
	btr	qword [rsi],	rbx

	; następna strona
	inc	rbx

	; koniec przetwarzania przestrzeni?
	dec	rdx
	jnz	.lock	; nie, kontynuuj

	; zwróć adres WZGLĘDNY odnalezionej przestrzeni
	mov	rdi,	rax
	shl	rdi,	STATIC_MULTIPLE_BY_PAGE_shift

.end:
	; przywróć oryginalne rejestry
	pop	rcx
	pop	rsi
	pop	rdx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret
