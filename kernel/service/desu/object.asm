;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

;===============================================================================
; wejście:
;	rbx - identyfikator okna
; wyjście:
;	Flaga CF, jeśli nie znaleziono
;	rdi - wskaźnik do obiektu na liście
service_desu_object_by_id:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rdi

	; na liście znajdują się obiekty?
	cmp	qword [service_desu_object_list_records],	STATIC_EMPTY
	je	.error	; nie

	; ilość obiektów na liście
	mov	rcx,	qword [service_desu_object_list_records]

	; pobierz wskaźnik początku listy obiektów
	mov	rdi,	qword [service_desu_object_list_address]

.loop:
	; poszukiwany identyfikator?
	cmp	qword [rdi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.id],	rbx
	je	.found	; tak

	; przesuń wskaźnik na następny obiekt
	add	rdi,	SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.SIZE

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
	mov	qword [rsp],	rdi

.end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx

	; powrót z procedury
	ret

	; informacja dla Bochs
	macro_debug	"service_desu_object_by_id"

;===============================================================================+
; wejście:
;	rsi - wskaźnik do obiektu
; wyjście:
;	rcx - identyfikator okna
;	rsi - wskaźnik do rekordu na liście
service_desu_object_insert:
	; zachowaj oryginalne rejestry
	push	rax
	push	rdx
	push	rdi
	push	rcx
	push	rsi

	; brak miejsca?
	cmp	qword [service_desu_object_list_records_free],	STATIC_EMPTY
	je	.end	; tak

	; ustaw wskaźnik na listę obiektów
	mov	rdi,	qword [service_desu_object_list_address]

	; oblicz pozycję względną za ostatnim obiektem na liście
	mov	rax,	SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.SIZE
	mul	qword [service_desu_object_list_records]

	; koryguj pozycje wskaźnika
	add	rdi,	rax

	; zwróć bezpośredni wskaźnik na liście do wstawianego obiektu
	mov	qword [rsp],	rdi

	; przygotuj dla obiektu nowy identyfikator
	call	service_desu_object_id_new
	mov	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.id],	rcx

	; zwróć informacje o identyfikatorze
	mov	qword [rsp + STATIC_QWORD_SIZE_byte],	rcx

	; rejestrowany obiekt będzie arbitrem?
	test	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags],	SERVICE_DESU_OBJECT_FLAG_arbiter
	jz	.insert	; nie

	; nie pozwól na zarejestrowanie kolejnego arbitra
	cmp	byte [service_desu_object_arbiter_semaphore],	STATIC_FALSE
	jne	.insert	; istnieje już, zignoruj

	; zablokuj dostęp do arbitra
	mov	byte [service_desu_object_arbiter_semaphore],	STATIC_TRUE

.insert:
	; zachowaj wskaźniki do obiektów
	push	rsi
	push	rdi

	; załaduj na koniec listy
	mov	rcx,	(SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.SIZE) >> STATIC_DIVIDE_BY_QWORD_shift
	rep	movsq

	; ilość obiektów na liście
	inc	qword [service_desu_object_list_records]

	; przywróć wskaźniki do obiektów
	pop	rdi
	pop	rsi

	; pobierz PID procesu właściciela okna
	call	kernel_task_active_pid
	mov	qword [rdi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.pid],	rax

.end:
	; przywróć oryginalne rejestry
	pop	rsi
	pop	rcx
	pop	rdi
	pop	rdx
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"service_desu_object_insert"

;===============================================================================
service_desu_object:
	; zachowaj oryginalne rejestry
	push	rbx
	push	rsi

	; ilość obiektów na liście
	mov	rbx,	qword [service_desu_object_list_records]

	; ustaw wskaźnik na początek listy obiektów
	mov	rsi,	qword [service_desu_object_list_address]

