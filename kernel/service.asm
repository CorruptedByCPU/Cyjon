;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

; information for linker
section	.rodata

; align routine
align	0x08,	db	0x00
kernel_service_list:
	dq	kernel_service_exit
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
	dq	kernel_service_serial_char
	dq	kernel_service_serial_string
	dq	kernel_service_serial_value
	dq	driver_rtc_time
	dq	kernel_stream_set
	dq	kernel_stream_get
	dq	kernel_service_sleep
	dq	kernel_service_uptime
	dq	kernel_stream_out_value
	dq	kernel_service_task
	dq	kernel_service_memory
kernel_service_list_end:

; information for linker
section	.text

;-------------------------------------------------------------------------------
; in:
;	rdi - pointer to Memory descriptor
kernel_service_memory:
	; preserve original registers
	push	rax
	push	r8

	; kernel environment variables/rountines base addrrax
	mov	r8,	qword [kernel_environment_base_address]

	; return information about

	; all available pages
	mov	rax,	qword [r8 + KERNEL_STRUCTURE.page_total]
	mov	qword [rdi + LIB_SYS_STRUCTURE_MEMORY.total],	rax

	; and currently free
	mov	rax,	qword [r8 + KERNEL_STRUCTURE.page_available]
	mov	qword [rdi + LIB_SYS_STRUCTURE_MEMORY.available],	rax

	; restore original registers
	pop	r8
	pop	rax

	; return from routine
	ret

;-------------------------------------------------------------------------------
; void
kernel_service_exit:
	; retrieve pointer to current task descriptor
	call	kernel_task_active

	; mark task as closed and not active
	or	word [r9 + KERNEL_TASK_STRUCTURE.flags],	KERNEL_TASK_FLAG_closed
	and	word [r9 + KERNEL_TASK_STRUCTURE.flags],	~KERNEL_TASK_FLAG_active

	; release rest of AP time
	int	0x20

;-------------------------------------------------------------------------------
; in:
;	rdi - sleep amount in microtime
kernel_service_sleep:
	; preserve original registers
	push	rdi
	push	r8
	push	r9

	; kernel environment variables/rountines base address
	mov	r8,	qword [kernel_environment_base_address]

	; retrieve pointer to current task descriptor
	call	kernel_task_active

	; current uptime
	add	rdi,	qword [r8 + KERNEL_STRUCTURE.lapic_microtime]

	; go to sleep for N ticks
	mov	qword [r9 + KERNEL_TASK_STRUCTURE.sleep],	rdi

	; release the remaining CPU time
	int	0x20

	; restore original registers
	pop	r9
	pop	r8
	pop	rdi

	; return from routine
	ret

;-------------------------------------------------------------------------------
; out:
;	rax - current uptime in microtime
kernel_service_uptime:
	; return current microtime index
	mov	rax,	qword [kernel_environment_base_address]
	mov	rax,	qword [rax + KERNEL_STRUCTURE.lapic_microtime]

	; return from routine
	ret

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
;	rdx - stream flags
;	rsi - length of file name/path
;	rdi - pointer to file name/path
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

	; reorganize registers
	mov	rcx,	rsi	; length of string
	mov	rsi,	rdx	; pointer to string
	xchg	rsi,	rdi	; stream flags

	; execute file from path
	call	kernel_exec

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
	call	kernel_task_active

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
	mov	rax,	qword [r8 + KERNEL_STRUCTURE.lapic_microtime]
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
	mov	ecx,	LIB_SYS_IPC_DATA_size_byte
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
;	sil - message type
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

.lock:
	; request an exclusive access
	mov	cl,	LOCK
	lock xchg	byte [r8 + KERNEL_STRUCTURE.ipc_semaphore],	cl

	; assigned?
	test	cl,	cl
	jnz	.lock	; no

	; retrieve ID of current process
	call	kernel_task_pid

	; amount of entries
	mov	rcx,	KERNEL_IPC_limit

	; set pointer to first message
	mov	rsi,	qword [r8 + KERNEL_STRUCTURE.ipc_base_address]

.loop:
	; message alive?
	mov	rbx,	qword [r8 + KERNEL_STRUCTURE.lapic_microtime]
	cmp	qword [rsi + LIB_SYS_STRUCTURE_IPC.ttl],	rbx
	ja	.check	; yes

.next:
	; next entry from list?
	add	rsi,	LIB_SYS_STRUCTURE_IPC.SIZE
	dec	rcx
	jnz	.loop	; yes

	; no message for us
	xor	eax,	eax

	; no
	jmp	.end

