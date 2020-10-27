;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

KERNEL_PAGE_FLAG_available	equ	1 << 0
KERNEL_PAGE_FLAG_write		equ	1 << 1
KERNEL_PAGE_FLAG_user		equ	1 << 2
KERNEL_PAGE_FLAG_write_through	equ	1 << 3
KERNEL_PAGE_FLAG_cache_disable	equ	1 << 4
KERNEL_PAGE_FLAG_length		equ	1 << 7
KERNEL_PAGE_FLAG_virtual	equ	1 << 9

KERNEL_PAGE_RECORDS_amount	equ	512

KERNEL_PAGE_PML4_SIZE_byte	equ	KERNEL_PAGE_RECORDS_amount * KERNEL_PAGE_PML3_SIZE_byte
KERNEL_PAGE_PML3_SIZE_byte	equ	KERNEL_PAGE_RECORDS_amount * KERNEL_PAGE_PML2_SIZE_byte
KERNEL_PAGE_PML2_SIZE_byte	equ	KERNEL_PAGE_RECORDS_amount * KERNEL_PAGE_PML1_SIZE_byte
KERNEL_PAGE_PML1_SIZE_byte	equ	KERNEL_PAGE_RECORDS_amount * STATIC_PAGE_SIZE_byte

; wyrównaj pozycję zmiennych do pełnego adresu
align	STATIC_QWORD_SIZE_byte,	db	STATIC_NOTHING

kernel_page_pml4_address	dq	STATIC_EMPTY

kernel_page_total_count		dq	STATIC_EMPTY
kernel_page_free_count		dq	STATIC_EMPTY
kernel_page_reserved_count	dq	STATIC_EMPTY
kernel_page_paged_count		dq	STATIC_EMPTY
kernel_page_shared_count	dq	STATIC_EMPTY

;===============================================================================
; wejście:
;	rdi - wskaźnik do strony
; wyjście:
;	Flaga ZF - jeśli pusta
kernel_page_empty:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx

	; wyczyść akumulator
	xor	eax,	eax

	; ilość rekordów do sprawdzenia
	mov	ecx,	KERNEL_PAGE_RECORDS_amount - 0x01

.loop:
	; pobierz zawartość rekordu
	or	rax,	qword [rdi + rcx * STATIC_QWORD_SIZE_byte]

	; koniec zliczania?
	dec	cx
	jns	.loop	; nie

	; strona pusta?
	test	rax,	rax

	; przywróć oryginalne rejestry
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	rdi - adres strony do wyczyszczenia
kernel_page_drain:
	; zachowaj oryginalne rejestry
	push	rcx

	; rozmiar strony w Bajtach
	mov	rcx,	STATIC_PAGE_SIZE_byte
	call	.proceed

	; przywróć oryginalne rejestry
	pop	rcx

	; powrót z procedury
	ret

;-------------------------------------------------------------------------------
; uwagi:
;	rcx - zniszczony
.proceed:
	; zachowaj oryginalne rejestry
	push	rax
	push	rdi

	; wyczyść przestrzeń
	xor	rax,	rax
	shr	rcx,	STATIC_DIVIDE_BY_8_shift	; po 8 Bajtów na raz
	and	di,	STATIC_PAGE_mask	; wyrównaj adres przestrzeni w dół (failsafe)
	rep	stosq

	; przywróć orygialne rejestry
	pop	rdi
	pop	rax

	; powrót z podprocedury
	ret

	macro_debug	"kernel_page_drain"

;===============================================================================
; wejście:
;	rcx - ilość kolejnych stron do wyczyszczenia
;	rdi - wskaźnik do pierwszej strony
kernel_page_drain_few:
	; zachowaj oryginalne rejestry
	push	rcx

	; oblicz rozmiar przestrzeni do wyczyszczenia
	shl	rcx,	STATIC_PAGE_SIZE_shift
	call	kernel_page_drain.proceed

	; przywróć oryginalne rejestry
	pop	rcx

	; powrót z procedury
	ret

	macro_debug	"kernel_page_drain_few"

