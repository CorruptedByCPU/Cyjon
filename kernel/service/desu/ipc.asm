;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

;===============================================================================
; wejście:
;	cl - identyfikator komunikatu
;	rsi - wskaźnik obiektu zależnego
service_desu_ipc:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rsi

	; pobierz ID okna i PID
	mov	rax,	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.id]
	mov	rbx,	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.pid]

	; zamień pozycję wskaźnika kursora na pośrednią (względem okna)
	sub	r8,	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.x]
	sub	r9,	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.y]

	; skomponuj komunikat dla procesu
	mov	rsi,	service_desu_ipc_data

	; wyślij informacje o typie akcji
	mov	byte [rsi + SERVICE_DESU_STRUCTURE_IPC.type],	cl

	; wyślij informacje o ID okna biorącego udział
	mov	qword [rsi + SERVICE_DESU_STRUCTURE_IPC.id],	rax

	; wyślij informacje o pozycji wskaźnika kursora
	mov	qword [rsi + SERVICE_DESU_STRUCTURE_IPC.value0],	r8	; x
	mov	qword [rsi + SERVICE_DESU_STRUCTURE_IPC.value1],	r9	; y

	; wyślij komunikat
	xor	ecx,	ecx	; standardowy rozmiar komunikatu pod adresem w rejestrze RSI
	call	kernel_ipc_insert

	; przywróć oryginalne rejestry
	pop	rsi
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"service_desu_ipc"
