;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

KERNEL_MEMORY_MAP_SIZE_page		equ	0x01	; domyślny rozmiar 4088 Bajtów (~128 MiB możliwej przestrzeni do opisania)

kernel_memory_map_address		dq	STATIC_EMPTY
kernel_memory_map_address_end		dq	STATIC_EMPTY

kernel_memory_high_mask			dq	KERNEL_MEMORY_HIGH_mask
kernel_memory_real_address		dq	KERNEL_MEMORY_HIGH_REAL_address

kernel_memory_lock_semaphore		db	STATIC_FALSE

;===============================================================================
; wejście:
;	rcx - ilość stron do oznaczenia jako zajęte
;	rsi - wskaźnik dp binarnej mapy pamięci
kernel_memory_secure:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rsi

	; rozpocznij blokowanie stron od początku binarnej mapy pamięci
	mov	rax,	STATIC_MAX_unsigned

.loop:
	; zablokuj dostęp do pierwszej strony "zestawu"
	inc	rax
	btr	qword [rsi],	rax

	; zablokować pozostałe strony?
	dec	rcx
	jnz	.loop	; tak

	; przywróć oryginalne rejestry
	pop	rsi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

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
	mov	qword [rsp + STATIC_QWORD_SIZE_byte],	KERNEL_ERROR_memory_low

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

	; wykorzystano zarezerwowaną stronę
	jmp	.reserved

.next:
	; ilość dostępnych stron zmiejszyła się
	dec	qword [kernel_page_free_count]

.reserved:
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
	pop	rsi
	pop	rdx
	pop	rbx

	; powrót z procedury
	ret

	macro_debug	"kernel_memory_alloc"

;===============================================================================
kernel_memory_lock:
	; zablokuj dostęp do binarnej mapy pamięci
	macro_lock	kernel_memory_lock_semaphore, 0

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
	shr	rax,	STATIC_PAGE_SIZE_shift

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
	add	rdi,	STATIC_PAGE_SIZE_byte

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
	mov	rcx,	STATIC_PAGE_SIZE_byte
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

	; pobierz adres fizyczny strony
	mov	rdi,	qword [r8]

	; strona oznaczona jako wirtualna?
	test	di,	KERNEL_PAGE_FLAG_virtual
	jnz	.virtual	; tak, zignoruj

	; zwolnij stronę
	and	di,	STATIC_PAGE_mask
	call	kernel_memory_release_page

.virtual:
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
	and	di,	STATIC_PAGE_mask
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
	and	di,	STATIC_PAGE_mask
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
	and	di,	STATIC_PAGE_mask
	call	kernel_page_empty
	jnz	.pml4	; nie

	; zwolnij przestrzeń tablicy
	call	kernel_memory_release_page

	; zwolniono tablicę stronicowania
	dec	qword [kernel_page_paged_count]

	; usuń rekord z tablicy PML4
	mov	qword [r11],	STATIC_EMPTY

	; wyczyszczono strukturę tablic aż do poziomu PML4

	; czy przestrzeń jest już przetworzona?
	test	rcx,	rcx
	jz	.end	; tak, koniec procedury

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

;===============================================================================
; wejście:
;	rcx - rozmiar oczekiwanej przestrzeni w stronach
; wyjście:
;	Flaga CF - jeśli brak miejsca
;	rdi - wskaźnik do przydzielonej przestrzeni
kernel_memory_alloc_task:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	r8
	push	r11

	; zarezerwuj podany rozmiar przestrzeni
	call	kernel_memory_alloc_task_secure
	jc	.error	; brak wystarczającej ilości pamięci

	; mapuj przestrzeń
	mov	rax,	rdi
	sub	rax,	qword [kernel_memory_high_mask]	; zamień na adres bezpośredni
	mov	bx,	KERNEL_PAGE_FLAG_write | KERNEL_PAGE_FLAG_user | KERNEL_PAGE_FLAG_available
	mov	r11,	cr3
	call	kernel_page_map_logical
	jnc	.ready	; przydzielono

	; brak wolnej przestrzeni RAM, wyrejestruj przestrzeń procesu
	call	kernel_memory_release_task_secured