.check:
	; message type selected?
	test	sil,	LIB_SYS_IPC_TYPE_ANY
	jz	.any	; no

	; requested message type?
	test	sil,	byte [rsi + LIB_SYS_STRUCTURE_IPC_DEFAULT.type]
	jnz	.next	; no

.any:
	; message for us?
	cmp	qword [rsi + LIB_SYS_STRUCTURE_IPC.target],	rax
	jne	.next	; no

	; preserve original register
	push	rsi

	; load message to process descriptor
	mov	ecx,	LIB_SYS_STRUCTURE_IPC.SIZE
	rep	movsb

	; restore original register
	pop	rsi

	; release entry
	mov	qword [rsi + LIB_SYS_STRUCTURE_IPC.ttl],	EMPTY

	; message transferred
	mov	eax,	TRUE

.end:
	; release access
	mov	byte [r8 + KERNEL_STRUCTURE.ipc_semaphore],	UNLOCK

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
	call	kernel_task_active

	; set pointer of process paging array
	mov	r11,	qword [r9 + KERNEL_TASK_STRUCTURE.cr3]

	; aquire memory space from process memory map
	mov	r9,	qword [r9 + KERNEL_TASK_STRUCTURE.memory_map]
	mov	rcx,	rdi	; number of pages
	call	kernel_memory_acquire
	jc	.error	; no enough memory

	; convert first page number to logical address
	shl	rdi,	STATIC_PAGE_SIZE_shift

	; assign pages to allocated memory in process space
	mov	rax,	rdi
	mov	bx,	KERNEL_PAGE_FLAG_present | KERNEL_PAGE_FLAG_write | KERNEL_PAGE_FLAG_user | KERNEL_PAGE_FLAG_process
	call	kernel_page_alloc
	jnc	.allocated	; space allocated

	; take back modifications
	mov	rsi,	rcx
	call	kernel_service_memory_release

.error:
	; no enough memory
	xor	eax,	eax

	; end
	jmp	.end

.allocated:
	; retrieve pointer to current task descriptor
	call	kernel_task_active

	; process memory usage
	add	qword [r9 + KERNEL_TASK_STRUCTURE.page],	rcx

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
	call	kernel_task_active

	; convert bytes to pages
	add	rsi,	~STATIC_PAGE_mask
	shr	rsi,	STATIC_PAGE_SIZE_shift

	; pointer and counter at place
	mov	rcx,	rsi
	mov	rsi,	rdi

	; process memory usage
	sub	qword [r9 + KERNEL_TASK_STRUCTURE.page],	rcx

.loop:
	; delete first physical page from logical address
	mov	r11,	qword [r9 + KERNEL_TASK_STRUCTURE.cr3]
	call	kernel_page_remove

	; release page inside kernels binary memory map
	mov	rdi,	rax
	or	rdi,	qword [kernel_page_mirror]
	call	kernel_memory_release_page

	; release page inside process binary memory map
	shr	rsi,	STATIC_PAGE_SIZE_shift
	mov	rdi,	qword [r9 + KERNEL_TASK_STRUCTURE.memory_map]
	bts	qword [rdi],	rsi

	; next page from space
	inc	rsi
	shl	rsi,	STATIC_PAGE_SIZE_shift

	; another page?
	dec	rcx
	jnz	.loop	; yes

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

	; convert page number to offset
	shl	rdi,	STATIC_PAGE_SIZE_shift

	; connect memory space of parent process with child
	mov	rax,	rdi
	mov	bx,	KERNEL_PAGE_FLAG_present | KERNEL_PAGE_FLAG_write | KERNEL_PAGE_FLAG_user | KERNEL_PAGE_FLAG_process | KERNEL_PAGE_FLAG_shared
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
	call	kernel_task_active

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
;	rdi - ASCII character
kernel_service_serial_char:
	; preserve original register
	push	rax

	; send character to serial
	mov	al,	dil
	call	driver_serial_char

	; restore original register
	pop	rax

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	rdi - pointer to string
;	rsi - length of string in Bytes
kernel_service_serial_string:
	; preserve original registers
	push	rcx
	push	rsi

	; send string to serial
	mov	rcx,	rsi
	mov	rsi,	rdi
	call	driver_serial_string

	; restore original registers
	pop	rsi
	pop	rcx

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	rdi - value
;	sil - base
;	rdx - prefix length
;	cl - TRUE/FALSE signed value?
kernel_service_serial_value:
	; preserve original registers
	push	rax
	push	rbx
	push	rcx
	push	rdx

	; send value to serial
	mov	rax,	rdi
	movzx	ebx,	sil
	xchg	rcx,	rdx
	call	driver_serial_value

	; restore original registers
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

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
	mov	rdi,	qword [rbp + KERNEL_STORAGE_STRUCTURE_FILE.size_byte]
	call	kernel_service_memory_alloc

	; no enough memory?
	test	rax,	rax
	jz	.end	; yes

	; load file content into prepared space
	mov	rsi,	qword [rbp + KERNEL_STORAGE_STRUCTURE_FILE.id]
	mov	rdi,	rax
	movzx	eax,	byte [r8 + KERNEL_STRUCTURE.storage_root_id]
	call	kernel_storage_read

	; retrieve current task pointer
	call	kernel_task_active

	; restore file descriptor
	mov	rax,	qword [rsp + KERNEL_STORAGE_STRUCTURE_FILE.SIZE]

	; inform process about file location and size
	push	qword [rbp + KERNEL_STORAGE_STRUCTURE_FILE.size_byte]
	pop	qword [rax + LIB_SYS_STRUCTURE_STORAGE.size_byte]
	mov	qword [rax + LIB_SYS_STRUCTURE_STORAGE.address],	rdi

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

