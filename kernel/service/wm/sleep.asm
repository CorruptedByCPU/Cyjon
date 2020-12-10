;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
kernel_wm_sleep:
	; brak obiektów na liście?
	cmp	qword [kernel_wm_object_list_length],	STATIC_EMPTY
	je	.end	; tak

	; kontynuuj oczekiwanie
	jmp	kernel_wm_sleep

.end:
	; powrót zprocedury
	ret

	; informacja dla Bochs
	macro_debug	"kernel_wm_sleep"
