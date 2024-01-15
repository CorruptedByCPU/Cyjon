;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

; Use:
; nasm - http://www.nasm.us/

VARIABLE_DAEMON_ETHERNET_NAME_COUNT		equ	16
variable_daemon_ethernet_name			db	"network ethernet"

; flaga, demon ethernet został prawidłowo uruchomiony
variable_daemon_ethernet_semaphore		db	VARIABLE_FALSE

; miejsce na przetwarzane pakiety
VARIABLE_DAEMON_ETHERNET_CACHE_SIZE		equ	8	; max 256
VARIABLE_DAEMON_ETHERNET_CACHE_FLAG_EMPTY	equ	0x00
VARIABLE_DAEMON_ETHERNET_CACHE_FLAG_READY	equ	0x01
variable_daemon_ethernet_cache			dq	VARIABLE_EMPTY

struc	STRUCTURE_DAEMON_ETHERNET_CACHE
	.flag	resb	1
	.data	resb	VARIABLE_MEMORY_PAGE_SIZE - VARIABLE_BYTE_SIZE
	.SIZE	resb	1
endstruc

; 64 Bitowy kod programu
[BITS 64]

daemon_ethernet:
	; usługa sieciowa załączona?
	cmp	byte [variable_network_enabled],	VARIABLE_FALSE
	je	daemon_ethernet	; czekaj

	; rozmiar buforu
	mov	rcx,	VARIABLE_DAEMON_ETHERNET_CACHE_SIZE

.wait:
	; przydziel przestrzeń pod bufor pakietów przychodzących
	call	cyjon_page_find_free_memory_physical
	cmp	rdi,	VARIABLE_EMPTY
	je	.wait	; brak miejsca, czekaj

	; zapisz adres
	call	cyjon_page_clear_few
	mov	qword [variable_daemon_ethernet_cache],	rdi

	; demon ethernet gotowy
	mov	byte [variable_daemon_ethernet_semaphore],	VARIABLE_TRUE

	; najpierw wyślij pakiety z bufora wyjściowego

.restart:
	; ilość możliwych pakietów przechowywanych w buforze
	mov	rcx,	VARIABLE_DAEMON_ETHERNET_CACHE_SIZE * VARIABLE_MEMORY_PAGE_SIZE / STRUCTURE_DAEMON_ETHERNET_CACHE.SIZE

	; wskaźnik do bufora
	mov	rsi,	qword [variable_daemon_ethernet_cache]

.search:
	; przeszukaj bufor za pakietem
	cmp	byte [rsi + STRUCTURE_DAEMON_ETHERNET_CACHE.flag],	 VARIABLE_DAEMON_ETHERNET_CACHE_FLAG_READY
	je	.found

.continue:
	; następny rekord
	add	rsi,	STRUCTURE_DAEMON_ETHERNET_CACHE.SIZE
	loop	.search

	; brak pakietów przychodzących

	; sprawdź bufor od początku
	jmp	.restart

.found:
	; zachowaj licznik
	push	rcx

	; zachowaj wskaźnik do pakietu
	push	rsi

	; przesuń wskaźnik za flagę
	add	rsi,	STRUCTURE_DAEMON_ETHERNET_CACHE.data

	; ramka Ethernet zawiera dane pakietu ARP?
	cmp	word [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_FIELD_TYPE],	VARIABLE_NETWORK_FRAME_ETHERNET_FIELD_TYPE_ARP
	je	.arp

	; ramka Ethernet zawiera dane pakietu IP?
	cmp	word [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_FIELD_TYPE],	VARIABLE_NETWORK_FRAME_ETHERNET_FIELD_TYPE_IP
	je	.ip

.mismatch:
	; przywróć wskaźnik do pakietu
	pop	rsi

	; zwolnij rekord
	mov	byte [rsi + STRUCTURE_DAEMON_ETHERNET_CACHE.flag],	VARIABLE_DAEMON_ETHERNET_CACHE_FLAG_EMPTY

	; przywróć licznik rekordów
	pop	rcx

	; kontynuj przetwarzanie kolejnych pakietów
	jmp	.continue

