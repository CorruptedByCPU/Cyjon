;===============================================================================
; Copyright (C) by vLock.dev
;===============================================================================

;===============================================================================
service_desu_cursor:
	; zachowaj oryginalne rejestry
	push	rsi

	;-----------------------------------------------------------------------
	; wyświetlić nową zawartość macierzy kursora?
	;-----------------------------------------------------------------------
	test	qword [service_desu_object_cursor + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags],	SERVICE_DESU_OBJECT_FLAG_flush
	jz	.no	; nie

	; zarejestruj strefę kursora
	mov	rsi,	service_desu_object_cursor
	call	service_desu_fill_insert_by_object
	call	service_desu_fill

	; obiekt kursora został wyświetlony
	and	qword [service_desu_object_cursor + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags],	~SERVICE_DESU_OBJECT_FLAG_flush

.no:
	; przywróć oryginalne rejestry
	pop	rsi

	; powrót z procedury
	ret

	macro_debug	"service_desu_cursor"
