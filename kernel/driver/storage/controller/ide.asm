;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

DRIVER_IDE_CHANNEL_PRIMARY				equ	0x01F0
DRIVER_IDE_CHANNEL_PRIMARY_control			equ	0x03F6
DRIVER_IDE_CHANNEL_SECONDARY				equ	0x0170
DRIVER_IDE_CHANNEL_SECONDARY_control			equ	0x0376

DRIVER_IDE_REGISTER_data				equ	0x0000
DRIVER_IDE_REGISTER_error				equ	0x0001
DRIVER_IDE_REGISTER_sector_count_0			equ	0x0002
DRIVER_IDE_REGISTER_lba0				equ	0x0003
DRIVER_IDE_REGISTER_lba1				equ	0x0004
DRIVER_IDE_REGISTER_lba2				equ	0x0005
DRIVER_IDE_REGISTER_drive_OR_head			equ	0x0006
DRIVER_IDE_REGISTER_command_OR_status			equ	0x0007
; DRIVER_IDE_REGISTER_sector_count_1			equ	0x0008	; niewykorzystywane
; DRIVER_IDE_REGISTER_lba3				equ	0x0009	; niewykorzystywane
; DRIVER_IDE_REGISTER_lba4				equ	0x000A	; niewykorzystywane
; DRIVER_IDE_REGISTER_lba5				equ	0x000B	; niewykorzystywane
DRIVER_IDE_REGISTER_control_OR_altstatus		equ	0x000C	; niewykorzystywane
; DRIVER_IDE_REGISTER_device_address			equ	0x000D	; niewykorzystywane

DRIVER_IDE_DRIVE_master					equ	11100000b	; 1, LBA(1), 1, Master(0), 000
DRIVER_IDE_DRIVE_slave					equ	11110000b	; 1, LBA(1), 1, Slave(1), 000

DRIVER_IDE_CONTROL_nIEN					equ	00000010b
DRIVER_IDE_CONTROL_SRST					equ	00000100b

DRIVER_IDE_COMMAND_ATAPI_eject				equ	0x1B
DRIVER_IDE_COMMAND_read_pio				equ	0x20
DRIVER_IDE_COMMAND_read_pio_extended			equ	0x24
DRIVER_IDE_COMMAND_read_dma_extended			equ	0x25
DRIVER_IDE_COMMAND_write_pio				equ	0x30
DRIVER_IDE_COMMAND_write_pio_extended			equ	0x34
DRIVER_IDE_COMMAND_write_dma_extended			equ	0x35
DRIVER_IDE_COMMAND_packet				equ	0xA0
DRIVER_IDE_COMMAND_identify_packet			equ	0xA1
DRIVER_IDE_COMMAND_ATAPI_read				equ	0xA8
DRIVER_IDE_COMMAND_read_dma				equ	0xC8
DRIVER_IDE_COMMAND_write_dma				equ	0xCA
DRIVER_IDE_COMMAND_cache_flush				equ	0xE7
DRIVER_IDE_COMMAND_cache_flush_extended			equ	0xEA
DRIVER_IDE_COMMAND_identify				equ	0xEC

DRIVER_IDE_IDENTIFY_device_type				equ	0x00
DRIVER_IDE_IDENTIFY_cylinders				equ	0x02
DRIVER_IDE_IDENTIFY_heads				equ	0x06
DRIVER_IDE_IDENTIFY_sectors				equ	0x0C
DRIVER_IDE_IDENTIFY_serial				equ	0x14
DRIVER_IDE_IDENTIFY_model				equ	0x36
DRIVER_IDE_IDENTIFY_capabilities			equ	0x62
DRIVER_IDE_IDENTIFY_field_valid				equ	0x6A
DRIVER_IDE_IDENTIFY_max_lba				equ	0x78
DRIVER_IDE_IDENTIFY_command_sets			equ	0xA4
DRIVER_IDE_IDENTIFY_max_lba_extended			equ	0xC8

DRIVER_IDE_IDENTIFY_COMMAND_SETS_lba_extended		equ	1 << 26

DRIVER_IDE_STATUS_error					equ	00000001b	; ERR
DRIVER_IDE_STATUS_index					equ	00000010b
DRIVER_IDE_STATUS_corrected_data			equ	00000100b
DRIVER_IDE_STATUS_data_ready				equ	00001000b	; DRQ
DRIVER_IDE_STATUS_seek_complete				equ	00010000b	; SRV
DRIVER_IDE_STATUS_write_fault				equ	00100000b	; DF
DRIVER_IDE_STATUS_ready					equ	01000000b	; RDY
DRIVER_IDE_STATUS_busy					equ	10000000b	; BSY

