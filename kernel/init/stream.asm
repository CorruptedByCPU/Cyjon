;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

kernel_init_stream:
	; przygotuj miejsce pod pustą tablicę potoków
	call	kernel_memory_alloc_page
	call	kernel_page_drain

	; zachowaj adres tablicy potoków
	mov	qword [kernel_stream_address],	rdi

	; ustaw wskaźnik następnego fragmentu tablicy na początek
	mov	qword [rdi + STATIC_STRUCTURE_BLOCK.link],	rdi

	; przygotuj domyślny potok wyjściowy (stdout, stderr, stdlog)
	call	kernel_stream

	; zachowaj wskaźnik do domyślnego potoku wyjściowego
	mov	qword [kernel_stream_out_default],	rbx
