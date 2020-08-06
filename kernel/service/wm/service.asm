;===============================================================================
; Copyright (C) by blackdev.org
;===============================================================================

;===============================================================================
; wejście:
;	ax - numer procedury do wykoania
;	rsi - wskaźnik do właściwości obiektu
kernel_wm_irq:
	; menedżer gotów na przetwarzenie zgłoszeń?
	cmp	byte [kernel_wm_semaphore],	STATIC_FALSE
	je	kernel_wm_irq	; nie, czekaj

	; zachowaj oryginalne rejestry
	push	rax

	; wyłącz Direction Flag
	cld

	; zarejestrować nowy obiekt?
	cmp	al,	KERNEL_WM_WINDOW_create
	je	.window_create	; tak

	; aktualizacja właściwości obiektu?
	cmp	al,	KERNEL_WM_WINDOW_update
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

	macro_debug	"kernel_wm_irq"

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
	mov	rcx,	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.size]
	call	library_page_from_size
	call	kernel_memory_alloc

	; zwróć adres przestrzeni okna
	mov	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.address],	rdi

	; oznacz przesterzeń jako dostępną dla procesu
	call	kernel_memory_mark

	; przydziel identyfikator dla okna
	call	kernel_wm_object_id_new
	mov	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.id],	rcx

	; zarejestruj obiekt
	call	kernel_wm_object_insert

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi

	; koniec obsługi opcji
	jmp	kernel_wm_irq.end

	macro_debug	"kernel_wm_irq.window_create"

;-------------------------------------------------------------------------------
; wejście:
;	rsi - wskaźnik do struktury obiektu
.window_update:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rsi

	; odszukaj obiekt o danym identyfikatorze
	mov	rbx,	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.id]
	call	kernel_wm_object_by_id

	; pobierz PID procesu
	call	kernel_task_active_pid

	; obiekt należy do procesu?
	cmp	rax,	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.pid]
	jne	.window_flags_error	; nie

	; aktualizuj właściwości okna
	mov	rbx,	qword [rsp]

	; ; pozycja na osi X
	; mov	rax,	qword [rbx + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.x]
	; mov	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.x],	rax

	; ; pozycja na osi Y
	; mov	rax,	qword [rbx + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.y]
	; mov	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.y],	rax

	; flagi
	mov	rax,	qword [rbx + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags]
	mov	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	rax

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
	jmp	kernel_wm_irq.end

	macro_debug	"kernel_wm_irq.window_update"
