;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

;-------------------------------------------------------------------------------
; UWAGA: brak zachowanych rejestrów
service_desu_zone_subroutine:
	; zablokuj dostęp do modyfikacji listy stref
	macro_lock	service_desu_zone_semaphore,	0

	; wskaźnik pośredni na koniec listy stref
	mov	eax,	SERVICE_DESU_STRUCTURE_ZONE.SIZE
	mul	qword [service_desu_zone_list_records]	; pozycja za ostatnią strefą listy

	; wskaźnik bezpośredni końca listy stref
	mov	rsi,	qword [service_desu_zone_list_address]
	add	rsi,	rax

	; wolne miejsce na liście stref?
	cmp	qword [service_desu_zone_list_records],	SERVICE_DESU_ZONE_LIST_limit
	je	.insert	; tak

	; ilość stref na liście
	xor	eax,	eax

	; przesuń na początek listy wszystkie strefy
	mov	rsi,	qword [service_desu_zone_list_address]
	xchg	rsi,	rdi

	; zwróć do nadprocedury nowy wskaźnik aktualnej strefy
	mov	qword [rsp],	rdi

.next:
	; przesuń strefę na początek
	mov	ecx,	SERVICE_DESU_STRUCTURE_ZONE.SIZE << STATIC_DIVIDE_BY_QWORD_shift
	rep	movsq

	; ilość stref na liście
	inc	eax

	; ostatnia strefa na liście?
	cmp	qword [rsi + SERVICE_DESU_STRUCTURE_ZONE.object],	STATIC_EMPTY
	jne	.next	; tak

	; zachowaj ilość pozostałych stref na liście
	mov	qword [service_desu_zone_list_records],	rax

	; wstaw nową strefę na koniec
	mov	rsi,	rdi

.insert:
	; powrót z podprocedury
	ret

;===============================================================================
; wejście:
;	rsi - wskaźnik do obiektu
service_desu_zone_insert_by_object:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdx
	push	rsi
	push	rdi

	; zablokuj dostęp do modyfikacji listy stref
	macro_lock	service_desu_zone_semaphore,	0

	; wskaźnik pośredni na koniec listy stref
	mov	eax,	SERVICE_DESU_STRUCTURE_ZONE.SIZE
	mul	qword [service_desu_zone_list_records]	; pozycja za ostatnią strefą listy

	; wskaźnik bezpośredni końca listy stref
	mov	rdi,	qword [service_desu_zone_list_address]
	add	rdi,	rax

	; wstaw właściwości strefy
	mov	ecx,	SERVICE_DESU_STRUCTURE_ZONE.SIZE << STATIC_DIVIDE_BY_QWORD_shift
	rep	movsq

	; oraz informacje o obiekcie zależnym
	mov	rax,	qword [rsp]
	mov	qword [rdi],	rax

	; ilość stref na liście
	inc	qword [service_desu_zone_list_records]

	; odblokuj listę stref do modyfikacji
	mov	byte [service_desu_zone_semaphore],	STATIC_FALSE

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	rdi - wskaźnik do strefy
;	r8 - pozycja na osi X
;	r9 - pozycja na osi Y
;	r10 - szerokość strefy
;	r11 - wysokość strefy
; wyjście:
;	rdi - nowa pozycja, jeśli zoptymalizowano listę stref
service_desu_zone_insert_by_register:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdx
	push	rsi
	push	rdi

	; ustaw wskaźnik na wolną pozycję
	call	service_desu_zone_subroutine

	; dodaj do listy nową strefę
	mov	qword [rsi + SERVICE_DESU_STRUCTURE_ZONE.field + SERVICE_DESU_STRUCTURE_FIELD.x],	r8
	mov	qword [rsi + SERVICE_DESU_STRUCTURE_ZONE.field + SERVICE_DESU_STRUCTURE_FIELD.y],	r9
	mov	qword [rsi + SERVICE_DESU_STRUCTURE_ZONE.field + SERVICE_DESU_STRUCTURE_FIELD.width],	r10
	mov	qword [rsi + SERVICE_DESU_STRUCTURE_ZONE.field + SERVICE_DESU_STRUCTURE_FIELD.height],	r11

	; oraz jej obiekt zależny
	mov	rax,	qword [rdi + SERVICE_DESU_STRUCTURE_ZONE.object]
	mov	qword [rsi + SERVICE_DESU_STRUCTURE_ZONE.object],	rax

	; ilość stref na liście
	inc	qword [service_desu_zone_list_records]

	; odblokuj listę stref do modyfikacji
	mov	byte [service_desu_zone_semaphore],	STATIC_FALSE

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	bl -	STATIC_TRUE - aktualizuj tylko widoczne podstrefy
;		STATIC_FALSE - aktualizuj wszystkie strefy
service_desu_zone:
	; zablokuj dostęp do modyfikacji listy obiektów
	macro_lock	service_desu_object_semaphore,	0

