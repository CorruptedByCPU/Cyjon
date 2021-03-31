;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
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
	push	rbp
	push	rax

	; zresetuj Direction Flag
	cld

	; zresetuj rejestr zastrzeżony
	xor	ebp,	ebp

	; wyłącz Direction Flag
	cld

	; zlikwidować obiekt?
	cmp	al,	KERNEL_WM_WINDOW_close
	je	.window_close	; tak

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
	or	word [rsp + KERNEL_TASK_STRUCTURE_IRETQ.eflags + STATIC_QWORD_SIZE_byte * 0x02],	ax

	; przywróć oryginalny rejestr
	pop	rax
	pop	rbp

	; koniec obsługi przerwania programowego
	iretq

	macro_debug	"kernel_wm_irq"

;-------------------------------------------------------------------------------
; wejście:
;	rsi - wskaźnik do struktury okna
.window_close:
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
	jne	.window_close_error	; nie

	; usuń obiekt z listy
	call	kernel_wm_object_delete

	; koniec procedury
	jmp	.window_close_end

.window_close_error:
	; flaga, błąd
	stc

.window_close_end:
	; przywróć oryginalne rejestry
	pop	rsi
	pop	rbx
	pop	rax

	; koniec obsługi opcji
	jmp	kernel_wm_irq.end

	macro_debug	"kernel_wm_irq.window_close"


;-------------------------------------------------------------------------------
; wejście:
;	rsi - wskaźnik do struktury obiektu
; wyjście:
;	Flaga CF - jeśli brak wystarczającej ilości pamięci
;	rcx - identyfikator obiektu
.window_create:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rdx
	push	rdi
	push	rcx
	push	rsi

	; przygotuj przestrzeń pod dane obiektu
	mov	ecx,	dword [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.size]
	call	library_page_from_size
	call	kernel_memory_alloc
	jc	.window_create_end	; brak wystarczającej ilości pamięci

	; zachowaj wskaźnik przestrzeni jądra systemu
	push	rdi

	; przygotuj przestrzeń pod dane obiektu w procesue
	call	kernel_memory_alloc_task_secure
	jnc	.window_create_allocated	; przydzielono

.window_create_failover:
	; zwolnij zmienną lokalną
	pop	rdi

	; zwolnij przestrzeń jądra systemu
	call	kernel_memory_release

	; flaga, błąd
	stc

	; koniec obsługi procedury
	jmp	.window_create_end

.window_create_allocated:
	; mapuj przestrzeń jądra do procesu
	mov	bx,	KERNEL_PAGE_FLAG_user | KERNEL_PAGE_FLAG_write | KERNEL_PAGE_FLAG_available	; flagi przestrzeni pamięci udostępnionej
	mov	rsi,	qword [rsp]
	call	kernel_page_map_virtual
	jc	.window_create_failover	; brak miejsca na stronicowanie

	; usuń zmienną lokalną
	add	rsp,	STATIC_QWORD_SIZE_byte

	; przywróć wskaźnik do właściwości obiektu
	mov	rdx,	qword [rsp]

	; zwróć adres przestrzeni obiektu w jądrze systemu
	mov	qword [rdx + KERNEL_WM_STRUCTURE_OBJECT.address],	rsi

	; przydziel identyfikator dla okna
	call	kernel_wm_object_id_new
	mov	qword [rdx + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.id],	rcx

	; ustaw okno na środku pzrestrzeni roboczej
	call	.window_create_position

	; zarejestruj obiekt
	mov	rsi,	rdx
	call	kernel_wm_object_insert

	; oznacz obiekt jako aktywny
	mov	qword [kernel_wm_object_active_pointer],	rsi

	; zachowaj wskaźnik do przestrzeni procesu
	mov	rsi,	rdi

	; proces jest usługą?
	call	kernel_task_active
	test	word [rdi + KERNEL_TASK_STRUCTURE.flags],	KERNEL_TASK_FLAG_service
	jnz	.window_create_service	; tak

	; do procesu zwróć adres przestrzeni okna w procesie
	mov	qword [rdx + KERNEL_WM_STRUCTURE_OBJECT.address],	rsi

.window_create_service:
	; zwróć identyfikator obiektu
	mov	qword [rsp + STATIC_QWORD_SIZE_byte],	rcx

.window_create_end:
	; przywróć oryginalne rejestry
	pop	rsi
	pop	rcx
	pop	rdi
	pop	rdx
	pop	rbx
	pop	rax

	; koniec obsługi opcji
	jmp	kernel_wm_irq.end

	macro_debug	"kernel_wm_irq.window_create"

.window_create_position:
	; pozycjonuj obiekt domyślnie na środku przestrzeni roboczej

	; oś X
%ifdef	TEST_TRANSPARENCY
	mov	ax,	-1
%else
	mov	ax,	word [kernel_video_width_pixel]
	mov	bx,	word [rdx + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.width]
	shr	ax,	STATIC_DIVIDE_BY_2_shift
	shr	bx,	STATIC_DIVIDE_BY_2_shift
	sub	ax,	bx
%endif
	mov	word [rdx + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.x],	ax

	; oś Y
%ifdef	TEST_TRANSPARENCY
	mov	ax,	-1
%else
	mov	ax,	word [kernel_video_height_pixel]
	mov	bx,	word [rdx + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.height]
	shr	ax,	STATIC_DIVIDE_BY_2_shift
	shr	bx,	STATIC_DIVIDE_BY_2_shift
	sub	ax,	bx
%endif
	mov	word [rdx + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.y],	ax

	; powrót z podprocedury
	ret

;-------------------------------------------------------------------------------
; wejście:
;	rsi - wskaźnik do struktury obiektu
.window_update:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdi
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

	; zawartość danych obiektu została zmieniona?
	test	word [rbx + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_flush
	jz	.unchanged	; nie

	; zachowaj informację
	or	word [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_flush

.unchanged:
	; ilość znaków reprezentujących nazwę okna
	mov	cl,	byte [rbx + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.length]
	mov	byte [rsi + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.length],	cl

	; nazwa obiektu
	mov	ecx,	KERNEL_WM_OBJECT_NAME_length
	mov	rdi,	rsi
	add	rdi,	KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.name
	mov	rsi,	rbx
	add	rsi,	KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.name
	rep	movsb

	; zachowaj czas ostatniej modyfikacji listy
	mov	rax,	qword [driver_rtc_microtime]
	mov	qword [kernel_wm_object_list_modify_time],	rax

	; koniec procedury
	jmp	.window_flags_end

.window_flags_error:
	; flaga, błąd
	stc

.window_flags_end:
	; przywróć oryginalne rejestry
	pop	rsi
	pop	rdi
	pop	rcx
	pop	rbx
	pop	rax

	; koniec obsługi opcji
	jmp	kernel_wm_irq.end

	macro_debug	"kernel_wm_irq.window_update"
