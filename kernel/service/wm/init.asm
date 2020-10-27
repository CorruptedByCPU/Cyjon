;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

	; pobierz własny PID
	call	kernel_task_active_pid
	mov	qword [kernel_wm_pid],	rax

	; odwróć kanała alfa obiektu
	mov	ecx,	kernel_wm_object_cursor.end - kernel_wm_object_cursor.data
	mov	rsi,	kernel_wm_object_cursor.data
	call	library_color_alpha_invert

	; pobierz rozmiar przestrzeni pamięci karty graficznej w pikselach i Bajtach
	mov	rbx,	qword [kernel_video_width_pixel]
	mov	rcx,	qword [kernel_video_size_byte]
	mov	rdx,	qword [kernel_video_height_pixel]

	; aktualizuj właściwości bufora
	mov	qword [kernel_wm_object_framebuffer + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.size],	rcx
	mov	qword [kernel_wm_object_framebuffer + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.width],	rbx
	mov	qword [kernel_wm_object_framebuffer + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.height],	rdx

	; dla większej wydajności w wirtualizacji, rezygnujemy z podwójnego buforowania
	; buforem będzie dla nasz bezpośrednio przestrzeń pamięci karty graficznej
	mov	rdi,	qword [kernel_video_base_address]

	; zachowaj wskaźnik początku przestrzeni bufora
	mov	qword [kernel_wm_object_framebuffer + KERNEL_WM_STRUCTURE_OBJECT.address],	rdi

	; przygotuj przestrzeń dla listy obiektów
	call	kernel_memory_alloc_page
	call	kernel_page_drain	; wyczyść
	mov	qword [kernel_wm_object_list_address],	rdi

	; przygotuj przestrzeń dla listy wypełnień
	call	kernel_memory_alloc_page
	call	kernel_page_drain	; wyczyść
	mov	qword [kernel_wm_fill_list_address],	rdi

	; przygotuj przestrzeń dla listy stref
	call	kernel_memory_alloc_page
	call	kernel_page_drain	; wyczyść
	mov	qword [kernel_wm_zone_list_address],	rdi

	; podłącz procedurę obsługi "systemu zarządzania oknami"
	mov	rax,	KERNEL_WM_IRQ
	mov	bx,	KERNEL_IDT_TYPE_isr
	mov	rdi,	kernel_wm_irq
	call	kernel_idt_mount

	; menedżer okien zainicjowany
	mov	byte [kernel_wm_semaphore],	STATIC_TRUE

.wait:
	; zarejestrowano na liście obiekty?
	cmp	qword [kernel_wm_object_list_records],	STATIC_EMPTY
	je	.wait	; nie, czekaj
