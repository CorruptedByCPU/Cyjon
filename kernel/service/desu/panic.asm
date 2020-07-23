;===============================================================================
; Copyright (C) by blackdev.org
;===============================================================================

service_desu_string_error_memory_low	db	"DESU: no enough memory."
service_desu_string_error_memory_low_end:

;===============================================================================
service_desu_panic_memory_low:
	; wyświetl komunikat błędu
	mov	ecx,	service_desu_string_error_memory_low_end - service_desu_string_error_memory_low
	mov	rsi,	service_desu_string_error_memory_low
	call	kernel_video_string

	; zatrzymaj dalszą pracę usługi
	jmp	$
