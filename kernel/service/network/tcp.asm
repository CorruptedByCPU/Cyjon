;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

	;-----------------------------------------------------------------------
	%include	"kernel/service/network/wrap.asm"
	;-----------------------------------------------------------------------

;===============================================================================
; wejście:
;	rsi - wskaźnik do pakietu przychodzącego
service_network_tcp:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdx

	; pobierz numer portu docelowego
	movzx	eax,	word [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.port_target]
	rol	ax,	STATIC_REPLACE_AL_WITH_HIGH_shift

	; port wspierany?
	cmp	ax,	512
	jnb	.end	; nie, zignoruj pakiet

	; port docelowy jest pusty?
	mov	ecx,	SERVICE_NETWORK_STRUCTURE_PORT.SIZE
	mul	ecx
	add	rax,	qword [service_network_port_table]
	cmp	qword [rax],	STATIC_EMPTY
	je	.end	; tak, zignoruj pakiet

	; prośba o nawiązanie połączenia?
	cmp	byte [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.flags],	SERVICE_NETWORK_FRAME_TCP_FLAGS_syn
	je	service_network_tcp_syn	; tak

	; odszukaj połączenie dotyczące pakietu
	call	service_network_tcp_find
	jc	.end	; brak nawiązanego połączenia z danym pakietem

	; akceptacja wysłanych danych?
	cmp	byte [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.flags],	SERVICE_NETWORK_FRAME_TCP_FLAGS_ack
	je	service_network_tcp_ack	; tak

	; zakończenie połączenia?
	test	byte [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.flags],	SERVICE_NETWORK_FRAME_TCP_FLAGS_fin
	jnz	service_network_tcp_fin	; tak

	; przesłanie danych do właściciela portu?
	test	byte [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.flags],	SERVICE_NETWORK_FRAME_TCP_FLAGS_psh
	jnz	service_network_tcp_psh	; tak

.end:
	; przywróć oryginalne rejestry
	pop	rdx
	pop	rcx
	pop	rax

	; powrót z procedury
	jmp	service_network.end

	macro_debug	"service_network_tcp"

;===============================================================================
; wejście:
;	rbx - rozmiar nagłówka IP
;	rsi - wskaźnik do pakietu przychodzącego
;	rdi - wskaźnik do połączenia na stosie
service_network_tcp_psh:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rdi
	push	rsi

	; pobierz numer portu docelowego
	movzx	eax,	word [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + rbx + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.port_target]
	rol	ax,	STATIC_REPLACE_AL_WITH_HIGH_shift	; Little-Endian
	mov	ecx,	SERVICE_NETWORK_STRUCTURE_PORT.SIZE
	mul	ecx	; zamień na przesunięcie wew. tablicy portów

	; pobierz rozmiar danych w ramce TCP
	movzx	ecx,	word [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.total_length]
	rol	cx,	STATIC_REPLACE_AL_WITH_HIGH_shift	; Little-Endian
	sub	cx,	bx	; koryguj rozmiar o nagłówek IP

	; zachowaj rozmiar danych ramki TCP w zmiennej lokalnej
	push	rcx

	; oblicz rozmiar nagłówka TCP
	movzx	edx,	byte [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + rbx + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.header_length]
	shr	dl,	STATIC_MOVE_AL_HALF_TO_HIGH_shift	; przesuń ilość podwójnych słów na młodszą pozycję
	shl	dx,	STATIC_MULTIPLE_BY_4_shift	; zamień ilość podwójnych słów na Bajty

	; przesuń na początek przestrzeni pakietu
	mov	rdi,	rsi

	; zawartość danych ramki TCP
	add	rsi,	SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE
	add	rsi,	rbx
	add	rsi,	rdx

	; wykonaj
	rep	movsb

	; wyczyść pozostałą przestrzeń ramki
	mov	rcx,	STATIC_PAGE_SIZE_byte
	sub	rcx,	qword [rsp]
	rep	stosb

	; pobierz PID procesu docelowego
	mov	rbx,	qword [service_network_port_table]
	mov	rbx,	qword [rbx + rax]

	; wyślij komunikat do procesu
	xor	ecx,	ecx
	mov	rsi,	rsp
	call	kernel_ipc_insert

	; zwolnij zmienną lokalną
	add	rsp,	STATIC_QWORD_SIZE_byte

	; przestrzeń przekazana do procesu
	mov	qword [rsp],	STATIC_EMPTY