;===============================================================================
; wejście:
;	rax - adres przestrzeni fizycznej do opisania w tablicach stronicowania
;	bx - flagi rekordów tablic stronicowania
;	rcx - rozmiar przestrzeni w stronach do opisania
;	r11 - adres fizyczny tablicy PML4, w której dokonać wpis
; wyjście:
;	Flaga CF - ustawiona, jeśli wystąpił błąd
;	r8 - adres wpisu opisującego pierwszą stronę przestrzeni
; uwagi:
;	zastrzeż odpowiednią ilość stron, rbp
kernel_page_map_physical:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rdx
	push	rdi
	push	r9
	push	r10
	push	r11
	push	r12
	push	r13
	push	r14
	push	r15
	push	rax

	; przygotuj podstawową ścieżkę do mapowanej przestrzeni
	call	kernel_page_prepare
	jc	.error	; błąd, brak wolnej pamięci lub przepełniono tablicę stronicowania

	; dołącz do początku opisywanej przestrzeni, właściwości
	or	ax,	bx

.row:
	; sprawdź czy skończyły się rekordy w tablicy PML1
	cmp	r12,	KERNEL_PAGE_RECORDS_amount
	jb	.exist	; nie

	; utwórz nową tablicę stronicowania PML1
	call	kernel_page_pml1

.exist:
	; zapisz adres mapowany do wiersza PML1[r12]
	stosq

	; przesuń adres do następnego mapowanej przestrzeni
	add	rax,	STATIC_PAGE_SIZE_byte

	; ustaw numer następnego wiersza w tablicy PML1
	inc	r12

	; następny wiersz tablicy?
	dec	rcx
	jnz	.row	; tak

	; flaga, sukces
	clc

	; koniec
	jmp	.end

.error:
	; flaga, błąd
	stc

.end:
	; przywróć oryginalne rejestry
	pop	rax
	pop	r15
	pop	r14
	pop	r13
	pop	r12
	pop	r11
	pop	r10
	pop	r9
	pop	rdi
	pop	rdx
	pop	rcx

	; powrót z procedury
	ret

	macro_debug	"kernel_page_map_physical"

;===============================================================================
; wejście:
;	rax - adres przestrzeni logicznej do opisania w tablicach stronicowania
;	bx - flagi rekordów tablic stronicowania
;	rcx - rozmiar przestrzeni w stronach do opisania
;	r11 - adres fizyczny tablicy PML4, w której dokonać wpis
; wyjście:
;	Flaga CF - jeśli ustawiona, błąd
;	r8 - adres rekordu opisującego pierwszą stronę przestrzeni
; uwagi:
;	zastrzeż odpowiednią ilość stron, rbp
kernel_page_map_logical:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rdx
	push	rdi
	push	r9
	push	r10
	push	r11
	push	r12
	push	r13
	push	r14
	push	r15
	push	rax

	; przygotuj podstawową ścieżkę z tablic do mapowanego adresu
	call	kernel_page_prepare
	jc	.error

.record:
	; sprawdź czy skończyły się rekordy w tablicy PML1
	cmp	r12,	KERNEL_PAGE_RECORDS_amount
	jb	.exists	; istnieją rekordy

	; utwórz nową tablicę stronicowania PML1
	call	kernel_page_pml1
	jc	.error

.exists:
	; rekord zajęty?
	cmp	qword [rdi],	STATIC_EMPTY
	je	.no

	; przesuń wskaźnik na następny rekord
	add	rdi,	STATIC_QWORD_SIZE_byte
	jmp	.continue

.no:
	; zachowaj adres rekordu tablicy PML1
	push	rdi

	; przydziel wolną stronę
	call	kernel_memory_alloc_page
	jc	.error

	; wyczyść
	call	kernel_page_drain

	; ustaw właściwości rekordu
	add	di,	bx

	; przywróć adres rekordu tablicy PML1
	pop	rax

	; zapisz adres przestrzeni mapowanej do rekordu tablicy PML1[r12]
	xchg	rdi,	rax
	stosq

.continue:
	; ustaw numer następnego rekordu w tablicy pml1
	inc	r12

	; kontynuuj
	dec	rcx
	jnz	.record

	; koniec procedury
	jmp	.end

.error:
	; zwróć kod błędu
	mov	qword [rsp],	rax

	; flaga, błąd
	stc

.end:
	; przywróć oryginalne rejestry
	pop	rax
	pop	r15
	pop	r14
	pop	r13
	pop	r12
	pop	r11
	pop	r10
	pop	r9
	pop	rdi
	pop	rdx
	pop	rcx

	; powrót z procedury
	ret

	macro_debug	"kernel_page_map_logical"