;-------------------------------------------------------------------------------
; out:
;	rax - pointer to list of first task descriptor
kernel_service_task:
	; preserve original registers
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	r8
	push	r10

	; kernel environment variables/rountines base address
	mov	r8,	qword [kernel_environment_base_address]

.lock:
	; request an exclusive access
	mov	al,	LOCK
	lock xchg	byte [r8 + KERNEL_STRUCTURE.task_queue_semaphore],	al

	; assigned?
	test	al,	al
	jnz	.lock	; no

	; length of tasks descriptors in Bytes	
	mov	eax,	LIB_SYS_STRUCTURE_TASK.SIZE
	mul	qword [r8 + KERNEL_STRUCTURE.task_count]

	; assign place for task descriptor list
	mov	rdi,	rax
	call	kernel_service_memory_alloc

	; parse every entry
	mov	rbx,	KERNEL_TASK_limit
	mov	r10,	qword [r8 + KERNEL_STRUCTURE.task_queue_address]

	; preserve memory space pointer of tasks descriptors
	push	rax

.loop:
	; entry exist?
	cmp	word [r10 + KERNEL_TASK_STRUCTURE.flags],	EMPTY
	je	.next	; no

	; do not pass kernel entry
	cmp	qword [r10 + KERNEL_TASK_STRUCTURE.pid],	EMPTY
	je	.next

	; share default information about task

	; process ID
	mov	rdx,	qword [r10 + KERNEL_TASK_STRUCTURE.pid]
	mov	qword [rax + LIB_SYS_STRUCTURE_TASK.pid],	rdx

	; process parents ID
	mov	rdx,	qword [r10 + KERNEL_TASK_STRUCTURE.pid_parent]
	mov	qword [rax + LIB_SYS_STRUCTURE_TASK.pid_parent],	rdx

	; wake up process micotime
	mov	rdx,	qword [r10 + KERNEL_TASK_STRUCTURE.sleep]
	mov	qword [rax + LIB_SYS_STRUCTURE_TASK.sleep],	rdx

	; amount of pages used by process
	mov	rdx,	qword [r10 + KERNEL_TASK_STRUCTURE.page]
	mov	qword [rax + LIB_SYS_STRUCTURE_TASK.page],	rdx

	; current task status
	mov	dx,	word [r10 + KERNEL_TASK_STRUCTURE.flags]
	mov	word [rax + LIB_SYS_STRUCTURE_TASK.flags],	dx

	; taks name length
	movzx	ecx,	byte [r10 + KERNEL_TASK_STRUCTURE.length]
	mov	byte [rax + LIB_SYS_STRUCTURE_TASK.length],	cl

	; task name itself
	lea	rsi,	[r10 + KERNEL_TASK_STRUCTURE.name]
	lea	rdi,	[rax + LIB_SYS_STRUCTURE_TASK.name]
	rep	movsb

	; next task descriptor position
	add	rax,	LIB_SYS_STRUCTURE_TASK.SIZE

.next:
	; move pointer to next entry of task table
	add	r10,	KERNEL_TASK_STRUCTURE.SIZE

	; end of tasks inside table?
	dec	rbx
	jnz	.loop	; no

	; last entry set as empty
	mov	qword [rax + LIB_SYS_STRUCTURE_TASK.pid],	EMPTY

	; return memory pointer of tasks descriptors
	pop	rax

	; release access
	mov	byte [r8 + KERNEL_STRUCTURE.task_queue_semaphore],	UNLOCK

	; restore original registers
	pop	r10
	pop	r8
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx

	; return from routine
	ret