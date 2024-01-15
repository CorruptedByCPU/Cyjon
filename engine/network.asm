;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

; Use:
; nasm - http://www.nasm.us/

VARIABLE_NETWORK_FRAME_ETHERNET_SIZE_TARGET		equ	0x06
VARIABLE_NETWORK_FRAME_ETHERNET_SIZE_SENDER		equ	0x06
VARIABLE_NETWORK_FRAME_ETHERNET_SIZE_TYPE		equ	0x02
VARIABLE_NETWORK_FRAME_ETHERNET_SIZE			equ	VARIABLE_NETWORK_FRAME_ETHERNET_SIZE_TARGET + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE_SENDER + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE_TYPE
VARIABLE_NETWORK_FRAME_ETHERNET_FIELD_TARGET		equ	0x00
VARIABLE_NETWORK_FRAME_ETHERNET_FIELD_SENDER		equ	VARIABLE_NETWORK_FRAME_ETHERNET_FIELD_TARGET + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE_TARGET
VARIABLE_NETWORK_FRAME_ETHERNET_FIELD_TYPE		equ	VARIABLE_NETWORK_FRAME_ETHERNET_FIELD_SENDER + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE_SENDER
VARIABLE_NETWORK_FRAME_ETHERNET_FIELD_TYPE_ARP		equ	0x0608
VARIABLE_NETWORK_FRAME_ETHERNET_FIELD_TYPE_IP		equ	0x0008

VARIABLE_NETWORK_FRAME_ARP_SIZE_HTYPE			equ	0x02
VARIABLE_NETWORK_FRAME_ARP_SIZE_PTYPE			equ	0x02
VARIABLE_NETWORK_FRAME_ARP_SIZE_HAL			equ	0x01
VARIABLE_NETWORK_FRAME_ARP_SIZE_PAL			equ	0x01
VARIABLE_NETWORK_FRAME_ARP_SIZE_OPCODE			equ	0x02
VARIABLE_NETWORK_FRAME_ARP_SIZE_SENDER_MAC		equ	0x06
VARIABLE_NETWORK_FRAME_ARP_SIZE_SENDER_IP		equ	0x04
VARIABLE_NETWORK_FRAME_ARP_SIZE_TARGET_MAC		equ	0x06
VARIABLE_NETWORK_FRAME_ARP_SIZE_TARGET_IP		equ	0x04
VARIABLE_NETWORK_FRAME_ARP_SIZE				equ	VARIABLE_NETWORK_FRAME_ARP_SIZE_HTYPE + VARIABLE_NETWORK_FRAME_ARP_SIZE_PTYPE + VARIABLE_NETWORK_FRAME_ARP_SIZE_HAL + VARIABLE_NETWORK_FRAME_ARP_SIZE_PAL + VARIABLE_NETWORK_FRAME_ARP_SIZE_OPCODE + VARIABLE_NETWORK_FRAME_ARP_SIZE_SENDER_MAC + VARIABLE_NETWORK_FRAME_ARP_SIZE_SENDER_IP + VARIABLE_NETWORK_FRAME_ARP_SIZE_TARGET_MAC + VARIABLE_NETWORK_FRAME_ARP_SIZE_TARGET_IP
VARIABLE_NETWORK_FRAME_ARP_FIELD_HTYPE			equ	0x00
VARIABLE_NETWORK_FRAME_ARP_FIELD_HTYPE_ETHERNET		equ	0x0100	; 0x0001
VARIABLE_NETWORK_FRAME_ARP_FIELD_PTYPE			equ	VARIABLE_NETWORK_FRAME_ARP_FIELD_HTYPE + VARIABLE_NETWORK_FRAME_ARP_SIZE_HTYPE
VARIABLE_NETWORK_FRAME_ARP_FIELD_PTYPE_IPV4		equ	0x0008	; 0x0800
VARIABLE_NETWORK_FRAME_ARP_FIELD_HAL			equ	VARIABLE_NETWORK_FRAME_ARP_FIELD_PTYPE + VARIABLE_NETWORK_FRAME_ARP_SIZE_PTYPE
VARIABLE_NETWORK_FRAME_ARP_FIELD_HAL_MAC		equ	0x06	; xx:xx:xx:xx:xx:xx
VARIABLE_NETWORK_FRAME_ARP_FIELD_PAL			equ	VARIABLE_NETWORK_FRAME_ARP_FIELD_HAL + VARIABLE_NETWORK_FRAME_ARP_SIZE_HAL
VARIABLE_NETWORK_FRAME_ARP_FIELD_PAL_IPV4		equ	0x04	; x.x.x.x
VARIABLE_NETWORK_FRAME_ARP_FIELD_OPCODE			equ	VARIABLE_NETWORK_FRAME_ARP_FIELD_PAL + VARIABLE_NETWORK_FRAME_ARP_SIZE_PAL
VARIABLE_NETWORK_FRAME_ARP_FIELD_OPCODE_REQUEST		equ	0x0100
VARIABLE_NETWORK_FRAME_ARP_FIELD_OPCODE_REPLY		equ	0x0200
VARIABLE_NETWORK_FRAME_ARP_FIELD_SENDER_MAC		equ	VARIABLE_NETWORK_FRAME_ARP_FIELD_OPCODE + VARIABLE_NETWORK_FRAME_ARP_SIZE_OPCODE
VARIABLE_NETWORK_FRAME_ARP_FIELD_SENDER_IP		equ	VARIABLE_NETWORK_FRAME_ARP_FIELD_SENDER_MAC + VARIABLE_NETWORK_FRAME_ARP_SIZE_SENDER_MAC
VARIABLE_NETWORK_FRAME_ARP_FIELD_TARGET_MAC		equ	VARIABLE_NETWORK_FRAME_ARP_FIELD_SENDER_IP + VARIABLE_NETWORK_FRAME_ARP_SIZE_SENDER_IP
VARIABLE_NETWORK_FRAME_ARP_FIELD_TARGET_IP		equ	VARIABLE_NETWORK_FRAME_ARP_FIELD_TARGET_MAC + VARIABLE_NETWORK_FRAME_ARP_SIZE_TARGET_MAC

