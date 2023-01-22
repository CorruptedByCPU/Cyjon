;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

; information for linker
section	.rodata

; align routine
align	0x08,	db	0x00
kernel_service_list:
	dq	kernel_service_framebuffer
	dq	kernel_service_memory_alloc
	dq	kernel_service_memory_release
	dq	kernel_service_task_pid
	dq	kernel_service_driver_mouse
	dq	kernel_service_storage_read
	dq	kernel_service_exec
	dq	kernel_service_ipc_send
	dq	kernel_service_ipc_receive
	dq	kernel_service_memory_share
	dq	driver_ps2_keyboard_key_read
	dq	kernel_service_task_status
	dq	kernel_stream_out
	dq	kernel_stream_in
kernel_service_list_end:

; information for linker
section	.text

;-------------------------------------------------------------------------------
; in:
;	rdi - pointer to mouse descriptor
kernel_service_driver_mouse:
	; preserve original registers
	push	rax
	push	r8

	; kernel environment variables/rountines base address
	mov	r8,	qword [kernel_environment_base_address]

	; share information about mouse location and status
	mov	ax,	word [r8 + KERNEL_STRUCTURE.driver_ps2_mouse_x]
	mov	word [rdi + LIB_SYS_STRUCTURE_MOUSE.x],	ax
	mov	ax,	word [r8 + KERNEL_STRUCTURE.driver_ps2_mouse_y]
	mov	word [rdi + LIB_SYS_STRUCTURE_MOUSE.y],	ax
	mov	al,	byte [r8 + KERNEL_STRUCTURE.driver_ps2_mouse_status]
	mov	byte [rdi + LIB_SYS_STRUCTURE_MOUSE.status],	al

	; restore original registers
	pop	r8
	pop	rax

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	rsi - pointer to file name/path ended with STATIC_ASCII_TERMINATOR
;	rdi - stream flags
; out:
;	rax - process ID
kernel_service_exec:
	; preserve original registers
	push	rcx
	push	rsi
	push	rdi
	push	rbp
	push	r8

	; kernel environment variables/rountines base address
	mov	r8,	qword [kernel_environment_base_address]

	; prepare exec descriptor
	sub	rsp,	KERNEL_EXEC_STRUCTURE.SIZE
	mov	rbp,	rsp	; pointer of file descriptor

	; recognize file name/path length
	xchg	rsi,	rdi
	call	lib_string_length

	; execute file from path
	call	kernel_exec

	; remove exec descriptor
	add	rsp,	KERNEL_EXEC_STRUCTURE.SIZE

	; restore original registers
	pop	r8
	pop	rbp
	pop	rdi
	pop	rsi
	pop	rcx

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	rdi - pointer to framebuffer descriptor
kernel_service_framebuffer:
	; preserve original registers
	push	rax
	push	rcx
	push	rdx
	push	rsi
	push	r8
	push	r9
	push	r11

	; kernel environment variables/rountines base address
	mov	r8,	qword [kernel_environment_base_address]

	; return properties of framebuffer

	; width in pixels
	mov	ax,	word [r8 + KERNEL_STRUCTURE.framebuffer_width_pixel]
	mov	word [rdi + LIB_SYS_STRUCTURE_FRAMEBUFFER.width_pixel],	ax

	; height in pixels
	mov	ax,	word [r8 + KERNEL_STRUCTURE.framebuffer_height_pixel]
	mov	word [rdi + LIB_SYS_STRUCTURE_FRAMEBUFFER.height_pixel],	ax

	; scanline in Bytes
	mov	eax,	dword [r8 + KERNEL_STRUCTURE.framebuffer_scanline_byte]
	mov	dword [rdi + LIB_SYS_STRUCTURE_FRAMEBUFFER.scanline_byte],	eax

	; framebuffer manager
	mov	rax,	qword [r8 + KERNEL_STRUCTURE.framebuffer_pid]

	; framebuffer manager exist?
	test	rax,	rax
	jnz	.return	; yes

	; retrieve pointer to current task descriptor
	call	kernel_task_current

	; calculate size of framebuffer space
	mov	eax,	dword [rdi + LIB_SYS_STRUCTURE_FRAMEBUFFER.scanline_byte]
	movzx	ecx,	word [rdi + LIB_SYS_STRUCTURE_FRAMEBUFFER.height_pixel]
	mul	rcx

	; convert to pages
	add	rax,	~STATIC_PAGE_mask
	shr	rax,	STATIC_PAGE_SIZE_shift

	; share framebuffer memory space with process
	xor	ecx,	ecx	; no framebuffer manager, if error on below function
	xchg	rcx,	rax	; length of shared space in pages
	mov	rsi,	qword [r8 + KERNEL_STRUCTURE.framebuffer_base_address]
	mov	r11,	qword [r9 + KERNEL_TASK_STRUCTURE.cr3]
	call	kernel_memory_share
	jc	.return	; no enough memory?

	; return pointer to shared memory of framebuffer
	mov	qword [rdi + LIB_SYS_STRUCTURE_FRAMEBUFFER.base_address],	rax

	; new framebuffer manager
	mov	rax,	qword [r9 + KERNEL_TASK_STRUCTURE.pid]
	mov	qword [r8 + KERNEL_STRUCTURE.framebuffer_pid],	rax

