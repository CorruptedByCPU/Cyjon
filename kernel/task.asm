;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

; align routine to full address (I am Speed - Lightning McQueen)
align	0x08,	db	0x00

;-------------------------------------------------------------------------------
; void
kernel_task:
	; turn off Interrupt Flag
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
	mov	rbp,	KERNEL_STACK_pointer
	FXSAVE64	[rbp]

	; round robin queue type
	call	kernel_task_switch

	; restore "floating point" registers
	mov	rbp,	KERNEL_STACK_pointer
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

	; return from routine
	iretq

;-------------------------------------------------------------------------------
; out:
;	r9 - pointer to current task descriptor
kernel_task_active:
	; preserve original flags
	push	rax

	; rom list of active tasks of individual logical processors
	call	kernel_lapic_id

	; select currently processed position relative to current logical processor
	mov	r9,	qword [kernel]
	mov	r9,	qword [r9 + KERNEL.task_cpu_address]
	mov	r9,	qword [r9 + rax * STD_SIZE_PTR_byte]

	; restore original flags
	pop	rax

	; return from routine
	ret

;------------------------------------------------------------------------------
; in:
;	rax - entry number of current task
;	r9 - entry pointer of current task
; out:
;	r9 - entry pointer to next task
kernel_task_select:
	; preserve original registers
	push	rax
	push	r8

.loop:
	; move pointer to next entry
	add	r9,	KERNEL_STRUCTURE_TASK.SIZE

	; next task from queue
	inc	rax

	; end of task list?
	cmp	rax,	KERNEL_TASK_limit
	jnb	.reload

	; search in task queue for a ready-to-do task

	; task available for processing?
	test	word [r9 + KERNEL_STRUCTURE_TASK.flags],	STD_TASK_FLAG_active
	jz	.loop	; no
	test	word [r9 + KERNEL_STRUCTURE_TASK.flags],	STD_TASK_FLAG_exec
	jz	.found	; yes

	; check next one
	jmp	.loop

.reload:
	; start from begining
	xor	eax,	eax

	; set pointer to first entry
	mov	r9,	qword [r8 + KERNEL.task_base_address]

	; try again
	jmp	.loop

.found:
	; mark task as performed by current logical processor
	or	word [r9 + KERNEL_STRUCTURE_TASK.flags],	STD_TASK_FLAG_exec

	; inform BS/A about task to execute as next
	call	kernel_lapic_id
	mov	r8,	qword [r8 + KERNEL.task_cpu_address]
	mov	qword [r8 + rax * STD_SIZE_PTR_byte],	r9

	; restore original registers
	pop	r8
	pop	rax

	; return from routine
	ret

