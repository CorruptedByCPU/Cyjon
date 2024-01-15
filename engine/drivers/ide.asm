;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Driver based on BareMetal OS https://github.com/ReturnInfinity/BareMetal-OS
;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

; Use:
; nasm - http://www.nasm.us/

VARIABLE_IDE_PRIMARY				equ	0x01F0
VARIABLE_IDE_SECONDARY				equ	0x0170

VARIABLE_IDE_MASTER				equ	0xA0
VARIABLE_IDE_SLAVE				equ	0xB0

VARIABLE_IDE_REGISTER_DATA			equ	0x00
VARIABLE_IDE_REGISTER_FEATURES			equ	0x01
VARIABLE_IDE_REGISTER_COUNTER			equ	0x02
VARIABLE_IDE_REGISTER_LBA_LOW			equ	0x03
VARIABLE_IDE_REGISTER_LBA_MIDDLE		equ	0x04
VARIABLE_IDE_REGISTER_LBA_HIGH			equ	0x05
VARIABLE_IDE_REGISTER_DRIVE			equ	0x06
VARIABLE_IDE_REGISTER_DRIVE_MASTER		equ	10100000b
VARIABLE_IDE_REGISTER_DRIVE_SLAVE		equ	10110000b
VARIABLE_IDE_REGISTER_DRIVE_LBA			equ	11100000b
VARIABLE_IDE_REGISTER_STATUS			equ	0x07
VARIABLE_IDE_REGISTER_STATUS_BIT_ERR		equ	0
VARIABLE_IDE_REGISTER_STATUS_BIT_DRQ		equ	3
VARIABLE_IDE_REGISTER_STATUS_BIT_DF		equ	5
VARIABLE_IDE_REGISTER_STATUS_BIT_BSY		equ	7
VARIABLE_IDE_REGISTER_COMMAND			equ	0x07
VARIABLE_IDE_REGISTER_COMMAND_READ_PIO_EXT	equ	0x24
VARIABLE_IDE_REGISTER_COMMAND_WRITE_PIO_EXT	equ	0x34
VARIABLE_IDE_REGISTER_COMMAND_CACHE_FLUSH_EXT	equ	0xEA
VARIABLE_IDE_REGISTER_COMMAND_IDENTIFY		equ	0xEC
VARIABLE_IDE_REGISTER_COMMAND_IDENTIFY_SIZE	equ	128

VARIABLE_IDE_REGISTER_ALTERNATE			equ	0x0206
VARIABLE_IDE_REGISTER_CONTROL			equ	0x0206
VARIABLE_IDE_REGISTER_CONTROL_nIEN		equ	00000010b
VARIABLE_IDE_REGISTER_CONTROL_SRST		equ	00000100b
VARIABLE_IDE_REGISTER_CONTROL_HOB		equ	10000000b

table_ide:
	dw	0x01F0	; primary
	; blokuję drugi kontroler, Qemu ma jakiś problem z samym sobą
	; Bochs działa od strzału...
	; zablokowałem też drugie urządzenie na pierwszym kontrolerze
	; debug
	;dw	0x0170	; secondary
	dw	VARIABLE_EMPTY

variable_ide_sector_size			dq	512	; Bajtów
variable_ide_disks				dq	VARIABLE_EMPTY

struc	STRUCTURE_IDE_DISK
	.controller		resb	2
	.device			resb	1
	.type			resb	2
	.cylinders		resb	2
	.reserved0		resb	2
	.heads			resb	2
	.special0		resb	4
	.sectors		resb	2
	.vendor_unique_0	resb	6
	.serial			resb	20
	.buffer_type		resb	2
	.buffer_size		resb	2
	.ecc			resb	2
	.revision		resb	8
	.model			resb	40
	.vendor_unique_1	resb	2
	.doubleword		resb	2
	.capabilities		resb	2
	.reserved_0		resb	2
	.pio_timing_mode	resb	2
	.dma_timing_mode	resb	2
	.current_valid		resb	2
	.cylinders_current	resb	2
	.heads_current		resb	2
	.sectors_current	resb	2
	.capacity_current	resb	4
	.reserved_2		resb	2
	.capacity_lba		resb	4
	.other			resb	256 - STRUCTURE_IDE_DISK.capacity_lba
	.SIZE			resb	1
