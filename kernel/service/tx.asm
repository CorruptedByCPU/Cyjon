;===============================================================================
; Copyright (C) by Andrzej Adamczyk at Blackend.dev
;===============================================================================

SERVICE_TX_CACHE_SIZE_page	equ	1

service_tx_semaphore		db	STATIC_TRUE	; domyślnie zablokowany dostęp

service_tx_cache_address	dq	STATIC_EMPTY
service_tx_cache_pointer	dq	((SERVICE_TX_CACHE_SIZE_page << STATIC_MULTIPLE_BY_PAGE_shift) / SERVICE_TX_STRUCTURE_CACHE.SIZE) - 0x01	; liczymy od zera

struc	SERVICE_TX_STRUCTURE_CACHE
	.size			resb	8
	.address		resb	8
	.SIZE:
endstruc

;===============================================================================
service_tx:
	; przygotuj przestrzeń pod bufor
	mov	rcx,	SERVICE_TX_CACHE_SIZE_page
	call	kernel_memory_alloc
	jc	service_tx	; spróbuj raz jeszcze

	; wyczyść bufor
	call	kernel_page_drain_few

	; zachowaj adres bufora
	mov	qword [service_tx_cache_address],	rdi

.reload:
	; odblokuj dostęp do bufora
	mov	byte [service_tx_semaphore],	STATIC_FALSE

	; ustaw wskaźnik na pierwszy wpis bufora
	mov	rsi,	qword [service_tx_cache_address]

.loop:
	; bufor zablokowany?
	cmp	byte [service_tx_semaphore],	STATIC_TRUE
	je	.loop	; tak, czekaj na odblokowanie

	; brak wpisu?
	cmp	qword [rsi],	STATIC_EMPTY
	je	.loop	; czekaj (sprawdź) dalej

	; wyślij
	mov	ax,	word [rsi + SERVICE_TX_STRUCTURE_CACHE.size]
	mov	rdi,	qword [rsi + SERVICE_TX_STRUCTURE_CACHE.address]
	call	driver_nic_i82540em_transfer

	; zablokuj dostęp do bufora
	macro_close	service_tx_semaphore, 0

	; usuń wpis

	; zwolnij przestrzeń pakietu
	call	kernel_memory_release_page

	; ustaw wskaźniki na pozycję
	mov	rdi,	rsi
	add	rsi,	SERVICE_TX_STRUCTURE_CACHE.SIZE

	; ilość wpisów do przesunięcia
	mov	rcx,	((SERVICE_TX_CACHE_SIZE_page << STATIC_MULTIPLE_BY_PAGE_shift) / SERVICE_TX_STRUCTURE_CACHE.SIZE) - 0x01
	sub	rcx,	qword [service_tx_cache_pointer]

.move:
	; przesuń pierwszy wpis
	movsq
	movsq

	; koniec bufora?
	dec	rcx
	jnz	.move	; nie, kontynuuj

	; ilość wolnych wpisów
	inc	qword [service_tx_cache_pointer]

	; powrót do pętli głównej
	jmp	.reload

	macro_debug	"service_tx"

;===============================================================================
; wejście:
;	eax - rozmiar pakietu w Bajtach
;	rdi - wskaźnik do przestrzeni pakietu
; wyjście:
;	Flaga CF - jeśli bufor pełny
service_tx_add:
	; zachowaj oryginalne rejestry
	push	rsi

	; zablokuj dostęp do bufora
	macro_close	service_tx_semaphore, 0

	; wolne miejsce w buforze?
	cmp	qword [service_tx_cache_pointer],	STATIC_EMPTY
	je	.error	; nie

	; ustal pozycję wolnego wpisu
	mov	rsi,	((SERVICE_TX_CACHE_SIZE_page << STATIC_MULTIPLE_BY_PAGE_shift) / SERVICE_TX_STRUCTURE_CACHE.SIZE) - 0x01
	sub	rsi,	qword [service_tx_cache_pointer]
	shl	rsi,	STATIC_MULTIPLE_BY_16_shift
	add	rsi,	qword [service_tx_cache_address]

	; ustaw informacje o pakiecie do wysłania
	mov	dword [rsi + SERVICE_TX_STRUCTURE_CACHE.size],	eax
	mov	qword [rsi + SERVICE_TX_STRUCTURE_CACHE.address],	rdi

	; ilość wolnych wpisów
	dec	qword [service_tx_cache_pointer]

	; koniec obsługi zgłoszenia
	jmp	.end

.error:
	; flaga, błąd
	stc

.end:
	; odblokuj dostęp do bufora
	mov	byte [service_tx_semaphore],	STATIC_FALSE

	; przywróć oryginalne rejestry
	pop	rsi

	; powrót z procedury
	ret

	macro_debug	"service_tx_add"
