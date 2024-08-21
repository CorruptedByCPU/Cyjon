;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;-------------------------------------------------------------------------------
; void
kernel_lapic_accept:
	; preserve original register
	push	rax

	; LAPIC controller base address
	mov	rax,	qword [kernel]
	mov	rax,	qword [rax + KERNEL.lapic_base_address]

	; accept currently pending interrupt
	mov	dword [rax + KERNEL_STRUCTURE_LAPIC.eoi],	EMPTY

	; restore original register
	pop	rax

	; return from routine
	ret

;-------------------------------------------------------------------------------
; out:
;	eax - cpu id
kernel_lapic_id:
	; global kernel environment variables/functions/rountines
	mov	rax,	qword [kernel]

	; retrieve CPU ID from LAPIC
	mov	rax,	qword [rax + KERNEL.lapic_base_address]
	mov	eax,	dword [rax + KERNEL_STRUCTURE_LAPIC.id]
	shr	eax,	24	; move ID at a begining of EAX register

	; return from routine
	ret

;-------------------------------------------------------------------------------
; void
kernel_lapic_init:
	; preserve original registers
	push	rax
	push	rdi

	; global kernel environment variables/functions/rountines
	mov	rdi,	qword [kernel]
	mov	rdi,	qword [rdi + KERNEL.lapic_base_address]

	; turn off Task Priority and Priority Sub-Class
	mov	dword [rdi + KERNEL_STRUCTURE_LAPIC.tp],	EMPTY;

	; turn on Flat Mode
	mov	dword [rdi + KERNEL_STRUCTURE_LAPIC.df],	KERNEL_LAPIC_DF_FLAG_flat_mode

	; all logical/BSP processors gets interrupts (physical!)
	mov	dword [rdi + KERNEL_STRUCTURE_LAPIC.ld],	KERNEL_LAPIC_LD_FLAG_target_cpu

	; enable APIC controller on the BSP/logical processor
	mov	eax,	dword [rdi + KERNEL_STRUCTURE_LAPIC.siv]
	or	eax,	KERNEL_LAPIC_SIV_FLAG_enable_apic | KERNEL_LAPIC_SIV_FLAG_spurious_vector3
	mov	dword [rdi + KERNEL_STRUCTURE_LAPIC.siv],	eax 

	; turn on internal interrupts time on APIC controller of BSP/logical processor
	mov	eax,	dword [rdi + KERNEL_STRUCTURE_LAPIC.lvt]
	and	eax,	KERNEL_LAPIC_LVT_TR_FLAG_mask_interrupts
	mov	dword [rdi + KERNEL_STRUCTURE_LAPIC.lvt],	eax

	; number of hardware interrupt at the end of the timer
	mov	dword [rdi + KERNEL_STRUCTURE_LAPIC.lvt],	KERNEL_LAPIC_IRQ_number

	; countdown time converter
	mov	dword [rdi + KERNEL_STRUCTURE_LAPIC.tdc],	KERNEL_LAPIC_TDC_divide_by_1

	; restore original registers
	pop	rdi
	pop	rax

	; return from routine
	ret

;-------------------------------------------------------------------------------
; void
kernel_lapic_reload:
	; preserve original register
	push	rax

	; LAPIC controller base address
	mov	rax,	qword [kernel]
	mov	rax,	qword [rax + KERNEL.lapic_base_address]

	; wake up internal interrupt after KERNEL_LAPIC_Hz cycles
	mov	dword [rax + KERNEL_STRUCTURE_LAPIC.tic],	KERNEL_LAPIC_Hz

	; restore original register
	pop	rax

	; return from routine
	ret