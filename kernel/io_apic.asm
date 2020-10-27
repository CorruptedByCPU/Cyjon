;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

KERNEL_IO_APIC_ioregsel			equ	0x00
KERNEL_IO_APIC_iowin			equ	0x10
KERNEL_IO_APIC_iowin_low		equ	0x00
KERNEL_IO_APIC_iowin_high		equ	0x01

KERNEL_IO_APIC_TRIGER_MODE_level	equ	1000000000000000b

kernel_io_apic_base_address		dq	STATIC_EMPTY

;===============================================================================
; wejście:
;	eax - adres względny wektora w tablicy IDT
;	ebx - rejestr kontrolera I/O APIC
kernel_io_apic_connect:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rdi

	; ustaw wskaźnik na przestrzeń tablicy I/O APIC
	mov	rdi,	qword [kernel_io_apic_base_address]

	; młodsza część rejestru
	add	ebx,	KERNEL_IO_APIC_iowin_low
	mov	dword [rdi + KERNEL_IO_APIC_ioregsel],	ebx

	; zachowaj informacje o młodszej części adresu wektora
	mov	dword [rdi + KERNEL_IO_APIC_iowin],	eax

	; starsza część rejestru
	add	ebx,	KERNEL_IO_APIC_iowin_high - KERNEL_IO_APIC_iowin_low
	mov	dword [rdi + KERNEL_IO_APIC_ioregsel],	ebx

	; zachowaj informacje o starszej części adresu wektora
	shr	rax,	STATIC_MOVE_HIGH_TO_EAX_shift
	mov	dword [rdi + KERNEL_IO_APIC_iowin],	eax

	; przywóć oryginalne rejestry
	pop	rdi
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"kernel_io_apic_connect"
