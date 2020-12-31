;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================+
; wejście:
;	rsi - wskaźnik do obiektu
; wyjście:
;	Flaga CF - jeśli brak miejsca
;	rsi - wskaźnik do rekordu w tablicy obiektów
kernel_wm_object_insert:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdi
	push	rsi

	; lista posiada wolne elementy?
	cmp	qword [kernel_wm_object_list_length],	KERNEL_WM_OBJECT_LIST_limit
	je	.error	; brak miejsca

	; znajdź wolny rekord w tablicy
	call	kernel_wm_object_table_entry
	jc	.error	 ; brak miejsca

	; zachowaj wskaźnik początku rekordu w tablicy
	push	rdi

	; załaduj obiekt
	mov	rcx,	(KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.SIZE) >> STATIC_DIVIDE_BY_QWORD_shift
	rep	movsq

	; pobierz wskaźnik początku rekordu w tablicy
	mov	rdi,	qword [rsp]

	; pobierz PID procesu (właściciel okna)
	call	kernel_task_active_pid
	mov	qword [rdi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.pid],	rax

	;-----------------------------------------------------------------------

	; zablokuj dostęp do modyfikacji listy obiektów
	macro_lock	kernel_wm_object_semaphore,	0

	; ilość elementów listy obiektów
	mov	rcx,	qword [kernel_wm_object_list_length]

	; ustaw wskaźnik na początek listy obiektów
	mov	rsi,	qword [kernel_wm_object_list_address]

.loop:
	; pobierz wskaźnik obiektu przechowywany w elemencie listy obiektów
	lodsq

	; element pusty?
	test	rax,	rax
	jz	.found	; tak

	; pozostało N elementów do sprawdzenia
	dec	rcx

	; wstaw zarejestrowany obiekt przed arbitrem (jeśli istnieje)

	; obiekt jest arbitrem?
	test	word [rax + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_arbiter
	jz	.loop	; nie, szukaj dalej

	; wbrak elementów do przesunięcia?
	test	rcx,	rcx
	jz	.moved	; tak

	; przesuń wszystkie kolejne elementy listy obiektów o pozycję dalej
	shl	rcx,	KERNEL_WM_OBJECT_LIST_ENTRY_SIZE_shift

	; ustaw wskaźnik na ostani i następny element
	add	rsi,	rcx

	; koryguj pozycję wskaźników
	mov	rdi,	rsi
	sub	rsi,	KERNEL_WM_STRUCTURE_OBJECT_LIST_ENTRY.SIZE

	; zachowaj oryginalne flagi procesora
	pushf

	; zamień wskaźnik pośredni na licznik
	shr	rcx,	KERNEL_WM_OBJECT_LIST_ENTRY_SIZE_shift
	inc	rcx	; przesuń wraz z arbitrem

	; przesuń elementy
	std	; wstecz
	rep	movsq

	; przywróć oryginalne flagi procesora
	popf

	; koryguj wskaźnik po operacji
	add	rsi,	KERNEL_WM_STRUCTURE_OBJECT_LIST_ENTRY.SIZE

.moved:
	; koryguj wskaźnik względem arbitra
	add	rsi,	KERNEL_WM_STRUCTURE_OBJECT_LIST_ENTRY.SIZE

.found:
	; przywróć wskaźnik pozycji rekordu w tablicy obiektów
	pop	rax

	; zachowaj wskaźnik w elemencie listy obiektów
	mov	qword [rsi - KERNEL_WM_STRUCTURE_OBJECT_LIST_ENTRY.SIZE],	rax

	; zwróć wskaźnik zarejestrowanego obiektu
	mov	qword [rsp],	rax

	; zarejestowano obiekt na liście
	inc	qword [kernel_wm_object_list_length]

	; zwolnij dostęp do modyfikacji listy obiektów
	mov	byte [kernel_wm_object_semaphore],	STATIC_FALSE

	; koniec procedury
	jmp	.end

.error:
	; flaga, błąd
	stc

.end:
	; przywróć oryginalne rejestry
	pop	rsi
	pop	rdi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"kernel_wm_object_insert"

;===============================================================================
; wyjście:
;	Flaga CF - jeśli brak wolnych rekordów
;	rdi - wskaźnik do wolnego rekordu tablicy
kernel_wm_object_table_entry:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rsi
	push	rdi

	; ustaw wskaźnik na początek tablicy obiektów
	mov	rsi,	qword [kernel_wm_object_table_address]

.block:
	; ilość obiektów na blok danych tablicy obiektów
	mov	rcx,	STATIC_STRUCTURE_BLOCK.link / (KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.SIZE)

.loop:
	; rekord wolny?
	cmp	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.address],	STATIC_EMPTY
	je	.found	; tak

	; koniec rekordów w bloku danych tablicy obiektów?
	dec	rcx
	jz	.loop	; nie

	; przesuń wskaźnik na następny rekord
	add	rsi,	KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.SIZE

	; szukaj dalej
	jmp	.loop

