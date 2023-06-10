;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

;-------------------------------------------------------------------------------
; void
kernel_init_hpet:
	; preserve original register
	push	rax
	push	rbx
	push	rcx

	; kernel environment variables/rountines base address
	mov	rbx,	qword [kernel_environment_base_address]

	;-----------------------------------------------------------------------

	; configure Timer 2 as uptime counter
	mov	rcx,	KERNEL_PAGE_mirror
	add	rcx,	qword [rbx + KERNEL_STRUCTURE.hpet_base_address]
	add	rcx,	KERNEL_HPET_TIMER_offset + (KERNEL_HPET_STRUCTURE_TIMER.SIZE * 2)

	; by default not configured
	xor	eax,	eax

	; IRQ number of IDT and I/O APIC
	or	rax,	KERNEL_HPET_TIMER_UPTIME_irq << 9
	
	; allow to set own periodic value
	or	rax,	1 << 6

	; periodic type interrupts
	or	rax,	1 << 3

	; enable interrupts
	or 	rax,	1 << 2

	; edge triggered type of interrupt
	or	rax,	0 << 1;	// 1 for level triggered

	; update Timer 2 configuration
	mov	qword [rcx + KERNEL_HPET_STRUCTURE_TIMER.configuration_and_capabilities],	rax

	; set interval every 1ms
	mov	qword [rcx + KERNEL_HPET_STRUCTURE_TIMER.comparator],	100000

	;-----------------------------------------------------------------------

	; HPET controller registers
	mov	rcx,	KERNEL_PAGE_mirror
	add	rcx,	qword [rbx + KERNEL_STRUCTURE.hpet_base_address]

	; enable HPET controller
	mov	rax,	qword [rcx + KERNEL_HPET_STRUCTURE_REGISTER.general_configuration]
	or	rax,	1
	mov	qword [rcx + KERNEL_HPET_STRUCTURE_REGISTER.general_configuration],	rax

	;-----------------------------------------------------------------------

	; connect HPET controller interrupt handler
	mov	rax,	kernel_hpet_irq
	mov	bx,	KERNEL_IDT_TYPE_irq
	mov	ecx,	KERNEL_IDT_IRQ_offset + KERNEL_HPET_TIMER_UPTIME_irq
	call	kernel_idt_update

	; connect interrupt vector from IDT table in I/O APIC controller
	mov	eax,	KERNEL_IDT_IRQ_offset + KERNEL_HPET_TIMER_UPTIME_irq
	mov	ebx,	KERNEL_HPET_IO_APIC_register
	call	kernel_io_apic_connect

	; restore original register
	pop	rcx
	pop	rbx
	pop	rax

	; return from routine
	ret