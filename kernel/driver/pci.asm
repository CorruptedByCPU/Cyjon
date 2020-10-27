;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

DRIVER_PCI_PORT_command			equ	0x0CF8
DRIVER_PCI_PORT_data			equ	0x0CFC

DRIVER_PCI_REGISTER_vendor_and_device	equ	0x00
DRIVER_PCI_REGISTER_status_and_command	equ	0x04
DRIVER_PCI_REGISTER_class_and_subclass	equ	0x08
DRIVER_PCI_REGISTER_bar0		equ	0x10
DRIVER_PCI_REGISTER_bar1		equ	0x14
DRIVER_PCI_REGISTER_bar2		equ	0x18
DRIVER_PCI_REGISTER_bar3		equ	0x1C
DRIVER_PCI_REGISTER_bar4		equ	0x20
DRIVER_PCI_REGISTER_bar5		equ	0x24
DRIVER_PCI_REGISTER_irq			equ	0x3C
DRIVER_PCI_REGISTER_FLAG_64_bit		equ	00000010b

DRIVER_PCI_CLASS_SUBCLASS_ide		equ	0x0101
DRIVER_PCI_CLASS_SUBCLASS_ahci		equ	0x0106
DRIVER_PCI_CLASS_SUBCLASS_scsi		equ	0x0107
DRIVER_PCI_CLASS_SUBCLASS_network	equ	0x0200

;============================================================================
; wejście:
;	eax - poszukiwana wartość
;		high - device
;		low - vendor
; wyjście:
;	Flaga CF, jeśli nie znaleziono
;	ebx - szyna
;	ecx - urządzenie
;	edx - funkcja
driver_pci_find_vendor_and_device:
	; zachowaj oryginalne rejestry
	push	rbx
	push	rcx
	push	rdx
	push	rax

	; szyna 0
	xor	ebx,	ebx
	; urządzenie 0
	xor	ecx,	ecx
	; funkcja 0
	xor	edx,	edx

.next:
	; pobierz zawartość rejestru Vendor & Device
	mov	eax,	DRIVER_PCI_REGISTER_vendor_and_device
	call	driver_pci_read

	; poszukiwany Vendor i Device?
	cmp	eax,	dword [rsp]
	je	.found	; tak

	; następna funkcja
	inc	edx

	; koniec przeglądanych funkcji?
	cmp	edx,	0x0008
	jb	.next	; nie

	; następne urządzenie na szynie
	inc	ecx

	; pierwsza funkcja urządzenia
	xor	edx,	edx

	; koniec urządzeń na danej szynie?
	cmp	ecx,	0x0020
	jb	.next	; nie

	; następna szyna
	inc	ebx

	; pierwsze urządzenie na szynie
	xor	ecx,	ecx

	; koniec dostępnych szyn?
	cmp	ebx,	0x0100
	jb	.next	; nie

.error:
	; flaga, błąd
	stc

	; koniec
	jmp	.end

.found:
	; pobierz zawartość rejestru Vendor & Device
	mov	eax,	DRIVER_PCI_REGISTER_bar0
	call	driver_pci_read

	; zwróć informacje o położeniu urządzenia
	mov	qword [rsp + STATIC_QWORD_SIZE_byte],	rdx
	mov	qword [rsp + STATIC_QWORD_SIZE_byte * 0x02],	rcx
	mov	qword [rsp + STATIC_QWORD_SIZE_byte * 0x03],	rbx

	; flaga, sukces
	clc

.end:
	; przywróć oryginalne rejestry
	pop	rax
	pop	rdx
	pop	rcx
	pop	rbx

	; powrót z procedury
	ret

;============================================================================
; wejście:
;	ax - poszukiwana wartość Class & Subclass
; wyjście:
;	Flaga CF, jeśli nie znaleziono
;	ebx - szyna
;	ecx - urządzenie
;	edx - funkcja
driver_pci_find_class_and_subclass:
	; zachowaj oryginalne rejestry
	push	rbx
	push	rcx
	push	rdx
	push	rax

	; szyna 0
	xor	ebx,	ebx
	; urządzenie 0
	xor	ecx,	ecx
	; funkcja 0
	xor	edx,	edx

