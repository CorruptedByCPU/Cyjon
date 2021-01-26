;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

	; utwórz okno
	mov	rsi,	soler_window
	macro_library	LIBRARY_STRUCTURE_ENTRY.bosu
	jc	soler.close	; brak wystarczającej przestrzeni pamięci

	; wyświetl okno
	mov	al,	KERNEL_WM_WINDOW_update
	or	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags],	LIBRARY_BOSU_WINDOW_FLAG_visible | LIBRARY_BOSU_WINDOW_FLAG_flush
	int	KERNEL_WM_IRQ

	; inicjalizuj tryb koprocesora
	finit
        fstcw	word [soler_fpu_control]	; zapisz flagi koprocesora do zmiennej
	or	word [soler_fpu_control],	110000000000b	; nie zachowuj wartości za przecinkiem
        fldcw	word [soler_fpu_control]	; wczytaj nowe flagi koprocesora z zmiennej