VARIABLE_NETWORK_FRAME_IP_SIZE_VERSION_AND_IHL		equ	0x01
VARIABLE_NETWORK_FRAME_IP_SIZE_DSCP_AND_ECN		equ	0x01
VARIABLE_NETWORK_FRAME_IP_SIZE_TOTAL_LENGTH		equ	0x02
VARIABLE_NETWORK_FRAME_IP_SIZE_IDENTIFICATION		equ	0x02
VARIABLE_NETWORK_FRAME_IP_SIZE_FLAGS_AND_FRAGMENT_OFFSET	equ	0x02
VARIABLE_NETWORK_FRAME_IP_SIZE_TTL			equ	0x01
VARIABLE_NETWORK_FRAME_IP_SIZE_PROTOCOL			equ	0x01
VARIABLE_NETWORK_FRAME_IP_SIZE_HEADER_CHECKSUM		equ	0x02
VARIABLE_NETWORK_FRAME_IP_SIZE_SOURCE_ADDRESS		equ	0x04
VARIABLE_NETWORK_FRAME_IP_SIZE_TARGET_ADDRESS		equ	0x04
VARIABLE_NETWORK_FRAME_IP_SIZE				equ	VARIABLE_NETWORK_FRAME_IP_SIZE_VERSION_AND_IHL + VARIABLE_NETWORK_FRAME_IP_SIZE_DSCP_AND_ECN + VARIABLE_NETWORK_FRAME_IP_SIZE_TOTAL_LENGTH + VARIABLE_NETWORK_FRAME_IP_SIZE_IDENTIFICATION + VARIABLE_NETWORK_FRAME_IP_SIZE_FLAGS_AND_FRAGMENT_OFFSET + VARIABLE_NETWORK_FRAME_IP_SIZE_TTL + VARIABLE_NETWORK_FRAME_IP_SIZE_PROTOCOL + VARIABLE_NETWORK_FRAME_IP_SIZE_HEADER_CHECKSUM + VARIABLE_NETWORK_FRAME_IP_SIZE_SOURCE_ADDRESS + VARIABLE_NETWORK_FRAME_IP_SIZE_TARGET_ADDRESS
VARIABLE_NETWORK_FRAME_IP_FIELD_VERSION_AND_IHL		equ	0x00
VARIABLE_NETWORK_FRAME_IP_FIELD_DSCP_AND_ECN		equ	VARIABLE_NETWORK_FRAME_IP_FIELD_VERSION_AND_IHL + VARIABLE_NETWORK_FRAME_IP_SIZE_VERSION_AND_IHL
VARIABLE_NETWORK_FRAME_IP_FIELD_TOTAL_LENGTH		equ	VARIABLE_NETWORK_FRAME_IP_FIELD_DSCP_AND_ECN + VARIABLE_NETWORK_FRAME_IP_SIZE_DSCP_AND_ECN
VARIABLE_NETWORK_FRAME_IP_FIELD_IDENTIFICATION		equ	VARIABLE_NETWORK_FRAME_IP_FIELD_TOTAL_LENGTH + VARIABLE_NETWORK_FRAME_IP_SIZE_TOTAL_LENGTH
VARIABLE_NETWORK_FRAME_IP_FIELD_FLAGS_AND_FRAGMENT_OFFSET	equ	VARIABLE_NETWORK_FRAME_IP_FIELD_IDENTIFICATION + VARIABLE_NETWORK_FRAME_IP_SIZE_IDENTIFICATION
VARIABLE_NETWORK_FRAME_IP_FIELD_TTL			equ	VARIABLE_NETWORK_FRAME_IP_FIELD_FLAGS_AND_FRAGMENT_OFFSET + VARIABLE_NETWORK_FRAME_IP_SIZE_FLAGS_AND_FRAGMENT_OFFSET
VARIABLE_NETWORK_FRAME_IP_FIELD_PROTOCOL		equ	VARIABLE_NETWORK_FRAME_IP_FIELD_TTL + VARIABLE_NETWORK_FRAME_IP_SIZE_TTL
VARIABLE_NETWORK_FRAME_IP_FIELD_PROTOCOL_ICMP		equ	0x01
VARIABLE_NETWORK_FRAME_IP_FIELD_PROTOCOL_TCP		equ	0x06
VARIABLE_NETWORK_FRAME_IP_FIELD_HEADER_CHECKSUM		equ	VARIABLE_NETWORK_FRAME_IP_FIELD_PROTOCOL + VARIABLE_NETWORK_FRAME_IP_SIZE_PROTOCOL
VARIABLE_NETWORK_FRAME_IP_FIELD_SOURCE_ADDRESS		equ	VARIABLE_NETWORK_FRAME_IP_FIELD_HEADER_CHECKSUM + VARIABLE_NETWORK_FRAME_IP_SIZE_HEADER_CHECKSUM
VARIABLE_NETWORK_FRAME_IP_FIELD_TARGET_ADDRESS		equ	VARIABLE_NETWORK_FRAME_IP_FIELD_SOURCE_ADDRESS + VARIABLE_NETWORK_FRAME_IP_SIZE_SOURCE_ADDRESS
VARIABLE_NETWORK_FRAME_IP_FIELD_OPTIONS			equ	VARIABLE_NETWORK_FRAME_IP_FIELD_TARGET_ADDRESS + VARIABLE_NETWORK_FRAME_IP_SIZE_TARGET_ADDRESS

