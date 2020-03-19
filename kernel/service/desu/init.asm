;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

	;-----------------------------------------------------------------------

	; odwróć kanała alfa obiektu
	mov	ecx,	service_desu_object_cursor.end - service_desu_object_cursor.data
	mov	rsi,	service_desu_object_cursor.data
	call	library_color_alpha_invert

	;-----------------------------------------------------------------------

	; pobierz rozmiar przestrzeni pamięci karty graficznej w pikselach i Bajtach
	mov	rbx,	qword [kernel_video_width_pixel]
	mov	rcx,	qword [kernel_video_size_byte]
	mov	rdx,	qword [kernel_video_height_pixel]

	;-----------------------------------------------------------------------

	; aktualizuj właściwości bufora
	mov	qword [service_desu_object_framebuffer + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.size],	rcx
	mov	qword [service_desu_object_framebuffer + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.width],	rbx
	mov	qword [service_desu_object_framebuffer + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.height],	rdx

	; dla większej wydajności w wirtualizacji, rezygnujemy z podwójnego buforowania
	; buforem będzie dla nasz bezpośrednio przestrzeń pamięci karty graficznej
	mov	rdi,	qword [kernel_video_base_address]

	; zachowaj wskaźnik początku przestrzeni bufora
	mov	qword [service_desu_object_framebuffer + SERVICE_DESU_STRUCTURE_OBJECT.address],	rdi

	;-----------------------------------------------------------------------

	; przygotuj przestrzeń dla listy obiektów
	call	kernel_memory_alloc_page
	call	kernel_page_drain	; wyczyść
	mov	qword [service_desu_object_list_address],	rdi

	; przygotuj przestrzeń dla listy wypełnień
	call	kernel_memory_alloc_page
	call	kernel_page_drain	; wyczyść
	mov	qword [service_desu_fill_list_address],	rdi

	; przygotuj przestrzeń dla listy stref
	call	kernel_memory_alloc_page
	call	kernel_page_drain	; wyczyść
	mov	qword [service_desu_zone_list_address],	rdi

	; ;-----------------------------------------------------------------------
	; ; DEBUG - remove on release with service_desu_object_tmp
	; ;-----------------------------------------------------------------------
	; mov	rsi,	service_desu_object_workbench
	; mov	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.size],	rcx
	; mov	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.width],	rbx
	; mov	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.height],	rdx
	; call	library_page_from_size
	; call	kernel_memory_alloc
	; call	kernel_page_drain_few
	; mov	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.address],	rdi
	; mov	eax,	0x00101010
	; mov	rcx,	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.size]
	; shr	rcx,	STATIC_DIVIDE_BY_DWORD_shift
	; rep	stosd
	; mov	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags],	SERVICE_DESU_OBJECT_FLAG_fixed_xy | SERVICE_DESU_OBJECT_FLAG_fixed_z | SERVICE_DESU_OBJECT_FLAG_flush | SERVICE_DESU_OBJECT_FLAG_visible
	; call	service_desu_object_insert
	; mov	rsi,	service_desu_object_tmp
	; call	service_desu_object_insert
	; call	kernel_memory_alloc_page
	; mov	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.address],	rdi
	; mov	eax,	0x00FF0000
	; mov	ecx,	4096 / 4
	; rep	stosd
	; mov	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags],	SERVICE_DESU_OBJECT_FLAG_flush | SERVICE_DESU_OBJECT_FLAG_visible
	; mov	rsi,	service_desu_object_another
	; call	service_desu_object_insert
	; call	kernel_memory_alloc_page
	; mov	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.address],	rdi
	; mov	eax,	0x0000FF00
	; mov	ecx,	4096 / 4
	; rep	stosd
	; mov	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags],	SERVICE_DESU_OBJECT_FLAG_flush | SERVICE_DESU_OBJECT_FLAG_visible