endstruc

variable_ide0					db	"IDE0 ", VARIABLE_ASCII_CODE_TERMINATOR
variable_ide1					db	"IDE1 ",	VARIABLE_ASCII_CODE_TERMINATOR
variable_master					db	"Master ", VARIABLE_ASCII_CODE_TERMINATOR
variable_slave					db	"Slave  ", VARIABLE_ASCII_CODE_TERMINATOR

; 64 Bitowy kod programu
[BITS 64]

ide_initialize:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi

.wait:
	; przydziel przestrzeń pod specyfikacje dostępnych nośników
	call	cyjon_page_allocate

	; czekaj na przydzielenie przestrzeni
	cmp	rdi,	VARIABLE_EMPTY
	je	.wait

	; zapisz
	mov	qword [variable_ide_disks],	rdi

	; przetwarzaj pierwszy kontroler
	mov	rsi,	table_ide

.second_controller:
	; sprawdź napęd MASTER
	mov	bx,	VARIABLE_IDE_MASTER

	; wyłącz przerwania dla kontrolera IDEn
	mov	al,	VARIABLE_IDE_REGISTER_CONTROL_nIEN
	mov	dx,	word [rsi]
	add	dx,	VARIABLE_IDE_REGISTER_CONTROL
	out	dx,	al

.second_drive:
	; wybierz napęd podpięty pod kontroler IDEn
	mov	al,	bl
	mov	dx,	word [rsi]
	add	dx,	VARIABLE_IDE_REGISTER_DRIVE
	out	dx,	al

	; czekaj na gotowość napędu
	call	ide_wait

	; wyślij polecenie identyfikacji podpiętego urządzenia
	mov	al,	VARIABLE_IDE_REGISTER_COMMAND_IDENTIFY
	mov	dx,	word [rsi]
	add	dx,	VARIABLE_IDE_REGISTER_COMMAND
	out	dx,	al

	; czekaj na gotowość napędu
	call	ide_wait

	; sprawdź odpowiedź z podpiętego urządzenia
	in	al,	dx	; VARIABLE_IDE_REGISTER_STATUS

	; pobierz status nośnika, jeśli ZERO brak podpiętego
	cmp	al,	VARIABLE_EMPTY
	ja	.device_busy

.next_drive:
	; sprawdzono obydwa napędy?
	cmp	bl,	VARIABLE_IDE_SLAVE
	je	.next_controller

	; sprawdź czy podpięty jest drugi nośnik do tego samego kontrolera
	mov	bx,	VARIABLE_IDE_SLAVE

	; kontynuuj
	; debug
	;jmp	.second_drive

.next_controller:
	; następny rekod z tablicy kontrolerów
	add	rsi,	VARIABLE_WORD_SIZE

	; koniec kontrolerów?
	cmp	word [rsi],	VARIABLE_EMPTY
	jne	.second_controller

.end:
	; sprawdź czy znaleziono jakiekolwiek nośniki ATA
	mov	rsi,	qword [variable_ide_disks]

	; jeśli istnieje pierwszy rekord, wyświetl nagłówek
	cmp	word [rsi],	VARIABLE_EMPTY
	je	.terminate	; nie

	; wyświetl informacje o wykrytych nośnikach
	mov	rbx,	VARIABLE_COLOR_LIGHT_GREEN
	mov	rcx,	VARIABLE_FULL
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_caution
	call	cyjon_screen_print_string
	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	rsi,	text_ide_found
	call	cyjon_screen_print_string

	; dekoduj nazwy i numery seryjny nośników
	call	ide_decode

	; wyświetl dostępne nośniki danych
	call	ide_show_devices

.terminate:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