VARIABLE_NETWORK_FRAME_ICMP_SIZE_TYPE			equ	0x01
VARIABLE_NETWORK_FRAME_ICMP_SIZE_CODE			equ	0x01
VARIABLE_NETWORK_FRAME_ICMP_SIZE_CHECKSUM		equ	0x02
VARIABLE_NETWORK_FRAME_ICMP_FIELD_TYPE			equ	0x00
VARIABLE_NETWORK_FRAME_ICMP_FIELD_TYPE_PING		equ	0x08
VARIABLE_NETWORK_FRAME_ICMP_FIELD_TYPE_REPLY		equ	0x00
VARIABLE_NETWORK_FRAME_ICMP_FIELD_CODE			equ	VARIABLE_NETWORK_FRAME_ICMP_FIELD_TYPE + VARIABLE_NETWORK_FRAME_ICMP_SIZE_TYPE
VARIABLE_NETWORK_FRAME_ICMP_FIELD_CHECKSUM		equ	VARIABLE_NETWORK_FRAME_ICMP_FIELD_CODE + VARIABLE_NETWORK_FRAME_ICMP_SIZE_CODE
VARIABLE_NETWORK_FRAME_ICMP_FIELD_DATA			equ	VARIABLE_NETWORK_FRAME_ICMP_FIELD_CHECKSUM + VARIABLE_NETWORK_FRAME_ICMP_SIZE_CHECKSUM