.return:
	; inform about framebuffer manager
	mov	qword [rdi + LIB_SYS_STRUCTURE_FRAMEBUFFER.pid],	rax

	; restore original registers
	pop	r11
	pop	r9
	pop	r8
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rax

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	rdi - ID of target process
;	rsi - pointer to message data
kernel_service_ipc_send:
	; preserve original registers
	push	rax
	push	rcx
	push	rsi
	push	rdi
	push	r8

	; kernel environment variables/rountines base address
	mov	r8,	qword [kernel_environment_base_address]

.lock:
	; request an exclusive access
	mov	cl,	LOCK
	lock xchg	byte [r8 + KERNEL_STRUCTURE.ipc_semaphore],	cl

	; assigned?
	test	cl,	cl
	jnz	.lock	; no

.restart:
	; amount of entries
	mov	rcx,	KERNEL_IPC_limit

	; set pointer to first message
	mov	rdx,	qword [r8 + KERNEL_STRUCTURE.ipc_base_address]

.loop:
	; free entry?
	mov	rax,	qword [r8 + KERNEL_STRUCTURE.driver_rtc_microtime]
	cmp	qword [rdx + LIB_SYS_STRUCTURE_IPC.ttl],	rax
	jbe	.found	; yes

	; next entry from list
	add	rdx,	LIB_SYS_STRUCTURE_IPC.SIZE

	; end of message list?
	dec	rcx
	jz	.restart	; yes

	; no
	jmp	.loop

.found:
	; set message time out
	add	rax,	DRIVER_RTC_Hz * 100
	mov	qword [rdx + LIB_SYS_STRUCTURE_IPC.ttl],	rax

	; set message source
	call	kernel_task_pid
	mov	qword [rdx + LIB_SYS_STRUCTURE_IPC.source],	rax

	; set message target
	mov	qword [rdx + LIB_SYS_STRUCTURE_IPC.target],	rdi

	; load data into message
	mov	ecx,	KERNEL_IPC_limit
	mov	rdi,	rdx
	add	rdi,	LIB_SYS_STRUCTURE_IPC.data
	rep	movsb

.end:
	; release access
	mov	byte [r8 + KERNEL_STRUCTURE.ipc_semaphore],	UNLOCK

	; restore original registers
	pop	r8
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rax

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	rdi - pointer to message descriptor
; out:
;	TRUE if message retrieved
kernel_service_ipc_receive:
	; preserve original registers
	push	rbx
	push	rcx
	push	rsi
	push	rdi
	push	r8

	; kernel environment variables/rountines base address
	mov	r8,	qword [kernel_environment_base_address]

	; retrieve ID of current process
	call	kernel_task_pid

	; amount of entries
	mov	rcx,	KERNEL_IPC_limit

	; set pointer to first message
	mov	rsi,	qword [r8 + KERNEL_STRUCTURE.ipc_base_address]

.loop:
	; message alive?
	mov	rbx,	qword [r8 + KERNEL_STRUCTURE.driver_rtc_microtime]
	cmp	qword [rsi + LIB_SYS_STRUCTURE_IPC.ttl],	rbx
	jb	.next	; no

	; message for us?
	cmp	qword [rsi + LIB_SYS_STRUCTURE_IPC.target],	rax
	je	.found	; yes

