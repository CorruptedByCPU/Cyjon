;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

;===============================================================================
; wejście:
;	ax - numer procedury do wykoania
;	rsi - wskaźnik do właściwości obiektu
service_desu_irq:
	; menedżer gotów na przetwarzenie zgłoszeń?
	cmp	byte [service_desu_semaphore],	STATIC_FALSE
	je	service_desu_irq	; nie, czekaj

	; zachowaj oryginalne rejestry
	push	rax

	; wyłącz Direction Flag
	cld

	; zarejestrować nowy obiekt?
	cmp	al,	SERVICE_DESU_WINDOW_create
	je	.window_create	; tak

	; aktualizacja właściwości obiektu?
	cmp	al,	SERVICE_DESU_WINDOW_update
	je	.window_update	; tak

.error:
	; flaga, błąd
	stc

.end:
	; pobierz aktualne flagi procesora
	pushf
	pop	rax

	; zwróć flagi do procesu (usuń które nie biorą udziału w komunikacji)
	and	ax,	KERNEL_TASK_EFLAGS_cf | KERNEL_TASK_EFLAGS_zf
	or	word [rsp + KERNEL_TASK_STRUCTURE_IRETQ.eflags + STATIC_QWORD_SIZE_byte],	ax

	; przywróć oryginalny rejestr
	pop	rax

	; koniec obsługi przerwania programowego
	iretq

	macro_debug	"service_desu_irq"

;-------------------------------------------------------------------------------
; wejście:
;	rsi - wskaźnik do struktury obiektu
; wyjście:
;	rcx - identyfikator obiektu
.window_create:
	; zachowaj oryginalne rejestry
	push	rsi
	push	rdi

	; przygotuj przestrzeń pod dane obiektu
	mov	rcx,	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.size]
	call	library_page_from_size
	call	kernel_memory_alloc

	; zwróć adres przestrzeni okna
	mov	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.address],	rdi

	; oznacz przesterzeń jako dostępną dla procesu
	call	kernel_memory_mark

	; przydziel identyfikator dla okna
	call	service_desu_object_id_new
	mov	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.id],	rcx

	; zarejestruj obiekt
	call	service_desu_object_insert

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi

	; koniec obsługi opcji
	jmp	service_desu_irq.end

	macro_debug	"service_desu_irq.window_create"

;-------------------------------------------------------------------------------
; wejście:
;	rsi - wskaźnik do struktury obiektu
.window_update:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rsi

	; odszukaj obiekt o danym identyfikatorze
	mov	rbx,	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.id]
	call	service_desu_object_by_id

	; pobierz PID procesu
	call	kernel_task_active_pid

	; obiekt należy do procesu?
	cmp	rax,	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.pid]
	jne	.window_flags_error	; nie

	; aktualizuj właściwości okna
	mov	rbx,	qword [rsp]

	; pozycja na osi X
	mov	rax,	qword [rbx + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.x]
	mov	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.x],	rax

	; pozycja na osi Y
	mov	rax,	qword [rbx + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.y]
	mov	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.y],	rax

	; flagi
	mov	rax,	qword [rbx + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags]
	mov	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags],	rax

	; koniec procedury
	jmp	.window_flags_end

.window_flags_error:
	; flaga, błąd
	stc

.window_flags_end:
	; przywróć oryginalne rejestry
	pop	rsi
	pop	rbx
	pop	rax

	; koniec obsługi opcji
	jmp	service_desu_irq.end

	macro_debug	"service_desu_irq.window_update"