VARIABLE_NETWORK_FRAME_TCP_SIZE_SOURCE_PORT		equ	0x02
VARIABLE_NETWORK_FRAME_TCP_SIZE_DESTINATION_PORT	equ	0x02
VARIABLE_NETWORK_FRAME_TCP_SIZE_SEQUENCE_NUMBER		equ	0x04
VARIABLE_NETWORK_FRAME_TCP_SIZE_ACKNOWLEDGEMENT_NUMBER	equ	0x04
VARIABLE_NETWORK_FRAME_TCP_SIZE_HEADER_LENGTH		equ	0x01
VARIABLE_NETWORK_FRAME_TCP_SIZE_FLAGS			equ	0x01
VARIABLE_NETWORK_FRAME_TCP_SIZE_WINDOW_SIZE		equ	0x02
VARIABLE_NETWORK_FRAME_TCP_SIZE_CHECKSUM		equ	0x02
VARIABLE_NETWORK_FRAME_TCP_SIZE_URGENT_POINTER		equ	0x02
VARIABLE_NETWORK_FRAME_TCP_SIZE_OPTIONS			equ	0x04
VARIABLE_NETWORK_FRAME_TCP_SIZE				equ	VARIABLE_NETWORK_FRAME_TCP_SIZE_SOURCE_PORT + VARIABLE_NETWORK_FRAME_TCP_SIZE_DESTINATION_PORT + VARIABLE_NETWORK_FRAME_TCP_SIZE_SEQUENCE_NUMBER + VARIABLE_NETWORK_FRAME_TCP_SIZE_ACKNOWLEDGEMENT_NUMBER + VARIABLE_NETWORK_FRAME_TCP_SIZE_HEADER_LENGTH + VARIABLE_NETWORK_FRAME_TCP_SIZE_FLAGS + VARIABLE_NETWORK_FRAME_TCP_SIZE_WINDOW_SIZE + VARIABLE_NETWORK_FRAME_TCP_SIZE_CHECKSUM + VARIABLE_NETWORK_FRAME_TCP_SIZE_URGENT_POINTER
VARIABLE_NETWORK_FRAME_TCP_FIELD_SOURCE_PORT		equ	0x00
VARIABLE_NETWORK_FRAME_TCP_FIELD_DESTINATION_PORT	equ	VARIABLE_NETWORK_FRAME_TCP_SIZE_SOURCE_PORT
VARIABLE_NETWORK_FRAME_TCP_FIELD_SEQUENCE_NUMBER	equ	VARIABLE_NETWORK_FRAME_TCP_FIELD_DESTINATION_PORT + VARIABLE_NETWORK_FRAME_TCP_SIZE_DESTINATION_PORT
VARIABLE_NETWORK_FRAME_TCP_FIELD_ACKNOWLEDGEMENT_NUMBER	equ	VARIABLE_NETWORK_FRAME_TCP_FIELD_SEQUENCE_NUMBER + VARIABLE_NETWORK_FRAME_TCP_SIZE_SEQUENCE_NUMBER
VARIABLE_NETWORK_FRAME_TCP_FIELD_HEADER_LENGTH		equ	VARIABLE_NETWORK_FRAME_TCP_FIELD_ACKNOWLEDGEMENT_NUMBER + VARIABLE_NETWORK_FRAME_TCP_SIZE_ACKNOWLEDGEMENT_NUMBER
VARIABLE_NETWORK_FRAME_TCP_FIELD_HEADER_LENGTH_DEFAULT	equ	0x50	; 5 * 4(32 bits) = 20 B header size
VARIABLE_NETWORK_FRAME_TCP_FIELD_FLAGS			equ	VARIABLE_NETWORK_FRAME_TCP_FIELD_HEADER_LENGTH + VARIABLE_NETWORK_FRAME_TCP_SIZE_HEADER_LENGTH
VARIABLE_NETWORK_FRAME_TCP_FIELD_FLAGS_FIN		equ	00000001b
VARIABLE_NETWORK_FRAME_TCP_FIELD_FLAGS_SYN		equ	00000010b
VARIABLE_NETWORK_FRAME_TCP_FIELD_FLAGS_RST		equ	00000100b
VARIABLE_NETWORK_FRAME_TCP_FIELD_FLAGS_PSH		equ	00001000b
VARIABLE_NETWORK_FRAME_TCP_FIELD_FLAGS_ACK		equ	00010000b
VARIABLE_NETWORK_FRAME_TCP_FIELD_FLAGS_URG		equ	00100000b
VARIABLE_NETWORK_FRAME_TCP_FIELD_WINDOW_SIZE		equ	VARIABLE_NETWORK_FRAME_TCP_FIELD_FLAGS + VARIABLE_NETWORK_FRAME_TCP_SIZE_FLAGS
VARIABLE_NETWORK_FRAME_TCP_FIELD_CHECKSUM		equ	VARIABLE_NETWORK_FRAME_TCP_FIELD_WINDOW_SIZE + VARIABLE_NETWORK_FRAME_TCP_SIZE_WINDOW_SIZE
VARIABLE_NETWORK_FRAME_TCP_FIELD_URGENT_POINTER		equ	VARIABLE_NETWORK_FRAME_TCP_FIELD_CHECKSUM + VARIABLE_NETWORK_FRAME_TCP_SIZE_CHECKSUM
VARIABLE_NETWORK_FRAME_TCP_FIELD_OPTIONS		equ	VARIABLE_NETWORK_FRAME_TCP_FIELD_URGENT_POINTER + VARIABLE_NETWORK_FRAME_TCP_SIZE_URGENT_POINTER
VARIABLE_NETWORK_FRAME_TCP_FIELD_OPTIONS_MSS		equ	VARIABLE_NETWORK_FRAME_TCP_FIELD_OPTIONS

