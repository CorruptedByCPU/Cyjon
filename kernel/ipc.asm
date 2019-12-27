;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

KERNEL_IPC_SIZE_page_default	equ	1
KERNEL_IPC_ENTRY_limit		equ	(KERNEL_IPC_SIZE_page_default << KERNEL_PAGE_SIZE_shift) / KERNEL_IPC_STRUCTURE_LIST.SIZE

KERNEL_IPC_TTL_default		equ	DRIVER_RTC_Hz / 100	; ~10ms

struc	KERNEL_IPC_STRUCTURE_LIST
	.ttl			resb	8
	.pid_source		resb	8
	.pid_destination	resb	8
	.size			resb	8
	.pointer		resb	8
	.data			resb	32
	.SIZE:
endstruc

kernel_ipc_semaphore		db	STATIC_FALSE
kernel_ipc_base_address		dq	STATIC_EMPTY
kernel_ipc_entry_count		dw	STATIC_EMPTY

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

	; uzyskaj dostęp do listy komunikatów
	macro_close	kernel_ipc_semaphore, 0

	; pobierz PID procesu wywołującego
	call	kernel_task_active
	mov	rdx,	qword [rdi + KERNEL_STRUCTURE_TASK.pid]

	; ustaw wskaźnik na początek listy
	mov	rdi,	qword [kernel_ipc_base_address]

.reload:
	; maksymalna ilość wpisów na liście
	mov	ecx,	KERNEL_IPC_ENTRY_limit

.search:
	; wpis przedawniony?
	mov	rax,	qword [driver_rtc_microtime]
	cmp	qword [rdi + KERNEL_IPC_STRUCTURE_LIST.ttl],	rax
	jb	.found	; tak, zastąp

	; wolny wpis?
	cmp	qword [rdi + KERNEL_IPC_STRUCTURE_LIST.ttl],	STATIC_EMPTY
	je	.found	; znaleziono

	; prdesuń wskaźnik na następny wpis
	add	rdi,	KERNEL_IPC_STRUCTURE_LIST.SIZE

	; pozostały wpisy do przejrzenia?
	dec	rcx
	jnz	.search	; tak

	; przesuń wskaźnik na następny blok danych listy
	and	di,	KERNEL_PAGE_mask
	mov	rdi,	qword [rdi + STATIC_STRUCTURE_BLOCK.link]

	; przetwórz następny blok
	jmp	.reload

.found:
	; ustaw czas przedawnienia wiadomości
	add	rax,	KERNEL_IPC_TTL_default
	mov	qword [rdi + KERNEL_IPC_STRUCTURE_LIST.ttl],	rax

	; ustaw PID nadawcy
	mov	qword [rdi + KERNEL_IPC_STRUCTURE_LIST.pid_source],	rdx

	; ustaw PID odbiorcy
	mov	qword [rdi + KERNEL_IPC_STRUCTURE_LIST.pid_destination],	rbx

	; brak przestrzeni do przekazania?
	mov	rcx,	qword [rsp]
	test	rcx,	rcx
	jz	.only_data	; tak

	; ustaw rozmiar i wskaźnik do przestrzeni danych
	mov	qword [rdi + KERNEL_IPC_STRUCTURE_LIST.size],	rcx
	mov	qword [rdi + KERNEL_IPC_STRUCTURE_LIST.pointer],	rsi

	; załadowano wiadomość
	jmp	.end

.only_data:
	; załaduj treść wiadomości
	mov	ecx,	KERNEL_IPC_STRUCTURE_LIST.SIZE - KERNEL_IPC_STRUCTURE_LIST.data
	add	rdi,	KERNEL_IPC_STRUCTURE_LIST.data
	rep	movsb

.end:
	; ilość wiadomości na liście
	inc	qword [kernel_ipc_entry_count]

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

	; pobierz PID procesu wywołującego
	call	kernel_task_active
	mov	rax,	qword [rdi + KERNEL_STRUCTURE_TASK.pid]

	; ustaw wskaźnik na początek listy
	mov	rsi,	qword [kernel_ipc_base_address]

.reload:
	; maksymalna ilość wiadomości na liście
	mov	ecx,	KERNEL_IPC_ENTRY_limit

.search:
	; szukaj wpisu przeznaczonego procesowi
	cmp	qword [rsi + KERNEL_IPC_STRUCTURE_LIST.pid_destination],	rax
	je	.found	; znaleziono

.next:
	; przesuń wskaźnik na następny wpis
	add	rsi,	KERNEL_IPC_STRUCTURE_LIST.SIZE

	; pozostały wpisy do przejrzenia?
	dec	rcx
	jnz	.search	; tak

	; brak wiadomości dla procesu

	; flaga, błąd
	stc

	; koniec procedury
	jmp	.error

.found:
	; wiadomość przeterminowana?
	mov	rax,	qword [driver_rtc_microtime]
	cmp	qword [rsi + KERNEL_IPC_STRUCTURE_LIST.ttl],	rax
	jb	.next	; tak, znajdź następną

	; uzyskaj wyłączny dostęp do listy komunikatów
	macro_close	kernel_ipc_semaphore, 0

	; zachowaj wskaźnik początku wpisu
	push	rsi

	; odbierz treść komunikatu
	mov	ecx,	KERNEL_IPC_STRUCTURE_LIST.SIZE
	mov	rdi,	qword [rsp + STATIC_QWORD_SIZE_byte]
	rep	movsb

	; przywróć wskaźnik do początku wpisu
	pop	rsi

	; zwróć informacje o właścicielu wiadomości
	mov	rbx,	qword [rsi + KERNEL_IPC_STRUCTURE_LIST.pid_source]

	; zwolnij wpis ustawiając TTL na przedawniony
	mov	qword [rsi + KERNEL_IPC_STRUCTURE_LIST.ttl],	STATIC_EMPTY

	; ilość komunikatów na liście
	dec	qword [kernel_ipc_entry_count]

	; zwolnij dostęp
	mov	byte [kernel_ipc_semaphore],	STATIC_FALSE

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
