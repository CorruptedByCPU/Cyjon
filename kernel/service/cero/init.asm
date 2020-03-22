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

	; zarejestruj okno
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

	; utwórz okno menu
	call	library_bosu
