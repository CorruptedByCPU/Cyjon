;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

; Use:
; nasm - http://www.nasm.us/

VARIABLE_DAEMON_IDE_IO_NAME_COUNT		equ	6
variable_daemon_ide_io_name			db	"ide io"

variable_daemon_ide_io_semaphore		db	VARIABLE_FALSE

VARIABLE_DAEMON_IDE_IO_CACHE_SIZE		equ	1
VARIABLE_DAEMON_IDE_IO_CACHE_STATUS_FREE	equ	VARIABLE_EMPTY
VARIABLE_DAEMON_IDE_IO_CACHE_STATUS_RESERVED	equ	0x01
VARIABLE_DAEMON_IDE_IO_CACHE_STATUS_PREPARED	equ	0x02
VARIABLE_DAEMON_IDE_IO_CACHE_STATUS_PROCESSING	equ	0x03
VARIABLE_DAEMON_IDE_IO_CACHE_STATUS_READY	equ	0x04
VARIABLE_DAEMON_IDE_IO_CACHE_ERROR_NO_ERROR	equ	VARIABLE_EMPTY
VARIABLE_DAEMON_IDE_IO_CACHE_ERROR_NO_DEVICE	equ	0x01
VARIABLE_DAEMON_IDE_IO_CACHE_ERROR_NO_LBA	equ	0x02
VARIABLE_DAEMON_IDE_IO_CACHE_ERROR_READ		equ	0x03
VARIABLE_DAEMON_IDE_IO_CACHE_ERROR_WRITE	equ	0x04

variable_daemon_ide_io_cache			dq	VARIABLE_EMPTY

struc	STRUCTURE_DAEMON_IDE_IO_CACHE
	.status		resb	1
	.error		resb	1
	.pid		resb	8
	.device		resb	1
	.lba		resb	8
	.data		resb	512
	.SIZE		resb	1
endstruc

; 64 Bitowy kod programu
[BITS 64]

daemon_ide_io:
	; czy dostępne są nośniki IDE?
	mov	rsi,	qword [variable_ide_disks]
	cmp	word [rsi],	VARIABLE_EMPTY
	je	irq64_process_end	; nie, wyłącz demona

	; rozmiar buforu
	mov	rcx,	VARIABLE_DAEMON_ETHERNET_CACHE_SIZE

.wait:
	; przydziel przestrzeń pod bufor
	call	cyjon_page_find_free_memory_physical
	cmp	rdi,	VARIABLE_EMPTY
	je	.wait	; brak miejsca, czekaj

	; zapisz adres
	call	cyjon_page_clear_few
	mov	qword [variable_daemon_ide_io_cache],	rdi

	; demon ethernet gotowy
	mov	byte [variable_daemon_ide_io_semaphore],	VARIABLE_TRUE

.restart:
	; ilość rekordów
	mov	rcx,	VARIABLE_DAEMON_IDE_IO_CACHE_SIZE * VARIABLE_MEMORY_PAGE_SIZE / STRUCTURE_DAEMON_IDE_IO_CACHE.SIZE

.find_request:
	; sprawdź rekord
	cmp	byte [rdi],	VARIABLE_DAEMON_IDE_IO_CACHE_STATUS_PREPARED
	je	.found

	; przesuń wskaźnik na następny rekord
	add	rdi,	STRUCTURE_DAEMON_IDE_IO_CACHE.SIZE
	loop	.find_request

	; brak poleceń w buforze, szukaj od początku
	mov	rdi,	qword [variable_daemon_ide_io_cache]

	; kontynuuj
	jmp	.restart

.found:
	; zachowaj wskaźnik polecenia i licznik
	push	rcx
	push	rdi

	; tablica dysków
	mov	rsi,	qword [variable_ide_disks]

	; rozmiar rekordu w tablicy dysków
	mov	rax,	STRUCTURE_IDE_DISK.SIZE
	xor	rdx,	rdx	; wyczyść starszą część
	mul	rbx

	; przesuń wskaźnik na rządany nośnik
	add	rsi,	rax

	; ustaw numer sektora do odczytania
	mov	rax,	qword [rdi + STRUCTURE_DAEMON_IDE_IO_CACHE.lba]

	; ilość sektorów do odczytania
	mov	rcx,	1

	; przesuń wskaźnik na miejsce docelowe odczytanego sektora
	add	rdi,	STRUCTURE_DAEMON_IDE_IO_CACHE.data

	; wykonaj polecenie
	call	ide_read_sectors

	; przesuń wskaźnik na początek polecenia
	sub	rdi,	STRUCTURE_DAEMON_IDE_IO_CACHE.data

	; oznacz polecenie jako wykonane
	mov	byte [rdi + STRUCTURE_DAEMON_IDE_IO_CACHE.status],	VARIABLE_DAEMON_IDE_IO_CACHE_STATUS_READY

	; koniec obśługi polecenia
	pop	rdi
	pop	rcx

	; kontynuuj wykonywanie pozostałych poleceń
	jmp	.find_request