.next:
	; koniec dostępnych bloków danych tablicy obiektów?
	and	si,	STATIC_PAGE_mask
	cmp	qword [rsi + STATIC_STRUCTURE_BLOCK.link],	STATIC_EMPTY
	je	.resize	; tak

.continue:
	; załaduj następny blok danych tablicy obiektów
	mov	rsi,	qword [STATIC_STRUCTURE_BLOCK.link]

	; kontynuuj przetwarzanie
	jmp	.block

.resize:
	; przygotuj nowy blok danych dla tablicy obiektów
	call	kernel_memory_alloc_page
	jc	.error	; brak miejsca

	; podłącz blok danych na koniec tablicy obiektów
	mov	qword [rsi + STATIC_STRUCTURE_BLOCK.link],	rdi

	; załaduj nowy blok danych tablicy obiektów
	jmp	.continue

.found:
	; zwróć wskaźnik wolnego rekordu tablicy obiektów
	mov	qword [rsp],	rsi

	; koniec procedury
	jmp	.end

.error:
	; flaga, błąd
	stc

.end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rcx

	; powrót z procedury
	ret

	macro_debug	"kernel_wm_object_table_entry"

;===============================================================================
kernel_wm_object:
	; zachowaj oryginalne rejestry
	push	rax
	push	rsi

	; ustaw wskaźnik na początek listy obiektów
	mov	rsi,	qword [kernel_wm_object_list_address]

