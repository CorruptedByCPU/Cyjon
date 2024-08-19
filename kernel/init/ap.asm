;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;-------------------------------------------------------------------------------
; void
kernel_init_ap:
	; global kernel environment variables/functions/rountines
	mov	r8,	qword [kernel]

	; reload kernel environment paging array
	mov	rax,	~KERNEL_PAGE_mirror	; physical address
	and	rax,	qword [r8 + KERNEL.page_base_address]
	mov	cr3,	rax

	; reload Global Descriptor Table
	lgdt	[r8 + KERNEL.gdt_header]

	; reset to valid descriptor values
	call	kernel_init_gdt_reload

	; reload Interrupt Descriptor Table
	lidt	[r8 + KERNEL.idt_header]

	; create a TSS descriptor for current BS/A processor
	call	kernel_lapic_id

	; convert to offset inside GDT table
	shl	rax,	STD_SHIFT_16
	add	rax,	KERNEL_STRUCTURE_GDT.tss

	; preserve TSS offset
	push	rax

	; Task State Segment descriptor properties
	mov	rdi,	qword [r8 + KERNEL.gdt_header + KERNEL_STRUCTURE_GDT_HEADER.base_address]
	add	rdi,	rax

	; insert descriptor data for BSP/logical processor

	; size of Task State Segment array in Bytes
	mov	ax,	KERNEL_STRUCTURE_TSS.SIZE
	stosw	; save

	; TSS header address
	mov	rax,	r8
	add	rax,	KERNEL.tss_table
	stosw	; save (bits 15..0)
	shr	rax,	16
	stosb	; save (bits 23..16)

	; TSS descriptor access attributes
	mov	al,	10001001b	; P, DPL, 0, Type
	stosb	; save
	xor	al,	al		; G, 0, 0, AVL, Limit (older part of TSS table size)
	stosb	; save

	; TSS header address
	shr	rax,	8
	stosb	; save (bits 31..24)
	shr	rax,	8
	stosd	; save (bits 63..32)

	; reserved 32 Bytes of descriptor
	xor	rax,	rax
	stosd	; save

	; set TSS descriptor for BS/A processor
	ltr	word [rsp]

	; select task from queue which CPU is now processing
	push	qword [r8 + KERNEL.task_base_address]

	; update CPU list
	call	kernel_lapic_id
	shl	rax,	STD_SHIFT_8
	add	rax,	qword [r8 + KERNEL.task_cpu_address]
	pop	qword [rax]

	; disable x87 FPU Emulation, enable co-processor Monitor
	mov	rax,	cr0
	and	al,	0xFB
	or	al,	0x02
	mov	cr0,	rax

	; reset FPU state
	fninit

	; allow all BS/A processors to write on read-only pages
	mov	rax,	cr0
	and	rax,	~(1 << 16)
	mov	cr0,	rax

	; enable FXSAVE/FXRSTOR (bit 9), OSXMMEXCPT (bit 10) and OSXSAVE (bit 18)
	mov	rax,	cr4
	or	rax,	000001000000011000000000b
	mov	cr4,	rax

	; enable X87, SSE, AVX support
	xor	ecx,	ecx
	xgetbv
	or	eax,	11b
	xsetbv

	;--------------------------------------------------------------------------
	; enable syscall/sysret support
	mov	ecx,	0xC0000080
	rdmsr
	or	eax,	1b
	wrmsr

	; set code/stack segments for kernel and process
	xor	eax,	eax
	mov	ecx,	KERNEL_INIT_AP_MSR_STAR
	mov	edx,	0x00180008	; GDT descriptors
	wrmsr

	; set the kernel entry routin
	; mov	rax,	kernel_syscall
	; mov	ecx,	KERNEL_INIT_AP_MSR_LSTAR
	; mov	rdx,	kernel_syscall
	; shr	rdx,	STD_MOVE_DWORD
	; wrmsr

	; disable IF flag and DF after calling syscall
	mov	eax,	KERNEL_TASK_EFLAGS_if | KERNEL_TASK_EFLAGS_df
	mov	ecx,	KERNEL_INIT_AP_MSR_EFLAGS
	xor	edx,	edx
	wrmsr
	;--------------------------------------------------------------------------

	; re/initialize LAPIC of BS/A processor
	call	kernel_lapic_init

	; reload CPU cycle counter inside APIC controller
	call	kernel_lapic_reload

	; accept current interrupt call (if exist)
	call	kernel_lapic_accept

	; BS/A initialized
	inc	qword [r8 + KERNEL.cpu_count]

	; enable interrupt handling
	sti

	; don't wait for miracle, speed is our motto :]
	int	0x20
