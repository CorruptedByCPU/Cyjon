;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

;===============================================================================
service_desu_sleep:
	; brak obiektów na liście?
	cmp	qword [service_desu_object_list_records],	STATIC_EMPTY
	je	.end	; tak

	; kontynuuj oczekiwanie
	jmp	service_desu_sleep

.end:
	; powrót zprocedury
	ret

	; informacja dla Bochs
	macro_debug	"service DESU sleep"