.end:
	; przywróć oryginalne rejestry
	pop	rsi
	pop	rdi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	jmp	service_network_tcp.end

	macro_debug	"service_network_tcp_psh_ack"

;===============================================================================
; wejście:
;	rbx - rozmiar nagłówka IP
;	rsi - wskaźnik do pakietu przychodzącego
;	rdi - wskaźnik do połączenia na stosie
service_network_tcp_fin:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rsi
	push	rdi

	; ustaw wskaźnik do połączenia w rejestrze źródłowym
	xchg	rsi,	rdi

	; usuń flagę ACK nawet, jeśli nie była oczekiwana
	and	byte [rsi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.flags_request],	~SERVICE_NETWORK_FRAME_TCP_FLAGS_ack

	;-----------------------------------------------------------------------

	; zachowaj numer sekwencji nadawcy
	mov	eax,	dword [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + rbx + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.sequence]
	bswap	eax	; zachowaj w formacie Little-Endian
	inc	eax	; potwierdź otrzymanie chęci zakończenia połączenia
	mov	dword [rsi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.source_sequence],	eax

	;-----------------------------------------------------------------------

	; nasz numer sekwencji
	mov	eax,	dword [rsi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.request_acknowledgement]
	inc	eax
	mov	dword [rsi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.host_sequence],	eax

	; nasz identyfikator
	inc	eax
	mov	dword [rsi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.request_acknowledgement],	eax

	;-----------------------------------------------------------------------

	; zamknięcie połączenia
	mov	word [rsi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.flags],	SERVICE_NETWORK_FRAME_TCP_FLAGS_ack | SERVICE_NETWORK_FRAME_TCP_FLAGS_fin

	; oczekuj flagi ACK w odpowiedzi
	mov	word [rsi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.flags_request],	SERVICE_NETWORK_FRAME_TCP_FLAGS_ack

	;-----------------------------------------------------------------------
	; wyślij odpowiedź
	;-----------------------------------------------------------------------

	; przygotuj miejsce na odpowiedź
	call	kernel_memory_alloc_page
	jc	.error

	; spakuj dane ramki TCP
	mov	bl,	(SERVICE_NETWORK_STRUCTURE_FRAME_TCP.SIZE >> STATIC_DIVIDE_BY_4_shift) << STATIC_MOVE_AL_HALF_TO_HIGH_shift
	mov	ecx,	SERVICE_NETWORK_STRUCTURE_FRAME_TCP.SIZE
	call	service_network_tcp_wrap

	; wyślij pakiet
	mov	eax,	SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.SIZE + STATIC_DWORD_SIZE_byte
	call	service_network_transfer

	; połączenie zatwierdzone
	jmp	.end

.error:
	; wyrejestruj połączenie
	mov	byte [rsi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.status],	STATIC_EMPTY

.end:
	; przywóć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	jmp	service_network_tcp.end

	macro_debug	"service_network_tcp_fin"

;===============================================================================
; wejście:
;	rsi - wskaźnik do pakietu przychodzącego
;	rdi - wskaźnik do połączenia na stosie
service_network_tcp_ack:
	; zachowaj oryginalne rejestry
	push	rsi
	push	rdi

	; oczekiwaliśmy potwierdzenia?
	test	word [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.flags_request],	SERVICE_NETWORK_FRAME_TCP_FLAGS_ack
	jz	.end	; nie

	; usuń oczekiwaną flagę z stosu
	and	word [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.flags_request],	~SERVICE_NETWORK_FRAME_TCP_FLAGS_ack

	; połączenie zostało zakończone?
	test	word [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.flags],	SERVICE_NETWORK_FRAME_TCP_FLAGS_fin | SERVICE_NETWORK_FRAME_TCP_FLAGS_ack
	jz	.end	; nie

	; zwolnij wpis na stosie dotyczący połączenia
	mov	word [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.flags],	STATIC_EMPTY