.device_busy:
	; pobierz status urządzenia
	in	al,	dx

	; czy nośnik zajęty przetwarzaniem polecenia?
	bt	ax,	VARIABLE_IDE_REGISTER_STATUS_BIT_BSY
	jc	.device_busy
	; czy nośnik zajęty przetwarzaniem polecenia?
	bt	ax,	VARIABLE_IDE_REGISTER_STATUS_BIT_DRQ
	jnc	.device_busy

	; zachowaj adres kontrolera
	mov	ax,	word [rsi]
	stosw

	; zachowaj numer nośnika na kontrolerze
	mov	al,	bl
	stosb

	; zachowaj licznik kontrolerów
	push	rcx

	; zapisz strukturę informacyjną nośnika
	mov	rcx,	VARIABLE_IDE_REGISTER_COMMAND_IDENTIFY_SIZE
	mov	dx,	word [rsi]	; == VARIABLE_IDE_REGISTER_DATA
	rep	insw

	; przywróć licznik kontrolerów
	pop	rcx

	; kontynuuj z pozostałymi nośnikami
	jmp	.next_drive

;-----------------------------------------------------------------------
; odczekaj 400ns
ide_wait:
	; zachowaj oryginalne rejestry
	push	rax
	push	rdx

	mov	dx,	word [rsi + STRUCTURE_IDE_DISK.controller]
	add	dx,	VARIABLE_IDE_REGISTER_ALTERNATE
	in	al,	dx

	; przywróć oryginalne rejestry
	pop	rdx
	pop	rax

	; powrót z procedury
	ret

;-----------------------------------------------------------------------
; ustaw na swoje pozycje znaki
ide_decode:
	; początek tablicy
	mov	rsi,	qword [variable_ide_disks]

.next_record:
	; jeśli brak dalszych rekordów, koniec
	cmp	word [rsi],	VARIABLE_EMPTY
	je	.end

	; dekoduj nazwę nośnika
	mov	rcx,	( STRUCTURE_IDE_DISK.vendor_unique_1 - STRUCTURE_IDE_DISK.model ) / VARIABLE_WORD_SIZE
	add	rsi,	STRUCTURE_IDE_DISK.model

.loop_name:
	; pobierz dwa znaki z nazwy nośnika
	lodsw

	; zmień miejscami
	xchg	al,	ah

	; aktualizuj
	mov	word [rsi - VARIABLE_WORD_SIZE],	ax

	; kontynuuj z pozostałymi
	loop	.loop_name

	; dekoduj numer seryjny nośnika
	mov	rcx,	( STRUCTURE_IDE_DISK.buffer_type - STRUCTURE_IDE_DISK.serial ) / VARIABLE_WORD_SIZE
	sub	rsi,	STRUCTURE_IDE_DISK.vendor_unique_1
	add	rsi,	STRUCTURE_IDE_DISK.serial

.loop_serial:
	; pobierz dwa znaki z nazwy nośnika
	lodsw

	; zmień miejscami
	xchg	al,	ah

	; aktualizuj
	mov	word [rsi - VARIABLE_WORD_SIZE],	ax

	; kontynuuj z pozostałymi
	loop	.loop_serial

	; następny rekord
	sub	rsi,	STRUCTURE_IDE_DISK.buffer_type
	add	rsi,	STRUCTURE_IDE_DISK.SIZE

	; kontynuuj
	jmp	.next_record

.end:
	; powrót z procedury
	ret

;-----------------------------------------------------------------------
; wyświetl podstawowe informacje o odnalezionych nośnikach
ide_show_devices:
	; wskaźnik początku tablicy
	mov	rdi,	qword [variable_ide_disks]

.loop:
	; jeśli brak następnych nośników do wyświetlenia, koniec
	cmp	word [rdi],	VARIABLE_EMPTY
	je	.end

	; przesuń kursor na poczatek listy
	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	rcx,	VARIABLE_FULL
	mov	rsi,	text_subsub
	call	cyjon_screen_print_string

	; wyświetl informacje i kontrolerze i urządzeniu
	cmp	word [rdi + STRUCTURE_IDE_DISK.controller],	VARIABLE_IDE_PRIMARY
	jne	.secondary

	; kontroler 0
	mov	rsi,	variable_ide0
	jmp	.print_controller

.secondary:
	; kontroler 1
	mov	rsi,	variable_ide1

.print_controller:
	call	cyjon_screen_print_string

	; pozycja urządzenia w kontrolerze
	cmp	byte [rdi + STRUCTURE_IDE_DISK.device],	VARIABLE_IDE_MASTER
	jne	.slave

	; urządzenie pierwsze
	mov	rsi,	variable_master
	jmp	.print_device

