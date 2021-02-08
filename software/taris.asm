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

	; debug
	mov	rsi,	taris_rgl_square
	mov	r8,	taris_rgl_properties
	macro_library	LIBRARY_STRUCTURE_ENTRY.rgl_square

.restart:
	; wylosuj blok i jego model
	call	taris_random_block

	; startowa pozycja bloku
	mov	r9,	TARIS_BRICK_START_POSITION_x
	mov	r10,	TARIS_BRICK_START_POSITION_y

.loop:
	; sprawdź czy nowy blok koliduje z aktualnie istniejącymi
	call	taris_collision

	; sprawdź przychodzące zdarzenia
	mov	rsi,	taris_window
	macro_library	LIBRARY_STRUCTURE_ENTRY.bosu_event

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
	jmp	.loop

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