.end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi

	; powrót z procedury
	jmp	service_network_tcp.end

	macro_debug	"service_network_tcp_ack"

;===============================================================================
; wejście:
;	rsi - wskaźnik do pakietu przychodzącego
; wyjście:
;	rbx - rozmiar nagłówka ramki IP
;	rdi - wskaźnik do połączenia
service_network_tcp_find:
 	; zachowaj oryginalne rejestry
 	push	rax
 	push	rcx
	push	rbx
 	push	rdi

	; rozmiar nagłówka ramki IP
	movzx	ebx,	byte [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.version_and_ihl]
	and	bl,	SERVICE_NETWORK_FRAME_IP_HEADER_LENGTH_mask
	shl	bl,	STATIC_MULTIPLE_BY_4_shift

	; przeszukaj stos TCP
	mov	rcx,	(SERVICE_NETWORK_STACK_SIZE_page << STATIC_PAGE_SIZE_shift) / SERVICE_NETWORK_STRUCTURE_TCP_STACK.SIZE
	mov	rdi,	qword [service_network_stack_address]

.loop:
	; adres MAC klienta, poprawny?
	mov	eax,	dword [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.source]
	rol	rax,	STATIC_REPLACE_EAX_WITH_HIGH_shift
	mov	ax,	word [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.source + SERVICE_NETWORK_STRUCTURE_MAC.4]
	ror	rax,	STATIC_REPLACE_EAX_WITH_HIGH_shift
	cmp	qword [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.source_mac],	rax
	jne	.next	; nie, następny wpis

	; adres IPv4 klienta, poprawny?
	mov	eax,	dword [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.source_ipv4]
	cmp	dword [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.source_address],	eax
	jne	.next	; nie, następny wpis

	; port docelowy poprawny?
	mov	ax,	word [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.host_port]
	cmp	word [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + rbx + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.port_target],	ax
	jne	.next	; nie, następny wpis

	; port źródłowy, porawny?
	mov	ax,	word [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.source_port]
	cmp	word [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + rbx + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.port_source],	ax
	je	.found	; nie, następny wpis

.next:
	; przesuń wskaźnik na następny wpis
	add	rdi,	SERVICE_NETWORK_STRUCTURE_TCP_STACK.SIZE

	; koniec stosu?
	dec	rcx
	jnz	.loop	; nie

	; brak zarejestrowanego połączenia dla pakietu przychodzącego
 	stc

 	; koniec procedury
 	jmp	.end

.found:
	; zwróć rozmiar nagłówka IPv4
	mov	qword [rsp + STATIC_QWORD_SIZE_byte],	rbx

	; zwróć wskaźnik do połączenia
	mov	qword [rsp],	rdi

.end:
 	; przywróć oryginalne rejestry
 	pop	rdi
	pop	rbx
 	pop	rcx
 	pop	rax

 	; powrót z procedury
 	ret

	macro_debug	"service_network_tcp_find"

;===============================================================================
; wejście:
;	rsi - wskaźnik do pakietu przychodzącego
service_network_tcp_syn:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rsi
	push	rdi

	; przeszukaj stos TCP
	mov	rcx,	(SERVICE_NETWORK_STACK_SIZE_page << STATIC_PAGE_SIZE_shift) / SERVICE_NETWORK_STRUCTURE_TCP_STACK.SIZE
	mov	rdi,	qword [service_network_stack_address]

.search:
	; za wolnym miejscem
	lock	bts word [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.status],	SERVICE_NETWORK_STACK_FLAG_busy
	jnc	.found	; znaleziono

	; przesuń wskaźnik na następny wpis połączenia
	add	rdi,	SERVICE_NETWORK_STRUCTURE_TCP_STACK.SIZE

	; przeszukano cały stos TCP?
	dec	rcx
	jnz	.search	; nie, szukaj dalej

	; brak miejsca na zarejestrowanie nowego połączenia
	jmp	.end