.next:
	; next entry from list?
	add	rsi,	LIB_SYS_STRUCTURE_IPC.SIZE
	dec	rcx
	jnz	.loop	; yes

	; no message for us
	xor	al,	al

	; no
	jmp	.end

.found:
	; preserve original register
	push	rsi

	; load message to process descriptor
	mov	ecx,	KERNEL_IPC_limit
	rep	movsb

	; restore original register
	pop	rsi

	; release entry
	mov	qword [rsi + LIB_SYS_STRUCTURE_IPC.ttl],	EMPTY

	; message transferred
	mov	al,	TRUE

.end:
	; restore original registers
	pop	r8
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rbx

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	rdi - length of space in Bytes
; out:
;	rax - pointer to allocated space
;	or EMPTY if no enough memory
kernel_service_memory_alloc:
	; preserve original registers
	push	rbx
	push	rcx
	push	rsi
	push	rdi
	push	r8
	push	r9
	push	r11

	; convert size to pages (align up to page boundaries)
	add	rdi,	~STATIC_PAGE_mask
	shr	rdi,	STATIC_PAGE_SIZE_shift

	; retrieve pointer to current task descriptor
	call	kernel_task_current

	; set pointer of process paging array
	mov	r11,	qword [r9 + KERNEL_TASK_STRUCTURE.cr3]

	; aquire memory space from process memory map
	mov	r9,	qword [r9 + KERNEL_TASK_STRUCTURE.memory_map]
	mov	rcx,	rdi	; number of pages
	call	kernel_memory_acquire
	jc	.error	; no enough memory

	; convert first page number to logical address
	shl	rdi,	STATIC_PAGE_SIZE_shift
	add	rdi,	KERNEL_EXEC_BASE_address

	; assign pages to allocated memory in process space
	mov	rax,	rdi
	mov	bx,	KERNEL_PAGE_FLAG_present | KERNEL_PAGE_FLAG_write | KERNEL_PAGE_FLAG_user | KERNEL_PAGE_FLAG_process
	call	kernel_page_alloc
	jnc	.end	; space allocated

	; take back modifications
	mov	rsi,	rcx
	call	kernel_service_memory_release

.error:
	; no enough memory
	xor	eax,	eax

.end:
	; restore original registers
	pop	r11
	pop	r9
	pop	r8
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rbx

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	rdi - pointer to allocated space
;	rsi - length of space in Bytes
kernel_service_memory_release:
	; preserve original registers
	push	rax
	push	rcx
	push	rsi
	push	rdi
	push	r9
	push	r11

	; retrieve pointer to current task descriptor
	call	kernel_task_current

	; convert bytes to pages
	add	rsi,	~STATIC_PAGE_mask
	shr	rsi,	STATIC_PAGE_SIZE_shift

	; release space from paging array of process
	mov	rax,	rdi	; address of releasing space
	mov	rcx,	rsi
	mov	r11,	qword [r9 + KERNEL_TASK_STRUCTURE.cr3]
	call	kernel_page_release

	; restore original registers
	pop	r11
	pop	r9
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rax

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	rdi - pointer to source memory space
;	rsi - length of space in Bytes
;	rdx - target process ID
; out:
;	rax - pointer to shared memory between processes
kernel_service_memory_share:
	; preserve original registers
	push	rbx
	push	rcx
	push	rsi
	push	rdi
	push	r9
	push	r11

	; convert Bytes to pages
	mov	rcx,	rsi
	add	rcx,	~STATIC_PAGE_mask
	shr	rcx,	STATIC_PAGE_SIZE_shift

	; retrieve task paging structure pointer
	call	kernel_task_by_id
	mov	r11,	qword [rbx + KERNEL_TASK_STRUCTURE.cr3]

	; set source pointer in place
	mov	rsi,	rdi

	; acquire memory space from target process
	mov	r9,	qword [rbx + KERNEL_TASK_STRUCTURE.memory_map]
	call	kernel_memory_acquire

	; connect memory space of parent process with child
	mov	rax,	rdi
	shl	rax,	STATIC_PAGE_SIZE_shift
	mov	bx,	KERNEL_PAGE_FLAG_present | KERNEL_PAGE_FLAG_write | KERNEL_PAGE_FLAG_user | KERNEL_PAGE_FLAG_shared
	call	kernel_page_clang

	; restore original registers
	pop	r11
	pop	r9
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rbx

	; return from routine
	ret