.slave:
	; urządzenie drugie
	mov	rsi,	variable_slave

.print_device:
	call	cyjon_screen_print_string

	; zachowaj wskaźnik
	push	rdi

	; wyświetl nazwę nośnika ---------------------------------------
	mov	rbx,	VARIABLE_COLOR_WHITE
	mov	rcx,	STRUCTURE_IDE_DISK.vendor_unique_1 - STRUCTURE_IDE_DISK.model
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	add	rdi,	STRUCTURE_IDE_DISK.model
	call	library_trim
	mov	rsi,	rdi
	call	cyjon_screen_print_string

	; wyświetl numer seryjny
	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	cl,	VARIABLE_FULL
	mov	rsi,	text_ide_serial
	call	cyjon_screen_print_string

	; przywróć wskaźnik
	mov	rdi,	qword [rsp]

	; numer seryjny nośnika ----------------------------------------
	mov	rbx,	VARIABLE_COLOR_WHITE
	mov	rcx,	STRUCTURE_IDE_DISK.buffer_type - STRUCTURE_IDE_DISK.serial
	add	rdi,	STRUCTURE_IDE_DISK.serial
	call	library_trim
	mov	rsi,	rdi
	call	cyjon_screen_print_string

	; wyświetl rozmiar nośnika
	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	cl,	VARIABLE_FULL
	mov	rsi,	text_ide_size
	call	cyjon_screen_print_string

	; przywróć wskaźnik
	mov	rdi,	qword [rsp]

	; pobierz rozmiar w sektorach z pola LBA
	mov	eax,	dword [rdi + STRUCTURE_IDE_DISK.capacity_lba]
	cmp	eax,	VARIABLE_EMPTY	; brak wsparcia dla LBA?
	ja	.size_type

	; pobierz rozmiar w sektorach z pola CHS
	mov	eax,	dword [rdi + STRUCTURE_IDE_DISK.capacity_current]

.size_type:
	; usuń informacje o sektorach
	shl	rax,	VARIABLE_MULTIPLE_BY_512

	; zamień na formę skróconą
	call	library_translate_size_and_type

	; rozmiar nośnika ----------------------------------------------
	mov	rbx,	VARIABLE_COLOR_WHITE
	mov	cx,	VARIABLE_SYSTEM_DECIMAL
	call	cyjon_screen_print_number

	; wyświetl typ rozmiaru
	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	rcx,	VARIABLE_FULL
	call	cyjon_screen_print_string

	; przesuń kursor do nowej linii
	mov	rcx,	VARIABLE_FULL
	mov	rsi,	text_return
	call	cyjon_screen_print_string

	; przywróć wskaźnik
	pop	rdi

	; przesuń wskaźnik na następny rekord tablicy
	add	rdi,	STRUCTURE_IDE_DISK.SIZE

	; kontynuuj
	jmp	.loop

.end:
	; powrót z procedury
	ret

; rax - lba
; rcx - ilość sektorów
; rsi - wskaźnik do opisu struktury nośnika
; rdi - gdzie zapisać
ide_read_sectors:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rdi
	push	rax

	; post statusu urządzenia
	mov	dx,	word [rsi + STRUCTURE_IDE_DISK.controller]
	add	dx,	VARIABLE_IDE_REGISTER_STATUS

.wait:
	; pobierz status urządzenia
	in	al,	dx

	; czy urządzenie jest zajęte przetwarzaniem polecenia?
	bt	ax,	VARIABLE_IDE_REGISTER_STATUS_BIT_BSY
	jc	.wait

	; wybierz nośnik z kontrolera
	movzx	ax,	byte [rsi + STRUCTURE_IDE_DISK.device]

	; tryb LBA
	or	ax,	VARIABLE_IDE_REGISTER_DRIVE_LBA

	; przygotuj nośnik
	mov	dx,	word [rsi + STRUCTURE_IDE_DISK.controller]
	add	dx,	VARIABLE_IDE_REGISTER_DRIVE
	out	dx,	al

	pop	rax

	; ustaw pozycje sektora w trybie LBA
	call	ide_lba

	; poinformuj nośnik o odczycie
	mov	al,	VARIABLE_IDE_REGISTER_COMMAND_READ_PIO_EXT
	mov	dx,	word [rsi + STRUCTURE_IDE_DISK.controller]
	add	dx,	VARIABLE_IDE_REGISTER_COMMAND
	out	dx,	al

