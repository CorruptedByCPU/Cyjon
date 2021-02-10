;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

	;-----------------------------------------------------------------------
	%include	"software/taris/config.asm"
	;-----------------------------------------------------------------------

;===============================================================================
taris:
	; inicjalizuj środowisko pracy
	%include	"software/taris/init.asm"

;===============================================================================
	; delty
	mov	r9,	1
	mov	r10,	1

.debug:
	; wyczyść przestrzeń roboczą
	macro_library	LIBRARY_STRUCTURE_ENTRY.rgl_clear

	;=======================================================================
	; BOUNCE TEST
	mov	rsi,	taris_rgl_square
	add	word [rsi + LIBRARY_RGL_STRUCTURE_SQUARE.x],	r9w
	add	word [rsi + LIBRARY_RGL_STRUCTURE_SQUARE.y],	r10w
	macro_library	LIBRARY_STRUCTURE_ENTRY.rgl_square
	mov	r11w,	word [rsi + LIBRARY_RGL_STRUCTURE_SQUARE.x]
	mov	r12w,	word [rsi + LIBRARY_RGL_STRUCTURE_SQUARE.y]
	mov	r13w,	word [rsi + LIBRARY_RGL_STRUCTURE_SQUARE.width]
	mov	r14w,	word [rsi + LIBRARY_RGL_STRUCTURE_SQUARE.height]
	test	r11w,	r11w
	jz	.ups_x
	mov	ax,	r11w
	add	ax,	r13w
	add	ax,	r9w
	cmp	ax,	word [r8 + LIBRARY_RGL_STRUCTURE_PROPERTIES.width]
	jb	.check_y
.ups_x:
	not	r9w
	inc	r9w
.check_y:
	test	r12w,	r12w
	jz	.ups_y
	mov	ax,	r12w
	add	ax,	r14w
	add	ax,	r10w
	cmp	ax,	word [r8 + LIBRARY_RGL_STRUCTURE_PROPERTIES.height]
	jb	.y_ok
.ups_y:
	not	r10w
	inc	r10w
.y_ok:
	;===============================================================================

.restart:
	; ; wylosuj blok i jego model
	; call	taris_random_block

	; ; startowa pozycja bloku
	; mov	r9,	TARIS_BRICK_START_POSITION_x
	; mov	r10,	TARIS_BRICK_START_POSITION_y

.loop:
	; sprawdź czy nowy blok koliduje z aktualnie istniejącymi
	call	taris_collision

	; sprawdź przychodzące zdarzenia
	mov	rsi,	taris_window
	macro_library	LIBRARY_STRUCTURE_ENTRY.bosu_event

	; synchronizacja zawartości z przestrzenią roboczą
	macro_library	LIBRARY_STRUCTURE_ENTRY.rgl_flush

	; aktualizuj zawartość okna
	mov	al,	KERNEL_WM_WINDOW_update
	mov	rsi,	taris_window
	or	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags],	LIBRARY_BOSU_WINDOW_FLAG_visible | LIBRARY_BOSU_WINDOW_FLAG_flush
	int	KERNEL_WM_IRQ

	; odczekaj ilość określoną ilość czasu na przesunięcie bloku
	mov	ax,	KERNEL_SERVICE_PROCESS_sleep
	mov	ecx,	dword [taris_microtime]
	int	KERNEL_SERVICE

	; kontnuuj
	jmp	.debug

.close:
	; zakończ pracę programu
	xor	ax,	ax
	int	KERNEL_SERVICE

	macro_debug	"software: taris"

	;-----------------------------------------------------------------------
	%include	"software/taris/data.asm"
	%include	"software/taris/random.asm"
	%include	"software/taris/collision.asm"
	;-----------------------------------------------------------------------
