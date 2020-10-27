;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; wejście:
;	rax - PID procesu
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
;	rax - PID procesu
; wyjście:
;	Flaga CF, jeśli nie znaleziono
;	rsi - wskaźnik do obiektu na liście
kernel_wm_object_by_pid:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rsi

	; na liście znajdują się obiekty?
	cmp	qword [kernel_wm_object_list_records],	STATIC_EMPTY
	je	.error	; nie

	; ilość obiektów na liście
	mov	rcx,	qword [kernel_wm_object_list_records]

	; pobierz wskaźnik początku listy obiektów
	mov	rsi,	qword [kernel_wm_object_list_address]

.loop:
	; poszukiwany identyfikator?
	cmp	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.pid],	rax
	je	.found	; tak

	; przesuń wskaźnik na następny obiekt
	add	rsi,	KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.SIZE

	; koniec obiektów?
	dec	rcx
	jnz	.loop	; nie, szukaj dalej

.error:
	; Flaga, błąd
	stc

	; koniec obsługi procedury
	jmp	.end

.found:
	; zwróć wskaźnik do obiektu
	mov	qword [rsp],	rsi

.end:
	; przywróć oryginalne rejestry
	pop	rsi
	pop	rcx

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
	push	rcx
	push	rsi

	; na liście znajdują się obiekty?
	cmp	qword [kernel_wm_object_list_records],	STATIC_EMPTY
	je	.error	; nie

	; ilość obiektów na liście
	mov	rcx,	qword [kernel_wm_object_list_records]

	; pobierz wskaźnik początku listy obiektów
	mov	rsi,	qword [kernel_wm_object_list_address]

.loop:
	; poszukiwany identyfikator?
	cmp	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.id],	rbx
	je	.found	; tak

	; przesuń wskaźnik na następny obiekt
	add	rsi,	KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.SIZE

	; koniec obiektów?
	dec	rcx
	jnz	.loop	; nie, szukaj dalej

.error:
	; Flaga, błąd
	stc

	; koniec obsługi procedury
	jmp	.end

.found:
	; zwróć wskaźnik do obiektu
	mov	qword [rsp],	rsi

.end:
	; przywróć oryginalne rejestry
	pop	rsi
	pop	rcx

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
	cmp	qword [kernel_wm_object_list_records_free],	STATIC_EMPTY
	je	.end	; tak

	; ustaw wskaźnik na listę obiektów
	mov	rdi,	qword [kernel_wm_object_list_address]

	; oblicz pozycję względną za ostatnim obiektem na liście
	mov	rax,	KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.SIZE
	mul	qword [kernel_wm_object_list_records]

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
	push	rbx
	push	rsi

	; ilość obiektów na liście
	mov	rbx,	qword [kernel_wm_object_list_records]

	; ustaw wskaźnik na początek listy obiektów
	mov	rsi,	qword [kernel_wm_object_list_address]

.loop:
	; przerysować zawartość pod obiektem?
	test	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_undraw
	jnz	.redraw	; tak

	; obiekt widoczny?
	test	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_visible
	jz	.next	; nie

	; obiekt aktualizował swoją zawartość?
	test	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_flush
	jz	.next	; nie