;-------------------------------------------------------------------------------
.arp:
	; przesuń wskaźnik na dane ramki ARP
	add	rsi,	VARIABLE_NETWORK_FRAME_ETHERNET_SIZE

	; Hardware Type
	cmp	word [rsi + VARIABLE_NETWORK_FRAME_ARP_FIELD_HTYPE],	VARIABLE_NETWORK_FRAME_ARP_FIELD_HTYPE_ETHERNET
	jne	.mismatch

	; Protocol Type
	cmp	word [rsi + VARIABLE_NETWORK_FRAME_ARP_FIELD_PTYPE],	VARIABLE_NETWORK_FRAME_ARP_FIELD_PTYPE_IPV4
	jne	.mismatch

	; Hardware Length / HAL
	cmp	byte [rsi + VARIABLE_NETWORK_FRAME_ARP_FIELD_HAL],	VARIABLE_NETWORK_FRAME_ARP_FIELD_HAL_MAC
	jne	.mismatch

	; Protocol Length / PAL
	cmp	byte [rsi + VARIABLE_NETWORK_FRAME_ARP_FIELD_PAL],	VARIABLE_NETWORK_FRAME_ARP_FIELD_PAL_IPV4
	jne	.mismatch

	; Request
	cmp	word [rsi + VARIABLE_NETWORK_FRAME_ARP_FIELD_OPCODE],	VARIABLE_NETWORK_FRAME_ARP_FIELD_OPCODE_REQUEST
	jne	.mismatch

	; czy zapytanie dotyczny naszego IP?
	mov	eax,	dword [rsi + VARIABLE_NETWORK_FRAME_ARP_FIELD_TARGET_IP]
	cmp	eax,	dword [variable_network_ip]
	jne	.mismatch	; nie, zignoruj

	; modyfikuj ramkę ARP---------------------------------------------------

	; zamień miejscami adresy IP nadawcy i odbiorcy+MAC
	mov	rax,	qword [rsi + VARIABLE_NETWORK_FRAME_ARP_FIELD_SENDER_MAC]
	push	rax	; zapamiętaj nadawcę
	mov	bx,	word [rsi + VARIABLE_NETWORK_FRAME_ARP_FIELD_SENDER_MAC + VARIABLE_QWORD_SIZE]
	xchg	rax,	qword [rsi + VARIABLE_NETWORK_FRAME_ARP_FIELD_TARGET_MAC]
	xchg	bx,	word [rsi + VARIABLE_NETWORK_FRAME_ARP_FIELD_TARGET_MAC + VARIABLE_QWORD_SIZE]
	mov	word [rsi + VARIABLE_NETWORK_FRAME_ARP_FIELD_SENDER_MAC + VARIABLE_QWORD_SIZE],	bx

	; zmień typ operacji na odpowiedź
	mov	word [rsi + VARIABLE_NETWORK_FRAME_ARP_FIELD_OPCODE],	VARIABLE_NETWORK_FRAME_ARP_FIELD_OPCODE_REPLY

	; w odpowiedzi podaj nasz adres MAC
	mov	rdx,	qword [variable_network_mac_filter]
	not	rdx
	pop	rax
	and	rax,	rdx
	or	rax,	qword [variable_network_i8254x_mac_address]
	mov	qword [rsi + VARIABLE_NETWORK_FRAME_ARP_FIELD_SENDER_MAC],	rax

	; modyfikuj ramkę Ethernet ---------------------------------------------

	; przesuń wskaźnik na dane ramki Ethernet
	sub	rsi,	VARIABLE_NETWORK_FRAME_ETHERNET_SIZE

	; zamień miejscami nadawca z odbiorcą
	mov	eax,	dword [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_FIELD_SENDER]
	mov	bx,	word [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_FIELD_SENDER + VARIABLE_DWORD_SIZE]
	mov	dword [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_FIELD_TARGET],	eax
	mov	word [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_FIELD_TARGET + VARIABLE_DWORD_SIZE],	bx
	; ustaw nadawcę
	mov	rax,	qword [variable_network_i8254x_mac_address]
	mov	dword [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_FIELD_SENDER],	eax
	shr	rax,	VARIABLE_MOVE_HIGH_RAX_TO_EAX
	mov	word [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_FIELD_SENDER + VARIABLE_DWORD_SIZE],	ax

	; wyślij odpowiedź
	mov	rcx,	VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_ARP_SIZE
	call	cyjon_network_i8254x_transmit_packet

	; koniec obsługi pakietu ARP
	jmp	.mismatch

;-------------------------------------------------------------------------------
.ip:
	; ramka IP zawiera dane pakietu ICMP?
	cmp	byte [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_FIELD_PROTOCOL],	VARIABLE_NETWORK_FRAME_IP_FIELD_PROTOCOL_ICMP
	je	.icmp

	; czy ramka IP jest skierowana do nas?
	mov	eax,	dword [variable_network_ip]
	cmp	eax,	dword [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_FIELD_TARGET_ADDRESS]
	jne	.mismatch

	; pobierz rozmiar ramki IP
	movzx	rbx,	word [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_FIELD_TOTAL_LENGTH]
	xchg	bl,	bh
	; koryguj o rozmiar ramki Ethernet
	add	rbx,	VARIABLE_NETWORK_FRAME_ETHERNET_SIZE

	; rozmiar bufora TCP/IP w rekordach
	mov	rcx,	VARIABLE_DAEMON_TCP_IP_STACK_CACHE_SIZE * VARIABLE_MEMORY_PAGE_SIZE / STRUCTURE_DAEMON_TCP_IP_STACK_CACHE_IN.SIZE

	; adres przestrzeni bufora Ethernet
	mov	rdi,	qword [variable_daemon_tcp_ip_stack_cache_in]