.loop:
	; obiekt widoczny?
	test	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags],	SERVICE_DESU_OBJECT_FLAG_visible
	jz	.next	; nie

	; obiekt aktualizował swoją zawartość?
	test	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags],	SERVICE_DESU_OBJECT_FLAG_flush
	jz	.next	; nie

	; przetwórz strefę
	call	service_desu_zone_insert_by_object

	; wyłącz flagę aktualizacji obiektu
	and	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags],	~SERVICE_DESU_OBJECT_FLAG_flush

	; wymuś aktualizacje obiektu kursora
	or	qword [service_desu_object_cursor + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags],	SERVICE_DESU_OBJECT_FLAG_flush

.next:
	; przesuń wskaźnik na następny obiekt
	add	rsi,	SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.SIZE

	; pozostały obiekty do sprawdzenia?
	dec	rbx
	jnz	.loop	; tak

	; przetwórz strefy
	call	service_desu_zone

.end:
	; przywróć oryginalne rejestry
	pop	rsi
	pop	rbx

	; powrót z procedury
	ret

	macro_debug	"service_desu_object"

;===============================================================================
; wyjście:
;	rcx - nowy identyfikator
service_desu_object_id_get:
	; zablokuj dostęp do procedury
	macro_lock	service_desu_object_id_semaphore,	0

	; pobierz wolny identyfikator
	mov	rcx,	qword [service_desu_object_id]

	; przygotuj następny
	inc	qword [service_desu_object_id]

	; zwolnij dostęp do procedury
	mov	byte [service_desu_object_id_semaphore],	STATIC_FALSE

	; powrót z procedury
	ret

	macro_debug	"service_desu_object_id_get"

;===============================================================================
; wejście:
;	r8w - pozycja kursora na osi X
;	r9w - pozycja kursora na osi Y
; wyjście:
;	rsi - wskaźnik do obiektu znajdującego się pod współrzędnymi kursora
service_desu_object_find:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdx
	push	rsi

	; na liście znajdują się obiekty?
	cmp	qword [service_desu_object_list_records],	STATIC_EMPTY
	je	.error	; nie

	; ilość obiektów na liście
	mov	rcx,	qword [service_desu_object_list_records]

	; oblicz adres względny za ostatnim rekordem listy obiektów
	mov	rax,	SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.SIZE
	mul	rcx

	; ustaw wskaźnik na adres bezwzględny początku listy obiektów
	mov	rsi,	qword [service_desu_object_list_address]
	add	rsi,	rax	; przesuń wskaźnik na koniec

.next:
	; cofnij wskaźnik na poprzedni obiekt
	sub	rsi,	SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.SIZE

	; obiekt widoczny?
	test	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags],	SERVICE_DESU_OBJECT_FLAG_visible
	jz	.fail	; nie

	;-----------------------------------------------------------------------
	; wskaźnik w przestrzeni obiektu względem lewej krawędzi?
	cmp	r8,	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.x]
	jl	.fail	; nie

	; wskaźnik w przestrzeni obiektu względem górnej krawędzi?
	cmp	r9,	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.y]
	jl	.fail	; nie

	; wskaźnik w przestrzeni obiektu względem prawej krawędzi?
	mov	rax,	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.x]
	add	rax,	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.width]
	cmp	r8,	rax
	jge	.fail	; nie

	; wskaźnik w przestrzeni obiektu względem dolnej krawędzi?
	mov	rax,	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.y]
	add	rax,	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.height]
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

	macro_debug	"service_desu_object_find"

;===============================================================================
; wejście:
;	rsi - wskaźnik do obiektu
; wyjście:
;	rsi - nowy wskaźnik do obiektu
service_desu_object_up:
	; zachowaj wskaźnik do aktualnego obiektu
	push	rsi

	; dodaj obiekt ponownie na listę
	call	service_desu_object_insert

	; zwróć nowy wskaźnik do obiektu
	xchg	rsi,	qword [rsp]

	; usuń stary obiekt z listy
	call	service_desu_object_remove

	; zwróć wskaźni do obiektu
	pop	rsi

	; koryguj pozycje
	sub	rsi,	SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.SIZE

	; powrót z procedury
	ret

	macro_debug	"service_desu_object_move_top"