.refill:
	; wypełnij pozostałą strefę zawartością obiektu pokrywającego
	mov	qword [rdi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.x],	r8
	mov	qword [rdi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.y],	r9
	sub	r10,	r8
	mov	qword [rdi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.width],	r10
	sub	r11,	r9
	mov	qword [rdi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.height],	r11
	mov	qword [rdi + SERVICE_DESU_STRUCTURE_OBJECT.address],	rsi
	xchg	rdi,	rsi	; ustaw wskaźnik źródłowy na strefę
	call	service_desu_fill_register	; zarejestruj

	; przywróć wskaźniki na miejsce
	xchg	rdi,	rsi

	; strefa przesłana do wypełnienia
	jmp	.next	; usuń

.fill:
	;-----------------------------------------------------------------------
	; zarejestruj wypełnienie
	mov	rsi,	rdi
	call	service_desu_fill_register

	; usuń zarejestrowaną stregę
	jmp	.next

.remove:
	; wypełnić porzuconą strefę?
	test	bl,	bl
	jnz	.refill	; tak

.next:
	; przesuń wskaźnik na następną strefę do przetworzenia
	add	rdi,	SERVICE_DESU_STRUCTURE_ZONE.SIZE

	; kontynuuj
	jmp	.loop

.restart:
	; ustaw wskaźnik na pierwszą opisaną strefę na liście
	mov	rdi,	qword [service_desu_zone_list_address]

.loop:
	; brak strefy do przetworzenia?
	cmp	qword [rdi + SERVICE_DESU_STRUCTURE_ZONE.object],	STATIC_EMPTY
	je	.end	; tak

	;-----------------------------------------------------------------------
	; pobierz właściwości strefy
	;-----------------------------------------------------------------------

	; lewa krawędź na oxi X
	mov	r8,	qword [rdi + SERVICE_DESU_STRUCTURE_ZONE.field + SERVICE_DESU_STRUCTURE_FIELD.x]
	; górna krawędź na osi Y
	mov	r9,	qword [rdi + SERVICE_DESU_STRUCTURE_ZONE.field + SERVICE_DESU_STRUCTURE_FIELD.y]
	; prawa krawędź na osi X
	mov	r10,	qword [rdi + SERVICE_DESU_STRUCTURE_ZONE.field + SERVICE_DESU_STRUCTURE_FIELD.width]
	add	r10,	r8
	; dolna krawędź na osi Y
	mov	r11,	qword [rdi + SERVICE_DESU_STRUCTURE_ZONE.field + SERVICE_DESU_STRUCTURE_FIELD.height]
	add	r11,	r9

	; opisana strefa znajduje się w przestrzeni "ekranu"?
	cmp	r8,	qword [kernel_video_width_pixel]
	jge	.next	; nie
	cmp	r9,	qword [kernel_video_height_pixel]
	jge	.next	; nie
	cmp	r10,	STATIC_EMPTY
	jle	.next	; nie
	cmp	r11,	STATIC_EMPTY
	jle	.next	; nie

	;-----------------------------------------------------------------------
	; interferencja
	;-----------------------------------------------------------------------

	; wskaźnik pośredni na koniec listy obiektów
	mov	eax,	SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.SIZE
	mul	qword [service_desu_object_list_records]	; pozycja za ostatnim obiektem listy

	; wskaźnik bezpośredni końca listy obiektów
	mov	rsi,	qword [service_desu_object_list_address]
	add	rsi,	rax

