;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
ls_init:
	; wyłącz wirtualny kursor (nie jest potrzebny, program nie wchodzi w interakcje, oszczędzamy czas procesora)
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	ls_string_init_end - ls_string_init
	mov	rsi,	ls_string_init
	int	KERNEL_SERVICE