;------------------------------------------------------------------------------
; void
kernel_task_switch:
	; only 1 CPU at a time
	MACRO_LOCK	r8,	KERNEL.task_cpu_semaphore

	; global kernel environment variables/functions/rountines
	mov	r8,	qword [kernel]

	; current task properties
	call	kernel_task_active

	; keep current top of stack pointer
	mov	qword [r9 + KERNEL_STRUCTURE_TASK.rsp],	rsp

	; current task execution stopped
	and	word [r9 + KERNEL_STRUCTURE_TASK.flags],	~STD_TASK_FLAG_exec

	;----------------------------------------------------------------------

	; stop time measuring
	call	kernel_time_rdtsc
	sub	rax,	qword [r9 + KERNEL_STRUCTURE_TASK.time_previous]
	mov	qword [r9 + KERNEL_STRUCTURE_TASK.time],	rax

	; select another process
	mov	rax,	r9
	sub	rax,	qword [r8 + KERNEL.task_base_address]
	mov	rcx,	KERNEL_STRUCTURE_TASK.SIZE
	xor	edx,	edx
	div	rcx
	call	kernel_task_select

	; start time measuring
	call	kernel_time_rdtsc
	mov	qword [r9 + KERNEL_STRUCTURE_TASK.time_previous],	rax

	;----------------------------------------------------------------------

	; reload environment paging array
	mov	rax,	~KERNEL_PAGE_mirror	; physical address
	and	rax,	qword [r9 + KERNEL_STRUCTURE_TASK.cr3]
	mov	cr3,	rax

	; restore previous stack pointer of next task
	mov	rsp,	qword [r9 + KERNEL_STRUCTURE_TASK.rsp]

	; unlock access
	MACRO_UNLOCK	r8,	KERNEL.task_cpu_semaphore

	; reload CPU cycle counter inside APIC controller
	call	kernel_lapic_reload

	; accept current interrupt call
	call	kernel_lapic_accept

	; first run of task?
	test	word [r9 + KERNEL_STRUCTURE_TASK.flags],	STD_TASK_FLAG_init
	jz	.ready	; no

	; disable init flag
	and	word [r9 + KERNEL_STRUCTURE_TASK.flags],	~STD_TASK_FLAG_init

	; by default pass a pointer to global kernel environment variables/functions/rountines
	xor	rsi,	rsi
	xor	rdi,	r8

	; if module
	test	word [r9 + KERNEL_STRUCTURE_TASK.flags],	STD_TASK_FLAG_module
	jnz	.ready	; yes

	; retrieve from stack:
	mov	rax,	qword [r9 + KERNEL_STRUCTURE_TASK.rsp]
	add	rax,	KERNEL_STRUCTURE_IDT_RETURN.rsp

	; TODO
	MACRO_DEBUF

	; length of string
	; mov	rcx,	qword [rax]

	; pointer to string
	; add	rax,	STD_SIZE_QWORD_byte

	; and pass them to process
	; mov	qword [rsp + 0x48],	rcx
	; mov	qword [rsp + 0x50],	rax

.ready:
	; reset FPU state
	fninit

	; kernel guarantee clean registers at first run
	xor	r15,	r15
	xor	r14,	r14
	xor	r13,	r13
	xor	r12,	r12
	xor	r11,	r11
	xor	r10,	r10
	xor	r9,	r9
	xor	r8,	r8
	xor	rbp,	rbp
	xor	rdx,	rdx
	xor	rcx,	rcx
	xor	rbx,	rbx
	xor	rax,	rax

	; run task in exception mode
	iretq
	
.end:
	; return from routine
	ret

; ;-------------------------------------------------------------------------------
; ; in:
; ;	rcx - length of process name in characters
; ;	rsi - pointer to process name
; ; out:
; ;	r10 - pointer to registered task entry
; ;		or EMPTY if unsuccessful
; kernel_task_add:
; 	; preserve original registers
; 	push	rax
; 	push	rcx
; 	push	rdx
; 	push	rsi
; 	push	rdi
; 	push	r8

; 	; global kernel environment variables/functions/rountines
; 	mov	r8,	qword [kernel]

; 	; search for free entry from beginning
; 	mov	rax,	KERNEL_TASK_limit
; 	mov	r10,	qword [r8 + KERNEL.task_base_address]

; .lock:
; 	; request an exclusive access
; 	mov	al,	LOCK
; 	xchg	byte [r8 + KERNEL.task_semaphore],	al

; .loop:
; 	; free queue entry?
; 	lock bts	word [r10 + KERNEL_STRUCTURE_TASK.flags],	STD_SIGN_WORD_bit
; 	jnc	.found	; yes

; 	; move pointer to next task in queue
; 	add	r10,	KERNEL_STRUCTURE_TASK.SIZE

; 	; end of task queue?
; 	dec	rax
; 	jnz	.loop	; no

; 	; there is no free entry on task queue
; 	xor	r10,	r10

; 	; end of procedure
; 	jmp	.end

; .found:
; 	; set process ID
; 	call	kernel_task_id_new
; 	mov	qword [r10 + KERNEL_STRUCTURE_TASK.pid],	rax

; 	; retieve parent ID
; 	call	kernel_task_id_parent
; 	mov	qword [r10 + KERNEL_STRUCTURE_TASK.pid_parent],	rdx

; 	; task doesn't use memory, yet
; 	mov	qword [r10 + KERNEL_STRUCTURE_TASK.page],	EMPTY