.next:
	; pobierz zawartość rejestru Class & Subclass
	mov	eax,	DRIVER_PCI_REGISTER_class_and_subclass
	call	driver_pci_read

	; przesuń wartość do AX
	shr	eax,	STATIC_MOVE_HIGH_TO_AX_shift

	; kontroler IDE?
	cmp	ax,	word [rsp]
	je	.found	; tak

	; następna funkcja
	inc	edx

	; koniec przeglądanych funkcji?
	cmp	edx,	0x0008
	jb	.next	; nie

	; następne urządzenie na szynie
	inc	ecx

	; pierwsza funkcja urządzenia
	xor	edx,	edx

	; koniec urządzeń na danej szynie?
	cmp	ecx,	0x0020
	jb	.next	; nie

	; następna szyna
	inc	ebx

	; pierwsze urządzenie na szynie
	xor	ecx,	ecx

	; koniec dostępnych szyn?
	cmp	ebx,	0x0100
	jb	.next	; nie

.error:
	; flaga, błąd
	stc

	; koniec
	jmp	.end

.found:
	; zwróć informacje o położeniu urządzenia
	mov	qword [rsp + STATIC_QWORD_SIZE_byte],	rdx
	mov	qword [rsp + STATIC_QWORD_SIZE_byte * 0x02],	rcx
	mov	qword [rsp + STATIC_QWORD_SIZE_byte * 0x03],	rbx

	; flaga, sukces
	clc

.end:
	; przywróć oryginalne rejestry
	pop	rax
	pop	rdx
	pop	rcx
	pop	rbx

	; powrót z procedury
	ret

;============================================================================
; wejście:
;	eax - adres rejestru do odczytu
;	bl - szyna
;	cl - urządzenie
;	dl - funkcja
; wyjście:
;	eax - odpowiedź
driver_pci_read:
	; zachowaj oryginalne rejestry
	push	rbx
	push	rcx
	push	rdx

	; włącz bit 31
	or	eax,	0x80000000

	; załaduj numer funkcji do bitów 10..8
	ror	eax,	8
	or	al,	dl

	; załaduj numer urządzenia do bitów 15..11
	ror	eax,	3
	or	al,	cl

	; załaduj numer szyny do bitów 23..16
	ror	eax,	5
	or	al,	bl

	; numer rejestru w bitach 7..2
	rol	eax,	16

	; poproś o informacje w danym rejestrze
	mov	dx,	DRIVER_PCI_PORT_command
	out	dx,	eax	; wyślij polecenie

	; odbierz odpowiedź
	mov	dx,	DRIVER_PCI_PORT_data
	in	eax,	dx

	; przywróć oryginalne rejestry
	pop	rdx
	pop	rcx
	pop	rbx

	; powrót z procedury
	ret

;============================================================================
; wejście:
;	eax - wartość
;
;	bl - szyna
;	cl - urządzenie
;	dl - funkcja
driver_pci_write:
	; zachowaj oryginalne rejestry
	push	rbx
	push	rcx
	push	rdx
	push	rax

	; włącz bit 31
	or	eax,	0x80000000

	; załaduj numer funkcji do bitów 10..8
	ror	eax,	8
	or	al,	dl

	; załaduj numer urządzenia do bitów 15..11
	ror	eax,	3
	or	al,	cl

	; załaduj numer szyny do bitów 23..16
	ror	eax,	5
	or	al,	bl

	; numer rejestru w bitach 7..2
	rol	eax,	16

	; poproś o dane z rejestru
	mov	dx,	DRIVER_PCI_PORT_command
	out	dx,	eax

	; przywróć wartość do wysłania
	pop	rax

	; wyślij
	mov	dx,	DRIVER_PCI_PORT_data
	out	dx,	eax

	; przywróć oryginalne rejestry
	pop	rdx
	pop	rcx
	pop	rbx

	; powrót z procedury
	ret
