;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;-------------------------------------------------------------------------------
; void
kernel_init_task:
	; preserve original registers
	push	rax
; TODO, remove me after refactoring
push	rbx
	push	rcx
	push	rdi
	push	rsi

	; default task limit (expendable)
	mov	qword [r8 + KERNEL.task_limit],	KERNEL_TASK_limit

	; prepare area for Task entries
	mov	ecx,	MACRO_PAGE_ALIGN_UP( KERNEL_TASK_limit * KERNEL_STRUCTURE_TASK.SIZE ) >> STD_SHIFT_PAGE
	call	kernel_memory_alloc

	; preserve pointer inside KERNEL environment
	mov	qword [r8 + KERNEL.task_base_address],	rdi

	;----------------------------------------------------------------------
	; we need to create first entry inside task queue for kernel itself
	; that entry will never be *active*, none of BSP/AP CPUs will ever run it
	; so why we still need it? each CPU exiting initialization state (file: ap.c)
	; will go stright into task selection procedure, and as we know (later)
	; all registers/flags needs to be stored somewhere before choosing next task
	; thats the purpose of kernel entry :)
	;----------------------------------------------------------------------

	; mark first entry of task queue as secured (in use)
	mov	word [rdi + KERNEL_STRUCTURE_TASK.flags],	KERNEL_TASK_FLAG_secured

	; kernel paging structure
	mov	rax,	qword [r8 + KERNEL.page_base_address]
	mov	qword [rdi + KERNEL_STRUCTURE_TASK.cr3],	rax

	; set binary memory map of kernel
	mov	rax,	qword [r8 + KERNEL.memory_base_address]
	mov	qword [rdi + KERNEL_STRUCTURE_TASK.memory_map],	rax

	; prepare stream[s] for kernel
	call	kernel_stream

	; as a kernel, both streams are of type null
	or	byte [rsi + KERNEL_STRUCTURE_STREAM.flags],	KERNEL_STREAM_FLAG_null

	; assign stream[s] to kernel entry
	mov	qword [rdi + KERNEL_STRUCTURE_TASK.stream_in],	rsi
	mov	qword [rdi + KERNEL_STRUCTURE_TASK.stream_out],	rsi

	; remember pointer kernel task entry
	push	rdi

	; retrieve available CPUs on host
	mov	rcx,	qword [limine_smp_request + LIMINE_SMP_REQUEST.response]
	mov	rcx,	qword [rcx + LIMINE_SMP_RESPONSE.cpu_count]

	; calculate CPU list size in Pages
	shl	rcx,	STD_SHIFT_PTR
	MACRO_PAGE_ALIGN_UP_REGISTER	rcx
	shr	rcx,	STD_SHIFT_PAGE

	; prepare area for APs
	call	kernel_memory_alloc
	mov	qword [r8 + KERNEL.task_cpu_address],	rdi

	; each CPU needs to know which task he is currently executing
	; that information is stored on CPU list
	call	kernel_lapic_id
	pop	qword [rdi + rax * STD_SIZE_PTR_byte]

; TODO, remove me after refactoring
mov	rax,	kernel_task
mov	bx,	KERNEL_IDT_TYPE_irq
mov	ecx,	KERNEL_TASK_irq
call	kernel_idt_mount

	; mark IRQ line as in use
	and	dword [r8 + KERNEL.io_apic_irq_lines],	~(1 << 0)

	; restore original registers
	pop	rdi
	pop	rsi
	pop	rcx
; TODO, remove me after refactoring
pop	rbx
	pop	rax

	; return from routine
	ret