.found:
	;-----------------------------------------------------------------------
	; zarejestruj połączenie na stosie
	;-----------------------------------------------------------------------

	; oblicz rozmiar ramki IP
	movzx	ecx,	byte [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.version_and_ihl]
	and	cl,	SERVICE_NETWORK_FRAME_IP_HEADER_LENGTH_mask
	shl	cl,	STATIC_MULTIPLE_BY_4_shift

	; zamień na pozycję bezwzględną ramki TCP
	add	ecx,	SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE

	;-----------------------------------------------------------------------

	; zachowaj numer portu usługi
	mov	ax,	word [rsi + rcx + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.port_target]
	mov	word [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.host_port],	ax

	; zachowaj numer portu nadawcy
	mov	ax,	word [rsi + rcx + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.port_source]
	mov	word [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.source_port],	ax

	; zachowaj numer sekwencji nadawcy
	mov	eax,	dword [rsi + rcx + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.sequence]
	bswap	eax	; w formacie Little-Endian
	mov	dword [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.source_sequence],	eax

	; zachowaj adres MAC nadawcy
	mov	rcx,	qword [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.source]
	shl	rcx,	STATIC_MOVE_AX_TO_HIGH_shift
	shr	rcx,	STATIC_MOVE_HIGH_TO_AX_shift
	mov	qword [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.source_mac],	rcx

	; zachowaj adres IPv4 nadawcy
	mov	ecx,	dword [rsi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.source_address]
	mov	dword [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.source_ipv4],	ecx

	;-----------------------------------------------------------------------

	; nasz numer sekwencji
	mov	dword [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.host_sequence],	STATIC_EMPTY

	; domyślny rozmiar okna
	mov	word [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.window_size],	SERVICE_NETWORK_FRAME_TCP_WINDOW_SIZE_default

	;-----------------------------------------------------------------------

	; aktualne flagi połączenia
	mov	word [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.flags],	SERVICE_NETWORK_FRAME_TCP_FLAGS_syn | SERVICE_NETWORK_FRAME_TCP_FLAGS_ack

	; oczekuj flagi ACK w odpowiedzi
	mov	word [rdi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.flags_request],	SERVICE_NETWORK_FRAME_TCP_FLAGS_ack

	;-----------------------------------------------------------------------
	; połączenie zarejestrowane
	;-----------------------------------------------------------------------
	mov	rsi,	rdi

	;-----------------------------------------------------------------------
	; wyślij odpowiedź
	;-----------------------------------------------------------------------
	call	service_network_tcp_reply

.end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	jmp	service_network_tcp.end

	macro_debug	"service_network_tcp_syn"

;===============================================================================
; wejście:
;	rsi - wskaźnik do połączenia na stosie
service_network_tcp_reply:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdi

	; przygotuj miejsce na odpowiedź
	call	kernel_memory_alloc_page

	; spakuj dane ramki TCP
	mov	bl,	(SERVICE_NETWORK_STRUCTURE_FRAME_TCP.SIZE >> STATIC_DIVIDE_BY_4_shift) << STATIC_MOVE_AL_HALF_TO_HIGH_shift
	mov	ecx,	SERVICE_NETWORK_STRUCTURE_FRAME_TCP.SIZE
	call	service_network_tcp_wrap

	; wyślij pakiet
	mov	eax,	SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.SIZE + STATIC_DWORD_SIZE_byte
	call	service_network_transfer

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	ecx - rozmiar ramki TCP w Bajtach
;	rsi - wskaźnik do właściwości połączenia
;	rdi - wskaźnik do przestrzeni pakietu do wysłania
; wyjście:
;	eax - suma kontrolna pseudo nagłówka
service_network_tcp_pseudo_header:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rdi

	; konfiguruj pseudo nagłówek

	; nadawca
	mov	eax,	dword [driver_nic_i82540em_ipv4_address]
	mov	dword [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE - SERVICE_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.source_ipv4],	eax

	; adresat
	mov	eax,	dword [rsi + SERVICE_NETWORK_STRUCTURE_TCP_STACK.source_ipv4]
	mov	dword [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE - SERVICE_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.target_ipv4],	eax

	; wyczyść wartość zarezerwowaną
	mov	byte [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE - SERVICE_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.reserved],	STATIC_EMPTY

	; protokół
	mov	byte [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE - SERVICE_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.protocol],	SERVICE_NETWORK_FRAME_TCP_PROTOCOL_default

	; rozmiar ramki TCP
	rol	cx,	STATIC_REPLACE_AL_WITH_HIGH_shift	; zamień na Big-Endian
	mov	word [rdi + SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE - SERVICE_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.segment_length],	cx

	; oblicz sumę kontrolną pseudo nagłówka
	xor	eax,	eax
	mov	ecx,	SERVICE_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.SIZE >> STATIC_DIVIDE_BY_2_shift
	add	rdi,	SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE - SERVICE_NETWORK_STRUCTURE_FRAME_TCP_PSEUDO_HEADER.SIZE
	call	service_network_checksum_part

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx

	; powrót z podprocedury
	ret

	macro_debug	"service_network_tcp_pseudo_header"

