;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

;===============================================================================
service_cero_taskbar:
	; lista obiektów została zmodyfikowana?
	mov	rax,	qword [service_desu_object_list_modify_time]
	cmp	qword [service_cero_window_taskbar_modify_time],	rax
	je	.end	; nie

	; zablokuj dostęp do modyfikacji listy obiektów
	macro_lock	service_desu_object_semaphore,	0

	; zwolnij dostęp do modyfikacji listy obiektów
	mov	byte [service_desu_object_semaphore],	STATIC_FALSE

.end:
	; powrót z procedury
	ret