VARIABLE_NETWORK_PORT_HTTP				equ	0x5000	; 80

variable_network_i8254x_base_address			dq	VARIABLE_EMPTY
variable_network_i8254x_irq				db	VARIABLE_EMPTY
variable_network_i8254x_rx_descriptor			dq	VARIABLE_EMPTY
variable_network_i8254x_rx_cache			dq	VARIABLE_EMPTY
variable_network_i8254x_tx_cache			dq	VARIABLE_EMPTY
variable_network_i8254x_mac_address			dq	VARIABLE_EMPTY

variable_network_enabled				db	VARIABLE_TRUE
variable_network_mac_filter				dq	0x0000FFFFFFFFFFFF
variable_network_ip_filter				dq	0x00000000FFFFFFFF

variable_network_ip					db	0, 0, 0, 0, VARIABLE_EMPTY, VARIABLE_EMPTY, VARIABLE_EMPTY, VARIABLE_EMPTY

; dla 512 portów
variable_network_port_table				dq	VARIABLE_EMPTY

; 64 bitowy kod
[BITS 64]

;===============================================================================
; wykrywa i inicjalizuje jedną z dostępnych kart sieciowych
; IN:
;	brak
;
; OUT:
;	brak
;
; wszystkie rejestry zachowane
network_init:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdx

	; szukaj od początku
	xor	rbx,	rbx
	xor	rcx,	rcx
	; sprawdzaj klasę/subklasę urządzenia/kontrolera
	mov	rdx,	2