;===============================================================================
; wejście:
;	cx - numer portu
; wyjście:
;	Flags CF, jeśli zajęty
service_network_tcp_port_assign:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdx
	push	rdi

	; zablokuj dostęp do tablicy portów
	macro_lock	service_network_port_semaphore,	0

	; numer portu obsługiwany?
	cmp	cx,	512
	jnb	.error	; nie

	; zamień numer portu na wskaźnik pośredni
	mov	eax,	SERVICE_NETWORK_STRUCTURE_PORT.SIZE
	and	ecx,	STATIC_WORD_mask
	mul	ecx

	; pobierz PID procesu wywołującego
	call	kernel_task_active
	mov	rcx,	qword [rdi + KERNEL_TASK_STRUCTURE.pid]

	; załaduj do tablicy portów identyfikator właściciela (zarazem wyczyść flagi)
	mov	rdi,	qword [service_network_port_table]
	test	rdi,	rdi
	jz	.error	; usługa sieciowa niezainicjowana

	; port zajęty?
	cmp	qword [rdi + rcx + SERVICE_NETWORK_STRUCTURE_PORT.pid],	STATIC_EMPTY
	jne	.error	; tak

	; zarezerwuj port przez proces o danym PID
	mov	qword [rdi + rax + SERVICE_NETWORK_STRUCTURE_PORT.pid],	rcx

	; zarejestrowano
	jmp	.end

.error:
	; port niedostępny
	stc

.end:
	; zwolnij dostęp do tablicy portów
	mov	byte [service_network_port_semaphore],	STATIC_FALSE

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rdx
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"service_network_tcp_port_assign"

;===============================================================================
; wejście:
;	rbx - identyfikator połączenia
;	rcx - rozmiar danych w Bajtach
;	rsi - wskaźnik do przestrzeni danych
service_network_tcp_port_send:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rsi
	push	rdi

	; przygotuj przestrzeń pod odpowiedź
	call	kernel_memory_alloc_page
	jc	.end	; brak miejsca

	; zachowaj rozmiar i wskaźnik do przestrzeni danych
	push	rcx
	push	rdi

	; dołącz dane odpowiedzi
	add	rdi,	SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_TCP.SIZE
	rep	movsb

	; przywróć rozmiar i wskaźnik do przestrzeni danych
	pop	rdi
	pop	rcx

	inc	dword [rbx + SERVICE_NETWORK_STRUCTURE_TCP_STACK.host_sequence]
	mov	byte [rbx + SERVICE_NETWORK_STRUCTURE_TCP_STACK.flags],	SERVICE_NETWORK_FRAME_TCP_FLAGS_psh | SERVICE_NETWORK_FRAME_TCP_FLAGS_ack

	; wypełnij ramki pakietu
	add	rcx,	SERVICE_NETWORK_STRUCTURE_FRAME_TCP.SIZE + 0x01
	mov	rsi,	rbx
	mov	bl,	SERVICE_NETWORK_FRAME_TCP_HEADER_LENGTH_default
	call	service_network_tcp_wrap

	; wyślij pakiet
	mov	rax,	rcx
	add	rax,	SERVICE_NETWORK_STRUCTURE_FRAME_ETHERNET.SIZE + SERVICE_NETWORK_STRUCTURE_FRAME_IP.SIZE
	call	service_network_transfer

.end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"service_network_tcp_port_send"
