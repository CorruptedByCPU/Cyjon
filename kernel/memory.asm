;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

KERNEL_MEMORY_MAP_SIZE_page		equ	0x01	; domyślny rozmiar 4088 Bajtów (~128 MiB możliwej przestrzeni do opisania)

kernel_memory_map_address		dq	STATIC_EMPTY
kernel_memory_map_address_end		dq	STATIC_EMPTY

kernel_memory_lock_semaphore		db	STATIC_FALSE

;===============================================================================
; wejście:
;	rbp - ilość stron zarezerowanych do wykorzystania
; wyjście:
;	Flaga CF, jeśli brak dostępnej
;	rax - kod błędu, jeśli Flaga CF jest podniesiona
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
;	rax - kod błędu, jeśli Flaga CF jest podniesiona
;	rdi - wskaźnik do przydzielonej przestrzeni
;	rbp - ilość pozostałych stron zarezerwowanych
kernel_memory_alloc:
	; zachowaj oryginalne rejestry
	push	rbx
	push	rdx
	push	rsi
	push	rbp
	push	rax
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
	; zwróć kod błędu
	mov	qword [rsp + STATIC_QWORD_SIZE_byte],	KERNEL_ERROR_PAGE_memory_low

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
	jz	.next	; nie

	; ilość zarezerwowanych stron mniejszyła się
	dec	rbp
	dec	dword [kernel_page_reserved_count]

.next:
	; ilość dostępnych stron zmiejszyła się
	dec	qword [kernel_page_free_count]

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
	pop	rax
	pop	rbp
	pop	rsi
	pop	rdx
	pop	rbx

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

;===============================================================================
; wejście:
;	rax - wskaźnik do początku przestrzeni
;	rcx - rozmiar przestrzeni w stronach
;	r11 - wskaźnik do tablicy PML4 przestrzeni
; wyjście:
;	Flaga CF, jeśli nieoczekiwany koniec tablic stronicowania
kernel_memory_release_foreign:
	; zachowaj oryginalne rejestry
	push	rax
	push	rdx
	push	rdi
	push	r8
	push	r9
	push	r10
	push	r12
	push	r13
	push	r14
	push	r15
	push	r11
	push	rcx

	;-----------------------------------------------------------------------
	; oblicz numer wpisu w tablicy PML4 na podstawie otrzymanego adresu fizycznego/logicznego
	mov	rcx,	KERNEL_PAGE_PML3_SIZE_byte
	xor	rdx,	rdx	; wyczyść starszą część
	div	rcx

	; zachowaj
	mov	r15,	rax

	; przesuń wskaźnik w tablicy PML4 na dany wpis
	shl	rax,	STATIC_MULTIPLE_BY_8_shift	; zamień na Bajty
	add	r11,	rax

	; pobierz wskaźnik tablicy PML3 z wpisu tablicy PML4
	mov	rax,	qword [r11]
	xor	al,	al	; usuń flagi wpisu

	; zachowaj wskaźnik tablicy PML3
	mov	r10,	rax

	;-----------------------------------------------------------------------
	; oblicz numer wpisu w tablicy PML3 na podstawie pozostałego adresu fizycznego/logicznego
	mov	rax,	rdx	; przywróć resztę z dzielenia
	mov	rcx,	KERNEL_PAGE_PML2_SIZE_byte
	xor	rdx,	rdx	; wyczyść starszą część
	div	rcx

	; zachowaj
	mov	r14,	rax

	; przesuń wskaźnik w tablicy PML3 na wpis
	shl	rax,	STATIC_MULTIPLE_BY_8_shift	; zamień na Bajty
	add	r10,	rax

	; pobierz adres tablicy PML2 z wpisu tablicy PML3
	mov	rax,	qword [r10]
	xor	al,	al	; usuń flagi wpisu

	; zachowaj wskaźnik tablicy PML2
	mov	r9,	rax

	;-----------------------------------------------------------------------
	; oblicz numer wpisu w tablicy PML2 na podstawie pozostałego adresu fizycznego/logicznego
	mov	rax,	rdx	; przywróć resztę z dzielenia
	mov	rcx,	KERNEL_PAGE_PML1_SIZE_byte
	xor	rdx,	rdx	; wyczyść starszą część
	div	rcx

	; zachowaj
	mov	r13,	rax

	; przesuń wskaźnik w tablicy PML2 na wpis
	shl	rax,	STATIC_MULTIPLE_BY_8_shift	; zamień na Bajty
	add	r9,	rax

	; pobierz adres tablicy PML1 z wpisu tablicy PML2
	mov	rax,	qword [r9]
	xor	al,	al	; usuń flagi wpisu

	; zachowaj wskaźnik tablicy PML2
	mov	r8,	rax

	;-----------------------------------------------------------------------
	; oblicz numer wpisu w tablicy PML1 na podstawie pozostałego adresu fizycznego/logicznego
	mov	rax,	rdx	; przywróć resztę z dzielenia
	mov	rcx,	KERNEL_PAGE_SIZE_byte
	xor	rdx,	rdx	; wyczyść starszą część
	div	rcx

	; zachowaj
	mov	r12,	rax

	; przesuń wskaźnik w tablicy PML1 na wpis
	shl	rax,	STATIC_MULTIPLE_BY_8_shift	; zamień na Bajty
	add	r8,	rax

	; rozmiar przestrzeni do zwolnienia w stronach
	mov	rcx,	qword [rsp]