.object:
	; ustaw wskaźnik na rozpatrywany obiekt
	sub	rsi,	SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.SIZE

	; rozpatrywany obiekt jest pierwszy na liście?
	cmp	rsi,	qword [service_desu_object_list_address]
	je	.fill	; tak

	; obiekt widoczny?
	test	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags],	SERVICE_DESU_OBJECT_FLAG_visible
	jz	.object	; nie

	; wystąpiła interferencja z obiektem przetwarzanym? (samym sobą)
	cmp	rsi,	qword [rdi + SERVICE_DESU_STRUCTURE_ZONE.object]
	je	.fill	; tak

	; pobierz współrzędne obiektu

	; lewa krawędź na oxi X
	mov	r12,	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.x]
	; górna krawędź na osi Y
	mov	r13,	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.y]
	; prawa krawędź na osi X
	mov	r14,	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.width]
	add	r14,	r12
	; dolna krawędź na osi Y
	mov	r15,	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.height]
	add	r15,	r13

	;--------------------------------
	;      r9	       r13	X
	;    -------	     -------
	; r8 |  S  | r10 r12 |  O  | r14
	;    -------	     -------
	;      r11	       r15
	; Y

	; obiekt znajduje się poza przetwarzaną strefą?
	cmp	r12,	r10	; lewa krawędź obiektu za prawą krawędzią strefy?
	jge	.object	; tak
	cmp	r13,	r11	; górna krawędź obiektu za dolną krawędzią strefy?
	jge	.object	; tak
	cmp	r14,	r8	; prawa krawędź obiektu przed lewą krawędzią strefy?
	jle	.object	; tak
	cmp	r15,	r9	; dolna krawędź obiektu przed górną krawędzią strefy?
	jle	.object	; tak

	;-----------------------------------------------------------------------
	; przycinanie
	;-----------------------------------------------------------------------

.left: ;)
	; lewa krawędź strefy przed lewą krawędzią obiektu?
	cmp	r8,	r12
	jge	.up	; nie

	; wytnij wystający fragment strefy

	; zachowaj oryginalną pozycję prawej krawędzi strefy
	push	r10

	; szerokość odcinanej strefy
	mov	r10,	r12
	sub	r10,	r8

	; wysokość odcinanej strefy
	sub	r11,	r9

	; odłóż na listę stref
	call	service_desu_zone_insert_by_register

	; przywróć oryginalną pozycję prawej krawędzi strefy
	pop	r10

	; przywróć oryginalną pozycję dolnej krawędzi strefy
	add	r11,	r9

	; nowa pozycja lewej krawędzi strefy
	mov	r8,	r12

.up:
	; górna krawędź strefy przed górną krawędzią obiektu?
	cmp	r9,	r13
	jge	.right	; nie

	; wytnij wystający fragment strefy

	; szerokość odcinanej strefy
	sub	r10,	r8

	; zachowaj oryginalną pozycję dolnej krawędzi strefy
	push	r11

	; wysokość odcinanej strefy
	mov	r11,	r13
	sub	r11,	r9

	; odłóż na listę stref
	call	service_desu_zone_insert_by_register

	; przywróć oryginalną pozycję prawej krawędzi strefy
	pop	r11

	; przywróć oryginalną pozycję dolnej krawędzi strefy
	add	r10,	r8

	; nowa pozycja górnej krawędzi strefy
	mov	r9,	r13

.right:
	; prawa krawędź strefy za prawą krawędzią obiektu?
	cmp	r10,	r14
	jle	.down	; nie

	; wytnij wystający fragment strefy

	; szerokość odcinanej strefy
	mov	r10,	r14
	sub	r10,	r8

	; zachowaj oryginalną pozycję lewej krawędzi strefy
	push	r8

	; pozycja lewej krawędzi odcinanej strefy
	mov	r8,	r14

	; wysokość odcinanej strefy
	sub	r11,	r9

	; odłóż na listę stref
	call	service_desu_zone_insert_by_register

	; przywróć oryginalną pozycję lewej krawędzi strefy
	pop	r8

	; przywróć oryginalną pozycję dolnej krawędzi strefy
	add	r11,	r9

	; nowa pozycja prawej krawędzi strefy
	mov	r10,	r14

.down:
	; dolna krawędź strefy za dolną krawędzią obiektu?
	cmp	r11,	r15
	jle	.remove	; nie

	; wytnij wystający fragment strefy

	; wysokość odcinanej strefy
	mov	r11,	r15
	sub	r11,	r9

	; zachowaj oryginalną pozycję górnej krawędzi strefy
	push	r9

	; pozycja górnej krawędzi odcinanej strefy
	mov	r9,	r15

	; szerokość odcinanej strefy
	sub	r10,	r8

	; odłóż na listę stref
	call	service_desu_zone_insert_by_register

	; przywróć oryginalną pozycję lewej krawędzi strefy
	pop	r9

	; przywróć oryginalną pozycję dolnej krawędzi strefy
	add	r10,	r8

	; nowa pozycja dolnej krawędzi strefy
	mov	r11,	r15

	; usuń pozostały fragment strefy
	jmp	.remove

.end:
	; odblokuj listę obiektów do modyfikacji
	mov	byte [service_desu_object_semaphore],	STATIC_FALSE

	; powrót z procedury
	ret