;===============================================================================
; wejście:
;	rsi - wskaźnik rekordu do usunięcia
service_desu_object_remove:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rsi
	push	rdi

	; ustaw wskaźnik źródłowy i docelowy
	mov	rdi,	rsi
	add	rsi,	SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.SIZE

.loop:
	; kopiuj następny rekord w miejsce aktualnego
	mov	rcx,	SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.SIZE
	rep	movsb

	; pozostały inne rekordy do prdesunięcia?
	cmp	qword [rdi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.width],	STATIC_EMPTY
	jne	.loop	; tak

	; ilość rekordów na liście
	dec	qword [service_desu_object_list_records]

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rcx

	; powrót z procedury
	ret

	macro_debug	"service_desu_object_remove"

;===============================================================================
; wejście:
;	r14 - delta osi X
;	r15 - delta osi Y
service_desu_object_move:
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
	mov	rbx,	qword [service_desu_object_list_address]

	; ustaw wskaźnik na wybrany obiekt
	mov	rsi,	qword [service_desu_object_selected_pointer]

	; obiekt można przemieszczać?
	test	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags],	SERVICE_DESU_OBJECT_FLAG_fixed_xy
	jnz	.end	; nie

	; pobierz właściwości obiektu
	mov	r8,	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.x]
	mov	r9,	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.y]
	mov	r10,	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.width]
	mov	r11,	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.height]

	; ustaw zmienne lokalne
	mov	r12,	r8
	mov	r13,	r10

	; brak przesunięcia na osi X?
	test	r14,	r14
	jz	.y	; tak

	; aktualizuj pozycję obiektu na osi X
	add	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.x],	r14

	; przesunięcie na osi X jest dodatnie?
	cmp	r14,	STATIC_EMPTY
	jl	.to_left	; nie

	; szerokość strefy
	mov	r10,	r14
	; zarejestruj
	mov	rdi,	rbx
	call	service_desu_zone_insert_by_register

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
	call	service_desu_zone_insert_by_register

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
	add	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.y],	r15

	; przesunięcie na osi Y jest dodatnie?
	cmp	r15,	STATIC_EMPTY
	jl	.to_up	; nie

	; wysokość strefy
	mov	r11,	r15
	; zarejestruj
	mov	rdi,	rbx
	call	service_desu_zone_insert_by_register

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
	call	service_desu_zone_insert_by_register

	; koryguj pozycję strefy na osi Y
	mov	r9,	r12

.y_done:
	; koryguj wysokość strefy
	mov	r11,	r13
	sub	r11,	r15

.ready:
	; wyświetl ponownie zawartość obiektu
	or	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags],	SERVICE_DESU_OBJECT_FLAG_flush

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

	macro_debug	"service_desu_object_move"

;===============================================================================
service_desu_object_hide:
	; zachowaj oryginalne rejestry
	push	rbx
	push	rcx
	push	rsi

	; ilość obiektów na liście
	mov	rcx,	qword [service_desu_object_list_records]

	; ustaw wskaźnik na początek listy obiektów
	mov	rsi,	qword [service_desu_object_list_address]

.loop:
	; obiekt widoczny?
	test	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags],	SERVICE_DESU_OBJECT_FLAG_visible
	jz	.next	; nie

	; obiekt "kruchy"?
	test	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags],	SERVICE_DESU_OBJECT_FLAG_fragile
	jz	.next	; nie

	; wyłącz flagę "widoczny"
	and	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags],	~SERVICE_DESU_OBJECT_FLAG_visible

	; dodaj strefę do przetworzenia
	call	service_desu_zone_insert_by_object

.next:
	; przesuń wskaźnik na następny obiekt
	add	rsi,	SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.SIZE

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

	macro_debug	"service_desu_object_hide"