;===============================================================================
; wejście:
;	rcx - rozmiar przestrzeni w stronach do opisania
;	rsi - wskaźnik do przestrzeni jądra systemu
;	rdi - wskaźnik do przestrzeni procesu
;	r11 - adres fizyczny tablicy PML4, w której dokonać podłączenie
; wyjście:
;	Flaga CF - jeśli ustawiona, błąd
kernel_page_map_virtual:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rsi
	push	rdi
	push	r8
	push	r9
	push	r10
	push	r11
	push	r12
	push	r13
	push	r14
	push	r15

	; koryguj adres przestrzeni logicznej
	mov	rax,	KERNEL_MEMORY_HIGH_mask
	sub	rdi,	rax
	mov	rax,	rdi

	; pobierz wskaźnik do właściwości procesu
	call	kernel_task_active

	; proces wykonujący jest usługą?
	test	qword [rdi + KERNEL_TASK_STRUCTURE.flags],	KERNEL_TASK_FLAG_service
	jnz	.end	; zignoruj wywołanie

	; tablice stronicowania domyślne dla procesu
	mov	bx,	KERNEL_PAGE_FLAG_user | KERNEL_PAGE_FLAG_write | KERNEL_PAGE_FLAG_available

	; strony fizyczne oznacz jako virtualne, gdyż są tylko "kopią" udostępnioną dla procesu
	or	si,	bx
	or	si,	KERNEL_PAGE_FLAG_virtual

	; przygotuj podstawową ścieżkę z tablic do mapowanego adresu
	mov	r11,	qword [rdi + KERNEL_TASK_STRUCTURE.cr3]
	call	kernel_page_prepare
	jc	.error

.record:
	; sprawdź czy skończyły się rekordy w tablicy PML1
	cmp	r12,	KERNEL_PAGE_RECORDS_amount
	jb	.exists	; istnieją rekordy

	; utwórz nową tablicę stronicowania PML1
	call	kernel_page_pml1
	jc	.error

.exists:
	; rekord wolny?
	cmp	qword [r8],	STATIC_EMPTY
	jne	.error	; przestrzeń jest już zajęta!

	; podłącz stronę przestrzeni jądra systemu do procesu
	mov	qword [r8],	rsi

	; następna strona przestrzeni jądra systemu
	add	rsi,	STATIC_PAGE_SIZE_byte
	add	r8,	STATIC_QWORD_SIZE_byte	; następny wpis w tablicy

	; ustaw numer następnego rekordu w tablicy pml1
	inc	r12

	; kontynuuj
	dec	rcx
	jnz	.record

	; koniec procedury
	jmp	.end

.error:
	; flaga, błąd
	stc

.end:
	; przywróć oryginalne rejestry
	pop	r15
	pop	r14
	pop	r13
	pop	r12
	pop	r11
	pop	r10
	pop	r9
	pop	r8
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"kernel_page_map_virtual"

;===============================================================================
; wejście:
;	rax - adres przestrzeni fizycznej do opisania w tablicach stronicowania
;	bx - flagi rekordów tablic stronicowania
;	r11 - adres fizyczny tablicy PML4, w której wykonać stronicowanie
; wyjście:
;	Flaga CF, jeśli brak wystarczającej ilości stron
;	rdi - wskaźnik do rekordu w tablicy PML1, początku opisywanego obszaru fizycznego
;
;	r8 - wskaźnik następnego rekordu w tablicy PML1
;	r9 - wskaźnik następnego rekordu w tablicy PML2
;	r10 - wskaźnik następnego rekordu w tablicy PML3
;	r11 - wskaźnik następnego rekordu w tablicy PML4
;	r12 - numer następnego rekordu w tablicy PML1
;	r13 - numer następnego rekordu w tablicy PML2
;	r14 - numer następnego rekordu w tablicy PML3
;	r15 - numer następnego rekordu w tablicy PML4
kernel_page_prepare:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rdx
	push	rax

	; oblicz numer rekordu w tablicy PML4 na podstawie otrzymanego adresu fizycznego/logicznego
	mov	rcx,	KERNEL_PAGE_PML3_SIZE_byte
	xor	rdx,	rdx	; wyczyść starszą część
	div	rcx

	; zapamiętaj numer rekordu tablicy PML4
	mov	r15,	rax

	; przesuń wskaźnik w tablicy PML4 na rekord
	shl	rax,	STATIC_MULTIPLE_BY_8_shift	; zamień na Bajty
	add	r11,	rax

	; rekord PML4 zawiera adres tablicy PML3?
	cmp	qword [r11],	STATIC_EMPTY
	je	.no_pml3

	; pobierz adres tablicy PML3 z rekordu tablicy PML4
	mov	rax,	qword [r11]
	xor	al,	al	; usuń właściwości rekordu

	; zapisz adres tablicy PML3
	mov	r10,	rax

	; kontynuuj
	jmp	.pml3