DRIVER_IDE_ERROR_no_address_mark			equ	00000001b
DRIVER_IDE_ERROR_track_0_not_found			equ	00000010b
DRIVER_IDE_ERROR_command_aborted			equ	00000100b
DRIVER_IDE_ERROR_media_change_request			equ	00001000b
DRIVER_IDE_ERROR_id_mark_not_found			equ	00010000b
DRIVER_IDE_ERROR_media_changed				equ	00100000b
DRIVER_IDE_ERROR_uncorrectble_data			equ	01000000b
DRIVER_IDE_ERROR_bad_block				equ	10000000b

struc	DRIVER_IDE_STRUCTURE_DEVICE
	.blocks						resb	8
	.block_size					resb	4
	.channel					resb	2
	.drive						resb	1
	.reserved					resb	1
	.SIZE:
endstruc

driver_ide_entry_table:					dq	driver_ide_read	; read procedure
							dq	STATIC_EMPTY	; write procedure

; wyrównaj pozycję tablicy do pełnego adresu
align	STATIC_QWORD_SIZE_byte,				db	STATIC_NOTHING
driver_ide_devices:
	times	DRIVER_IDE_STRUCTURE_DEVICE.SIZE * 0x04	db	STATIC_EMPTY

;===============================================================================
; wejście:
;	rax - numer pierwszego sektora do odczytu (LBA)
;	rbx - identyfikator nośnika
;	rcx - łączna ilość sektorów
;	rdi - wskaźnik docelowy odczytanych danych
; wyjście:
;	Flaga CF, jeśli błąd odczytu lub brak nośnika
driver_ide_read:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rdi
	push	rax

	; domyślnie: flaga, błąd
	stc

	; identyfikator poprawny?
	cmp	rbx,	0x04	; maksymalna ilość nośników
	jnb	.end	; nie

	; zamień identyfikator na wskaźnik
	shl	bl,	4
	add	rbx,	driver_ide_devices

	; ustaw nośnik oraz przełącz go w tryb LBA
	mov	al,	byte [rbx + DRIVER_IDE_STRUCTURE_DEVICE.drive]
	mov	dx,	word [rbx + DRIVER_IDE_STRUCTURE_DEVICE.channel]
	add	dx,	DRIVER_IDE_REGISTER_drive_OR_head
	out	dx,	al

	; odczekaj na gotowość nośnika
	mov	dx,	word [rbx + DRIVER_IDE_STRUCTURE_DEVICE.channel]
	call	driver_ide_pool
	jc	.end	; błąd

	; przywróć numer pierwszego sektora
	pop	rax

	; wyślij informację o ilości i pierwszym sektorze do odczytu
	call	driver_ide_lba

	; odczekaj na gotowość nośnika
	mov	dx,	word [rbx + DRIVER_IDE_STRUCTURE_DEVICE.channel]
	call	driver_ide_pool
	jc	.end	; błąd

	; wydaj polecenie odczytu w rozszerzonym trybie PIO
	mov	al,	DRIVER_IDE_COMMAND_read_pio_extended
	mov	dx,	word [rbx + DRIVER_IDE_STRUCTURE_DEVICE.channel]
	add	dx,	DRIVER_IDE_REGISTER_command_OR_status
	out	dx,	al

	; odczekaj na gotowość nośnika
	mov	dx,	word [rbx + DRIVER_IDE_STRUCTURE_DEVICE.channel]
	call	driver_ide_pool
	jc	.end	; błąd

.read:
	; odczytaj pierwszy sektor
	mov	dx,	word [rbx + DRIVER_IDE_STRUCTURE_DEVICE.channel]
	add	dx,	DRIVER_IDE_REGISTER_data

	; zachowaj pozostałą ilość sektorów do odczytu
	push	rcx

	; pobierz z nośnika 256 słów
	mov	rcx,	256
	rep	insw

	; przywróć pozostałą ilość sektorów do odczytu
	pop	rcx

	; odczytano wszystkie sektory?
	dec	rcx
	jnz	.read	; nie

