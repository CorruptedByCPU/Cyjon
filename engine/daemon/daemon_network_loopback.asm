;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

; Use:
; nasm - http://www.nasm.us/

VARIABLE_DAEMON_NETWORK_LOOPBACK_NAME_COUNT		equ	16
variable_daemon_network_loopback_name			db	"network loopback"

; flaga, demon ethernet został prawidłowo uruchomiony
variable_daemon_network_loopback_semaphore		db	VARIABLE_FALSE

; miejsce na przetwarzane pakiety
VARIABLE_DAEMON_NETWORK_LOOPBACK_CACHE_SIZE		equ	8	; max 256
VARIABLE_DAEMON_NETWORK_LOOPBACK_CACHE_FLAG_EMPTY	equ	0x00
VARIABLE_DAEMON_NETWORK_LOOPBACK_CACHE_FLAG_READY	equ	0x01
variable_daemon_network_loopback_cache			dq	VARIABLE_EMPTY

struc	STRUCTURE_DAEMON_NETWORK_LOOPBACK_CACHE
	.flag	resb	1
	.data	resb	VARIABLE_MEMORY_PAGE_SIZE - VARIABLE_BYTE_SIZE
	.SIZE	resb	1
endstruc

; 64 Bitowy kod programu
[BITS 64]

daemon_network_loopback:
	; rozmiar buforu
	mov	rcx,	VARIABLE_DAEMON_NETWORK_LOOPBACK_CACHE_SIZE

.wait:
	; przydziel przestrzeń pod bufor pakietów przychodzących
	call	cyjon_page_find_free_memory_physical
	cmp	rdi,	VARIABLE_EMPTY
	je	.wait	; brak miejsca, czekaj

	; zapisz adres
	call	cyjon_page_clear_few
	mov	qword [variable_daemon_network_loopback_cache],	rdi

	; demon ethernet gotowy
	mov	byte [variable_daemon_network_loopback_semaphore],	VARIABLE_TRUE

.in_restart:
	; ilość możliwych pakietów przechowywanych w buforze
	mov	rcx,	VARIABLE_DAEMON_NETWORK_LOOPBACK_CACHE_SIZE * VARIABLE_MEMORY_PAGE_SIZE / STRUCTURE_DAEMON_NETWORK_LOOPBACK_CACHE.SIZE

	; wskaźnik do bufora
	mov	rsi,	qword [variable_daemon_network_loopback_cache]

.in_search:
	; przeszukaj bufor za pakietem
	cmp	byte [rsi + STRUCTURE_DAEMON_NETWORK_LOOPBACK_CACHE.flag],	 VARIABLE_DAEMON_NETWORK_LOOPBACK_CACHE_FLAG_READY
	je	.in_found

.in_continue:
	; następny rekord
	add	rsi,	STRUCTURE_DAEMON_NETWORK_LOOPBACK_CACHE.SIZE
	loop	.in_search

	; brak pakietów przychodzących

	; sprawdź bufor od początku
	jmp	.in_restart

.in_found:
	; zachowaj licznik
	push	rcx

	; zachowaj wskaźnik do pakietu
	push	rsi

	; TODO
	; wywalać z przestrzeni bufora, polecenia przeterminowane

.mismatch:
	; przywróć wskaźnik do pakietu
	pop	rsi

	; zwolnij rekord
	mov	byte [rsi + STRUCTURE_DAEMON_NETWORK_LOOPBACK_CACHE.flag],	VARIABLE_DAEMON_NETWORK_LOOPBACK_CACHE_FLAG_EMPTY

	; przywróć licznik rekordów
	pop	rcx

	; kontynuj przetwarzanie kolejnych pakietów
	jmp	.in_continue
