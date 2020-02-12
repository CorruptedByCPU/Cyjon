;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

KERNEL_IPC_SIZE_page_default	equ	1
KERNEL_IPC_ENTRY_limit		equ	(KERNEL_IPC_SIZE_page_default << KERNEL_PAGE_SIZE_shift) / KERNEL_IPC_STRUCTURE_LIST.SIZE

KERNEL_IPC_TTL_default		equ	DRIVER_RTC_Hz / 10	; ~100ms

struc	KERNEL_IPC_STRUCTURE_LIST
	.ttl			resb	8
	.pid_source		resb	8
	.pid_destination	resb	8
	.data:
	.size			resb	8
	.pointer		resb	8
	.other			resb	24
	.SIZE:
endstruc

kernel_ipc_semaphore		db	STATIC_FALSE
kernel_ipc_base_address		dq	STATIC_EMPTY
kernel_ipc_entry_count		dq	STATIC_EMPTY

;===============================================================================
; wejście:
;	rbx - PID procesu docelowego
;	ecx - rozmiar przestrzeni w Bajtach lub jeśli wartość pusta, 32 Bajty z pozycji wskaźnika RSI
;	rsi - wskaźnik do przestrzeni danych
kernel_ipc_insert:
	; zachowaj oryginalne rejestry
	push	rax
	push	rdx
	push	rsi
	push	rdi
	push	rcx

	; pobierz PID procesu wywołującego
	call	kernel_task_active
	mov	rdx,	qword [rdi + KERNEL_TASK_STRUCTURE.pid]

	; uzyskaj dostęp do listy komunikatów
	macro_close	kernel_ipc_semaphore, 0

.wait:
	; brak miejsca na liście?
	cmp	qword [kernel_ipc_entry_count],	KERNEL_IPC_ENTRY_limit
	je	.wait	; czekaj na zwolnienie przynajmniej jednego miejsca

.reload:
	; pobierz aktualny czas systemu
	mov	rax,	qword [driver_rtc_microtime]

	; ilość dostępnych wpisów na liście
	mov	rcx,	KERNEL_IPC_ENTRY_limit

	; ustaw wskaźnik na początek listy
	mov	rdi,	qword [kernel_ipc_base_address]

.loop:
	; wpis przeterminowany?
	cmp	rax,	qword [rdi + KERNEL_IPC_STRUCTURE_LIST.ttl]
	ja	.found	; tak

	; przesuń wskaźnik na następny wpis
	add	rdi,	KERNEL_IPC_STRUCTURE_LIST.SIZE

	; koniec miejsca?
	dec	rcx
	jz	.loop	; tak

	; powrót do pętli głównej
	jmp	.reload

.found:
	; ustaw PID nadawcy
	mov	qword [rdi + KERNEL_IPC_STRUCTURE_LIST.pid_source],	rdx

	; ustaw PID odbiorcy
	mov	qword [rdi + KERNEL_IPC_STRUCTURE_LIST.pid_destination],	rbx

	; przywróć oryginalny rejestr
	mov	rcx,	qword [rsp]

	; rozmiar przestrzeni danych pusty?
	test	rcx,	rcx
	jz	.load	; tak, uzupełnij komunikat danymi z wskaźnika RSI

	; ustaw rozmiar danych przestrzeni
	mov	qword [rdi + KERNEL_IPC_STRUCTURE_LIST.size],	rcx

	; ustaw wskaźnik do przestrzeni danych
	mov	qword [rdi + KERNEL_IPC_STRUCTURE_LIST.pointer],	rsi

	; koniec tworzenia wiadomości do procesu
	jmp	.end

.load:
	; zachowaj wskaźnik początku wpisu
	push	rdi

	; załaduj treść wiadomości
	mov	ecx,	KERNEL_IPC_STRUCTURE_LIST.SIZE - KERNEL_IPC_STRUCTURE_LIST.data
	add	rdi,	KERNEL_IPC_STRUCTURE_LIST.data
	rep	movsb

	; przywróć wskaźnik początku wpisu
	pop	rdi

.end:
	; ilość wiadomości na liście
	inc	qword [kernel_ipc_entry_count]

	; ustaw czas przedawnienia wiadomości
	add	rax,	KERNEL_IPC_TTL_default
	mov	qword [rdi + KERNEL_IPC_STRUCTURE_LIST.ttl],	rax

	; zwolnij dostęp
	mov	byte [kernel_ipc_semaphore],	STATIC_FALSE

	; przywróć oryginalne rejestry
	pop	rcx
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rax

	; powrót z procedury
	ret

	; informacja dla Bochs
	macro_debug	"kernel_ipc_insert"

;===============================================================================
; wejście:
;	rdi - wskaźnik do miejsca docelowego
; wyjście:
;	Flaga CF jeśli brak wiadomości
kernel_ipc_receive:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rsi
	push	rdi

	; istnieją komunikaty na liście?
	cmp	qword [kernel_ipc_entry_count],	STATIC_EMPTY
	je	.empty	; nie

	; pobierz PID procesu wywołującego
	call	kernel_task_active
	mov	rax,	qword [rdi + KERNEL_TASK_STRUCTURE.pid]

	; ilość dostępnych wpisów na liście
	mov	rcx,	KERNEL_IPC_ENTRY_limit

	; ustaw wskaźnik na początek listy
	mov	rsi,	qword [kernel_ipc_base_address]

	; pobierz aktualny czas systemu
	mov	rdi,	qword [driver_rtc_microtime]

.loop:
	; wpis dla procesu?
	cmp	qword [rsi + KERNEL_IPC_STRUCTURE_LIST.pid_destination],	rax
	jne	.next	; nie

	; wiadomość przeterminowana?
	cmp	rdi,	qword [rsi + KERNEL_IPC_STRUCTURE_LIST.ttl]
	jbe	.found	; nie

.next:
	; przesuń wskaźnik na następny wpis
	add	rsi,	KERNEL_IPC_STRUCTURE_LIST.SIZE

	; pozostały wpisy do przejrzenia?
	dec	rcx
	jnz	.loop	; tak

	; brak wiadomości dla procesu

.empty:
	; flaga, błąd
	stc

	; koniec procedury
	jmp	.error

.found:
	; prześlij komunikat do przestrzeni procesu
	mov	ecx,	KERNEL_IPC_STRUCTURE_LIST.SIZE
	mov	rdi,	qword [rsp]
	rep	movsb

	; zwolnij wpis na liście
	mov	qword [rsi - KERNEL_IPC_STRUCTURE_LIST.SIZE],	STATIC_EMPTY

	; ilość komunikatów na liście
	dec	qword [kernel_ipc_entry_count]

	; flaga, sukces
	clc

.error:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

	; informacja dla Bochs
	macro_debug	"kernel_ipc_receive"