.next:
	; pobierz klasę/subklasę
	call	cyjon_pci_read

	; przesuń starszą część do młodszej
	shr	eax,	16

	; kontroler sieci?
	cmp	ax,	VARIABLE_NIC
	je	.check

.continue:
	; następne urządzenie
	inc	ecx

	; koniec urządzeń na szynie?
	cmp	ecx,	256
	jb	.next

	; następna szyna
	inc	ebx

	; zacznij przeszukiwać od początku szyny
	xor	ecx,	ecx

	; koniec szyn?
	cmp	ebx,	256
	jb	.next

	; wyłącz obsługę sieci
	mov	byte [variable_network_enabled],	VARIABLE_FALSE

.end:
	; nie znaleziono jakiegokolwiek kontrolera sieci

	; przywróć oryginalne rejestry
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

.check:
	; pobierz identyfikator Firmy(Vendor) i Urządzenia(Device)
	xor	edx,	edx
	call	cyjon_pci_read

	; kontroler sieci typu i8254x?
	cmp	eax,	VARIABLE_NIC_INTEL_82540EM_PCI
	je	cyjon_network_i8254x_init

	; nieznany kontroler sieci, szukaj dalej
	jmp	.continue

.configured:
	; podłącz procedurę obsługi przerwania kontrolera sieci
	mov	rdi,	network
	call	cyjon_interrupt_descriptor_table_isr_hardware_mount

	; tablica portów
	call	cyjon_page_allocate
	cmp	rdi,	VARIABLE_EMPTY
	je	.continue
	; nie udało się zaalokować przestrzeni pamięci pod tablicę portów,
	; tym samym nie będzie działać protokół TCP, wyłączamy dostęp do sieci

	; zapisz wskaźnik
	mov	qword [variable_network_port_table],	rdi

	; wyczyść porty (wszystkie dostępne)
	call	cyjon_page_clear

	; włącz obsługę przerwania
	mov	cx,	ax
	call	cyjon_programmable_interrupt_controller_enable_irq

	; pobierz status kontrolera sieci
	call	cyjon_network_i8254x_irq

	; koniec
	jmp	.end

;===============================================================================
; obsługa przerwania sprzętowego kontrolera sieci
; procedura odbiera pakiety od karty sieciowej
; i zapisuje do bufora demona ethernet
; IN:
;	brak
;
; OUT:
;	brak
;
; wszystkie rejestry zachowane
network:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rsi
	pushf

	; pobierz status kontrolera
	call	cyjon_network_i8254x_irq

	; przerwanie wywołane poprzez wysyłany pakiet? (TX)
	bt	eax,	0
	jc	.transfer

	; przerwanie wywołane poprzez przychodzący pakiet? (RX)
	bt	eax,	7
	jc	.receive

.end:
	; poinformuj kontroler PIC o obsłużeniu przerwania sprzętowego
	mov	al,	0x20

	; przerwane obsługiwane w trybie kaskady?
	cmp	byte [variable_network_i8254x_irq],	8
	jb	.no_cascade

	; wyślij do kontrolera "kaskadowego"
	out	VARIABLE_PIC_COMMAND_PORT1,	al

.no_cascade:
	; wyślij do kontrolera głównego
	out	VARIABLE_PIC_COMMAND_PORT0,	al

	; przywróć oryginalne rejestry
	popf
	pop	rsi
	pop	rcx
	pop	rax

	; koniec obsługi przerwania sprzętowego
	iretq