.end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	rax - numer pierwszego sektora do odczytu w postaci LBA
;	rbx - wskaźnik do identyfikatora nośnika
;	cl - ilość kolejnych sektorów do odczytu
driver_ide_lba:
	; zachowaj oryginalne rejestry
	push	rbx
	push	rdx
	push	rax

	; starsza część ilości odczytywanych sektorów
	mov	dx,	word [rbx + DRIVER_IDE_STRUCTURE_DEVICE.channel]
	add	dx,	DRIVER_IDE_REGISTER_sector_count_0
	mov	al,	0x00
	out	dx,	al

	; wyślij najstarsze 24 bitwy numeru sektora

	; al = 31..24
	mov	dx,	word [rbx + DRIVER_IDE_STRUCTURE_DEVICE.channel]
	add	dx,	DRIVER_IDE_REGISTER_lba0
	mov	rax,	qword [rsp]
	shr	rax,	24
	out	dx,	al

	; al = 39..32
	mov	dx,	word [rbx + DRIVER_IDE_STRUCTURE_DEVICE.channel]
	add	dx,	DRIVER_IDE_REGISTER_lba1
	mov	rax,	qword [rsp]
	shr	rax,	32
	out	dx,	al

	; al = 47..40
	mov	dx,	word [rbx + DRIVER_IDE_STRUCTURE_DEVICE.channel]
	add	dx,	DRIVER_IDE_REGISTER_lba2
	mov	rax,	qword [rsp]
	shr	rax,	40
	out	dx,	al

	; młodsza część ilości odczytywanych sektorów
	mov	dx,	word [rbx + DRIVER_IDE_STRUCTURE_DEVICE.channel]
	add	dx,	DRIVER_IDE_REGISTER_sector_count_0
	mov	al,	cl
	out	dx,	al

	; al = 7..0
	mov	dx,	word [rbx + DRIVER_IDE_STRUCTURE_DEVICE.channel]
	add	dx,	DRIVER_IDE_REGISTER_lba0
	mov	al,	byte [rsp]
	out	dx,	al

	; al = 15..8
	mov	dx,	word [rbx + DRIVER_IDE_STRUCTURE_DEVICE.channel]
	add	dx,	DRIVER_IDE_REGISTER_lba1
	mov	ax,	word [rsp]
	shr	ax,	8
	out	dx,	al

	; al = 23..16
	mov	dx,	word [rbx + DRIVER_IDE_STRUCTURE_DEVICE.channel]
	add	dx,	DRIVER_IDE_REGISTER_lba2
	mov	eax,	dword [rsp]
	shr	eax,	16
	out	dx,	al

	; przywróć oryginalne rejestry
	pop	rax
	pop	rdx
	pop	rbx

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	al - urządzenie MASTER lub SLAVE
;	dx - kanał PRIMARY lub SECONDARY
driver_ide_init_drive:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rax
	push	rdi
	push	rdx

	; wybierz urządzenie X na kanale Y
	add	dx,	DRIVER_IDE_REGISTER_drive_OR_head
	out	dx,	al

	; odczekaj na wykonanie polecenia
	call	driver_ide_wait

	; wyślij polecenie IDENTIFY	; kanał
	mov	al,	DRIVER_IDE_COMMAND_identify
	mov	dx,	word [rsp]
	add	dx,	DRIVER_IDE_REGISTER_command_OR_status
	out	dx,	al

	; odczekaj na wykonanie polecenia
	call	driver_ide_wait

	; pobierz status urządzenia X na kanale Y
	in	al,	dx

	; brak urządzenia?
	test	al,	al
	jz	.end	; tak

	; brak urządzenia?
	cmp	al,	STATIC_MAX_unsigned
	je	.end	; tak

	; wystąpił błąd na urządzeniu?
	test	al,	DRIVER_IDE_STATUS_error
	jnz	.end	; tak

	; odbierz oczekujące dane z polecenia IDENTIFY
	mov	ecx,	256	; 512 Bajtów
	mov	dx,	word [rsp]
	add	dx,	DRIVER_IDE_REGISTER_data
	rep	insw

	; przywróć wskaźnik do początku przestrzeni roboczej
	mov	rdi,	qword [rsp + STATIC_QWORD_SIZE_byte]

	; urządzenie wspiera tryb LBA Extended?
	mov	eax,	dword [rdi + DRIVER_IDE_IDENTIFY_command_sets]
	test	eax,	DRIVER_IDE_IDENTIFY_COMMAND_SETS_lba_extended
	jz	.end	; nie

	; nośnik zainicjowany, zarejestruj
	mov	rcx,	driver_ide_devices

	; kanał PRIMARY?
	mov	dx,	word [rsp]
	cmp	dx,	DRIVER_IDE_CHANNEL_PRIMARY
	je	.primary	; tak

	; nie, przesuń na wpis SECONDARY
	add	rcx,	DRIVER_IDE_STRUCTURE_DEVICE.SIZE << STATIC_MULTIPLE_BY_2_shift

.primary:
	; nośnik MASTER?
	mov	al,	byte [rsp + STATIC_QWORD_SIZE_byte * 0x02]
	cmp	al,	DRIVER_IDE_DRIVE_master
	je	.master	; tak

	; nie, przesuń na wpis SLAVE
	add	rcx,	DRIVER_IDE_STRUCTURE_DEVICE.SIZE

.master:
	; zachowaj kanał nośnika
	mov	word [rcx + DRIVER_IDE_STRUCTURE_DEVICE.channel],	dx

	; zachowaj urządzenie nośnika
	mov	byte [rcx + DRIVER_IDE_STRUCTURE_DEVICE.drive],	al

	; zachowaj rozmiar nośnika w sektorach
	mov	eax,	dword [rdi + DRIVER_IDE_IDENTIFY_max_lba_extended]
	mov	qword [rcx + DRIVER_IDE_STRUCTURE_DEVICE.blocks],	rax

