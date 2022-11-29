;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

; align routine to full address
align	0x08,	db	0x00
kernel_task:
	; turn off Interrupts Flag
	cli

	; turn off Direction Flag
	cld

	; keep original registers
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	rbp
	push	r8
	push	r9
	push	r10
	push	r11
	push	r12
	push	r13
	push	r14
	push	r15

	; keep "floating point" registers
	mov	rbp,	KERNEL_TASK_STACK_pointer
	FXSAVE64	[rbp]

	; [PRESERVE]

	; kernel environment variables/rountines base address
	mov	r8,	qword [kernel_environment_base_address]

	; retrieve CPU id
	call	kernel_lapic_id

	; set pointer to current task of CPU
	mov	r10,	qword [r8 + KERNEL_STRUCTURE.task_cpu_address]
	mov	r10,	qword [r10 + rax * STATIC_PTR_SIZE_byte]

	; save tasks current stack pointer
	mov	qword [r10 + KERNEL_TASK_STRUCTURE_ENTRY.rsp],	rsp

	; set flag of current task as free for execution by next CPU
	and	word [r10 + KERNEL_TASK_STRUCTURE_ENTRY.flags],	~KERNEL_TASK_FLAG_exec

	; [SELECT]
	call	kernel_task_select	; choose new task for execution

	; [RESTORE]

	; restore tasks stack pointer
	mov	rsp,	qword [r10 + KERNEL_TASK_STRUCTURE_ENTRY.rsp]

	; restore tasks page arrays
	mov	rax,	qword [r10 + KERNEL_TASK_STRUCTURE_ENTRY.cr3]
	mov	cr3,	rax

	; reload CPU cycle counter in APIC controller
	call	kernel_lapic_reload

	; accept current interrupt call
	call	kernel_lapic_accept

	; [INIT]

	; first run of task?
	test	word [r10 + KERNEL_TASK_STRUCTURE_ENTRY.flags],	KERNEL_TASK_FLAG_init
	jz	.initialized	; no

	; remove flag of initialization
	and	word [r10 + KERNEL_TASK_STRUCTURE_ENTRY.flags],	~KERNEL_TASK_FLAG_init

	; run the task in exception mode
	iretq

.initialized:
	; restore "floating point" registers
	mov	rbp,	KERNEL_TASK_STACK_pointer
	FXRSTOR64	[rbp]

	; restore ogirinal registers
	pop	r15
	pop	r14
	pop	r13
	pop	r12
	pop	r11
	pop	r10
	pop	r9
	pop	r8
	pop	rbp
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; return from the procedure
	iretq

;-------------------------------------------------------------------------------
; in:
;	r8 - kernel environment variables/rountines base address
;	r10 - pointer to current task
; out:
;	r10 - pointer to next task
kernel_task_select:
	; preserve original register
	push	rax
	push	rcx
	push	rdx

.lock:
	; request an exclusive access
	mov	al,	LOCK
	lock xchg	byte [r8 + KERNEL_STRUCTURE.task_queue_semaphore],	al

	; assigned?
	test	al,	al
	jnz	.lock	; no

	; calculate task queue size
	mov	rax,	KERNEL_TASK_STRUCTURE_ENTRY.SIZE
	mov	ecx,	KERNEL_TASK_limit
	mul	rcx

	; set queue limit pointer
	add	rax,	qword [r8 + KERNEL_STRUCTURE.task_queue_address]

.next:
	; move pointer to next task in queue
	add	r10,	KERNEL_TASK_STRUCTURE_ENTRY.SIZE

	; end of task queue?
	cmp	r10,	rax
	jb	.check	; no

	; start searching from beginning
	mov	r10,	qword [r8 + KERNEL_STRUCTURE.task_queue_address]

.check:
	; task is active? (sleep, close etc.)
	test	word [r10 + KERNEL_TASK_STRUCTURE_ENTRY.flags],	KERNEL_TASK_FLAG_active
	jz	.next	; no

	; task can be executed?
	test	word [r10 + KERNEL_TASK_STRUCTURE_ENTRY.flags],	KERNEL_TASK_FLAG_exec
	jnz	.next	; no

	; mark task as selected by current CPU
	or	word [r10 + KERNEL_TASK_STRUCTURE_ENTRY.flags],	KERNEL_TASK_FLAG_exec

	; release access
	mov	byte [r8 + KERNEL_STRUCTURE.task_queue_semaphore],	UNLOCK

	; restore original register
	pop	rdx
	pop	rcx
	pop	rax

	; return from routine
	ret