; 	; process name too long?
; 	cmp	rcx,	KERNEL_TASK_NAME_limit
; 	jbe	.proper_length	; no

; 	; fix name length
; 	mov	rcx,	KERNEL_TASK_NAME_limit

; .proper_length:
; 	; length of process name
; 	mov	qword [r10 + KERNEL_STRUCTURE_TASK.name_length],	rcx

; 	; copy name to task entry
; 	mov	rdi,	r10
; 	add	rdi,	KERNEL_STRUCTURE_TASK.name
; 	rep	movsb

; 	; last character as TERMINATOR
; 	mov	byte [rdi],	STD_ASCII_TERMINATOR

; 	; number of tasks inside queue
; 	inc	qword [r8 + KERNEL.task_count]

; .end:
; 	; release access
; 	mov	byte [r8 + KERNEL.task_semaphore],	UNLOCK

; 	; restore original registers
; 	pop	r8
; 	pop	rdi
; 	pop	rsi
; 	pop	rdx
; 	pop	rcx
; 	pop	rax

; 	; return from routine
; 	ret

; ;-------------------------------------------------------------------------------
; ; in:
; ;	rdx - ID of requested task
; ; out:
; ;	rbx - pointer to task of this ID
; ;	or EMPTY if not found
; kernel_task_by_id:
; 	; preserve original registers
; 	push	rcx
; 	push	r8

; 	; global kernel environment variables/functions/rountines
; 	mov	r8,	qword [kernel]

; 	; search for free entry from beginning
; 	mov	rcx,	KERNEL_TASK_limit
; 	mov	rbx,	qword [r8 + KERNEL.task_base_address]

; .loop:
; 	; our task we are looking for?
; 	cmp	qword [rbx + KERNEL_STRUCTURE_TASK.pid],	rdx
; 	je	.end	; yes

; 	; move pointer to next task in queue
; 	add	rbx,	KERNEL_STRUCTURE_TASK.SIZE

; 	; end of task queue?
; 	dec	rcx
; 	jnz	.loop	; no

; 	; task not found
; 	xor	ebx,	ebx

; .end:
; 	; restore original registers
; 	pop	r8
; 	pop	rcx

; 	; return from routine
; 	ret

; ;-------------------------------------------------------------------------------
; ; out:
; ;	rax - new ID for use
; kernel_task_id_new:
; 	; preserve original registers
; 	push	r8

; 	; global kernel environment variables/functions/rountines
; 	mov	r8,	qword [kernel]

; 	; generate new ID :D
; 	inc	qword [r8 + KERNEL.task_id]

; 	; new ID
; 	mov	rax,	qword [r8 + KERNEL.task_id]

; 	; restore original registers
; 	pop	r8

; 	; return from routine
; 	ret

; ;-------------------------------------------------------------------------------
; ; out:
; ;	rdx - ID of parent
; kernel_task_id_parent:
; 	; preserve original registers
; 	push	r9

; 	; retrieve pointer to current task descriptor
; 	call	kernel_task_active

; 	; return parent ID
; 	mov	rdx,	qword [r9 + KERNEL_STRUCTURE_TASK.pid]

; 	; restore original registers
; 	pop	r9

; 	; return from routine
; 	ret

; ;-------------------------------------------------------------------------------
; ; out:
; ;	rax - ID of currrent task
; kernel_task_pid:
; 	; preserve original flags
; 	push	r8
; 	pushf

; 	; turn off interrupts
; 	; we cannot allow task switch
; 	; when looking for current task pointe
; 	cli

; 	; retrieve CPU id
; 	call	kernel_lapic_id

; 	; set pointer to current task of CPU
; 	mov	r8,	qword [kernel]
; 	mov	r8,	qword [r8 + KERNEL.task_cpu_address]
; 	mov	r8,	qword [r8 + rax * STD_SIZE_PTR_byte]
; 	mov	rax,	qword [r8 + KERNEL_STRUCTURE_TASK.pid]

; 	; restore original flags
; 	popf
; 	pop	r8

; 	; return from routine
; 	ret