;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

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

	; wykonaj dla pozostałych obiektów należących do procesu
	jmp	.next

.end:
	; przywróć oryginalne rejestry
	pop	rsi

	; powrót z procedury
	ret

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

	; pobierz wskaźnik początku listy obiektów
	mov	rsi,	qword [kernel_wm_object_list_address]

.loop:
	; pobierz wskaźnik obiektu z listy
	lodsq

	; koniec elementów na liście obiektów?
	test	rax,	rax
	jz	.error	; tak

	; obiekt posiada poszukiwany PID procesu?
	cmp	qword [rax + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.pid],	rcx
	je	.found	; tak

	; następny element listy obiektów
	jmp	.loop

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

;===============================================================================+
; wejście:
;	rsi - wskaźnik do obiektu
; wyjście:
;	rsi - wskaźnik do rekordu na liście
kernel_wm_object_insert:
	; zachowaj oryginalne rejestry
	push	rax
	push	rdx
	push	rdi
	push	rcx
	push	rsi

	; zablokuj dostęp do modyfikacji listy obiektów
	macro_lock	kernel_wm_object_semaphore,	0

	; brak miejsca?
	cmp	qword [kernel_wm_object_list_length],	(STATIC_PAGE_SIZE_BYTE / KERNEL_WM_STRUCTURE_OBJECT_LIST_ENTRY.SIZE) - 0x01
	je	.end	; tak

	; ustaw wskaźnik na listę obiektów
	mov	rdi,	qword [kernel_wm_object_list_address]

	; oblicz pozycję względną za ostatnim obiektem na liście
	mov	rax,	KERNEL_WM_STRUCTURE_OBJECT_LIST_ENTRY.SIZE
	mul	qword [kernel_wm_object_list_length]

	; koryguj pozycje wskaźnika
	add	rdi,	rax

	; zwróć bezpośredni wskaźnik na liście do wstawianego obiektu
	mov	qword [rsp],	rdi

	; rejestrowany obiekt będzie arbitrem?
	test	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_arbiter
	jz	.insert	; nie

	; nie pozwól na zarejestrowanie kolejnego arbitra
	cmp	byte [kernel_wm_object_arbiter_semaphore],	STATIC_FALSE
	jne	.insert	; istnieje już, zignoruj

	; zablokuj dostęp do arbitra
	mov	byte [kernel_wm_object_arbiter_semaphore],	STATIC_TRUE

.insert:
	; zachowaj wskaźniki do obiektów
	push	rsi
	push	rdi

	; załaduj na koniec listy
	mov	rcx,	(KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.SIZE) >> STATIC_DIVIDE_BY_QWORD_shift
	rep	movsq

	; ilość obiektów na liście
	inc	qword [kernel_wm_object_list_records]

	; przywróć wskaźniki do obiektów
	pop	rdi
	pop	rsi

	; pobierz PID procesu właściciela okna
	call	kernel_task_active_pid
	mov	qword [rdi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.pid],	rax

	; zachowaj czas ostatniej modyfikacji listy
	mov	rax,	qword [driver_rtc_microtime]
	mov	qword [kernel_wm_object_list_modify_time],	rax

