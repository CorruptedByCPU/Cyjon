;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
kernel_gui_init:
	; menedżer okien w gotowości?
	cmp	byte [kernel_wm_semaphore],	STATIC_FALSE
	je	kernel_gui_init	; nie, czekaj

	; zachowaj własny numer PID
	call	kernel_task_active_pid
	mov	qword [kernel_gui_pid],	rax

	;-----------------------------------------------------------------------
	; skonfiguruj przestrzeń roboczą
	;-----------------------------------------------------------------------
	mov	rsi,	kernel_gui_window_workbench

	; ustaw szerokość, wysokość i rozmiar przestrzeni roboczej
	mov	ax,	word [kernel_video_width_pixel]
	mov	bx,	word [kernel_video_height_pixel]
	mov	ecx,	dword [kernel_video_size_byte]
	mov	word [rsi + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.width],	ax
	mov	word [rsi + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.height],	bx
	mov	dword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.size],	ecx

	; przygotuj miejsce pod przestrzeń roboczą
	call	library_page_from_size
	call	kernel_memory_alloc

	; zachowaj adres przestrzeni
	mov	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.address],	rdi

	;-----------------------------------------------------------------------

	; pobierz miks kolorów
	mov	rax,	qword [kernel_gui_background_mixer]

	; szerokość i wysokość przestrzeni
	mov	bx,	word [rsi + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.width]
	mov	dx,	word [rsi + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.height]

	; przesunięcie linii pionowych
	xor	r9w,	r9w

	; szerokość fragmentu na podstawie rozdzielszości
	mov	r10w,	word [kernel_video_width_pixel]
	shr	r10w,	STATIC_DIVIDE_BY_16_shift

.background_reload:
	; rozpocznij od fragmentu o rozmiarze 64 pikseli
	movzx	ecx,	r10w

.background_loop:
	; szerokość mniejsza od fragmentu?
	cmp	bx,	r10w
	jb	.fill	; tak, koryguj

	; wypełnij fragment kolorem
	rol	rax,	STATIC_REPLACE_EAX_WITH_HIGH_shift	; zamień kolorystykę
	rep	stosd

	; pozostała szerokość przestrzeni
	sub	bx,	r10w
	jz	.offset	; pierwszy wiersz gotowy
	jns	.background_reload	; brak przepełnienia, kontynuuj

.fill:
	; pozostała szerokość do wypełnienia
	movzx	ecx,	bx
	rol	rax,	STATIC_REPLACE_EAX_WITH_HIGH_shift	; zamień kolorystykę
	rep	stosd

.offset:
	; następny wiersz przesunięty o kolejny piksel
	inc	r9w

	; przesunięcie większe od szerokości fragmentu?
	cmp	r9w,	r10w
	jb	.offset_ok	; nie

	; resetuj pozycję przesunięcia
	xor	r9w,	r9w

	; zamień kolorystykę
	rol	rax,	STATIC_REPLACE_EAX_WITH_HIGH_shift

	; kontynuuj
	jmp	.offset_end

.offset_ok:
	; wypełnij fragment przesunięcia
	movzx	ecx,	r9w
	rep	stosd

.offset_end:
	; szrokość przestrzeni
	mov	bx,	word [rsi + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.width]

	; koryguj szerokość przestrzeni o przesunięcie fragmentu
	sub	bx,	r9w

	; koniec przestrzeni na wysokość
	dec	dx
	jnz	.background_reload	; nie

	;-----------------------------------------------------------------------

	; przydziel identyfikator dla okna
	call	kernel_wm_object_id_new
	mov	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.id],	rcx

	; zarejestruj okno
	call	kernel_wm_object_insert

	;-----------------------------------------------------------------------
	; skonfiguruj przestrzeń paska zadań
	;-----------------------------------------------------------------------
	mov	rsi,	kernel_gui_window_taskbar

	; ustaw pozycję paska zadań na dole ekranu
	mov	bx,	word [kernel_video_height_pixel]
	sub	bx,	KERNEL_GUI_WINDOW_TASKBAR_HEIGHT_pixel
	mov	word [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.y],	bx

	; ustaw szerokość paska zadań na cały ekran
	mov	ax,	word [kernel_video_width_pixel]
	mov	word [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.width],	ax

	; ustaw etykietę "zegar" na końcu paska zadań
	sub	ax,	word [kernel_gui_window_taskbar.element_label_clock + LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
	mov	word [kernel_gui_window_taskbar.element_label_clock + LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.x],	ax

	; oblicz rozmiar przestrzeni danych okna w Bajtach
	movzx	eax,	word [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
	shl	eax,	KERNEL_VIDEO_DEPTH_shift
	movzx	ebx,	word [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.height]
	mul	ebx

	; przygotuj miejsce pod przestrzeń okna
	mov	ecx,	eax
	call	library_page_from_size
	call	kernel_memory_alloc

	; zachowaj adres przestrzeni
	mov	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.address],	rdi

	; utwórz okno paska zadań
	call	library_bosu

	; przydziel identyfikator dla okna
	call	kernel_wm_object_id_new
	mov	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.id],	rcx

	; zarejestruj okno w menedżerze okien
	call	kernel_wm_object_insert

	;-----------------------------------------------------------------------
	; utwórz menu kontekstowe
	;-----------------------------------------------------------------------
	mov	rsi,	kernel_gui_window_menu

	; ilość elementów wchodzących w skład menu oraz ich łączna wysokość względem siebie
	call	library_bosu_elements_specification

	; ustaw szerokość i wysokość okna menu
	mov	word [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.width],	r8w
	mov	word [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.height],	r9w

	; oblicz rozmiar przestrzeni danych okna w Bajtach
	movzx	eax,	word [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
	shl	rax,	KERNEL_VIDEO_DEPTH_shift
	movzx	ebx,	word [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.height]
	mul	ebx

	; przygotuj miejsce pod przestrzeń okna
	mov	ecx,	eax
	call	library_page_from_size
	call	kernel_memory_alloc

	; zachowaj adres przestrzeni
	mov	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.address],	rdi

	; utwórz okno paska zadań
	call	library_bosu

	; przydziel identyfikator dla okna
	call	kernel_wm_object_id_new
	mov	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.id],	rcx

	; zarejestruj okno w menedżerze okien
	call	kernel_wm_object_insert

	; zachowaj informacje o ostatniej modyfikacji listy okien
	mov	rax,	qword [kernel_wm_object_list_modify_time]
	mov	qword [kernel_gui_window_taskbar_modify_time],	rax

	; przygotuj listę kolejności okien
	call	kernel_memory_alloc_page
	call	kernel_page_drain
	mov	qword [kernel_gui_taskbar_list_address],	rdi	; zachowaj wskaźnik

	; uruchom domyślnie program Console
	call	kernel_gui_event_soler

	macro_debug	"kernel_gui_init"
