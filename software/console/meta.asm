;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; UWAGA:
;	rejestry zniszczone
console_meta:
	; aktualna pozycja kursora
	mov	ax,	word [console_terminal_table + LIBRARY_TERMINAL_STRUCTURE.cursor + LIBRARY_TERMINAL_STURCTURE_CURSOR.x]
	mov	word [console_stream_meta + CONSOLE_STRUCTURE_STREAM_META.x],	ax
	mov	ax,	word [console_terminal_table + LIBRARY_TERMINAL_STRUCTURE.cursor + LIBRARY_TERMINAL_STURCTURE_CURSOR.y]
	mov	word [console_stream_meta + CONSOLE_STRUCTURE_STREAM_META.y],	ax

	; zachowaj oryginalne rejestry
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_meta
	mov	bl,	KERNEL_SERVICE_PROCESS_STREAM_META_FLAG_set | KERNEL_SERVICE_PROCESS_STREAM_META_FLAG_in
	mov	ecx,	CONSOLE_STRUCTURE_STREAM_META.SIZE
	mov	rsi,	console_stream_meta
	int	KERNEL_SERVICE

	; powrót z procedury
	ret
