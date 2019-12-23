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
;	rbp - ilość stron zarezerowanych do wykorzystania
; wyjście:
;	Flaga CF, jeśli brak dostępnej
;	rdi - wskaźnik do przydzielonej przestrzeni
;	rbp - ilość pozostałych stron zarezerwowanych
kernel_memory_alloc_page:
	; zachowaj oryginalne rejestry
	push	rcx

	; przydziel przestrzeń o rozmiarze jednej strony
	mov	ecx,	0x01
	call	kernel_memory_alloc

	; przywróć oryginalne rejestry
	pop	rcx

	; powrót z procedury
	ret

	macro_debug	"kernel_memory_alloc_page"

;===============================================================================
; wejście:
;	rcx - rozmiar przestrzeni w stronach
;	rbp - ilość stron zarezerowanych do wykorzystania
; wyjście:
;	Flaga CF, jeśli brak dostępnej
;	rdi - wskaźnik do przydzielonej przestrzeni
;	rbp - ilość pozostałych stron zarezerwowanych
kernel_memory_alloc:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rdx
	push	rsi
	push	rbp
	push	rcx

	; zresetuj numer pierwszego bitu poszukiwanej przestrzeni
	mov	rax,	STATIC_MAX_unsigned

	; pobierz ilość opisanych stron w binarnej mapie pamięci
	mov	rcx,	qword [kernel_page_total_count]

	; przeszukaj binarną mapę pamięci od początku
	mov	rsi,	qword [kernel_memory_map_address]

.reload:
	; ilość stron wchodzących w skład rozpatrywanej przestrzeni
	xor	edx,	edx

.search:
	; sprawdź następną stronę
	inc	rax

	; koniec binarnej mapy pamięci?
	cmp	rax,	rcx
	je	.error	; tak

	; znaleziono wolną stronę?
	bt	qword [rsi],	rax
	jnc	.search	; nie

	; zachowaj numer pierwszego bitu wchodzącego w skład poszukiwanej przestrzeni
	mov	rbx,	rax

.check:
	; sprawdź następną stronę
	inc	rax

	; zalicz aktualną stronę do poszukiwanej przestrzeni
	inc	rdx

	; znaleziono całkowity rozmiar przestrzeni
	cmp	rdx,	qword [rsp]
	je	.found	; tak

	; koniec binarnej mapy pamięci?
	cmp	rax,	rcx
	je	.error	; tak

	; następna strona wchodząca w skład poszukiwanej przestrzeni?
	bt	qword [rsi],	rax
	jc	.check	; tak

	; rozpatrywana przestrzeń jest niepełna, znajdź następną
	jmp	.reload

.error:
	; flaga, błąd
	stc

	; koniec procedury
	jmp	.end

.found:
	; ustaw numer pierwszej strony przestrzeni do zablokowania
	mov	rax,	rbx

.lock:
	; zwolnij kolejne strony wchodzące w skład znalezionej przestrzeni
	btr	qword [rsi],	rax

	; wykorzystaj zarezerwowaną stronę?
	test	rbp,	rbp
	jz	.empty	; nie

	; ilość zarezerwowanych stron mniejszyła się
	dec	rbp
	dec	dword [kernel_page_reserved_count]

	; kontynuuj
	jmp	.next

.empty:
	; ilość dostępnych stron zmiejszyła się
	dec	qword [kernel_page_free_count]

.next:
	; następna strona
	inc	rax

	; koniec przetwarzania przestrzeni?
	dec	rdx
	jnz	.lock	; nie, kontynuuj

	; przelicz numer pierwszej strony przestrzeni na adres WZGLĘDNY
	mov	rdi,	rbx
	shl	rdi,	STATIC_MULTIPLE_BY_PAGE_shift

	; koryguj o adres początku opisanej przestrzeni przez binarną mapę pamięci
	add	rdi,	KERNEL_BASE_address

.end:
	; zwolnij dostęp do binarnej mapy pamięci
	mov	byte [kernel_memory_lock_semaphore],	STATIC_FALSE

	; przywróć oryginalne rejestry
	pop	rcx
	pop	rbp
	pop	rsi
	pop	rdx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"kernel_memory_alloc"

;===============================================================================
kernel_memory_lock:
	; zablokuj dostęp do binarnej mapy pamięci
	macro_close	kernel_memory_lock_semaphore, 0

	; powrót z procedury
	ret

	macro_debug	"kernel_memory_lock"

;===============================================================================
; wejście:
;	rdi - adres strony do zwolnienia
kernel_memory_release_page:
	; zachowaj oryginalne rejestry i flagi
	push	rax
	push	rcx
	push	rdx
	push	rsi
	push	rdi

	; pobierz adres początku binarnej mapy pamięci
	mov	rsi,	qword [kernel_memory_map_address]

	; przelicz adres strony na numer bitu
	mov	rax,	rdi
	sub	rax,	KERNEL_BASE_address
	shr	rax,	KERNEL_PAGE_SIZE_shift

	; oblicz prdesunięcie względem początku binarnej mapy pamięci
	mov	rcx,	64
	xor	rdx,	rdx	; wyczyść starszą część
	div	rcx

	; prdesuń wskaźnik na "pakiet"
	shl	rax,	STATIC_MULTIPLE_BY_8_shift
	add	rsi,	rax

	; włącz bit odpowiadający za zwalnianą stronę
	bts	qword [rsi],	rdx

	; zwiększamy ilość dostępnych stron o jedną
	inc	qword [kernel_page_free_count]

	; przywróć oryginalne rejestry i flagi
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"kernel_memory_release_page"

;===============================================================================
; wejście:
;	rcx - ilość kolejnych stron do zwolnienia
;	rdi - wskaźnik do pierwszej strony
kernel_memory_release:
	; zachowaj oryginalne rejestry i flagi
	push	rcx
	push	rdi

.loop:
	; zwolnij pierwszą stronę
	call	kernel_memory_release_page

	; przesuń wskaźnik na następną stronę
	add	rdi,	KERNEL_PAGE_SIZE_byte

	; pozostały strony do zwolnienia?
	dec	rcx
	jnz	.loop	; tak

	; przywróć oryginalne rejestry i flagi
	pop	rdi
	pop	rcx

	; powrót z procedury
	ret

	macro_debug	"kernel_memory_release"
