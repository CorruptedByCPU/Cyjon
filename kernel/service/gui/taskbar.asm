;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
kernel_gui_taskbar_reload:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rsi
	push	rdi

	; lista obiektów została zmodyfikowana?
	mov	rax,	qword [kernel_wm_object_list_modify_time]
	cmp	qword [kernel_gui_window_taskbar_modify_time],	rax
	je	.end	; nie

	; zablokuj dostęp do modyfikacji listy obiektów
	macro_lock	kernel_wm_object_semaphore,	0

	; nasz numer PID
	mov	rcx,	qword [kernel_gui_pid]

	; zarejestruj okna na liście w kolejności ich pojawiania się
	mov	rsi,	qword [kernel_wm_object_list_address]
	mov	rdi,	qword [kernel_gui_taskbar_list_address]

.loop:
	; koniec listy okien?
	cmp	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	STATIC_EMPTY
	je	.registered	; tak

	; zarejestrowane okno należy do nas?
	cmp	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.pid],	rcx
	je	.next	; tak, pomiń okno

	; dodaj do listy
	call	.insert

.next:
	; przesuń wskaźnik na następną pozycję obiektu
	add	rsi,	KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.SIZE

	; kontynuuj
	jmp	.loop

.insert:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rdi

	; identyfikator okna
	mov	rax,	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.id]

	; ilość identyfikatorów okien na liście
	mov	rcx,	qword [kernel_gui_taskbar_list_count]

	; lista jest pusta?
	test	rcx,	rcx
	jz	.insert_new	; tak

.insert_loop:
	; identyfikator znajduje się na liście?
	cmp	rax,	qword [rdi]
	je	.insert_end	; tak

	; następny wpis
	add	rdi,	STATIC_QWORD_SIZE_byte

	; koniec listy?
	dec	rcx
	jnz	.insert_loop	; nie

.insert_new:
	; odłóż na listę identyfikator okna
	stosq

	; ilość zarejestrowanych okien
	inc	qword [kernel_gui_taskbar_list_count]

.insert_end:
	; przywróć oryginale rejestry
	pop	rdi
	pop	rcx

	; powrót z podprocedury
	ret

.remove:
	; zachowaj oryginalne rejestry
	push	rbx

	; przeszukaj całą listę identyfikatorów za nieistniejącymi oknami
	mov	rcx,	qword [kernel_gui_taskbar_list_count]
	mov	rdi,	qword [kernel_gui_taskbar_list_address]

.remove_loop:
	; lista identyfokatorów jest pusta?
	test	rcx,	rcx
	jz	.remove_end

	; sprawdź czy identyfikator okna istnieje
	mov	rbx,	qword [rdi]
	call	kernel_wm_object_by_id
	jnc	.remove_next	; istnieje

	; zachowaj oryginalne rejestry
	push	rcx
	push	rdi

	; usuń identyfikator z listy
	mov	rsi,	rdi
	add	rsi,	STATIC_QWORD_SIZE_byte
	rep	movsq

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx

	; ilość zarejestrowanych identyfikatorów
	dec	qword [kernel_gui_taskbar_list_count]

	; kontynuuj
	jmp	.remove_step_by

.remove_next:
	; przesuń wskaźnik na następną pozycję
	add	rdi,	STATIC_QWORD_SIZE_byte

.remove_step_by:
	; koniec listy?
	dec	rcx
	jnz	.remove_loop	; nie

.remove_end:
	; przywróć oryginalne rejestry
	pop	rbx

	; powrót z podprocedury
	ret

.registered:
	; zwolnij wszystkie wpisy z nieistniejącymi identyfikatorami
	call	.remove

	; zwolnij dostęp do modyfikacji listy obiektów
	mov	byte [kernel_wm_object_semaphore],	STATIC_FALSE

.end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"kernel_gui_taskbar_reload"

;===============================================================================
; wejście:
;	rdi - wskaźnik do komunikatu IPC
kernel_gui_taskbar_event:
	; zachowaj oryginalne rejestry
	push	rbx
	push	rsi

	; lewy przycisk myszki?
	cmp	byte [rdi + KERNEL_IPC_STRUCTURE.data + KERNEL_WM_STRUCTURE_IPC.action],	KERNEL_WM_IPC_MOUSE_btn_left_press
	jne	.end	; nie

	; sprawdź, którego elementu okna dotyczny akcja
	mov	rsi,	kernel_gui_window_taskbar
	call	library_bosu_element
	jc	.end	; brak akcji

	; akcja dotyczy elementu zegara?
	cmp	rsi,	kernel_gui_window_taskbar.element_label_clock
	je	.end	; tak, brak akcji

	; pobierz wskaźnik do obiektu na podstawie identyfikatora okna
	mov	rbx,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.event]
	call	kernel_wm_object_by_id

	; zmień widoczność obiektu
	xor	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_visible

	; poinformuj menedżer okien
	or	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_undraw

	; przwtwórz raz jeszcze taskbar
	mov	qword [kernel_gui_window_taskbar_modify_time],	STATIC_EMPTY