;===============================================================================
; wyjście:
;	rcx - nowy identyfikator
service_desu_object_id_new:
	; zablokuj dostęp do procedury
	macro_lock	service_desu_object_id_semaphore,	0

	; pobierz wolny identyfikator
	mov	rcx,	qword [service_desu_object_id]

	; przygotuj następny
	inc	qword [service_desu_object_id]

	; zwolnij dostęp do procedury
	mov	byte [service_desu_object_id_semaphore],	STATIC_FALSE

	; powrót z procedury
	ret

	macro_debug	"service_desu_object_id"

; ;===============================================================================
; service_desu_object_lock:
; 	; zablokuj dostęp do modyfikacji listy obiektów
; 	macro_lock	service_desu_object_semaphore, 0
;
; .wait:
; 	; czekaj, aż wszystkie procedury przestaną korzystać z listy obietków
; 	test	byte [service_desu_object_lock_level],	STATIC_EMPTY
; 	jnz	.wait
;
; 	; powrót z procedury
; 	ret
;
; 	; informacja dla Bochs
; 	macro_debug	"service desu object list lock"

; ;===============================================================================
; ; wejście:
; ;	rbx - identyfikator okna
; ; wyjście:
; ;	Flaga CF, jeśli nie znaleziono
; ;	rdi - wskaźnik do obiektu na liście
; service_desu_object_find_by_id:
; 	; zachowaj oryginalne rejestry
; 	push	rcx
; 	push	rdi
;
; 	; na liście znajdują się obiekty?
; 	cmp	qword [service_desu_object_list_records],	STATIC_EMPTY
; 	je	.error	; nie
;
; 	; ilość obiektów na liście
; 	mov	rcx,	qword [service_desu_object_list_records]
;
; 	; pobierz wskaźnik początku listy obiektów
; 	mov	rdi,	qword [service_desu_object_list_address]
;
; .loop:
; 	; poszukiwany identyfikator?
; 	cmp	qword [rdi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.id],	rbx
; 	je	.found	; tak
;
; 	; przesuń wskaźnik na następny obiekt
; 	add	rdi,	SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.SIZE
;
; 	; koniec obiektów?
; 	dec	rcx
; 	jnz	.loop	; nie, szukaj dalej
;
; .error:
; 	; Flaga, błąd
; 	stc
;
; 	; koniec obsługi procedury
; 	jmp	.end
;
; .found:
; 	; zwróć wskaźnik do obiektu
; 	mov	qword [rsp],	rdi
;
; .end:
; 	; przywróć oryginalne rejestry
; 	pop	rdi
; 	pop	rcx
;
; 	; powrót z procedury
; 	ret
;
; 	; informacja dla Bochs
; 	macro_debug	"service desu object find by id"
;
; ;~ ;===============================================================================
; ;~ ; wejście:
; ;~ ;	rsi - wskaźnik rekordu do usunięcia
; ;~ service_desu_object_delete:
; 	;~ ; zachowaj oryginalne rejestry
; 	;~ push	rcx
; 	;~ push	rdi
;
; 	;~ ; pobierz rozmiar przestrzeni obiektu i zamień na strony
; 	;~ mov	rcx,	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.size]
; 	;~ call	library_page_from_byte
;
; 	;~ ; pobierz wskaźnik do przestrzeni obiektu
; 	;~ mov	rdi,	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.address]
;
; 	;~ ; usuń obiekt z listy
; 	;~ call	service_desu_object_remove
;
; 	;~ ; usuń obiekt z przestrzeni pamięci
; 	;~ call	kernel_page_release_few
;
; 	;~ ; przywróć oryginalne rejestry
; 	;~ pop	rdi
; 	;~ pop	rcx
;
; 	;~ ; powrót z procedury
; 	;~ ret
;
; 	; informacja dla Bochs
; 	macro_debug	"service desu object delete"