.pml1:
	; koniec przetwarzania?
	test	rcx,	rcx
	jz	.end	; tak

	; brak zarejestrowanej strony?
	cmp	qword [r8],	STATIC_EMPTY
	je	.pml1_omit	; tak, pomiń

	; zwolnij przestrzeń
	mov	rdi,	qword [r8]
	and	di,	KERNEL_PAGE_mask
	call	kernel_memory_release_page

	; zwolnij wpis w tablicy PML1
	mov	qword [r8],	STATIC_EMPTY

.pml1_omit:
	; "zwolniono" stronę z przestrzeni
	dec	rcx

	; następny wpis tablicy tablicy PML1
	add	r8,	STATIC_QWORD_SIZE_byte
	inc	r12

	; koniec tablicy PML1
	cmp	r12,	KERNEL_PAGE_RECORDS_amount
	jne	.pml1	; nie

.pml2_entry:
	; aktualna tablica PML1 jest pusta?
	mov	rdi,	qword [r9]
	and	di,	KERNEL_PAGE_mask
	call	kernel_page_empty
	jnz	.pml2	; nie

	; zwolnij przestrzeń tablicy
	call	kernel_memory_release_page

	; zwolniono tablicę stronicowania
	dec	qword [kernel_page_paged_count]

	; usuń rekord z tablicy PML2
	mov	qword [r9],	STATIC_EMPTY

.pml2:
	; następny wpis w tablicy PML2
	add	r9,	STATIC_QWORD_SIZE_byte
	inc	r13

	; koniec tablicy PML2?
	cmp	r13,	KERNEL_PAGE_RECORDS_amount
	je	.pml3_entry	; tak

.pml2_record:
	; pobierz adres tablicy PML1
	mov	r8,	qword [r9]

	; brak tablicy PML1
	test	r8,	r8
	jz	.pml2	; tak, następny rekord

	; usuń flagi
	xor	r8b,	r8b

	; wyczyść ilość przetworzonych wpisów
	xor	r12,	r12

	; kontynuuj
	jmp	.pml1

.pml3_entry:
	; aktualna tablica PML2 jest pusta?
	mov	rdi,	qword [r10]
	and	di,	KERNEL_PAGE_mask
	call	kernel_page_empty
	jnz	.pml3	; nie

	; zwolnij przestrzeń tablicy
	call	kernel_memory_release_page

	; zwolniono tablicę stronicowania
	dec	qword [kernel_page_paged_count]

	; usuń rekord z tablicy PML3
	mov	qword [r10],	STATIC_EMPTY

.pml3:
	; następny wpis w tablicy PML3
	add	r10,	STATIC_QWORD_SIZE_byte
	inc	r14

	; koniec tablicy PML3?
	cmp	r14,	KERNEL_PAGE_RECORDS_amount
	je	.pml4_entry	; tak

.pml3_record:
	; pobierz adres tablicy PML2
	mov	r9,	qword [r10]

	; brak tablicy PML2?
	test	r9,	r9
	jz	.pml3	; tak, następny rekord

	; usuń flagi
	xor	r9b,	r9b

	; wyczyść ilość przetworzonych wpisów
	xor	r13,	r13

	; kontynuuj
	jmp	.pml2_record

.pml4_entry:
	; aktualna tablica PML3 jest pusta?
	mov	rdi,	qword [r11]
	and	di,	KERNEL_PAGE_mask
	call	kernel_page_empty
	jnz	.pml4	; nie

	; zwolnij przestrzeń tablicy
	call	kernel_memory_release_page

	; zwolniono tablicę stronicowania
	dec	qword [kernel_page_paged_count]

	; usuń rekord z tablicy PML4
	mov	qword [r11],	STATIC_EMPTY

.pml4:
	; następny wpis w tablicy PML4
	add	r11,	STATIC_QWORD_SIZE_byte
	inc	r15

	; koniec tablicy PML4?
	cmp	r15,	KERNEL_PAGE_RECORDS_amount
	je	.pml5	; tak... że jak?

	; pobierz adres tablicy PML3
	mov	r10,	qword [r11]

	; brak tablicy PML3?
	test	r10,	r10
	jz	.pml4	; tak, następny rekord

	; usuń flagi
	xor	r10b,	r10b

	; wyczyść ilość przetworzonych wpisów
	xor	r14,	r14

	; kontynuuj
	jmp	.pml3_record

.pml5:
	; flaga, błąd
	stc

.end:
	; przywróć oryginalne rejestry
	pop	rcx
	pop	r11
	pop	r15
	pop	r14
	pop	r13
	pop	r12
	pop	r10
	pop	r9
	pop	r8
	pop	rdi
	pop	rdx
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"kernel_memory_release_foreign"

;===============================================================================
; wejście:
;	rcx % 256 = 0 - rozmiar przestrzeni do skopiowania w Bajtach
;	rsi - miejsce źródłowe
;	rdi - miejsce docelowe
kernel_memory_copy:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rsi
	push	rdi

	; przestrzeń kopiujemy w pakietach po 256 Bajtów
	shr	rcx,	STATIC_DIVIDE_BY_256_shift

.loop:
	; kopiuj
	macro_copy

	; przesuń wskaźniki na następny pakiet danych
	add	rsi,	256
	add	rdi,	256

	; koniec przestrzeni?
	dec	rcx
	jnz	.loop	; nie

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rcx

	; powrót z procedury
	ret

	macro_debug	"kernel_memory_copy"