.end:
	; przywróć oryginalne rejestry
	pop	rsi
	pop	rbx

	; powrót z procedury
	ret

	macro_debug	"kernel_gui_taskbar_event"

;===============================================================================
kernel_gui_taskbar:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	r8

	; przygotuj aktualną listę identyfikatorów okien
	call	kernel_gui_taskbar_reload

	; lista obiektów została zmodyfikowana?
	mov	rax,	qword [kernel_wm_object_list_modify_time]
	cmp	qword [kernel_gui_window_taskbar_modify_time],	rax
	je	.end	; nie

	; zablokuj dostęp do modyfikacji listy obiektów
	macro_lock	kernel_wm_object_semaphore,	0

	; wylicz niezbędny rozmiar przestrzeni łańcucha do wypisania wszystkich elementów paska zadań
	mov	eax,	LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.SIZE + LIBRARY_BOSU_WINDOW_NAME_length
	mov	rcx,	qword [kernel_gui_taskbar_list_count]
	inc	rcx	; element czyszczący przestrzeń
	mul	rcx

	; zachowaj rozmiar przestrzeni
	push	rax

	; aktualny rozmiar łańcucha jest wystarczający?
	cmp	rax,	qword [kernel_gui_window_taskbar.element_chain_0 + LIBRARY_BOSU_STRUCTURE_ELEMENT_CHAIN.size]
	jbe	.enough	; tak

	; pobierz aktualny rozmiar przestrzeni łańcucha
	mov	rcx,	qword [kernel_gui_window_taskbar.element_chain_0 + LIBRARY_BOSU_STRUCTURE_ELEMENT_CHAIN.size]

	; brak przestrzeni
	test	rcx,	rcx
	jz	.new	; tak, zarejestruj nową

	; zwolnij aktualną przestrzeń łańcucha
	call	library_page_from_size
	mov	rdi,	qword [kernel_gui_window_taskbar.element_chain_0 + LIBRARY_BOSU_STRUCTURE_ELEMENT_CHAIN.address]
	call	kernel_memory_release

.new:
	; przydziel przestrzeń pod generowane elementy
	mov	rcx,	rax
	call	library_page_from_size
	call	kernel_memory_alloc

	; zachowaj nowy wskaźnik przestrzeni łańcucha
	mov	qword [kernel_gui_window_taskbar.element_chain_0 + LIBRARY_BOSU_STRUCTURE_ELEMENT_CHAIN.address],	rdi