;-------------------------------------------------------------------------------
; out:
;	rax - PID of current task
kernel_service_task_pid:
	; preserve original registers
	push	r9

	; retrieve pointer to current task descriptor
	call	kernel_task_current

	; set pointer of process paging array
	mov	rax,	qword [r9 + KERNEL_TASK_STRUCTURE.pid]

	; restore original registers
	pop	r9

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	rdi - process ID
; out:
;	ax - task status
kernel_service_task_status:
	; preserve original registers
	push	rbx
	push	rdx

	; retrieve pointer to current task descriptor
	mov	rdx,	rdi
	call	kernel_task_by_id

	; set pointer of process paging array
	mov	ax,	word [rbx + KERNEL_TASK_STRUCTURE.flags]

	; restore original registers
	pop	rdx
	pop	rbx

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	rdi - pointer to file descriptor
kernel_service_storage_read:
	; preserve original registers
	push	rax
	push	rbx
	push	rcx
	push	rsi
	push	rbp
	push	r8
	push	r9
	push	r11
	push	rdi

	; kernel environment variables/rountines base address
	mov	r8,	qword [kernel_environment_base_address]

	; prepare space for file descriptor
	sub	rsp,	KERNEL_STORAGE_STRUCTURE_FILE.SIZE
	mov	rbp,	rsp	; pointer of file descriptor

	; get file properties
	movzx	eax,	byte [r8 + KERNEL_STRUCTURE.storage_root_id]
	movzx	ecx,	byte [rdi + LIB_SYS_STRUCTURE_STORAGE.length]
	lea	rsi,	[rdi + LIB_SYS_STRUCTURE_STORAGE.name]
	call	kernel_storage_file

	; file found?
	cmp	qword [rbp + KERNEL_STORAGE_STRUCTURE_FILE.id],	EMPTY
	je	.end	; no

	; prepare space for file content
	mov	rcx,	qword [rbp + KERNEL_STORAGE_STRUCTURE_FILE.size_byte]
	add	rcx,	~STATIC_PAGE_mask
	shr	rcx,	STATIC_PAGE_SIZE_shift
	call	kernel_memory_alloc
	jc	.end	; no enough memory

	; load file content into prepared space
	mov	rsi,	qword [rbp + KERNEL_STORAGE_STRUCTURE_FILE.id]
	call	kernel_storage_read

	; retrieve current task pointer
	call	kernel_task_current

	; preserve file content address
	sub	rdi,	qword [kernel_page_mirror]	; convert address to physical
	mov	rsi,	rdi

	; aquire memory inside process space for file
	mov	r9,	qword [r9 + KERNEL_TASK_STRUCTURE.memory_map]
	call	kernel_memory_acquire
	jc	.error	; no enough memory

	; convert first page number to logical address
	shl	rdi,	STATIC_PAGE_SIZE_shift
	add	rdi,	KERNEL_EXEC_BASE_address

	; map file content to process space
	mov	rax,	rdi	; first page number of memory space inside process
	mov	bx,	KERNEL_PAGE_FLAG_present | KERNEL_PAGE_FLAG_write | KERNEL_PAGE_FLAG_user | KERNEL_PAGE_FLAG_process
	mov	r11,	cr3	; task paging array
	call	kernel_page_map
	jc	.error	; no enough memory

	; restore file descriptor
	mov	rdi,	qword [rsp + KERNEL_STORAGE_STRUCTURE_FILE.SIZE]

	; inform process about file location and size
	push	qword [rbp + KERNEL_STORAGE_STRUCTURE_FILE.size_byte]
	pop	qword [rdi + LIB_SYS_STRUCTURE_STORAGE.size_byte]
	mov	qword [rdi + LIB_SYS_STRUCTURE_STORAGE.address],	rax

	; file loaded to process memory
	jmp	.end

.error:
	; release memory assigned for file
	mov	rdi,	rsi
	or	rdi,	qword [kernel_page_mirror]
	call	kernel_memory_release

.end:
	; remove file descriptor from stack
	add	rsp,	KERNEL_STORAGE_STRUCTURE_FILE.SIZE

	; restore original registers
	pop	rdi
	pop	r11
	pop	r9
	pop	r8
	pop	rbp
	pop	rsi
	pop	rcx
	pop	rbx
	pop	rax

	; return from routine
	ret