.end:
	; przywróć oryginalne rejestry
	pop	rdx
	pop	rdi
	pop	rax
	pop	rcx

	; powrót z procedury
	ret

;===============================================================================
driver_ide_wait:
	; zachowaj oryginalne rejestry
	push	rax

	; pobierz znacznik czasu systemu w mikrosekundach
	mov	rax,	qword [driver_rtc_microtime]
	inc	rax	; odczekaj ~1ms

.wait:
	; odczekano?
	cmp	rax,	qword [driver_rtc_microtime]
	jnb	.wait	; nie

	; przywróć oryginalne rejestry
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
driver_ide_reset:
	; zachowaj oryginalne rejestry
	push	rax
	push	rdx

	; kanały
	mov	edx,	DRIVER_IDE_CHANNEL_SECONDARY << STATIC_MOVE_AX_TO_HIGH_shift | DRIVER_IDE_CHANNEL_PRIMARY

.next:
	; wyłącz nIEN na danym kanale kontrolera i przełącz w stan RESET
	mov	al,	DRIVER_IDE_CONTROL_nIEN | DRIVER_IDE_CONTROL_SRST
	add	dx,	DRIVER_IDE_REGISTER_control_OR_altstatus
	out	dx,	al

	; odczekaj 400ms
	in	al,	dx
	in	al,	dx
	in	al,	dx
	in	al,	dx

	; wyłącz stan RESET
	xor	al,	al
	out	dx,	al

	; odczekaj 400ms
	in	al,	dx
	in	al,	dx
	in	al,	dx
	in	al,	dx

	; następny kanał
	rol	edx,	STATIC_REPLACE_AX_WITH_HIGH_shift

	; zainicjalizowano obydwa?
	cmp	dx,	DRIVER_IDE_CHANNEL_PRIMARY + DRIVER_IDE_REGISTER_control_OR_altstatus
	jne	.next	; nie

	; przywróć oryginalne rejestry
	pop	rdx
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
driver_ide_init:
	; zachowaj oryginalne rejestry
	push	rax
	push	rdx
	push	rdi

	; inicjalizuj kontroler IDE
	call	driver_ide_reset

	; przygotuj przestrzeń roboczą
	call	kernel_memory_alloc_page

	; inicjalizuj urządzenie MASTER na kanale PRIMARY
	mov	al,	DRIVER_IDE_DRIVE_master
	mov	dx,	DRIVER_IDE_CHANNEL_PRIMARY
	call	driver_ide_init_drive

	; inicjalizuj urządzenie SLAVE na kanale PRIMARY
	mov	al,	DRIVER_IDE_DRIVE_slave
	mov	dx,	DRIVER_IDE_CHANNEL_PRIMARY
	call	driver_ide_init_drive

	; inicjalizuj urządzenie MASTER na kanale SECONDARY
	mov	al,	DRIVER_IDE_DRIVE_master
	mov	dx,	DRIVER_IDE_CHANNEL_SECONDARY
	call	driver_ide_init_drive

	; inicjalizuj urządzenie SLAVE na kanale SECONDARY
	mov	al,	DRIVER_IDE_DRIVE_slave
	mov	dx,	DRIVER_IDE_CHANNEL_SECONDARY
	call	driver_ide_init_drive

	; zwolnij przestrzeń roboczą
	call	kernel_memory_release_page

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rdx
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	dx - kontroler PRIMARY/SECONDARY
driver_ide_pool:
	; zachowaj oryginalne rejestry
	push	rax
	push	rdx

	; odczekaj 400ms
	add	dx,	DRIVER_IDE_REGISTER_control_OR_altstatus
	in	al,	dx
	in	al,	dx
	in	al,	dx
	in	al,	dx

	; wybierz rejestr kontrolera
	mov	dx,	word [rsp]
	add	dx,	DRIVER_IDE_REGISTER_command_OR_status

	; brak urządzeń?
	test	al,	al
	jz	.error	; tak

	; brak urządzeń?
	cmp	al,	STATIC_MAX_unsigned
	jne	.wait	; tak

.error:
	; flaga, błąd
	stc

	; koniec obsługi procedury
	jmp	.end

.wait:
	; pobierz stan urządzeń na kanale
	in	al,	dx
	and	al,	DRIVER_IDE_STATUS_busy | DRIVER_IDE_STATUS_ready
	cmp	al,	DRIVER_IDE_STATUS_ready
	jne	.wait	; urządzenia nadal niegotowe, czekaj

	; flaga, sukces
	clc

.end:
	; przywróć oryginalne rejestry
	pop	rdx
	pop	rax

	; powrót z procedury
	ret