.read:
	; czekaj na gotowość nośnika
	call	ide_pool
	cmp	al,	VARIABLE_EMPTY
	je	.ok

	; wystąpił błąd urządzenia
	jmp	$

.ok:
	mov	dx,	word [rsi + STRUCTURE_IDE_DISK.controller]
	add	dx,	VARIABLE_IDE_REGISTER_DATA

	push	rcx

	mov	rcx,	256
	rep	insw

	pop	rcx

	sub	rcx,	VARIABLE_DECREMENT
	jnz	.read

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

ide_pool:
	push	rcx
	push	rdx

	; czekaj na nośnik 400ns
	call	ide_wait

	; status nośnika
	mov	dx,	word [rsi + STRUCTURE_IDE_DISK.controller]
	add	dx,	VARIABLE_IDE_REGISTER_ALTERNATE

.bsy_bit:
	; pobierz status urządzenia
	in	al,	dx

	; urządzenie jest zajęte przetwarzaniem polecenia?
	bt	ax,	VARIABLE_IDE_REGISTER_STATUS_BIT_BSY
	jc	.bsy_bit

	; pobierz status urządzenia
	in	al,	dx

	; brak błędów?
	bt	ax,	VARIABLE_IDE_REGISTER_STATUS_BIT_ERR
	jnc	.no_err

	; błąd
	mov	ax,	2

	jmp	.end

.no_err:
	bt	ax,	VARIABLE_IDE_REGISTER_STATUS_BIT_DF
	jnc	.no_df

	; błąd urządzenia
	mov	al,	1

	jmp	.end

.no_df:
	bt	ax,	VARIABLE_IDE_REGISTER_STATUS_BIT_DRQ
	jc	.ok

	; błąd - brak danych do przesłania
	mov	al,	3

	jmp	.end

.ok:
	xor	al,	al

.end:
	; przywróć oryginalne rejestry
	pop	rdx
	pop	rcx

	; powrót z procedury
	ret

ide_lba:
	; zachowaj
	mov	rbx,	rax

	; starsza część ilości odczytywanych sektorów
	mov	dx,	word [rsi + STRUCTURE_IDE_DISK.controller]	
	add	dx,	VARIABLE_IDE_REGISTER_COUNTER
	mov	al,	VARIABLE_EMPTY
	out	dx,	al

	; wyślij 48 bitowy numer sektora

	; al = 31..24
	inc	dx	; VARIABLE_IDE_REGISTER_LBA_LOW
	mov	rax,	rbx
	shr	rax,	24
	out	dx,	al

	; al = 39..32
	inc	dx	; VARIABLE_IDE_REGISTER_LBA_MIDDLE
	mov	rax,	rbx
	shr	rax,	VARIABLE_MOVE_HIGH_RAX_TO_EAX
	out	dx,	al

	; al = 47..40
	inc	dx,	; VARIABLE_IDE_REGISTER_LBA_HIGH
	mov	rax,	rbx
	shr	rax,	40
	out	dx,	al

	; młodsza część ilości odczytywanych sektorów
	sub	dx,	0x03	; VARIABLE_IDE_REGISTER_COUNTER
	mov	al,	cl
	out	dx,	al

	; al = 7..0
	inc	dx	; VARIABLE_IDE_REGISTER_LBA_LOW
	mov	rax,	rbx
	out	dx,	al

	; al = 15..8
	inc	dx	; VARIABLE_IDE_REGISTER_LBA_MIDDL
	mov	al,	bh
	out	dx,	al

	; al = 23..16
	inc	dx,	; VARIABLE_IDE_REGISTER_LBA_HIGH
	mov	rax,	rbx
	shr	rax,	VARIABLE_MOVE_HIGH_EAX_TO_AX
	out	dx,	al

	; powrót z procedury
	ret
