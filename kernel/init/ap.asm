;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;-------------------------------------------------------------------------------
; void
kernel_init_ap:
	;-----------------------------------------------------------------------
	; all that's left is the quintessential initialization of all local processors
	; even the BSP processor has to go through it (because we don't want to
	; duplicate the code specifically for it).
	;-----------------------------------------------------------------------

	; kernel environment variables/rountines base address
	mov	r8,	qword [kernel]

	;--------
	; PAGE
	;--------

	; switch to new kernel paging array
	mov	rax,	~KERNEL_PAGE_mirror	; physical address
	and	rax,	qword [r8 + KERNEL.page_base_address]
	mov	cr3,	rax

	;-----
	; GDT
	;-----

	; reload Global Descriptor Table
	lgdt	[r8 + KERNEL.gdt_header]
	call	kernel_init_gdt_reload

	;-----
	; TSS
	;-----

	; change CPU ID to descriptor offset
	call	kernel_lapic_id
	shl	rax,	STD_SHIFT_16
	add	rax,	KERNEL_STRUCTURE_GDT.tss

	; preserve TSS offset
	push	rax

	; set pointer to TSS entry of this AP
	mov	rdi,	qword [r8 + KERNEL.gdt_header + KERNEL_STRUCTURE_GDT_HEADER.base_address]
	add	rdi,	rax

	; length of TSS header
	mov	ax,	KERNEL_STRUCTURE_TSS.SIZE
	stosw	; save

	; TSS header address
	mov	rax,	r8
	add	rax,	KERNEL.tss_table
	stosw	; save (bits 15..0)
	shr	rax,	16
	stosb	; save (bits 23..16)

	; fill Task State Segment with flags
	mov	al,	10001001b	; P, DPL, 0, Type
	stosb	; zapisz
	xor	al,	al		; G, 0, 0, AVL, Limit (older part of TSS table size)
	stosb	; zapisz

	; TSS header address
	shr	rax,	8
	stosb	; save (bits 31..24)
	shr	rax,	8
	stosd	; save (bits 63..32)

	; reserved 32 Bytes of descriptor
	xor	rax,	rax
	stosd	; save

	; load TSS descriptor for this AP
	ltr	word [rsp]

	;-----
	; IDT
	;-----

	; reload Interrupt Descriptor Table
	lidt	[r8 + KERNEL.idt_header]

	;-----------
	; CPU Flags
	;-----------

	; enable Monitor co-processor (bit 1) and disable x87 FPU Emulation (bit 2)
	mov	rax,	cr0
	and	al,	0xFB
	or	al,	0x02
	mov	cr0,	rax

	; enable FXSAVE/FXRSTOR (bit 9), OSXMMEXCPT (bit 10) and OSXSAVE (bit 18)
	mov	rax,	cr4
	or	rax,	1000000011000000000b
	mov	cr4,	rax

	; reset FPU state
	fninit

	; enable X87, SSE, AVX support
	xor	ecx,	ecx
	xgetbv
	or	eax,	111b
	xsetbv

	;----------------
	; SYSCALL/SYSRET
	;----------------

	; enable SYSCALL/SYSRET (SCE bit) support
	mov	ecx,	0xC0000080
	rdmsr
	or	eax,	1b
	wrmsr

	; set code/stack segments of syscall routine
	mov	ecx,	KERNEL_INIT_AP_MSR_STAR
	mov	edx,	0x00180008	; GDT descriptors
	wrmsr

	; set syscall entry routine
	mov	rax,	kernel_syscall
	mov	ecx,	KERNEL_INIT_AP_MSR_LSTAR
	mov	rdx,	kernel_syscall
	shr	rdx,	STD_MOVE_DWORD
	wrmsr

	; set EFLAGS mask of entry routine
	mov	eax,	KERNEL_TASK_EFLAGS_if | KERNEL_TASK_EFLAGS_df	; disable Direction flags
	mov	ecx,	KERNEL_INIT_AP_MSR_EFLAGS
	xor	edx,	edx
	wrmsr

	;------
	; TASK
	;------

	; set task in queue being processed by AP
	call	kernel_lapic_id
	push	qword [r8 + KERNEL.task_queue_address]	; by default: kernel

	; insert into task cpu list at AP position
	shl	rax,	STD_SHIFT_8
	add	rax,	qword [r8 + KERNEL.task_ap_address]
	pop	qword [rax]

	;-------
	; LAPIC
	;-------

	; initialize LAPIC of current AP
	call	kernel_lapic_init

	; reload AP cycle counter
	call	kernel_lapic_reload

	; accept pending interrupts
	call	kernel_lapic_accept

	; AP initialized
	inc	qword [r8 + KERNEL.cpu_count]

	; enable interrupt handling
	sti

	; wait for miracle :)
	jmp	$