;-------------------------------------------------------------------------------
.transfer:
	; czy wystąpiło jednocześnie wysłanie pakietu?
	bt	eax,	7
	jnc	.end	; nie

;-------------------------------------------------------------------------------
.receive:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi

	; adres przestrzeni cache karty sieciowej
	mov	rsi,	qword [variable_network_i8254x_rx_cache]

	; pakiet dotyczy naszego adresu MAC
	mov	eax,	dword [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_FIELD_TARGET + VARIABLE_WORD_SIZE]
	shl	rax,	VARIABLE_MOVE_RAX_WORD_LEFT
	or	ax,	word [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_FIELD_TARGET]
	cmp	rax,	qword [variable_network_i8254x_mac_address]
	je	.our_packet

	; pakiet dotyczy adresu rozgłoszeniowego?
	mov	eax,	dword [variable_network_ip_filter]
	cmp	eax,	dword [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_FIELD_TARGET]
	jne	.receive_end

.our_packet:
	; sprawdź gotowość bufora stosu ethernet
	cmp	byte [variable_daemon_ethernet_semaphore],	VARIABLE_FALSE
	je	.receive_end	; nie jest gotowy, zignoruj pakiet

	; pobierz informacje z pola TYPE ramki Ethernet ------------------------
	movzx	rbx,	word [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_FIELD_TYPE]
	xchg	bl,	bh

	;-----------------------------------------------------------------------
	; wyłączamy obsługę czystych pakietów Ethernet oraz nie będących ARP lub IP
	;-----------------------------------------------------------------------

	; jeśli wartość mniejsza od 0x0800, jest to rozmiar ramki Ethernet
	cmp	bx,	0x0800
	jb	.receive_end	; brak obsługi czystych pakietów Ethernet

	; ramka ARP ma stały rozmiar (nie posiada danych) ----------------------
	mov	bx,	VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_ARP_SIZE

	; sprawdź czy pakiet zawiera ramkę ARP
	cmp	word [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_FIELD_TYPE],	VARIABLE_NETWORK_FRAME_ETHERNET_FIELD_TYPE_ARP
	je	.receive_move

	; sprawdź pakiet pod kątem zawartości ramki IP -------------------------
	cmp	word [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_FIELD_TYPE],	VARIABLE_NETWORK_FRAME_ETHERNET_FIELD_TYPE_IP
	jne	.receive_end	; przychodzący pakiet nie został rozpoznany, zignoruj

	; pobierz rozmiar nagłówka IP
	mov	bl,	byte [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_SIZE_VERSION_AND_IHL]
	and	bl,	0x0F
	cmp	bl,	0x05
	ja	.receive_end	; brak obsługi dodatkowych opcji w nagłówku IP

	; pobierz rozmiar ramki IP
	movzx	rbx,	word [rsi + VARIABLE_NETWORK_FRAME_ETHERNET_SIZE + VARIABLE_NETWORK_FRAME_IP_FIELD_TOTAL_LENGTH]
	xchg	bl,	bh
	; koryguj o rozmiar ramki Ethernet
	add	rbx,	VARIABLE_NETWORK_FRAME_ETHERNET_SIZE

	; sprawdź czy rozmiar pakietu jest obsługiwany
	cmp	rbx,	STRUCTURE_DAEMON_ETHERNET_CACHE.SIZE - VARIABLE_BYTE_SIZE	; - 1 Bajt, rozmiar flagi rekordu
	jbe	.receive_move

	; przychodzący pakiet jest za duży lub brak obsługi, zignoruj

