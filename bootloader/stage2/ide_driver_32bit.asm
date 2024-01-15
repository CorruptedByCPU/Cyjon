;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

; Use:
; nasm - http://www.nasm.us/

VARIABLE_IDE_PRIMARY			equ	0x01F0
VARIABLE_IDE_PRIMARY_REG_DATA		equ	0x01F0
VARIABLE_IDE_PRIMARY_REG_FEATURES	equ	0x01F1
VARIABLE_IDE_PRIMARY_REG_COUNTER	equ	0x01F2
VARIABLE_IDE_PRIMARY_REG_LBA_LOW	equ	0x01F3
VARIABLE_IDE_PRIMARY_REG_LBA_MIDDLE	equ	0x01F4
VARIABLE_IDE_PRIMARY_REG_LBA_HIGH	equ	0x01F5
VARIABLE_IDE_PRIMARY_REG_DRIVE		equ	0x01F6
VARIABLE_IDE_PRIMARY_REG_STATUS		equ	0x01F7
VARIABLE_IDE_PRIMARY_REG_COMMAND	equ	0x01F7
VARIABLE_IDE_PRIMARY_REG_ALTERNATE	equ	0x03F6
VARIABLE_IDE_PRIMARY_REG_CONTROL	equ	0x03F6

VARIABLE_IDE_PRIMARY_MASTER		equ	0xA0
VARIABLE_IDE_PRIMARY_SLAVE		equ	0xB0

VARIABLE_IDE_CMD_READ_PIO_EXT		equ	0x24
VARIABLE_IDE_CMD_WRITE_PIO_EXT		equ	0x34
VARIABLE_IDE_CMD_CACHE_FLUSH_EXT	equ	0xEA
VARIABLE_IDE_CMD_IDENTIFY		equ	0xEC

VARIABLE_IDE_SR_ERR			equ	0	; 00000001b	0x01
VARIABLE_IDE_SR_DRQ			equ	3	; 00001000b	0x08
VARIABLE_IDE_SR_DF			equ	5	; 00100000b	0x20
VARIABLE_IDE_SR_BSY			equ	7	; 10000000b	0x80

VARIABLE_IDE_IDENTIFY_SERIAL		equ	20
VARIABLE_IDE_IDENTIFY_MODEL		equ	54
VARIABLE_IDE_IDENTIFY_SIZE		equ	100

; 32 Bitowy kod programu
[BITS 32]

stage2_ide_drive_initialize:
	; ustaw interfejs na dysk IDE0 Master PIO
	mov	eax,	ide_drive_read
	mov	dword [variable_disk_interface_read],	eax

	; powrót z procedury
	ret

; eax - numer sektora w postaci LBA
; ecx - ilość sektorów do odczytania
; edi - adres w pamięci do zapisania sektorów
ide_drive_read:
	; zachowaj oryginalne rejestry
	push	eax
	push	ebx
	push	ecx
	push	edx
	push	edi
	push	eax

	mov	dx,	VARIABLE_IDE_PRIMARY_REG_STATUS

.wait_ready:
	; poczekaj na gotowość urządzenia
	in	al,	dx
	bt	ax,	VARIABLE_IDE_SR_BSY
	jc	.wait_ready	; urządzenie jest zajęte

	; wyślij polecenie - tryb LBA
	mov	ax,	0xE0
	mov	dx,	VARIABLE_IDE_PRIMARY_REG_DRIVE
	out	dx,	al

	; przywróć numer pierwszego sektora i załaduj do urządzenia
	pop	eax
	call	.ide_lba

	; wyślij polecenie odczytu
	mov	al,	VARIABLE_IDE_CMD_READ_PIO_EXT
	mov	dx,	VARIABLE_IDE_PRIMARY_REG_COMMAND
	out	dx,	al

.read:
	; czekaj na odpowiedź urządzenia
	call	.ide_pool

	mov	dx,	VARIABLE_IDE_PRIMARY_REG_DATA

	; zachowaj licznik pętli
	push	ecx

	mov	ecx,	256
	rep	insw

	; przywróć licznik pętli
	pop	ecx

	; sprawdź czy przetwarzać następne
	sub	ecx,	VARIABLE_DECREMENT
	jnz	.read

	; przywróć oryginalne rejestry
	pop	edi
	pop	edx
	pop	ecx
	pop	ebx
	pop	eax

	; powrót z procedury
	ret

.ide_pool:
	push	ecx
	push	edx

	; odczekaj blicko 400ns, na gotowość udządzenia
	mov	cl,	4

	mov	dx,	VARIABLE_IDE_PRIMARY_REG_ALTERNATE

.wait:
	in	al,	dx
	sub	ecx,	VARIABLE_DECREMENT
	jnz	.wait	; czekaj kolejne 100ns

.busy:
	; pobierz status urządzenia
	in	al,	dx

	bt	ax,	VARIABLE_IDE_SR_BSY
	jc	.busy	; urządzenie jest zajęte przetwarzaniem polecenia

	in	al,	dx

	bt	ax,	VARIABLE_IDE_SR_ERR
	jc	.error

	bt	ax,	VARIABLE_IDE_SR_DF
	jc	.error

	bt	ax,	VARIABLE_IDE_SR_DRQ
	jnc	.error

	; urządzenie gotowe do przesyłania danych

	; przywróć oryginalne rejestry
	pop	edx
	pop	ecx

	; powrót z procedury
	ret

.ide_lba:
	; zachowaj
	mov	ebx,	eax

	; starsza część ilości odczytywanych sektorów
	mov	dx,	VARIABLE_IDE_PRIMARY_REG_COUNTER
	mov	al,	0x00
	out	dx,	al

	; wyślij 48 bitowy numer sektora

	; al = 31..24
	mov	dx,	VARIABLE_IDE_PRIMARY_REG_LBA_LOW
	mov	eax,	ebx
	shr	eax,	24
	out	dx,	al

	; al = 39..32
	mov	dx,	VARIABLE_IDE_PRIMARY_REG_LBA_MIDDLE
	xor	al,	al
	out	dx,	al

	; al = 47..40
	mov	dx,	VARIABLE_IDE_PRIMARY_REG_LBA_HIGH
	out	dx,	al

	; młodsza część ilości odczytywanych sektorów
	mov	dx,	VARIABLE_IDE_PRIMARY_REG_COUNTER
	mov	al,	cl
	out	dx,	al

	; al = 7..0
	mov	dx,	VARIABLE_IDE_PRIMARY_REG_LBA_LOW
	mov	al,	bl
	out	dx,	al

	; al = 15..8
	mov	dx,	VARIABLE_IDE_PRIMARY_REG_LBA_MIDDLE
	mov	al,	bh
	out	dx,	al

	; al = 23..16
	mov	dx,	VARIABLE_IDE_PRIMARY_REG_LBA_HIGH
	mov	eax,	ebx
	shr	eax,	16
	out	dx,	al

	; powrót z procedury
	ret

.error:
	jmp	$