.ip_loop:
	; szukaj wolnego miejsca w buforze TCP/IP
	cmp	byte [rdi + STRUCTURE_DAEMON_TCP_IP_STACK_CACHE_IN.flag],	VARIABLE_DAEMON_TCP_IP_STACK_CACHE_FLAG_EMPTY
	jne	.ip_next

	; przenieś/kopiuj
	mov	rcx,	rbx	; załaduj do licznika rozmiar pakietu
	push	rdi
	inc	rdi
	rep	movsb
	pop	rdi

	; oznacz rekord jako gotowy
	mov	byte [rdi + STRUCTURE_DAEMON_TCP_IP_STACK_CACHE_IN.flag],	VARIABLE_DAEMON_TCP_IP_STACK_CACHE_FLAG_READY

	; koniec obsługi pakietu
	jmp	.mismatch

.ip_next:
	; następny rekord
	add	rdi,	STRUCTURE_DAEMON_TCP_IP_STACK_CACHE_IN.SIZE
	loop	.ip_loop

	; pakiet nie pasuje do wzorców lub brak miejsca w buforze, zignoruj
	jmp	.mismatch

;-------------------------------------------------------------------------------
.icmp:
	; ustaw ramkę ICMP jako odpowiedź --------------------------------------
	mov	byte [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_ICMP_FIELD_TYPE],	VARIABLE_NETWORK_FRAME_ICMP_FIELD_TYPE_REPLY

	; oblicz sumę kontrolną

	; rozmiar ramki ICMP
	movzx	rcx,	word [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_FIELD_TOTAL_LENGTH]
	xchg	cl,	ch
	; nagłówek ramki Ethernet i IP nie bierze udziału w obliczeniach
	sub	rcx,	VARIABLE_NETWORK_FRAME_IP_SIZE
	; zachowaj rozmiar ramki ICMP
	push	rcx
	; zamień na słowa
	shr	rcx,	VARIABLE_DIVIDE_BY_2
	; wyczyść sumę kontrolną
	mov	word [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_ICMP_FIELD_CHECKSUM],	VARIABLE_EMPTY
	; brak wstępnej sumy kontrolnej
	xor	rax,	rax
	; ustaw wskaźnik na ramkę ICMP
	mov	rdi,	rsi
	add	rdi,	VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE
	call	cyjon_network_checksum_create

	; zapisz sumę kontrolną ramki ICMP
	xchg	al,	ah
	mov	word [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE + VARIABLE_NETWORK_FRAME_ICMP_FIELD_CHECKSUM],	ax

	; zamień nadawcę i odbiorcę w ramce IP ---------------------------------
	mov	eax,	dword [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_FIELD_SOURCE_ADDRESS]
	xchg	eax,	dword [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_FIELD_TARGET_ADDRESS]
	mov	dword [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_FIELD_SOURCE_ADDRESS],	eax

	; oblicz sumę kontrolną w ramce IP

	; wyczyść starą sumę kontrolną
	mov	word [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_FIELD_HEADER_CHECKSUM],	VARIABLE_EMPTY
	; brak wstępnej sumy kontrolnej
	xor	rax,	rax
	; rozmiar ramki IP
	mov	rcx,	VARIABLE_NETWORK_FRAME_IP_SIZE / VARIABLE_WORD_SIZE
	; ustaw wskaźnik na ramkę IP
	mov	rdi,	rsi
	add	rdi,	VARIABLE_NETWORK_FRAME_ETHERNET_SIZE
	call	cyjon_network_checksum_create

	; zapisz
	xchg	al,	ah
	mov	word [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_FIELD_HEADER_CHECKSUM],	ax

	; zamień nadawcę i odbiorcę w ramce Ethernet ---------------------------
	mov	eax,	dword [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_FIELD_SENDER]
	mov	bx,	word [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_FIELD_SENDER + VARIABLE_DWORD_SIZE]
	xchg	eax,	dword [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_FIELD_TARGET]
	xchg	bx,	word [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_FIELD_TARGET + VARIABLE_DWORD_SIZE]
	mov	dword [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_FIELD_SENDER],	eax
	mov	word [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_FIELD_SENDER + VARIABLE_DWORD_SIZE],	bx

	; przywróć rozmiar ramki ICMP
	pop	rcx

	; koryguj rozmiar pakietu do wysłania
	add	rcx,	VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE
	call	cyjon_network_i8254x_transmit_packet

	; koniec obsługi pakietu IP/ICMP
	jmp	.mismatch