.receive_end:
	; przywóć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; poinformuj kontroler o zakończeniu przetwarzania pakietu
	mov	rsi,	qword [variable_network_i8254x_base_address]
	mov	dword [rsi + VARIABLE_NIC_INTEL_82540EM_RDH],	VARIABLE_EMPTY
	mov	dword [rsi + VARIABLE_NIC_INTEL_82540EM_RDT],	VARIABLE_TRUE

	; zresetuj deskryptor rx
	mov	rcx,	qword [variable_network_i8254x_rx_cache]
	mov	dword [variable_network_i8254x_rx_descriptor],	ecx

	; karta sieciowa gotowa do dalszej pracy
	jmp	.end

.receive_move:
	; rozmiar bufora Ethernet w rekordach
	mov	rcx,	VARIABLE_DAEMON_ETHERNET_CACHE_SIZE * VARIABLE_MEMORY_PAGE_SIZE / STRUCTURE_DAEMON_ETHERNET_CACHE.SIZE

	; adres przestrzeni bufora Ethernet
	mov	rdi,	qword [variable_daemon_ethernet_cache]

.loop:
	; szukaj wolnego miejsca w buforze Ethernet
	cmp	byte [rdi + STRUCTURE_DAEMON_ETHERNET_CACHE.flag],	VARIABLE_DAEMON_ETHERNET_CACHE_FLAG_EMPTY
	jne	.receive_next

	; przenieś/kopiuj
	mov	rcx,	rbx	; załaduj do licznika rozmiar pakietu
	push	rdi
	inc	rdi
	rep	movsb
	pop	rdi

	; oznacz rekord jako gotowy
	mov	byte [rdi + STRUCTURE_DAEMON_ETHERNET_CACHE.flag],	VARIABLE_DAEMON_ETHERNET_CACHE_FLAG_READY

	; koniec obsługi pakietu
	jmp	.receive_end

.receive_next:
	; następny rekord
	add	rdi,	STRUCTURE_DAEMON_ETHERNET_CACHE.SIZE
	loop	.loop

	; brak miejsca w buforze Ethernet, zignoruj pakiet
	jmp	.receive_end

;===============================================================================
; wylicza sumę kontrolną fragmentu pamięci
; IN:
;	rax - wstępna suma kontrolna
;	rcx - rozmiar fragmentu w Słowach [dw]
;	rdi - wskaźnik do fragmentu pamięci
;
; OUT:
;	ax - suma kontrolna
;
; pozostałe rejestry zachowane
cyjon_network_checksum_create:
	; zachowaj oryginalne rejestry
	push	rbx
	push	rcx
	push	rdi

.checksum:
	; pobierz pierwsze słowo
	movzx	rbx,	word [rdi]
	xchg	bl,	bh	; koryguj pozycje

	; dodaj do akumulatora
	add	rax,	rbx

	; przesuń wskaźnik na następne słowo
	add	rdi,	VARIABLE_WORD_SIZE

	; wykonaj operacje z pozostałymi słowami ramki ICMP
	loop	.checksum

	; koryguj sumę kontrolną o przepełnienia rejestru AX
	mov	bx,	ax
	shr	eax,	VARIABLE_MOVE_HIGH_EAX_TO_AX
	add	rbx,	rax

	; odwróć wartość
	not	bx

	; wynik zwróć w ax
	mov	ax,	bx

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx
	pop	rbx

	; powrót z procedury
	ret

;===============================================================================
; procedura zamienia miejscami Bajty w rejestrze EAX
; IN:
;	eax - liczba do przekonwertowania
;
; OUT:
;	eax - wynik
;
; pozostałe rejestry zachowane
cyjon_network_convert_between_little_big_endian:
	; zachowaj oryginalne rejestry
	push	rbx

	; konwertuj
	mov	bh,	al
	mov	bl,	ah
	shl	rbx,	VARIABLE_MOVE_RAX_WORD_LEFT
	shr	rax,	VARIABLE_MOVE_HIGH_EAX_TO_AX
	mov	bh,	al
	mov	bl,	ah

	; ustaw wynik na pozycje
	mov	eax,	ebx

	; przywróć oryginalne rejestry
	pop	rbx

	; powrót z procedury
	ret
