;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

; align routine to full address
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
	mov	rbp,	KERNEL_TASK_STACK_pointer
	FXSAVE64	[rbp]

	;-----------------------------------------------------------------------
	; [PRESERVE]

	; kernel environment variables/rountines base address
	mov	r8,	qword [kernel_environment_base_address]

	; retrieve CPU ID from LAPIC
	mov	rbx,	qword [r8 + KERNEL_STRUCTURE.lapic_base_address]
	mov	ebx,	dword [rbx + KERNEL_LAPIC_STRUCTURE.id]
	shr	ebx,	24	; move ID at a begining of EAX register

	; get pointer to current task of AP
	mov	r9,	qword [r8 + KERNEL_STRUCTURE.task_ap_address]
	mov	r10,	qword [r9 + rbx * STATIC_PTR_SIZE_byte]

	;=======================================================================
	; todo, find why task_ap_address[ cpu_id ] doesn't contain task pointer
	; it might be race condition at AP initialization -_-
	; this bypass is safe

	; bug, AP doesn't have information about currently executed task?
	test	r10,	r10
	jnz	.ok

	; set initial task as closed
	mov	r10,	qword [r8 + KERNEL_STRUCTURE.task_queue_address]
	;=======================================================================

.ok:
	; save tasks current stack pointer
	mov	qword [r10 + KERNEL_TASK_STRUCTURE.rsp],	rsp

	; set flag of current task as free for execution by next CPU
	and	word [r10 + KERNEL_TASK_STRUCTURE.flags],	~KERNEL_TASK_FLAG_exec

	; increase microtime?
	call	kernel_lapic_id
	cmp	eax,	dword [r8 + KERNEL_STRUCTURE.lapic_last_id]
	jne	.lock	; no

	; increase ticks
	inc	qword [r8 + KERNEL_STRUCTURE.lapic_microtime]

	;-----------------------------------------------------------------------
	; [SELECT]

.lock:
	; request an exclusive access
	mov	al,	LOCK
	lock xchg	byte [r8 + KERNEL_STRUCTURE.task_cpu_semaphore],	al

	; assigned?
	test	al,	al
	jnz	.lock	; no

	; calculate task queue size
	mov	rax,	KERNEL_TASK_STRUCTURE.SIZE
	mov	ecx,	KERNEL_TASK_limit
	mul	rcx

	; set queue limit pointer
	add	rax,	qword [r8 + KERNEL_STRUCTURE.task_queue_address]

.next:
	; move pointer to next task in queue
	add	r10,	KERNEL_TASK_STRUCTURE.SIZE

	; end of task queue?
	cmp	r10,	rax
	jb	.check	; no

	; start searching from beginning
	mov	r10,	qword [r8 + KERNEL_STRUCTURE.task_queue_address]

.check:
	; task is active? (close etc.)
	test	word [r10 + KERNEL_TASK_STRUCTURE.flags],	KERNEL_TASK_FLAG_active
	jz	.next	; no

	; a dormant task?
	mov	rdx,	qword [r10 + KERNEL_TASK_STRUCTURE.sleep]
	cmp	rdx,	qword [r8 + KERNEL_STRUCTURE.lapic_microtime]
	ja	.next	; yes

	; task can be executed?
	test	word [r10 + KERNEL_TASK_STRUCTURE.flags],	KERNEL_TASK_FLAG_exec
	jnz	.next	; no

	; mark task as selected by current CPU
	or	word [r10 + KERNEL_TASK_STRUCTURE.flags],	KERNEL_TASK_FLAG_exec

	; release access
	mov	byte [r8 + KERNEL_STRUCTURE.task_cpu_semaphore],	UNLOCK

	;-----------------------------------------------------------------------
	; [RESTORE]

	; set pointer to current task for AP
	mov	qword [r9 + rbx * STATIC_PTR_SIZE_byte],	r10

	; restore tasks stack pointer
	mov	rsp,	qword [r10 + KERNEL_TASK_STRUCTURE.rsp]

	; restore tasks page arrays
	mov	rax,	qword [r10 + KERNEL_TASK_STRUCTURE.cr3]
	mov	cr3,	rax

	; first run?
	test	word [r10 + KERNEL_TASK_STRUCTURE.flags],	KERNEL_TASK_FLAG_init
	jz	.ready	; no

	; disable init flag
	and	word [r10 + KERNEL_TASK_STRUCTURE.flags],	~KERNEL_TASK_FLAG_init

	; reset FPU state
	fninit

	; save FPU state/registers
	mov	rbp,	KERNEL_TASK_STACK_pointer
	FXSAVE64	[rbp]

	; it's a daemon?
	test	word [r10 + KERNEL_TASK_STRUCTURE.flags],	KERNEL_TASK_FLAG_daemon
	jz	.no_daemon	; no

	; share with daemon - kernel environment variables/rountines base address
	mov	qword [rsp + 0x48],	r8

	; initialized
	jmp	.ready

.no_daemon:
	; retrieve from stack:
	mov	rax,	qword [rsp + 0x90]

	; length of string
	mov	rcx,	qword [rax]

	; pointer to string
	add	rax,	STATIC_QWORD_SIZE_byte

	; and pass them to process
	mov	qword [rsp + 0x48],	rcx
	mov	qword [rsp + 0x50],	rax

.ready:
	; reload CPU cycle counter in APIC controller
	mov	rax,	qword [r8 + KERNEL_STRUCTURE.lapic_base_address]
	mov	dword [rax + KERNEL_LAPIC_STRUCTURE.tic],	KERNEL_LAPIC_Hz

	; accept current interrupt call
	mov	dword [rax + KERNEL_LAPIC_STRUCTURE.eoi],	EMPTY

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

	; return from routine
	iretq