.no_pml3:
	; pobierz zarezerwowaną stronę na potrzebę utworzenia nowej tablicy
	call	kernel_memory_alloc_page
	jc	.error

	; wyczyść
	call	kernel_page_drain

	; zapisz adres tablicy PML3
	mov	r10,	rdi

	; zapisz adres tablicy PML3 do rekordu tablicy PML4
	mov	qword [r11],	rdi
	or	word [r11],	bx	; ustaw właściwości rekordu tablicy PML4

	; strona wykorzystana do tablic stronicowania
	inc	qword [kernel_page_paged_count]

.pml3:
	; ustaw numer i wskaźnik rekordu w tablicy PML4 na następny
	inc	r15
	add	r11,	STATIC_QWORD_SIZE_byte

	; oblicz numer rekordu w tablicy PML4 na podstawie otrzymanego adresu fizycznego/logicznego
	mov	rax,	rdx	; przywróć resztę z dzielenia
	mov	rcx,	KERNEL_PAGE_PML2_SIZE_byte
	xor	rdx,	rdx	; wyczyść starszą część
	div	rcx

	; zapamiętaj numer rekordu
	mov	r14,	rax

	; przesuń wskaźnik w tablicy PML3 na rekord
	shl	rax,	STATIC_MULTIPLE_BY_8_shift	; zamień na Bajty
	add	r10,	rax

	; rekord PML3 zawiera adres tablicy PML2?
	cmp	qword [r10],	STATIC_EMPTY
	je	.no_pml2

	; pobierz adres tablicy PML2 z rekordu tablicy PML3
	mov	rax,	qword [r10]
	xor	al,	al	; usuń właściwości rekordu

	; zapisz adres tablicy PML2
	mov	r9,	rax

	; kontynuuj
	jmp	.pml2

.no_pml2:
	; pobierz zarezerwowaną stronę na potrzebę utworzenia nowej tablicy
	call	kernel_memory_alloc_page
	jc	.error

	; wyczyść
	call	kernel_page_drain

	; zapisz adres tablicy PML2
	mov	r9,	rdi

	; zapisz adres tablicy PML2 do rekordu tablicy PML3
	mov	qword [r10],	rdi
	or	word [r10],	bx	; ustaw właściwości rekordu tablicy PML3

	; strona wykorzystana do tablic stronicowania
	inc	qword [kernel_page_paged_count]

.pml2:
	; ustaw numer i wskaźnik rekordu w tablicy PML3 na następny
	inc	r14
	add	r10,	STATIC_QWORD_SIZE_byte

	; oblicz numer rekordu w tablicy PML2 na podstawie otrzymanego adresu fizycznego/logicznego
	mov	rax,	rdx	; przywróć resztę z dzielenia
	mov	rcx,	KERNEL_PAGE_PML1_SIZE_byte
	xor	rdx,	rdx	; wyczyść starszą część
	div	rcx

	; zapamiętaj numer rekordu
	mov	r13,	rax

	; przesuń wskaźnik w tablicy PML2 na rekord
	shl	rax,	STATIC_MULTIPLE_BY_8_shift	; zamień na Bajty
	add	r9,	rax

	; rekord PML2 zawiera adres tablicy PML1?
	cmp	qword [r9],	STATIC_EMPTY
	je	.no_pml1

	; pobierz adres tablicy PML1 z rekordu tablicy PML2
	mov	rax,	qword [r9]
	xor	al,	al	; usuń właściwości rekordu

	; zapisz adres tablicy PML1
	mov	r8,	rax

	; kontynuuj
	jmp	.pml1

