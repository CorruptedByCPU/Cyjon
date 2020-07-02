;===============================================================================
; Copyright (C) by vLock.dev
;===============================================================================

kernel_init_stream:
	; przygotuj miejsce pod pustą tablicę potoków
	call	kernel_memory_alloc_page
	call	kernel_page_drain

	; zachowaj adres tablicy potoków
	mov	qword [kernel_stream_address],	rdi