;-------------------------------------------------------------------------------
; in:
;	rcx - length of process name in characters
;	rsi - pointer to process name
; out:
;	r10 - pointer to registered task entry
;		or EMPTY if unsuccessful
kernel_task_add:
	; preserve original registers
	push	rax
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	r8

	; kernel environment variables/rountines base address
	mov	r8,	qword [kernel_environment_base_address]

	; search for free entry from beginning
	mov	rax,	KERNEL_TASK_limit
	mov	r10,	qword [r8 + KERNEL_STRUCTURE.task_queue_address]

.lock:
	; request an exclusive access
	mov	al,	LOCK
	lock xchg	byte [r8 + KERNEL_STRUCTURE.task_queue_semaphore],	al

.loop:
	; free queue entry?
	lock bts	word [r10 + KERNEL_TASK_STRUCTURE.flags],	KERNEL_TASK_FLAG_secured_bit
	jnc	.found	; yes

	; move pointer to next task in queue
	add	r10,	KERNEL_TASK_STRUCTURE.SIZE

	; end of task queue?
	dec	rax
	jnz	.loop	; no

	; there is no free entry on task queue
	xor	r10,	r10

	; end of procedure
	jmp	.end

.found:
	; set process ID
	call	kernel_task_id_new
	mov	qword [r10 + KERNEL_TASK_STRUCTURE.pid],	rax

	; retieve parent ID
	call	kernel_task_id_parent
	mov	qword [r10 + KERNEL_TASK_STRUCTURE.pid_parent],	rdx

	; task doesn't use memory, yet
	mov	qword [r10 + KERNEL_TASK_STRUCTURE.page],	EMPTY

	; process name too long?
	cmp	rcx,	KERNEL_TASK_NAME_limit
	jbe	.proper_length	; no

	; fix name length
	mov	rcx,	KERNEL_TASK_NAME_limit

.proper_length:
	; length of process name
	mov	qword [r10 + KERNEL_TASK_STRUCTURE.length],	rcx

	; copy name to task entry
	mov	rdi,	r10
	add	rdi,	KERNEL_TASK_STRUCTURE.name
	rep	movsb

	; last character as TERMINATOR
	mov	byte [rdi],	STATIC_ASCII_TERMINATOR

	; number of tasks inside queue
	inc	qword [r8 + KERNEL_STRUCTURE.task_count]

.end:
	; release access
	mov	byte [r8 + KERNEL_STRUCTURE.task_queue_semaphore],	UNLOCK

	; restore original registers
	pop	r8
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rax

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	rdx - ID of requested task
; out:
;	rbx - pointer to task of this ID
;	or EMPTY if not found
kernel_task_by_id:
	; preserve original registers
	push	rcx
	push	r8

	; kernel environment variables/rountines base address
	mov	r8,	qword [kernel_environment_base_address]

	; search for free entry from beginning
	mov	rcx,	KERNEL_TASK_limit
	mov	rbx,	qword [r8 + KERNEL_STRUCTURE.task_queue_address]

.loop:
	; our task we are looking for?
	cmp	qword [rbx + KERNEL_TASK_STRUCTURE.pid],	rdx
	je	.end	; yes

	; move pointer to next task in queue
	add	rbx,	KERNEL_TASK_STRUCTURE.SIZE

	; end of task queue?
	dec	rcx
	jnz	.loop	; no

	; task not found
	xor	ebx,	ebx

.end:
	; restore original registers
	pop	r8
	pop	rcx

	; return from routine
	ret

;-------------------------------------------------------------------------------
; out:
;	r9 - pointer to current task descriptor
kernel_task_active:
	; preserve original flags
	push	rax
	pushf

	; turn off interrupts
	; we cannot allow task switch
	; when looking for current task pointer
	cli

	; retrieve CPU id
	call	kernel_lapic_id

	; set pointer to current task of CPU
	mov	r9,	qword [kernel_environment_base_address]
	mov	r9,	qword [r9 + KERNEL_STRUCTURE.task_ap_address]
	mov	r9,	qword [r9 + rax * STATIC_PTR_SIZE_byte]

	; restore original flags
	popf
	pop	rax

	; return from routine
	ret

;-------------------------------------------------------------------------------
; out:
;	rax - new ID for use
kernel_task_id_new:
	; preserve original registers
	push	r8

	; kernel environment variables/rountines base address
	mov	r8,	qword [kernel_environment_base_address]

	; generate new ID :D
	inc	qword [r8 + KERNEL_STRUCTURE.task_id]

	; new ID
	mov	rax,	qword [r8 + KERNEL_STRUCTURE.task_id]

	; restore original registers
	pop	r8

	; return from routine
	ret

;-------------------------------------------------------------------------------
; out:
;	rdx - ID of parent
kernel_task_id_parent:
	; preserve original registers
	push	r9

	; retrieve pointer to current task descriptor
	call	kernel_task_active

	; return parent ID
	mov	rdx,	qword [r9 + KERNEL_TASK_STRUCTURE.pid]

	; restore original registers
	pop	r9

	; return from routine
	ret

;-------------------------------------------------------------------------------
; out:
;	rax - ID of currrent task
kernel_task_pid:
	; preserve original flags
	push	r8
	pushf

	; turn off interrupts
	; we cannot allow task switch
	; when looking for current task pointe
	cli

	; retrieve CPU id
	call	kernel_lapic_id

	; set pointer to current task of CPU
	mov	r8,	qword [kernel_environment_base_address]
	mov	r8,	qword [r8 + KERNEL_STRUCTURE.task_ap_address]
	mov	r8,	qword [r8 + rax * STATIC_PTR_SIZE_byte]
	mov	rax,	qword [r8 + KERNEL_TASK_STRUCTURE.pid]

	; restore original flags
	popf
	pop	r8

	; return from routine
	ret