.no_pml1:
	; pobierz zarezerwowaną stronę na potrzebę utworzenia nowej tablicy
	call	kernel_memory_alloc_page
	jc	.error

	; wyczyść
	call	kernel_page_drain

	; zapisz adres tablicy PML1
	mov	r8,	rdi

	; zapisz adres tablicy PML1 do rekordu tablicy PML2
	mov	qword [r9],	rdi
	or	word [r9],	bx	; ustaw właściwości rekordu tablicy PML2

	; strona wykorzystana do tablic stronicowania
	inc	qword [kernel_page_paged_count]

.pml1:
	; ustaw numer i wskaźnik rekordu w tablicy PML3 na następny
	inc	r13
	add	r9,	STATIC_QWORD_SIZE_byte

	; oblicz numer rekordu w tablicy PML1 na podstawie otrzymanego adresu fizycznego/logicznego
	mov	rax,	rdx	; przywróć resztę z dzielenia
	mov	rcx,	STATIC_PAGE_SIZE_byte
	xor	rdx,	rdx	; wyczyść starszą część
	div	rcx

	; zapamiętaj numer rekordu
	mov	r12,	rax

	; przesuń wskaźnik w tablicy PML2 na rekord
	shl	rax,	STATIC_MULTIPLE_BY_8_shift	; zamień na Bajty
	add	r8,	rax

	; zwróć wskaźnik do rekordu tablicy PML1
	mov	rdi,	r8

	; koniec procedury
	jmp	.end

.error:
	; zwróć kod błędu
	mov	qword [rsp],	rax

.end:
	; przywróć oryginalne rejestry
	pop	rax
	pop	rdx
	pop	rcx

	; powrót z procedury
	ret

	macro_debug	"kernel_page_prepare"

;===============================================================================
; opcjonalnie:
;	rbp - ilość stron zarezerwowanych (jeśli procedura ma z nich korzystać)
; wejście:
;	r8 - wskaźnik aktualnego wiersza w tablicy PML1
;	r9 - wskaźnik aktualnego wiersza w tablicy PML2
;	r10 - wskaźnik aktualnego wiersza w tablicy PML3
;	r11 - wskaźnik aktualnego wiersza w tablicy PML4
;	r12 - numer aktualnego wiersza w tablicy PML1
;	r13 - numer aktualnego wiersza w tablicy PML2
;	r14 - numer aktualnego wiersza w tablicy PML3
;	r15 - numer aktualnego wiersza w tablicy PML4
; wyjście:
;	Flaga CF, jeśli błąd
;	rax - kod błędu, jeśli Flaga CF jest podniesiona
;	rdi - wskaźnik do wiersza w tablicy PML1, początku opisywanego obszaru fizycznego
;
;	r8 - wskaźnik następnego wiersza w tablicy PML1
;	r9 - wskaźnik następnego wiersza w tablicy PML2
;	r10 - wskaźnik następnego wiersza w tablicy PML3
;	r11 - wskaźnik następnego wiersza w tablicy PML4
;	r12 - numer następnego wiersza w tablicy PML1
;	r13 - numer następnego wiersza w tablicy PML2
;	r14 - numer następnego wiersza w tablicy PML3
;	r15 - numer następnego wiersza w tablicy PML4
; uwagi:
;	procedura zmniejsza licznik stron zarezerwowanych w binarnej mapie pamięci!
kernel_page_pml1:
	; sprawdź czy tablica PML2 jest pełna
	cmp	r13,	KERNEL_PAGE_RECORDS_amount
	je	.pml3	; jeśli tak, utwórz nową tablicę PML2

	; sprawdź czy kolejny w kolejce rekord tablicy PML2 posiada adres tablicy PML1
	cmp	qword [r9],	STATIC_EMPTY
	je	.pml2_create	; nie

	; pobierz adres tablicy PML1 z rekordu tablicy PML2
	mov	rdi,	qword [r9]

	; koniec
	jmp	.pml2_continue

.pml2_create:
	; przygotuj miejsce na tablicę PML1
	call	kernel_memory_alloc_page
	jc	.error

	; wyczyść
	call	kernel_page_drain

	; ustaw właściwości rekordu w tablicy PML2
	or	di,	bx

	; podepnij tablice PML1 pod rekord tablicy PML2[r13]
	mov	qword [r9],	rdi

	; strona wykorzystana do tablic stronicowania
	inc	qword [kernel_page_paged_count]

