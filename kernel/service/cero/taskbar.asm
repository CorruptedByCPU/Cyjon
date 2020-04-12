;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

;===============================================================================
service_cero_taskbar:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rdx
	push	rdx
	push	rsi
	push	rdi

	; lista obiektów została zmodyfikowana?
	mov	rax,	qword [service_desu_object_list_modify_time]
	cmp	qword [service_cero_window_taskbar_modify_time],	rax
	je	.end	; nie

	; zatwierdź czas ostatniej modyfikacji listy okien
	mov	qword [service_cero_window_taskbar_modify_time],	rax

	; zablokuj dostęp do modyfikacji listy obiektów
	macro_lock	service_desu_object_semaphore,	0

	; wylicz niezbędny rozmiar przestrzeni łańcucha do wypisania wszystkich elementów paska zadań
	mov	eax,	LIBRARY_BOSU_STRUCTURE_ELEMENT_BUTTON.SIZE + LIBRARY_BOSU_WINDOW_NAME_length
	mul	qword [service_desu_object_list_records]

	; zachowaj rozmiar przestrzeni
	push	rax

	; aktualny rozmiar łańcucha jest wystarczający?
	cmp	rax,	qword [service_cero_window_taskbar.element_chain_0 + LIBRARY_BOSU_STRUCTURE_ELEMENT_CHAIN.size]
	jbe	.enough	; tak

	; pobierz aktualny rozmiar przestrzeni łańcucha
	mov	rcx,	qword [service_cero_window_taskbar.element_chain_0 + LIBRARY_BOSU_STRUCTURE_ELEMENT_CHAIN.size]

	; brak przestrzeni
	test	rcx,	rcx
	jz	.new	; tak, zarejestruj nową

	; zwolnij aktualną przestrzeń łańcucha
	call	library_page_from_size
	mov	rdi,	qword [service_cero_window_taskbar.element_chain_0 + LIBRARY_BOSU_STRUCTURE_ELEMENT_CHAIN.address]
	call	kernel_memory_release

.new:
	; przydziel przestrzeń pod generowane elementy
	mov	rcx,	rax
	call	library_page_from_size
	call	kernel_memory_alloc

	; zachowaj nowy wskaźnik przestrzeni łańcucha
	mov	qword [service_cero_window_taskbar.element_chain_0 + LIBRARY_BOSU_STRUCTURE_ELEMENT_CHAIN.address],	rdi

.enough:
	; pobierz aktualny wskaźnik przestrzeni łańcucha
	mov	rdi,	qword [service_cero_window_taskbar.element_chain_0 + LIBRARY_BOSU_STRUCTURE_ELEMENT_CHAIN.address]

	;-----------------------------------------------------------------------

	; wylicz domyślną szerokość jednego elementu uwzględniająć dostępną przestrzeń paska zadań
	mov	rax,	qword [service_cero_window_taskbar + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
	sub	rax,	qword [service_cero_window_taskbar.element_label_clock + LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
	mov	rcx,	qword [service_desu_object_list_records]
	sub	rcx,	SERVICE_CERO_WINDOW_count
	xor	edx,	edx
	div	rcx

	; zachowaj szerokość elementu
	mov	rbx,	rax

	; pobierz nasz PID
	mov	rax,	qword [service_cero_pid]

	; pozycja pierwszego elementu na osi X
	xor	edx,	edx

	; sprawdź wszystkie okna od początku listy
	mov	rsi,	qword [service_desu_object_list_address]

.loop:
	; koniec listy okien?
	cmp	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags],	STATIC_EMPTY
	je	.ready	; tak

	; zarejestrowane okno należy do nas?
	cmp	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.pid],	rax
	je	.next	; tak, pomiń okno

	; zachowaj oryginalne rejstry
	push	rsi
	push	rdi

	; utwórz pierwszy element opisujący okno na początku paska zadań
	mov	dword [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_BUTTON.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.type],	LIBRARY_BOSU_ELEMENT_TYPE_button
	mov	qword [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_BUTTON.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.size],	LIBRARY_BOSU_STRUCTURE_ELEMENT_BUTTON.SIZE
	mov	qword [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_BUTTON.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.x],	rdx
	mov	qword [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_BUTTON.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.y],	STATIC_EMPTY
	mov	qword [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_BUTTON.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.width],	rbx
	mov	qword [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_BUTTON.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.height],	SERVICE_CERO_WINDOW_TASKBAR_HEIGHT_pixel
	mov	qword [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_BUTTON.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.event],	STATIC_EMPTY	; brak akcji
	;-----------------------------------------------------------------------
	movzx	ecx,	byte [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.length]
	mov	byte [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_BUTTON.length],	cl
	add	qword [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_BUTTON.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.size],	rcx

	; wstaw nazwę elementu na podstawie nazwy okna
	add	rsi,	SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.name
	add	rdi,	LIBRARY_BOSU_STRUCTURE_ELEMENT_BUTTON.string
	rep	movsb

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi

	; przesuń wskaźnik przestrzeni łańcucha za utworzony element
	add	rdi,	qword [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_BUTTON.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.size]

	; następny element z prawej strony aktualnego
	add	rdx,	rbx

.next:
	; przesuń wskaźnik na następny wpis listy okien
	add	rsi,	SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.SIZE

	; kontynuuj
	jmp	.loop

.ready:
	; aktualizuj rozmiar przestrzeni łańcucha
	pop	qword [service_cero_window_taskbar.element_chain_0 + LIBRARY_BOSU_STRUCTURE_ELEMENT_CHAIN.size]

	; zakończ listę elementów łańcucha pustym rekordem
	mov	dword [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT.type],	STATIC_EMPTY

	; zwolnij dostęp do modyfikacji listy obiektów
	mov	byte [service_desu_object_semaphore],	STATIC_FALSE

	; przetwórz wszystkie elementy w łańcuchu
	mov	rsi,	service_cero_window_taskbar.element_chain_0
	mov	rdi,	service_cero_window_taskbar
	call	library_bosu_element_chain

	; ustaw flagę okna: nowa zawartość
	mov	al,	SERVICE_DESU_WINDOW_update
	mov	rsi,	service_cero_window_taskbar
	int	SERVICE_DESU_IRQ

.end:
	; przywróć oryginalne rejestry
	pop	rsi
	pop	rdi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret
