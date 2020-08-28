;===============================================================================
; Copyright (C) by blackdev.org
;===============================================================================

;===============================================================================
kernel_gui_taskbar:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rdx
	push	rdx
	push	rsi
	push	rdi

	; lista obiektów została zmodyfikowana?
	mov	rax,	qword [kernel_wm_object_list_modify_time]
	cmp	qword [kernel_gui_window_taskbar_modify_time],	rax
	je	.end	; nie

	; zatwierdź czas ostatniej modyfikacji listy okien
	mov	qword [kernel_gui_window_taskbar_modify_time],	rax

	; zablokuj dostęp do modyfikacji listy obiektów
	macro_lock	kernel_wm_object_semaphore,	0

	; wylicz niezbędny rozmiar przestrzeni łańcucha do wypisania wszystkich elementów paska zadań
	mov	eax,	LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.SIZE + LIBRARY_BOSU_WINDOW_NAME_length
	mov	rcx,	qword [kernel_wm_object_list_records]
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
	mov	rcx,	qword [kernel_wm_object_list_records]
	xor	edx,	edx

	; ilość otwartych okien, nienależących do GUI
	sub	rcx,	KERNEL_GUI_WINDOW_count
	jz	.max	; brak otwartych okien

	; wylicz szerokość elementu
	div	rcx

.max:
	; zachowaj szerokość elementu
	mov	rbx,	rax
	sub	rbx,	KERNEL_GUI_WINDOW_TASKBAR_MARGIN_right

	; pobierz nasz PID
	mov	rax,	qword [kernel_gui_pid]

	; pozycja pierwszego elementu na osi X
	xor	edx,	edx

	; sprawdź wszystkie okna od początku listy
	mov	rsi,	qword [kernel_wm_object_list_address]

	; brak elementów do wygenerowania?
	test	rcx,	rcx
	jz	.empty	; tak

.loop:
	; koniec listy okien?
	cmp	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	STATIC_EMPTY
	je	.ready	; tak

	; zarejestrowane okno należy do nas?
	cmp	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.pid],	rax
	je	.next	; tak, pomiń okno

	; wyczyść przestrzeń za pomocą pustej etykiety
	call	kernel_gui_taskbar_clear

	; zachowaj oryginalne rejstry
	push	rsi
	push	rdi

	; utwórz pierwszy element opisujący okno na początku paska zadań
	mov	dword [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.type],	LIBRARY_BOSU_ELEMENT_TYPE_taskbar
	mov	qword [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.size],	LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.SIZE
	mov	qword [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.x],	rdx
	mov	qword [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.y],	STATIC_EMPTY
	mov	qword [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.width],	rbx
	mov	qword [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.height],	KERNEL_GUI_WINDOW_TASKBAR_HEIGHT_pixel
	mov	qword [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.event],	STATIC_EMPTY	; brak akcji
	;-----------------------------------------------------------------------
	movzx	ecx,	byte [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.length]
	mov	byte [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.length],	cl
	add	qword [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.size],	rcx
	;-----------------------------------------------------------------------
	mov	dword [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.background],	LIBRARY_BOSU_ELEMENT_TASKBAR_BACKGROUND_color
	;-----------------------------------------------------------------------
	; wstaw nazwę elementu na podstawie nazwy okna
	add	rsi,	KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.name
	add	rdi,	LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.string
	rep	movsb

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi

	; zachowaj wskaźnik do ostatniego zarejestowanego elementu
	mov	rcx,	rdi

	; przesuń wskaźnik przestrzeni łańcucha za utworzony element
	add	rdi,	qword [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.size]

	; następny element z prawej strony aktualnego
	add	rdx,	rbx
	add	rdx,	KERNEL_GUI_WINDOW_TASKBAR_MARGIN_right << STATIC_MULTIPLE_BY_2_shift

.next:
	; przesuń wskaźnik na następny wpis listy okien
	add	rsi,	KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.SIZE

	; kontynuuj
	jmp	.loop

.empty:
	; wyczyść przestrzeń za pomocą pustej etykiety
	call	kernel_gui_taskbar_clear

.ready:
	; oznaczyć ostatni element listy?
	test	rcx,	rcx
	jz	.no_active	; nie

	; oznacz okno na pasku zadań jako aktywne
	mov	dword [rcx + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.background],	LIBRARY_BOSU_ELEMENT_TASKBAR_BG_ACTIVE_color

.no_active:
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

	macro_debug	"kernel_gui_taskbar"

;===============================================================================
; wejście:
;	rbx - szerokość elementu w pikselach
;	rdx - pozycja elementu na osi X
;	rdi - wskaźnik do pozycji na liście elementów
; wyjście:
;	rdi - wskaźnik następnej pozycji na liście elementów
kernel_gui_taskbar_clear:
	; zachowaj oryginalne rejestry
	push	rbx

	; pełna szerokość bez marginesu
	add	rbx,	KERNEL_GUI_WINDOW_TASKBAR_MARGIN_right

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

	; przesuń wskaźnik przestrzeni łańcucha za utworzony element
	add	rdi,	qword [rdi + LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.size]

	; przywróć oryginalne rejstry
	pop	rbx

	; powrót z procedury
	ret