.pml2_continue:
	; usuń właściwości rekordu tablicy PML2
	and	di,	STATIC_PAGE_mask

	; zwróć adres pierwszego rekordu w tablicy PML1
	mov	r8,	rdi

	; zresetuj numer przetwarzanego rekordu w tablicy PML1
	xor	r12,	r12

	; ustaw adres następnego rekordu w tablicy PML2
	add	r9,	STATIC_QWORD_SIZE_byte
	inc	r13	; ustaw numer następnego rekordu w tablicy PML2

	; powrót z procedury
	ret

.pml3:
	; sprawdź czy tablica PML3 jest pełna
	cmp	r14,	KERNEL_PAGE_RECORDS_amount
	je	.pml4	; jeśli tak, utwórz nową tablicę PML3

	; sprawdź czy kolejny w kolejce rekord tablicy PML3 posiada adres tablicy PML2
	cmp	qword [r10],	STATIC_EMPTY
	je	.pml3_create	; nie

	; pobierz adres tablicy PML2 z rekordu tablicy PML3
	mov	rdi,	qword [r10]

	; koniec
	jmp	.pml3_continue

.pml3_create:
	; przygotuj miejsce na tablicę PML2
	call	kernel_memory_alloc_page
	jc	.error

	; wyczyść
	call	kernel_page_drain

	; ustaw właściwości rekordu w tablicy PML3
	or	di,	bx

	; podepnij tablice PML2 pod rekord tablicy PML3[r14]
	mov	qword [r10],	rdi

	; strona wykorzystana do tablic stronicowania
	inc	qword [kernel_page_paged_count]

.pml3_continue:
	; usuń właściwości rekordu tablicy PML3
	and	di,	STATIC_PAGE_mask

	; zwróć adres pierwszego rekordu w tablicy PML2
	mov	r9,	rdi

	; zresetuj numer przetwarzanego rekordu w tablicy PML2
	xor	r13,	r13

	; ustaw adres następnego rekordu w tablicy PML3
	add	r10,	STATIC_QWORD_SIZE_byte
	inc	r14	; ustaw numer następnego rekordu w tablicy PML3

	; powrót do procedury głównej
	jmp	kernel_page_pml1

.pml4:
	; sprawdź czy tablica PML4 jest pełna
	cmp	r15,	KERNEL_PAGE_RECORDS_amount
	je	.error	; jeśli tak, utwórz nową tablicę PML5..., że jak?!

	; sprawdź czy kolejny w kolejce rekord tablicy PML4 posiada adres tablicy PML3
	cmp	qword [r11],	STATIC_EMPTY
	je	.pml4_create	; nie

	; pobierz adres tablicy PML3 z rekordu tablicy PML4
	mov	rdi,	qword [r11]

	; koniec
	jmp	.pml4_continue

.pml4_create:
	; przygotuj miejsce na tablicę PML3
	call	kernel_memory_alloc_page
	jc	.error

	; wyczyść
	call	kernel_page_drain

	; ustaw właściwości rekordu w tablicy PML4
	or	di,	bx

	; podepnij tablice PML3 pod rekord tablicy PML4[r15]
	mov	qword [r11],	rdi

	; strona wykorzystana do tablic stronicowania
	inc	qword [kernel_page_paged_count]

.pml4_continue:
	; usuń właściwości rekordu tablicy PML4
	and	di,	STATIC_PAGE_mask

	; zwróć adres pierwszego rekordu w tablicy PML3
	mov	r10,	rdi

	; zresetuj numer przetwarzanego rekordu w tablicy PML3
	xor	r14,	r14

	; ustaw adres następnego rekordu w tablicy PML4
	add	r11,	STATIC_QWORD_SIZE_byte
	inc	r15	; ustaw numer następnego rekordu w tablicy PML4

	; powrót do podprocedury
	jmp	.pml3

.error:
	; flaga, błąd
	stc

	; powrót z procedury
	ret

	macro_debug	"kernel_page_pml1"