.error:
	; flaga, błąd
	stc

.ready:
	; przywróć oryginalne rejestry
	pop	r11
	pop	r8
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	rcx - rozmiar przestrzeni w stronach
; wyjście:
;	Flaga CF, jeśli brak dostępnej
;	rax - kod błędu, jeśli Flaga CF jest podniesiona
;	rdi - wskaźnik do przydzielonej przestrzeni
kernel_memory_alloc_task_secure:
	; zachowaj oryginalne rejestry
	push	rbx
	push	rdx
	push	rsi
	push	rdi
	push	rax
	push	rcx

	; numer pierwszego bitu wolnej przestrzeni
	mov	rax,	STATIC_MAX_unsigned

	; pobierz wskaźnik do właściwości procesu
	call	kernel_task_active

	; proces wykonujący jest usługą?
	test	qword [rdi + KERNEL_TASK_STRUCTURE.flags],	KERNEL_TASK_FLAG_service
	jnz	.end	; zignoruj wywołanie

	; pobierz wskaźnik i ilość stron w binarnej mapie pamięci procesu
	mov	rcx,	qword [rdi + KERNEL_TASK_STRUCTURE.map_size]
	mov	rsi,	qword [rdi + KERNEL_TASK_STRUCTURE.map]

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
	mov	qword [rsp + STATIC_QWORD_SIZE_byte],	KERNEL_ERROR_memory_low

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

	; następna strona
	inc	rax

	; koniec przetwarzania przestrzeni?
	dec	rdx
	jnz	.lock	; nie, kontynuuj

	; przelicz numer pierwszej strony przestrzeni na adres WZGLĘDNY
	shl	rbx,	STATIC_MULTIPLE_BY_PAGE_shift

	; koryguj o adres początku opisanej przestrzeni przez binarną mapę pamięci procesu
	add	rbx,	qword [kernel_memory_real_address]

	; zwróć adres do procesu
	mov	qword [rsp + STATIC_QWORD_SIZE_byte * 0x02],	rbx

.end:
	; przywróć oryginalne rejestry
	pop	rcx
	pop	rax
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rbx

	; powrót z procedury
	ret

	macro_debug	"kernel_memory_alloc_task_secure"

;===============================================================================
; wejście:
;	rcx - rozmiar przestrzeni w stronach
;	rdi - adres przestrzeni do zwolnienia
kernel_memory_release_task_secured:
	; zachowaj oryginalne rejestry i flagi
	push	rax
	push	rdx
	push	rsi
	push	rdi
	push	rcx

	; pobierz wskaźnik do właściwości procesu
	call	kernel_task_active

	; pobierz wskaźnik do binarnej mapy pamięci procesu
	mov	rsi,	qword [rdi + KERNEL_TASK_STRUCTURE.map]

	; przelicz adres strony na numer bitu
	mov	rax,	rdi
	sub	rax,	qword [kernel_memory_real_address]
	shr	rax,	STATIC_PAGE_SIZE_shift

	; oblicz prdesunięcie względem początku binarnej mapy pamięci
	mov	rcx,	64
	xor	rdx,	rdx	; wyczyść starszą część
	div	rcx

	; przesuń wskaźnik na "pakiet"
	shl	rax,	STATIC_MULTIPLE_BY_8_shift
	add	rsi,	rax

	; zwolnij wszystkie strony wchodzące w skład przestrzeni
	mov	rcx,	qword [rsp]

.loop:
	; włącz bit odpowiadający za zwalnianą stronę
	bts	qword [rsi],	rdx

	; następna strona przestrzeni
	inc	rdx

	; koniec przestrzeni?
	dec	rcx
	jnz	.loop	; nie

	; przywróć oryginalne rejestry i flagi
	pop	rcx
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"kernel_memory_release_task_secured"
