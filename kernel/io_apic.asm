;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

;===============================================================================
; in:
;	eax - interrupt number
;	ebx - I/O APIC register
kernel_io_apic_connect:
	; preserve original registers
	push	rax
	push	rbx
	push	rdi

	; kernel environment variables/rountines base address
	mov	rdi,	qword [kernel_environment_base_address]
	mov	rdi,	qword [rdi + KERNEL_STRUCTURE.io_apic_base_address]

	; inside lower half of register
	add	ebx,	KERNEL_IO_APIC_iowin_low
	mov	dword [rdi + KERNEL_IO_APIC_ioregsel],	ebx

	; save lower half of interrupt vector
	mov	dword [rdi + KERNEL_IO_APIC_iowin],	eax

	; inside higher half
	add	ebx,	KERNEL_IO_APIC_iowin_high - KERNEL_IO_APIC_iowin_low
	mov	dword [rdi + KERNEL_IO_APIC_ioregsel],	ebx

	; save higher half of interrupt vector
	shr	rax,	STATIC_MOVE_HIGH_TO_EAX_shift
	mov	dword [rdi + KERNEL_IO_APIC_iowin],	eax

	; restore original registers
	pop	rdi
	pop	rbx
	pop	rax

	; return from routine
	ret