;===============================================================================
; wejście:
;	rsi - adres źródłowy tablicy PML4
;	rdi - adres docelowy tablicy PML4
; uwagi:
;	procedura łączy dwie tablice PML4 (z uwzględenieniem "podtablic")
;	zachowując oryginalne rekordy tablicy docelowej!
kernel_page_merge:
	; zachowaj oryginalne rejestry
	push	rbx

	; aktualny poziom tablicy PML
	mov	rbx,	4

.inner:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rsi
	push	rdi

	; czy tablica jest kopią oryginału?
	cmp	rdi,	rsi
	je	.copy	; tak, nie wykonuj syzyfowej pracy

	; zmniejsz poziom przetwarzanej tablicy
	dec	rbx

	; ilość rekordów na jedną tablicę
	mov	rcx,	KERNEL_PAGE_RECORDS_amount

.loop:
	; sprawdź czy rekord źródłowy istnieje
	cmp	qword [rsi],	STATIC_EMPTY
	je	.next	; brak

	; sprawdź czy rekord docelowy zajęty
	cmp	qword [rdi],	STATIC_EMPTY
	jne	.level	; zajęty

	; pobierz wpis z tablicy źródłowej
	mov	rax,	qword [rsi]

; 	; znajdujemy się w tablicy PML1?
; 	test	bl,	bl
; 	jz	.page	; tak
;
; 	; zachowaj wskaźnik do aktualnego rekordu tablicy PML procesu
; 	push	rdi
;
; 	; przygotuj przestrzeń pod tablicę stronicowania
; 	call	kernel_memory_alloc_page
; 	call	kernel_page_drain	; wyczyść wszystkie wpisy
;
; 	; ustaw flagi nowej tablicy
; 	mov	rax,	rdi
; 	or	ax,	KERNEL_PAGE_FLAG_user | KERNEL_PAGE_FLAG_write | KERNEL_PAGE_FLAG_available
;
; 	; dołącz do tablic stronicowania
; 	pop	rdi
;
; .page:
	; załaduj wpis do tablicy docelowej
	mov	qword [rdi],	rax

.level:
	; brak tablic innego poziomu
	test	bl,	bl
	jz	.next	; tak

	; zachowaj oryginalne rejestry
	push	rsi
	push	rdi

	; załaduj adres tablicy źródłowej i docelowej
	mov	rsi,	qword [rsi]
	mov	rdi,	qword [rdi]

	; tablica jest kopią oryginału?
	test	rsi,	rdi
	jz	.the_same	; tak

	; usuń właściwości rekordów
	and	si,	STATIC_PAGE_mask
	and	di,	STATIC_PAGE_mask

	; połącz zawartość tablic
	call	.inner

.the_same:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi

.next:
	; następny rekord tablicy
	add	rsi,	STATIC_QWORD_SIZE_byte
	add	rdi,	STATIC_QWORD_SIZE_byte

	; kontynuuj
	dec	rcx
	jnz	.loop

.copy:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rbx
	pop	rax

	; przetworzyliśmy poziom 4?
	cmp	rbx,	4
	jne	.return	; nie

	; przywróć oryginalne rejestry
	pop	rbx

.return:
	; powrót z procedury
	ret

	macro_debug	"kernel_page_merge"

;===============================================================================
; wejście:
;	rcx - ilość stron do zarezerwowania
; wyjście:
;	Flaga CF - jeśli brak wystarczającej ilości
;	rax - kod błędu, jeśli Flaga CF jest podniesiona
kernel_page_secure:
	; zachowaj oryginalne rejestry
	push	rax

	; zablokuj modyfikacje zmiennych przez inne procesy
	call	kernel_memory_lock

	; istnieją dostępne strony?
	mov	rax,	qword [kernel_page_free_count]
	sub	rax,	qword [kernel_page_reserved_count]
	jz	.error	; nie

	; pozostało wystarczająco?
	cmp	rax,	rcx
	jb	.error	; nie

	; zarezerwuj
	sub	qword [kernel_page_free_count],	rcx
	add	qword [kernel_page_reserved_count],	rcx

	; flaga, sukces
	clc

	; koniec
	jmp	.end

.error:
	; zwróć kod błędu
	mov	qword [rsp],	KERNEL_ERROR_memory_low

	; flaga, błąd
	stc

.end:
	; odblokuj
	mov	byte [kernel_memory_lock_semaphore],	STATIC_FALSE

	; przywróć oryginalne rejestry
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"kernel_page_secure"
