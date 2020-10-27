;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

KERNEL_IPC_SIZE_page_default	equ	1
KERNEL_IPC_ENTRY_limit		equ	(KERNEL_IPC_SIZE_page_default << STATIC_PAGE_SIZE_shift) / KERNEL_IPC_STRUCTURE.SIZE

KERNEL_IPC_TTL_default		equ	DRIVER_RTC_Hz / 10	; ~100ms

kernel_ipc_semaphore		db	STATIC_FALSE
kernel_ipc_base_address		dq	STATIC_EMPTY
kernel_ipc_entry_count		dq	STATIC_EMPTY

;===============================================================================
; wejście:
;	rbx - PID procesu docelowego
;	ecx - rozmiar przestrzeni w Bajtach lub jeśli wartość pusta, 40 Bajtów z pozycji wskaźnika RSI
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

.retry:
	; uzyskaj dostęp do listy komunikatów
	macro_lock	kernel_ipc_semaphore, 0

	; pobierz aktualny czas systemu
	mov	rax,	qword [driver_rtc_microtime]

	; ilość dostępnych wpisów na liście
	mov	rcx,	KERNEL_IPC_ENTRY_limit

	; ustaw wskaźnik na początek listy
	mov	rdi,	qword [kernel_ipc_base_address]

.loop:
	; wpis przeterminowany?
	cmp	rax,	qword [rdi + KERNEL_IPC_STRUCTURE.ttl]
	ja	.found	; tak

	; przesuń wskaźnik na następny wpis
	add	rdi,	KERNEL_IPC_STRUCTURE.SIZE

	; sprawdzić następny wpis?
	dec	rcx
	jnz	.loop	; tak

	; zwolnij dostęp do listy komunikatów
	mov	byte [kernel_ipc_semaphore],	STATIC_FALSE

	; sprawdź raz jeszcze
	jmp	.retry

.found:
	; ustaw PID nadawcy
	mov	qword [rdi + KERNEL_IPC_STRUCTURE.pid_source],	rdx

	; ustaw PID odbiorcy
	mov	qword [rdi + KERNEL_IPC_STRUCTURE.pid_destination],	rbx

	; typ wiadomości
	mov	bl,	byte [rsi + KERNEL_IPC_STRUCTURE.type]
	mov	byte [rdi + KERNEL_IPC_STRUCTURE.type],	bl

	; przywróć oryginalny rejestr
	mov	rcx,	qword [rsp]

	; rozmiar przestrzeni danych pusty?
	test	rcx,	rcx
	jz	.load	; tak, uzupełnij komunikat danymi z wskaźnika RSI

	; ustaw rozmiar danych przestrzeni
	mov	qword [rdi + KERNEL_IPC_STRUCTURE.size],	rcx

	; ustaw wskaźnik do przestrzeni danych
	mov	qword [rdi + KERNEL_IPC_STRUCTURE.pointer],	rsi

	; koniec tworzenia wiadomości do procesu
	jmp	.end

.load:
	; zachowaj wskaźnik początku wpisu
	push	rdi

	; załaduj treść wiadomości
	mov	ecx,	KERNEL_IPC_STRUCTURE.SIZE - KERNEL_IPC_STRUCTURE.data
	add	rsi,	KERNEL_IPC_STRUCTURE.data
	add	rdi,	KERNEL_IPC_STRUCTURE.data
	rep	movsb

	; przywróć wskaźnik początku wpisu
	pop	rdi

.end:
	; ilość wiadomości na liście
	inc	qword [kernel_ipc_entry_count]

	; ustaw czas przedawnienia wiadomości
	add	rax,	KERNEL_IPC_TTL_default
	mov	qword [rdi + KERNEL_IPC_STRUCTURE.ttl],	rax

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
	call	kernel_task_active_pid

	; ilość dostępnych wpisów na liście
	mov	rcx,	KERNEL_IPC_ENTRY_limit

	; ustaw wskaźnik na początek listy
	mov	rsi,	qword [kernel_ipc_base_address]

	; pobierz aktualny czas systemu
	mov	rdi,	qword [driver_rtc_microtime]

.loop:
	; wpis dla procesu?
	cmp	qword [rsi + KERNEL_IPC_STRUCTURE.pid_destination],	rax
	jne	.next	; nie

	; wiadomość przeterminowana?
	cmp	rdi,	qword [rsi + KERNEL_IPC_STRUCTURE.ttl]
	jbe	.found	; nie

.next:
	; przesuń wskaźnik na następny wpis
	add	rsi,	KERNEL_IPC_STRUCTURE.SIZE

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
	mov	ecx,	KERNEL_IPC_STRUCTURE.SIZE
	mov	rdi,	qword [rsp]
	rep	movsb

	; zwolnij wpis na liście
	mov	qword [rsi - KERNEL_IPC_STRUCTURE.SIZE],	STATIC_EMPTY

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
