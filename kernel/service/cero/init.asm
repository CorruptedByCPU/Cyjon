;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

;===============================================================================
service_cero_init:
	; menedżer okien w gotowości?
	cmp	byte [service_desu_semaphore],	STATIC_FALSE
	je	service_cero_init	; nie, czekaj

	;-----------------------------------------------------------------------
	; skonfiguruj przestrzeń roboczą
	;-----------------------------------------------------------------------
	mov	rsi,	service_cero_window_workbench

	; ustaw szerokość, wysokość i rozmiar przestrzeni roboczej
	mov	rax,	qword [kernel_video_width_pixel]
	mov	rbx,	qword [kernel_video_height_pixel]
	mov	rcx,	qword [kernel_video_size_byte]
	mov	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.width],	rax
	mov	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.height],	rbx
	mov	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.size],	rcx

	; przygotuj miejsce pod przestrzeń roboczą
	call	library_page_from_size
	call	kernel_memory_alloc

	; zachowaj adres przestrzeni
	mov	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.address],	rdi

	; wypełnij przestrzeń okna domyślnym kolorem tła
	mov	eax,	SERVICE_CERO_WINDOW_WORKBENCH_BACKGROUND_color
	mov	rcx,	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.size]
	shr	rcx,	STATIC_DIVIDE_BY_DWORD_shift
	rep	stosd

	; przydziel identyfikator dla okna
	call	service_desu_object_id_new
	mov	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.id],	rcx

	; zarejestruj okno
	call	service_desu_object_insert

	;-----------------------------------------------------------------------
	; skonfiguruj przestrzeń paska zadań
	;-----------------------------------------------------------------------
	mov	rsi,	service_cero_window_taskbar

	; ustaw pozycję paska zadań na dole ekranu
	sub	rbx,	SERVICE_CERO_WINDOW_TASKBAR_HEIGHT_pixel
	mov	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.y],	rbx

	; ustaw szerokość paska zadań na cały ekran
	mov	rax,	qword [kernel_video_width_pixel]
	mov	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.width],	rax

	; ustaw etykietę "zegar" na końcu paska zadań
	sub	rax,	qword [service_cero_window_taskbar.element_label_clock + LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
	mov	qword [service_cero_window_taskbar.element_label_clock + LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.x],	rax

	; oblicz rozmiar przestrzeni danych okna w Bajtach
	mov	rax,	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
	shl	rax,	KERNEL_VIDEO_DEPTH_shift
	mul	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.height]

	; przygotuj miejsce pod przestrzeń okna
	mov	rcx,	rax
	call	library_page_from_size
	call	kernel_memory_alloc

	; zachowaj adres przestrzeni
	mov	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.address],	rdi

	; utwórz okno paska zadań
	call	library_bosu

	; przydziel identyfikator dla okna
	call	service_desu_object_id_new
	mov	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.id],	rcx

	; zarejestruj okno w menedżerze okien
	call	service_desu_object_insert

	;-----------------------------------------------------------------------
	; utwórz menu kontekstowe
	;-----------------------------------------------------------------------
	mov	rsi,	service_cero_window_menu

	; ilość elementów wchodzących w skład menu oraz ich łączna wysokość względem siebie
	call	library_bosu_elements_specification

	; ustaw szerokość i wysokość okna menu
	mov	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.width],	r8
	mov	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.height],	r9

	; oblicz rozmiar przestrzeni danych okna w Bajtach
	mov	rax,	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
	shl	rax,	KERNEL_VIDEO_DEPTH_shift
	mul	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.height]

	; przygotuj miejsce pod przestrzeń okna
	mov	rcx,	rax
	call	library_page_from_size
	call	kernel_memory_alloc

	; zachowaj adres przestrzeni
	mov	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.address],	rdi

	; utwórz okno paska zadań
	call	library_bosu

	; przydziel identyfikator dla okna
	call	service_desu_object_id_new
	mov	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.id],	rcx

	; zarejestruj okno w menedżerze okien
	call	service_desu_object_insert

	; zachowaj informacje o ostatniej modyfikacji listy okien
	mov	rax,	qword [service_desu_object_list_modify_time]
	mov	qword [service_cero_window_list_modify_time],	rax