.loop:
	; pobierz wskaźnik obiektu z listy
	lodsq

	; koniec wpisów?
	test	rax,	rax
	jz	.end	; tak

	; przerysować zawartość pod obiektem?
	test	word [rax + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_undraw
	jnz	.undraw	; tak

	; obiekt widoczny?
	test	word [rax + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_visible
	jz	.loop	; nie

	; obiekt aktualizował swoją zawartość?
	test	word [rax + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_flush
	jz	.loop	; nie

.undraw:
	; przetwórz strefę
	; rax - wskaźnik do obiektu
	call	kernel_wm_zone_insert_by_object

	; wyłącz flagę aktualizacji obiektu lub przerysowania zawartości pod obiektem
	and	word [rax + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	~KERNEL_WM_OBJECT_FLAG_flush & ~KERNEL_WM_OBJECT_FLAG_undraw

	; wymuś aktualizacje obiektu kursora
	or	word [kernel_wm_object_cursor + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_flush

	; kontynuuj
	jmp	.loop

.end:
	; przywróć oryginalne rejestry
	pop	rsi
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"kernel_wm_object"

;===============================================================================
; wejście:
;	rcx - PID procesu
kernel_wm_object_drain:
	; zachowaj oryginalne rejestry
	push	rsi

.next:
	; zamknij wszystkie obiekty należące do procesu
	call	kernel_wm_object_by_pid
	jc	.end	; wszystkie zamknięte

	; usuń obiekt
	call	kernel_wm_object_delete

.end:
	; przywróć oryginalne rejestry
	pop	rsi

	; powrót z procedury
	ret

	macro_debug	"kernel_wm_object_drain"

;===============================================================================
; wejście:
;	rcx - PID procesu
; wyjście:
;	Flaga CF, jeśli nie znaleziono
;	rsi - wskaźnik do obiektu na liście
kernel_wm_object_by_pid:
	; zachowaj oryginalne rejestry
	push	rax
	push	rsi

	; na liście znajdują się obiekty?
	cmp	qword [kernel_wm_object_list_length],	STATIC_EMPTY
	je	.error	; nie

	; przeszukaj listę obiektów
	mov	rsi,	qword [kernel_wm_object_list_address]

.loop:
	; pobierz wskaźnik do rekordu tablicy obiektów
	lodsq

	; koniec elementów na liście obiektów?
	test	rax,	rax
	jz	.error	; tak

	; obiekt posiada poszukiwany PID procesu?
	cmp	qword [rax + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.pid],	rcx
	jne	.loop	; nie

.found:
	; zwróć wskaźnik do obiektu
	mov	qword [rsp],	rax

	; koniec obsługi procedury
	jmp	.end

.error:
	; Flaga, błąd
	stc

.end:
	; przywróć oryginalne rejestry
	pop	rsi
	pop	rax

	; powrót z procedury
	ret

	; informacja dla Bochs
	macro_debug	"kernel_wm_object_by_pid"

;===============================================================================
; wejście:
;	rbx - identyfikator okna
; wyjście:
;	Flaga CF, jeśli nie znaleziono
;	rsi - wskaźnik do obiektu na liście
kernel_wm_object_by_id:
	; zachowaj oryginalne rejestry
	push	rax
	push	rsi

	; na liście znajdują się obiekty?
	cmp	qword [kernel_wm_object_list_length],	STATIC_EMPTY
	je	.error	; nie

	; pobierz wskaźnik początku listy obiektów
	mov	rsi,	qword [kernel_wm_object_list_address]

.loop:
	; pobierz wskaźnik obiektu z listy
	lodsq

	; obiekt posiada poszukiwany identyfikator?
	cmp	qword [rax + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.id],	rbx
	je	.found	; tak

	; koniec elementów na liście obiektów?
	cmp	qword [rsi],	STATIC_EMPTY
	jnz	.loop	; nie

.error:
	; Flaga, błąd
	stc

	; koniec obsługi procedury
	jmp	.end

.found:
	; zwróć wskaźnik do obiektu
	mov	qword [rsp],	rax

.end:
	; przywróć oryginalne rejestry
	pop	rsi
	pop	rax

	; powrót z procedury
	ret

	; informacja dla Bochs
	macro_debug	"kernel_wm_object_by_id"


;===============================================================================
; wyjście:
;	rcx - nowy identyfikator
kernel_wm_object_id_get:
	; zablokuj dostęp do procedury
	macro_lock	kernel_wm_object_id_semaphore,	0

	; pobierz wolny identyfikator
	mov	rcx,	qword [kernel_wm_object_id]

	; przygotuj następny
	inc	qword [kernel_wm_object_id]

	; zwolnij dostęp do procedury
	mov	byte [kernel_wm_object_id_semaphore],	STATIC_FALSE

	; powrót z procedury
	ret

	macro_debug	"kernel_wm_object_id_get"

;===============================================================================
; wejście:
;	r8w - pozycja kursora na osi X
;	r9w - pozycja kursora na osi Y
; wyjście:
;	Flaga CF - jeśli nie znaleziono elementu z wskaźnikiem obiektu
;	rsi - wskaźnik do rekordu tablicy obiektów znajdującego się pod współrzędnymi kursora
kernel_wm_object_find:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rsi

	; na liście znajdują się elementy?
	cmp	qword [kernel_wm_object_list_length],	STATIC_EMPTY
	je	.error	; nie

	; ustaw wskaźnik na ostatni element listy obiektów
	mov	rsi,	qword [kernel_wm_object_list_length]
	shl	rsi,	KERNEL_WM_OBJECT_LIST_ENTRY_SIZE_shift
	; zamień na adres bezpośredni
	add	rsi,	qword [kernel_wm_object_list_address]

.loop:
	; ustaw wskaźnik na element do sprawdzenia
	sub	rsi,	KERNEL_WM_STRUCTURE_OBJECT_LIST_ENTRY.SIZE

	; koniec listy obiektów?
	cmp	rsi,	qword [kernel_wm_object_list_address]
	jb	.error	; tak

	; pobierz wskaźnik do obiektu z elementu listy
	mov	rax,	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT_LIST_ENTRY.object_address]

	; obiekt widoczny?
	test	word [rax + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_visible
	jz	.loop	; nie

	;-----------------------------------------------------------------------
	; wskaźnik w przestrzeni obiektu względem lewej krawędzi?
	cmp	r8,	qword [rax + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.x]
	jl	.loop	; nie

	; wskaźnik w przestrzeni obiektu względem górnej krawędzi?
	cmp	r9,	qword [rax + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.y]
	jl	.loop	; nie

	; wskaźnik w przestrzeni obiektu względem prawej krawędzi?
	mov	rcx,	qword [rax + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.x]
	add	rcx,	qword [rax + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.width]
	cmp	r8,	rcx
	jge	.loop	; nie

	; wskaźnik w przestrzeni obiektu względem dolnej krawędzi?
	mov	rcx,	qword [rax + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.y]
	add	rcx,	qword [rax + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.height]
	cmp	r9,	rcx
	jge	.loop	; nie
	;-----------------------------------------------------------------------

	; zwróć wskaźnik do obiektu
	mov	qword [rsp],	rax

	; flaga, sukces
	clc

	; koniec
	jmp	.end

.error:
	; flaga, błąd
	stc

.end:
	; przywróć oryginalne rejestry
	pop	rsi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"kernel_wm_object_find"

;===============================================================================
; wejście:
;	rsi - wskaźnik do rekordu z tablicy obiektów
kernel_wm_object_up:
	; zachowaj oryginalny rejestr
	push	rax
	push	rcx
	push	rdi
	push	rsi

	; zablokuj dostęp do modyfikacji listy obiektów
	macro_lock	kernel_wm_object_semaphore,	0

	; przesunięcie elementu na liście obiektów, nie jest równoznaczne z modyfikacją rekordu w tablicy obiektów
	push	qword [kernel_wm_object_list_modify_time]

	; odszukaj element opisujący rekord tablicy obiektów
	mov	rcx,	qword [kernel_wm_object_list_length]
	mov	rdi,	qword [kernel_wm_object_list_address]

.search:
	; znaleziono?
	cmp	rsi,	qword [rdi + KERNEL_WM_STRUCTURE_OBJECT_LIST_ENTRY.object_address]
	je	.found	; tak

	; przesuń wskaźnik na następny element listy obiektów
	add	rdi,	KERNEL_WM_STRUCTURE_OBJECT_LIST_ENTRY.SIZE

	; koniec elementów?
	dec	rcx
	jnz	.search	; nie

	; flaga, błąd krytyczny
	stc

	; koniec obsługi procedury
	jmp	.end

.found:
	; zachowaj wskaźnik obiektu rekordu tablicy
	push	rsi

	; przemieść pozostałe elementy listy obiektów na poprzednią pozycję
	mov	rsi,	rdi
	add	rsi,	KERNEL_WM_STRUCTURE_OBJECT_LIST_ENTRY.SIZE

.loop:
	; koniec elementów na liście obiektów?
	dec	rcx
	jz	.last	; tak

	; element wskazuje na obiekt arbitra?
	mov	rax,	qword [rsi]
	test	word [rax + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_arbiter
	jnz	.last	; tak

	; przesuń element na poprzednią pozycję
	movsq

	; koniec elementów listy obiektów?
	dec	rcx
	jnz	.loop	; nie

.last:
	; wstaw wskaźnik obiektu do elementu na ostatnią pozycję (lub przed arbitrem)
	pop	qword [rdi]

.end:
	; przywróć oryginalny czas ostatniej modyfikacji listy obiektów
	pop	qword [kernel_wm_object_list_modify_time]

	; zwolnij dostęp do modyfikacji listy obiektów
	mov	byte [kernel_wm_object_semaphore],	STATIC_FALSE

	; przywróć oryginalny rejestr
	pop	rsi
	pop	rdi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"kernel_wm_object_up"

;===============================================================================
; wejście:
;	rsi - wskaźnik do rekordu tablicy obiektów
kernel_wm_object_remove:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rsi
	push	rdi

	; zablokuj dostęp do modyfikacji listy obiektów
	macro_lock	kernel_wm_object_semaphore,	0

	; odszukaj wskaźnik w elemencie listy obiektów
	mov	rcx,	qword [kernel_wm_object_list_length]
	mov	rdi,	qword [kernel_wm_object_list_address]

.search:
	; znaleziono element?
	cmp	rsi,	qword [rdi + KERNEL_WM_STRUCTURE_OBJECT_LIST_ENTRY.object_address]
	je	.found	; tak

	; przesuń wskaźnik na nastepny element z listy obiektów
	add	rdi,	KERNEL_WM_STRUCTURE_OBJECT_LIST_ENTRY.SIZE

	; koniec listy elementów?
	dec	rcx
	jnz	.search	; nie

	; flaga, błąd
	stc

	; koniec obsługi procedury
	jmp	.end

.found:
	; ustaw wskaźnik źródłowy i docelowy
	mov	rsi,	rdi
	add	rsi,	KERNEL_WM_STRUCTURE_OBJECT_LIST_ENTRY.SIZE

	; przesuń wszystkie pozostałe elementy o pozycję wstecz
	rep	movsq

.end:
	; ilość rekordów na liście
	dec	qword [kernel_wm_object_list_length]

	; zachowaj czas ostatniej modyfikacji listy
	mov	rcx,	qword [driver_rtc_microtime]
	mov	qword [kernel_wm_object_list_modify_time],	rcx

	; zwolnij dostęp do modyfikacji listy obiektów
	mov	byte [kernel_wm_object_semaphore],	STATIC_FALSE

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rcx

	; powrót z procedury
	ret

	macro_debug	"kernel_wm_object_remove"

;===============================================================================
; wejście:
;	r14 - delta osi X
;	r15 - delta osi Y
kernel_wm_object_move:
	; zachowaj oryginalne rejestry
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

	; ustaw wskaźnik na wybrany obiekt
	mov	rsi,	qword [kernel_wm_object_selected_pointer]

	; pobierz wskaźnik domyślnego obiektu wypełniającego strefę
	mov	rdi,	qword [kernel_wm_object_table_address]

	; obiekt można przemieszczać?
	test	word [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_fixed_xy
	jnz	.end	; nie

	; pobierz właściwości obiektu
	mov	r8,	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.x]
	mov	r9,	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.y]
	mov	r10,	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.width]
	mov	r11,	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.height]

	; ustaw zmienne lokalne
	mov	r12,	r8
	mov	r13,	r10

	; brak przesunięcia na osi X?
	test	r14,	r14
	jz	.y	; tak

	; aktualizuj pozycję obiektu na osi X
	add	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.x],	r14

	; przesunięcie na osi X jest dodatnie?
	cmp	r14,	STATIC_EMPTY
	jl	.to_left	; nie

	; szerokość strefy
	mov	r10,	r14

	; zarejestruj
	call	kernel_wm_zone_insert_by_register

	; koryguj pozycję strefy na osi X
	add	r8,	r14

.to_left:
	; przesunięcie na osi X jest ujemne?
	cmp	r14,	STATIC_EMPTY
	jnl	.x_done	; nie

	; zamień przesunięcie na wartość bezwzględną
	neg	r14

	; pozycja i szerokość strefy
	add	r8,	r10
	sub	r8,	r14
	mov	r10,	r14

	; zarejestruj
	call	kernel_wm_zone_insert_by_register

	; koryguj pozycję strefy na osi X
	mov	r8,	r12

.x_done:
	; koryguj szerokość strefy
	mov	r10,	r13
	sub	r10,	r14

.y:
	; ustaw zmienne lokalne
	mov	r12,	r9
	mov	r13,	r11

	; brak przesunięcia na osi X?
	test	r15,	r15
	jz	.ready	; tak

	; aktualizuj pozycję obiektu na osi Y
	add	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.y],	r15

	; przesunięcie na osi Y jest dodatnie?
	cmp	r15,	STATIC_EMPTY
	jl	.to_up	; nie

	; wysokość strefy
	mov	r11,	r15

	; zarejestruj
	call	kernel_wm_zone_insert_by_register

	; koryguj pozycję strefy na osi Y
	add	r9,	r15

.to_up:
	; przesunięcie na osi Y jest ujemne?
	cmp	r15,	STATIC_EMPTY
	jnl	.y_done	; nie

	; zamień przesunięcie na wartość bezwzględną
	neg	r15

	; pozycja i wysokość strefy
	add	r9,	r11
	sub	r9,	r15
	mov	r11,	r15

	; zarejestruj
	call	kernel_wm_zone_insert_by_register

	; koryguj pozycję strefy na osi Y
	mov	r9,	r12

.y_done:
	; koryguj wysokość strefy
	mov	r11,	r13
	sub	r11,	r15

.ready:
	; wyświetl ponownie zawartość obiektu
	or	word [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_flush

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

	; powrót z procedury
	ret

	macro_debug	"kernel_wm_object_move"

;===============================================================================
kernel_wm_object_hide_fragile:
	; zachowaj oryginalne rejestry
	push	rax
	push	rsi

	; ustaw wskaźnik na początek listy obiektów
	mov	rsi,	qword [kernel_wm_object_list_address]

.loop:
	; pobierz z elementu wskaźnik do rekordu tablicy obiektów
	lodsq

	; koniec wpisów?
	test	rax,	rax
	jz	.end	; tak

	; obiekt VISIBLE?
	test	word [rax + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_visible
	jz	.loop	; nie

	; obiekt FRAGILE?
	test	word [rax + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_fragile
	jz	.loop	; nie

	; wyłącz flagę VISIBLE, ustaw flagę UNDRAW
	and	word [rax + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	~KERNEL_WM_OBJECT_FLAG_visible
	or	word [rax + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_undraw

	; kontynuuj
	jmp	.loop

.end:
	; przywróć oryginalne rejestry
	pop	rsi
	pop	rax

	; powrót z podprocedury
	ret

	macro_debug	"kernel_wm_object_hide_fragile"

;===============================================================================
; wyjście:
;	rcx - nowy identyfikator
kernel_wm_object_id_new:
	; zablokuj dostęp do procedury
	macro_lock	kernel_wm_object_id_semaphore,	0

	; pobierz wolny identyfikator
	mov	rcx,	qword [kernel_wm_object_id]

	; przygotuj następny
	inc	qword [kernel_wm_object_id]

	; zwolnij dostęp do procedury
	mov	byte [kernel_wm_object_id_semaphore],	STATIC_FALSE

	; powrót z procedury
	ret

	macro_debug	"kernel_wm_object_id_new"

;===============================================================================
; wejście:
;	rsi - wskaźnik do rekordu tablicy obiektów
kernel_wm_object_delete:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rdi

	; pobierz rozmiar przestrzeni obiektu i zamień na strony
	mov	rcx,	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.size]
	call	library_page_from_size

	; zwolnij przestrzeń obiektu
	mov	rdi,	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.address]
	call	kernel_memory_release

	; przerysuj przestrzeń pod obiektem
	mov	word [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	~KERNEL_WM_OBJECT_FLAG_visible | KERNEL_WM_OBJECT_FLAG_undraw

.wait:
	; przestrzeń pod obiektem została przerysowana?
	test	word [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_undraw
	jnz	.wait	; nie, czekaj

	; usuń obiekt z listy
	call	kernel_wm_object_remove

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx

	; powrót z procedury
	ret

	macro_debug	"kernel_wm_object_delete"
