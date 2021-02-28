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

	; odwróć kanała alfa obiektu kursora
	mov	ecx,	kernel_wm_object_cursor.end - kernel_wm_object_cursor.data
	mov	rsi,	kernel_wm_object_cursor.data
	macro_library	LIBRARY_STRUCTURE_ENTRY.color_alpha_invert

	; pobierz rozmiar przestrzeni pamięci karty graficznej w pikselach i Bajtach
	mov	bx,	word [kernel_video_width_pixel]
	mov	dx,	word [kernel_video_height_pixel]
	mov	ecx,	dword [kernel_video_size_byte]

	; aktualizuj właściwości bufora
	mov	word [kernel_wm_object_framebuffer + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.width],	bx
	mov	word [kernel_wm_object_framebuffer + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.height],	dx
	mov	dword [kernel_wm_object_framebuffer + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.size],	ecx

%ifdef	TRANSPARENCY
	; przygotuj przestrzeń pod bufor
	macro_library	LIBRARY_STRUCTURE_ENTRY.page_from_size
	call	kernel_memory_alloc
%else
	; bezpośredni zapis do przestrzeni pamięci karty graficznej
	mov	rdi,	qword [kernel_video_base_address]
%endif

	; zachowaj wskaźnik początku przestrzeni bufora
	mov	qword [kernel_wm_object_framebuffer + KERNEL_WM_STRUCTURE_OBJECT.address],	rdi

	; przygotuj przestrzeń dla listy obiektów
	call	kernel_memory_alloc_page
	call	kernel_page_drain	; wyczyść
	mov	qword [kernel_wm_object_list_address],	rdi

	; przygotuj przestrzeń dla tablicy obiektów
	call	kernel_memory_alloc_page
	call	kernel_page_drain	; wyczyść
	mov	qword [kernel_wm_object_table_address],	rdi

	; przygotuj przestrzeń dla listy wypełnień
	call	kernel_memory_alloc_page
	call	kernel_page_drain	; wyczyść
	mov	qword [kernel_wm_fill_list_address],	rdi

	; przygotuj przestrzeń dla listy stref
	call	kernel_memory_alloc_page
	call	kernel_page_drain	; wyczyść
	mov	qword [kernel_wm_zone_list_address],	rdi

	; przygotuj przestrzeń dla listy scaleń
	call	kernel_memory_alloc_page
	call	kernel_page_drain	; wyczyść
	mov	qword [kernel_wm_merge_list_address],	rdi

	; podłącz procedurę obsługi "systemu zarządzania oknami"
	mov	rax,	KERNEL_WM_IRQ
	mov	bx,	KERNEL_IDT_TYPE_isr
	mov	rdi,	kernel_wm_irq
	call	kernel_idt_mount

	; menedżer okien zainicjowany
	mov	byte [kernel_wm_semaphore],	STATIC_TRUE

.wait:
	; zarejestrowano na liście obiekty?
	cmp	qword [kernel_wm_object_list_length],	STATIC_EMPTY
	je	.wait	; nie, czekaj
