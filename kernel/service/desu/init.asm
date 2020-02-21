;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

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

	;-----------------------------------------------------------------------
	; Temporary ------------------------------------------------------------
	;-----------------------------------------------------------------------
	mov	rsi,	service_desu_object_workbench

	; aktualizuj informacje o obszarze roboczym
	mov	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.size],	rcx
	mov	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.width],	rbx
	mov	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.height],	rdx

	; przygotuj przegtrzeń dla obszaru roboczego
	call	library_page_from_size
	call	kernel_memory_alloc
	call	kernel_page_drain_few

	; zachowaj wskaźnik początku obszaru roboczego
	mov	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.address],	rdi

	; ustaw flagi obiektu
	mov	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags],	SERVICE_DESU_OBJECT_FLAG_fixed_xy | SERVICE_DESU_OBJECT_FLAG_fixed_z | SERVICE_DESU_OBJECT_FLAG_flush | SERVICE_DESU_OBJECT_FLAG_visible 

	; dodaj obiekt obszaru roboczego jako pierwszy na listę obiektów
	call	service_desu_object_insert
