;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

;===============================================================================
kernel_init_panic_low_memory:
	; ustaw komunikat błędu: brak wystarczającej ilości pamięci RAM
	mov	ecx,	kernel_init_string_error_memory_low_end - kernel_init_string_error_memory_low
	mov	esi,	kernel_init_string_error_memory_low

	; wyświetl
	jmp	kernel_panic