.redraw:
	; przetwórz strefę
	call	kernel_wm_zone_insert_by_object

	; wyłącz flagę aktualizacji obiektu lub przerysowania zawartości pod obiektem
	and	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	~KERNEL_WM_OBJECT_FLAG_flush & ~KERNEL_WM_OBJECT_FLAG_undraw

	; wymuś aktualizacje obiektu kursora
	or	qword [kernel_wm_object_cursor + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_flush

.next:
	; przesuń wskaźnik na następny obiekt
	add	rsi,	KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.SIZE

	; pozostały obiekty do sprawdzenia?
	dec	rbx
	jnz	.loop	; tak

	; przetwórz strefy
	call	kernel_wm_zone

.end:
	; przywróć oryginalne rejestry
	pop	rsi
	pop	rbx

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
	push	rdx
	push	rsi

	; na liście znajdują się obiekty?
	cmp	qword [kernel_wm_object_list_records],	STATIC_EMPTY
	je	.error	; nie

	; ilość obiektów na liście
	mov	rcx,	qword [kernel_wm_object_list_records]

	; oblicz adres względny za ostatnim rekordem listy obiektów
	mov	rax,	KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.SIZE
	mul	rcx

	; ustaw wskaźnik na adres bezwzględny początku listy obiektów
	mov	rsi,	qword [kernel_wm_object_list_address]
	add	rsi,	rax	; przesuń wskaźnik na koniec

.next:
	; cofnij wskaźnik na poprzedni obiekt
	sub	rsi,	KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.SIZE

	; obiekt widoczny?
	test	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_visible
	jz	.fail	; nie

	;-----------------------------------------------------------------------
	; wskaźnik w przestrzeni obiektu względem lewej krawędzi?
	cmp	r8,	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.x]
	jl	.fail	; nie

	; wskaźnik w przestrzeni obiektu względem górnej krawędzi?
	cmp	r9,	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.y]
	jl	.fail	; nie

	; wskaźnik w przestrzeni obiektu względem prawej krawędzi?
	mov	rax,	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.x]
	add	rax,	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.width]
	cmp	r8,	rax
	jge	.fail	; nie

	; wskaźnik w przestrzeni obiektu względem dolnej krawędzi?
	mov	rax,	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.y]
	add	rax,	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.height]
	cmp	r9,	rax
	jge	.fail	; nie
	;-----------------------------------------------------------------------

	; zwróć wskaźnik do obiektu
	mov	qword [rsp],	rsi

	; flaga, sukces
	clc

	; koniec
	jmp	.end

.fail:
	; istnieją pozostałe obiekty do sprawdzenia?
	dec	rcx
	jnz	.next	; tak

.error:
	; flaga, błąd
	stc

.end:
	; przywróć oryginalne rejestry
	pop	rsi
	pop	rdx
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
	; przesunięcie obiektu na liście, nie jest równoznaczne z jego modyfikacją
	push	qword [kernel_wm_object_list_modify_time]

	; zachowaj wskaźnik do aktualnego obiektu
	push	rsi

	; dodaj kopię obiektu na listę
	call	kernel_wm_object_insert

	; koryguj PID właścieciela
	mov	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.pid],	rax

	; zwróć nowy wskaźnik do obiektu
	xchg	rsi,	qword [rsp]

	; usuń stary obiekt z listy
	call	kernel_wm_object_remove

	; zwróć wskaźni do nowego obiektu
	pop	rsi

	; koryguj pozycje
	sub	rsi,	KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.SIZE

	; przywróć oryginalny czas ostatniej modyfikacji listy obiektów
	pop	qword [kernel_wm_object_list_modify_time]

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
kernel_wm_object_hide:
	; zachowaj oryginalne rejestry
	push	rbx
	push	rcx
	push	rsi

	; ilość obiektów na liście
	mov	rcx,	qword [kernel_wm_object_list_records]

	; ustaw wskaźnik na początek listy obiektów
	mov	rsi,	qword [kernel_wm_object_list_address]

.loop:
	; obiekt widoczny?
	test	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_visible
	jz	.next	; nie

	; obiekt "kruchy"?
	test	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_fragile
	jz	.next	; nie

	; wyłącz flagę "widoczny"
	and	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	~KERNEL_WM_OBJECT_FLAG_visible

	; dodaj strefę do przetworzenia
	call	kernel_wm_zone_insert_by_object

.next:
	; przesuń wskaźnik na następny obiekt
	add	rsi,	KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.SIZE

	; pozostały obiekty do sprawdzenia?
	dec	rcx
	jnz	.loop	; tak

.end:
	; przywróć oryginalne rejestry
	pop	rsi
	pop	rcx
	pop	rbx

	; powrót z podprocedury
	ret

	macro_debug	"kernel_wm_object_hide"

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