.end:
	; zwolnij dostęp do modyfikacji listy obiektów
	mov	byte [kernel_wm_object_semaphore],	STATIC_FALSE

	; przywróć oryginalne rejestry
	pop	rsi
	pop	rcx
	pop	rdi
	pop	rdx
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"kernel_wm_object_insert"

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
	test	qword [rax + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_undraw
	jnz	.undraw	; tak

	; obiekt widoczny?
	test	qword [rax + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_visible
	jz	.loop	; nie

	; obiekt aktualizował swoją zawartość?
	test	qword [rax + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_flush
	jz	.loop	; nie

.undraw:
	; przetwórz strefę
	; rax - wskaźnik do obiektu
	call	kernel_wm_zone_insert_by_object

	; wyłącz flagę aktualizacji obiektu lub przerysowania zawartości pod obiektem
	and	qword [rax + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	~KERNEL_WM_OBJECT_FLAG_flush & ~KERNEL_WM_OBJECT_FLAG_undraw

	; wymuś aktualizacje obiektu kursora
	or	qword [kernel_wm_object_cursor + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_flush

	; kontynuuj
	jmp	.loop

.ready:
	; przetwórz strefy
	call	kernel_wm_zone

.end:
	; przywróć oryginalne rejestry
	pop	rsi
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"kernel_wm_object"

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
;	rsi - wskaźnik do obiektu znajdującego się pod współrzędnymi kursora
kernel_wm_object_find:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rsi

	; na liście znajdują się elementy?
	cmp	qword [kernel_wm_object_list_length],	STATIC_EMPTY
	jz	.error	; nie

	; ustaw wskaźnik za ostatni element listy obiektów
	mov	rax,	KERNEL_WM_STRUCTURE_OBJECT_LIST_ENTRY.SIZE	; rozmiar jednego elementu listy
	mov	rsi,	qword [kernel_wm_object_list_address]	; adres listy elementów
	mul	qword [kernel_wm_object_list_length]	; ilość elementów na liście
	add	rsi,	rax	; adres bezpośredni

	xchg	bx,bx

	; cofamy się na liście elementów
	std	; Direction Flag

	; pomiń pusty obiekt kończący listę
	lodsq

.loop:
	; koniec listy obiektów?
	cmp	rsi,	qword [kernel_wm_object_list_address]
	jb	.error	; tak

	; pobierz wskaźnik obiektu rozpatrywanego
	lodsq

	; obiekt widoczny?
	test	qword [rax + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_visible
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

	; wyłącz Direction Flag
	cld

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
;	rsi - wskaźnik do obiektu
; wyjście:
;	rsi - nowy wskaźnik do obiektu
kernel_wm_object_up:
	; zachowaj oryginalny rejestr
	push	rax
	push	rsi
	push	rdi

	; przesunięcie obiektu na liście, nie jest równoznaczne z jego modyfikacją
	push	qword [kernel_wm_object_list_modify_time]

	; zachowaj wskaźnik obiektu z listy
	push	qword [rsi]

	; przemieszczaj kolejne elementy listy obiektów na wcześniejszą pozycję
	mov	rdi,	rsi
	add	rsi,	KERNEL_WM_STRUCTURE_OBJECT_LIST_ENTRY.SIZE

.loop:
	; koniec elementów na liście obiektów?
	cmp	qword [rsi],	STATIC_EMPTY
	je	.last	; tak

	; pobierz wskaźnik obiektu z listy
	mov	rax,	qword [rsi]

	; obiekt jest arbitrem?
	test	qword [rax + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_arbiter
	jnz	.last	; tak

	; przesuń obiekt na poprzednią pozycję
	movsq

	; kontynuj
	jmp	.loop

.last:
	; wstaw obiekt na ostatnią pozycję (lub przed arbitrem)
	pop	qword [rdi]

	; przywróć oryginalny czas ostatniej modyfikacji listy obiektów
	pop	qword [kernel_wm_object_list_modify_time]

	; przywróć oryginalny rejestr
	pop	rdi
	pop	rsi
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"kernel_wm_object_up"

;===============================================================================
; wejście:
;	rsi - wskaźnik rekordu do usunięcia
kernel_wm_object_remove:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rsi
	push	rdi

	; zablokuj dostęp do modyfikacji listy obiektów
	macro_lock	kernel_wm_object_semaphore,	0

	; ustaw wskaźnik źródłowy i docelowy
	mov	rdi,	rsi
	add	rsi,	KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.SIZE

.loop:
	; kopiuj następny rekord w miejsce aktualnego
	mov	rcx,	KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.SIZE
	rep	movsb

	; pozostały inne rekordy do prdesunięcia?
	cmp	qword [rdi + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.width],	STATIC_EMPTY
	jne	.loop	; tak

	; ilość rekordów na liście
	dec	qword [kernel_wm_object_list_records]

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
	push	rbx
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

	; pobierz wskaźnik domyślnego obiektu wypełniającego strefę
	mov	rbx,	qword [kernel_wm_object_list_address]

	; ustaw wskaźnik na wybrany obiekt
	mov	rsi,	qword [kernel_wm_object_selected_pointer]

	; obiekt można przemieszczać?
	test	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_fixed_xy
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
	mov	rdi,	rbx
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
	mov	rdi,	rbx
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
	mov	rdi,	rbx
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
	mov	rdi,	rbx
	call	kernel_wm_zone_insert_by_register

	; koryguj pozycję strefy na osi Y
	mov	r9,	r12

.y_done:
	; koryguj wysokość strefy
	mov	r11,	r13
	sub	r11,	r15

.ready:
	; wyświetl ponownie zawartość obiektu
	or	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_flush

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
	pop	rbx

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
	; pobierz wskaźnik do obiektu
	lodsq

	; koniec wpisów?
	test	rax,	rax
	jz	.end	; tak

	; obiekt VISIBLE?
	test	qword [rax + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_visible
	jz	.loop	; nie

	; obiekt FRAGILE?
	test	qword [rax + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_fragile
	jz	.loop	; nie

	; wyłącz flagę VISIBLE, ustaw flagę UNDRAW
	and	qword [rax + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	~KERNEL_WM_OBJECT_FLAG_visible
	or	qword [rax + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_undraw

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

	macro_debug	"kernel_wm_object_id"

;===============================================================================
; wejście:
;	rsi - wskaźnik rekordu do usunięcia
kernel_wm_object_delete:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rdi

	; pobierz rozmiar przestrzeni obiektu i zamień na strony
	mov	rcx,	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.size]
	call	library_page_from_size

	; pobierz wskaźnik do przestrzeni obiektu
	mov	rdi,	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.address]

	; usuń obiekt z przestrzeni pamięci
	call	kernel_memory_release

	; przerysuj przestrzeń pod obiektem
	mov	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	~KERNEL_WM_OBJECT_FLAG_visible | KERNEL_WM_OBJECT_FLAG_undraw

.wait:
	; przestrzeń pod obiektem została przerysowana?
	test	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_undraw
	jnz	.wait	; nie, czekaj

	; usuń obiekt z listy
	call	kernel_wm_object_remove

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx

	; powrót z procedury
	ret

	macro_debug	"kernel_wm_object_delete"