.enough:
	; pobierz aktualny wskaźnik przestrzeni łańcucha
	mov	rdi,	qword [kernel_gui_window_taskbar.element_chain_0 + LIBRARY_BOSU_STRUCTURE_ELEMENT_CHAIN.address]

	;-----------------------------------------------------------------------

	; wylicz domyślną szerokość jednego elementu uwzględniająć dostępną przestrzeń paska zadań
	mov	rax,	qword [kernel_gui_window_taskbar + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
	sub	rax,	qword [kernel_gui_window_taskbar.element_label_clock + LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
	mov	rcx,	qword [kernel_gui_taskbar_list_count]
	xor	edx,	edx

	; brak otwartych okien?
	test	rcx,	rcx
	jz	.max	; tak

	; wylicz szerokość jednego elementu
	div	rcx

.max:
	; zachowaj szerokość elementu
	mov	rbx,	rax
	sub	rbx,	KERNEL_GUI_WINDOW_TASKBAR_MARGIN_right

	; pozycja pierwszego elementu na osi X
	xor	edx,	edx

	; sprawdź wszystkie okna od początku listy
	mov	r8,	qword [kernel_gui_taskbar_list_address]

	; brak elementów do wygenerowania?
	test	rcx,	rcx
	jz	.empty	; tak

.loop:
	; koniec listy okien?
	cmp	qword [r8],	STATIC_EMPTY
	je	.ready	; tak

	; pobierz wskaźnik do obiektu
	push	rbx
	mov	rbx,	qword [r8]
	call	kernel_wm_object_by_id
	pop	rbx

	; zachowaj oryginalne rejstry
	push	rdi

	; utwórz pierwszy element opisujący okno na początku paska zadań
	mov	dword [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.type],	LIBRARY_BOSU_ELEMENT_TYPE_taskbar
	mov	qword [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.size],	LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.SIZE
	mov	qword [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.x],	rdx
	mov	qword [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.y],	STATIC_EMPTY
	mov	qword [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.width],	rbx
	mov	qword [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.height],	KERNEL_GUI_WINDOW_TASKBAR_HEIGHT_pixel
	;----------------------------------------------------------------------
	; pobierz identyfikator okna dla elementu
	mov	rax,	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.id]
	mov	qword [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.event],	rax	; identyfikator okna
	;-----------------------------------------------------------------------
	movzx	ecx,	byte [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.length]
	mov	byte [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.length],	cl
	add	qword [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.size],	rcx
	;-----------------------------------------------------------------------
	mov	dword [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.background],	LIBRARY_BOSU_ELEMENT_TASKBAR_BG_color
	; okno jest widoczne?
	test	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_visible
	jnz	.visible	; tak

	; oznacz okno na pasku zadań jako widoczne
	mov	dword [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.background],	LIBRARY_BOSU_ELEMENT_TASKBAR_BG_HIDDEN_color

.visible:
	;-----------------------------------------------------------------------
	; wstaw nazwę elementu na podstawie nazwy okna
	add	rsi,	KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.name
	add	rdi,	LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.string
	rep	movsb

	; przywróć oryginalne rejestry
	pop	rdi

	; przesuń wskaźnik przestrzeni łańcucha za utworzony element
	add	rdi,	qword [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.size]

	; następny element z prawej strony aktualnego
	add	rdx,	rbx

	; zachowaj szerokość elementów
	push	rbx

	; wstaw margines
	mov	rbx,	KERNEL_GUI_WINDOW_TASKBAR_MARGIN_right
	call	kernel_gui_taskbar_margin

	; przywróć szerokość elementów
	pop	rbx

.next:
	; przesuń wskaźnik na następny wpis listy okien
	add	r8,	STATIC_QWORD_SIZE_byte

	; kontynuuj
	jmp	.loop

.empty:
	; wyczyść przestrzeń za pomocą pustej etykiety
	add	rbx,	KERNEL_GUI_WINDOW_TASKBAR_MARGIN_right	; wraz z prawym marginesem
	call	kernel_gui_taskbar_margin

.ready:
	; aktualizuj rozmiar przestrzeni łańcucha
	pop	qword [kernel_gui_window_taskbar.element_chain_0 + LIBRARY_BOSU_STRUCTURE_ELEMENT_CHAIN.size]

	; zakończ listę elementów łańcucha pustym rekordem
	mov	dword [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT.type],	STATIC_EMPTY

	; zwolnij dostęp do modyfikacji listy obiektów
	mov	byte [kernel_wm_object_semaphore],	STATIC_FALSE

	; przetwórz wszystkie elementy w łańcuchu
	mov	rsi,	kernel_gui_window_taskbar.element_chain_0
	mov	rdi,	kernel_gui_window_taskbar
	call	library_bosu_element_chain

	; ustaw flagę okna: nowa zawartość
	mov	al,	KERNEL_WM_WINDOW_update
	mov	rsi,	kernel_gui_window_taskbar
	int	KERNEL_WM_IRQ

	; zatwierdź czas ostatniej modyfikacji listy okien
	mov	rax,	qword [kernel_wm_object_list_modify_time]
	mov	qword [kernel_gui_window_taskbar_modify_time],	rax

.end:
	; przywróć oryginalne rejestry
	pop	r8
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"kernel_gui_taskbar"

;===============================================================================
; wejście:
;	rdx - pozycja elementu na osi X
;	rdi - wskaźnik do pozycji na liście elementów
; wyjście:
;	rdx - pozycja następnego elementu na osi X
;	rdi - wskaźnik następnej pozycji na liście elementów
kernel_gui_taskbar_margin:
	; wyczyść przestrzeń za pomocą pustej etykiety
	mov	dword [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.type],	LIBRARY_BOSU_ELEMENT_TYPE_label
	mov	qword [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.size],	LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.SIZE
	mov	qword [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.x],	rdx
	mov	qword [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.y],	STATIC_EMPTY
	mov	qword [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.width],	rbx
	mov	qword [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.height],	KERNEL_GUI_WINDOW_TASKBAR_HEIGHT_pixel
	mov	qword [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.event],	STATIC_EMPTY	; brak akcji
	;-----------------------------------------------------------------------
	mov	byte [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.length],	0x01
	mov	byte [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.string],	STATIC_ASCII_SPACE
	add	qword [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.size],	0x01

	; przesuń wskaźnik osi X
	add	rdx,	rbx

	; przesuń wskaźnik przestrzeni łańcucha za utworzony element
	add	rdi,	qword [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.size]

	; powrót z procedury
	ret
