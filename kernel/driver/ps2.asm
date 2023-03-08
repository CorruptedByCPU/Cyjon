;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

; information for linker
section	.data

driver_ps2_mouse_semaphore				db	FALSE
driver_ps2_mouse_type					db	EMPTY
driver_ps2_mouse_packet_id				db	EMPTY

driver_ps2_keyboard_scancode				dw	EMPTY
driver_ps2_keyboard_semaphore				db	UNLOCK

; align list
align	0x08,	db	0x00
driver_ps2_keyboard_storage:
		times	DRIVER_PS2_KEYBOARD_CACHE_limit	dw	EMPTY

; align array
align	0x08,	db	0x00
driver_ps2_keyboard_matrix				dq	driver_ps2_keyboard_matrix_low
driver_ps2_keyboard_matrix_low				dw	EMPTY
							dw	DRIVER_PS2_KEYBOARD_PRESS_ESC	; Escape
							dw	0x0031	; 1
							dw	0x0032	; 2
							dw	0x0033	; 3
							dw	0x0034	; 4
							dw	0x0035	; 5
							dw	0x0036	; 6
							dw	0x0037	; 7
							dw	0x0038	; 8
							dw	0x0039	; 9
							dw	0x0030	; 0
							dw	0x002D	; -
							dw	0x003D	; =
							dw	DRIVER_PS2_KEYBOARD_PRESS_BACKSPACE
							dw	DRIVER_PS2_KEYBOARD_PRESS_TAB
							dw	0x0071	; q
							dw	0x0077	; w
							dw	0x0065	; e
							dw	0x0072	; r
							dw	0x0074	; t
							dw	0x0079	; y
							dw	0x0075	; u
							dw	0x0069	; i
							dw	0x006F	; o
							dw	0x0070	; p
							dw	0x005B	; [
							dw	0x005D	; ]
							dw	DRIVER_PS2_KEYBOARD_PRESS_ENTER
							dw	DRIVER_PS2_KEYBOARD_PRESS_CTRL_LEFT
							dw	0x0061	; a
							dw	0x0073	; s
							dw	0x0064	; d
							dw	0x0066	; f
							dw	0x0067	; g
							dw	0x0068	; h
							dw	0x006A	; j
							dw	0x006B	; k
							dw	0x006C	; l
							dw	0x003B	; ;
							dw	0x0027	; '
							dw	0x0060	; `
							dw	DRIVER_PS2_KEYBOARD_PRESS_SHIFT_LEFT
							dw	0x005C	; \\
							dw	0x0000
							dw	0x007A	; z
							dw	0x0078	; x
							dw	0x0063	; c
							dw	0x0076	; v
							dw	0x0062	; b
							dw	0x006E	; n
							dw	0x006D	; m
							dw	0x002C	; 
							dw	0x002E	; .
							dw	0x002F	; /
							dw	DRIVER_PS2_KEYBOARD_PRESS_SHIFT_RIGHT
							dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_MULTIPLY
							dw	DRIVER_PS2_KEYBOARD_PRESS_ALT_LEFT
							dw	DRIVER_PS2_KEYBOARD_PRESS_SPACE
							dw	DRIVER_PS2_KEYBOARD_PRESS_CAPSLOCK
							dw	DRIVER_PS2_KEYBOARD_PRESS_F1
							dw	DRIVER_PS2_KEYBOARD_PRESS_F2
							dw	DRIVER_PS2_KEYBOARD_PRESS_F3
							dw	DRIVER_PS2_KEYBOARD_PRESS_F4
							dw	DRIVER_PS2_KEYBOARD_PRESS_F5
							dw	DRIVER_PS2_KEYBOARD_PRESS_F6
							dw	DRIVER_PS2_KEYBOARD_PRESS_F7
							dw	DRIVER_PS2_KEYBOARD_PRESS_F8
							dw	DRIVER_PS2_KEYBOARD_PRESS_F9
							dw	DRIVER_PS2_KEYBOARD_PRESS_F10
							dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK
							dw	DRIVER_PS2_KEYBOARD_PRESS_SCROLL_LOCK
							dw	EMPTY
							dw	EMPTY
							dw	EMPTY
							dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_7
							dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_8
							dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_9
							dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_MINUS
							dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_4
							dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_5
							dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_6
							dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_PLUS
							dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_1
							dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_2
							dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_3
							dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_0
							dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_DOT
							dw	EMPTY
							dw	EMPTY
							dw	EMPTY
							dw	EMPTY
							dw	DRIVER_PS2_KEYBOARD_PRESS_F11
							dw	DRIVER_PS2_KEYBOARD_PRESS_F12

driver_ps2_keyboard_matrix_high				dw	0x0000
							dw	DRIVER_PS2_KEYBOARD_PRESS_ESC
							dw	0x0021	; !
							dw	0x0040	; @
							dw	0x0023	; #
							dw	0x0024	; $
							dw	0x0025	; %
							dw	0x005E	; ^
							dw	0x0026	; &
							dw	0x002A	; *
							dw	0x0028	; ()
							dw	0x0029	; )
							dw	0x005F	; _
							dw	0x002B	; +
							dw	DRIVER_PS2_KEYBOARD_PRESS_BACKSPACE
							dw	DRIVER_PS2_KEYBOARD_PRESS_TAB
							dw	0x0051	; Q
							dw	0x0057	; W
							dw	0x0045	; E
							dw	0x0052	; R
							dw	0x0054	; T
							dw	0x0059	; Y
							dw	0x0055	; U
							dw	0x0049	; I
							dw	0x004F	; O
							dw	0x0050	; P
							dw	0x007B	; }
							dw	0x007D	; {
							dw	DRIVER_PS2_KEYBOARD_PRESS_ENTER
							dw	DRIVER_PS2_KEYBOARD_PRESS_CTRL_LEFT
							dw	0x0041	; A
							dw	0x0053	; S
							dw	0x0044	; D
							dw	0x0046	; F
							dw	0x0047	; G
							dw	0x0048	; H
							dw	0x004A	; J
							dw	0x004B	; K
							dw	0x004C	; L
							dw	0x003A	; :
							dw	0x0022	; "
							dw	0x007E	; ~
							dw	DRIVER_PS2_KEYBOARD_PRESS_SHIFT_LEFT
							dw	0x007C	; |
							dw	0x005A	; Z
							dw	0x0058	; X
							dw	0x0043	; C
							dw	0x0056	; V
							dw	0x0042	; B
							dw	0x004E	; N
							dw	0x004D	; M
							dw	0x003C	; <
							dw	0x003E	; >
							dw	0x003F	; ?
							dw	DRIVER_PS2_KEYBOARD_PRESS_SHIFT_RIGHT
							dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_MULTIPLY
							dw	DRIVER_PS2_KEYBOARD_PRESS_ALT_LEFT
							dw	DRIVER_PS2_KEYBOARD_PRESS_SPACE
							dw	DRIVER_PS2_KEYBOARD_PRESS_CAPSLOCK
							dw	DRIVER_PS2_KEYBOARD_PRESS_F1
							dw	DRIVER_PS2_KEYBOARD_PRESS_F2
							dw	DRIVER_PS2_KEYBOARD_PRESS_F3
							dw	DRIVER_PS2_KEYBOARD_PRESS_F4
							dw	DRIVER_PS2_KEYBOARD_PRESS_F5
							dw	DRIVER_PS2_KEYBOARD_PRESS_F6
							dw	DRIVER_PS2_KEYBOARD_PRESS_F7
							dw	DRIVER_PS2_KEYBOARD_PRESS_F8
							dw	DRIVER_PS2_KEYBOARD_PRESS_F9
							dw	DRIVER_PS2_KEYBOARD_PRESS_F10
							dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK
							dw	DRIVER_PS2_KEYBOARD_PRESS_SCROLL_LOCK
							dw	EMPTY
							dw	EMPTY
							dw	EMPTY
							dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_7
							dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_8
							dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_9
							dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_MINUS
							dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_4
							dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_5
							dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_6
							dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_PLUS
							dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_1
							dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_2
							dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_3
							dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_0
							dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_DOT
							dw	EMPTY
							dw	EMPTY
							dw	EMPTY
							dw	EMPTY
							dw	DRIVER_PS2_KEYBOARD_PRESS_F11
							dw	DRIVER_PS2_KEYBOARD_PRESS_F12

; information for linker
section .text

;-------------------------------------------------------------------------------
; void
driver_ps2:
	; preserve original registers
	push	rax
	push	rbx
	push	rcx
	push	r8

	; drain PS2 controller buffer
	call	driver_ps2_drain

	;-----------------------------------------------------------------------

	; retrieve PS2 controller configuration
	mov	al,	DRIVER_PS2_COMMAND_CONFIGURATION_GET
	call	driver_ps2_send_command_receive_answer

	; enable interrupts on second device of PS2 controller (mouse)
	or	al,	DRIVER_PS2_CONFIGURATION_PORT_SECOND_INTERRUPT
	; and clock
	and	al,	~DRIVER_PS2_CONFIGURATION_PORT_SECOND_CLOCK

	; preserve answer
	push	rax

	; set new PS2 controller configuration
	mov	al,	DRIVER_PS2_COMMAND_CONFIGURATION_SET
	call	driver_ps2_send_command
	pop	rax	; restore answer
	call	driver_ps2_send_data

	;-----------------------------------------------------------------------

	; send RESET command to second device on PS2 controller (mouse)
	mov	al,	DRIVER_PS2_COMMAND_PORT_SECOND
	call	driver_ps2_send_command
	mov	al,	DRIVER_PS2_DEVICE_reset
	call	driver_ps2_send_data

	; receive first answer
	call	driver_ps2_receive_data

	; command accepted?
	cmp	al,	DRIVER_PS2_ANSWER_ACKNOWLEDGED
	jne	.no_mouse	; no

	; receive second answer
	call	driver_ps2_receive_data

	; device is working properly?
	cmp	al,	DRIVER_PS2_ANSWER_SELF_TEST_SUCCESS
	jne	.no_mouse	;no

	; receive third answer
	call	driver_ps2_receive_data

	; preserve mouse device type
	mov	byte [driver_ps2_mouse_type],	al

	;-----------------------------------------------------------------------

	; init device by its own DEFAULT configuration (mouse)
	mov	al,	DRIVER_PS2_COMMAND_PORT_SECOND
	call	driver_ps2_send_command
	mov	al,	DRIVER_PS2_DEVICE_SET_DEFAULT
	call	driver_ps2_send_data

	; receive answer
	call	driver_ps2_receive_data

	; command accepted?
	cmp	al,	DRIVER_PS2_ANSWER_ACKNOWLEDGED
	jne	.no_mouse	; no

	;-----------------------------------------------------------------------

	; init device by its own DEFAULT configuration (mouse)
	mov	al,	DRIVER_PS2_COMMAND_PORT_SECOND
	call	driver_ps2_send_command
	mov	al,	DRIVER_PS2_DEVICE_PACKETS_ENABLE
	call	driver_ps2_send_data

	; receive answer
	call	driver_ps2_receive_data

	; command accepted?
	cmp	al,	DRIVER_PS2_ANSWER_ACKNOWLEDGED
	jne	.no_mouse	; no

	; connect interrupt handler of second device of PS2 controller (mouse)
	mov	rax,	driver_ps2_mouse
	mov	bx,	KERNEL_IDT_TYPE_irq
	mov	ecx,	KERNEL_IDT_IRQ_offset + DRIVER_PS2_MOUSE_IRQ_number
	call	kernel_idt_update

	; redirect interrupt vector inside I/O APIC controller to correct IDT entry
	mov	eax,	KERNEL_IDT_IRQ_offset + DRIVER_PS2_MOUSE_IRQ_number
	mov	ebx,	DRIVER_PS2_MOUSE_IO_APIC_register
	call	kernel_io_apic_connect

.no_mouse:
	; connect interrupt handler of first device of PS2 controller (keyboard)
	mov	rax,	driver_ps2_keyboard
	mov	bx,	KERNEL_IDT_TYPE_irq
	mov	ecx,	KERNEL_IDT_IRQ_offset + DRIVER_PS2_KEYBOARD_IRQ_number
	call	kernel_idt_update

	; redirect interrupt vector inside I/O APIC controller to correct IDT entry
	mov	eax,	KERNEL_IDT_IRQ_offset + DRIVER_PS2_KEYBOARD_IRQ_number
	mov	ebx,	DRIVER_PS2_KEYBOARD_IO_APIC_register
	call	kernel_io_apic_connect

	; even if there is no mouse, set its default position for Window Manager

	; X axis
	mov	ax,	word [r8 + KERNEL_STRUCTURE.framebuffer_width_pixel]
	shr	ax,	STATIC_DIVIDE_BY_2_shift
	mov	word [r8 + KERNEL_STRUCTURE.driver_ps2_mouse_x],	ax

	; Y axis
	mov	ax,	word [r8 + KERNEL_STRUCTURE.framebuffer_height_pixel]
	shr	ax,	STATIC_DIVIDE_BY_2_shift
	mov	word [r8 + KERNEL_STRUCTURE.driver_ps2_mouse_y],	ax

	; restore original registers
	pop	r8
	pop	rcx
	pop	rbx
	pop	rax

	; return from routine
	ret

;-------------------------------------------------------------------------------
; void
driver_ps2_drain:
	; preserve original registers
	push	rax

.loop:
	; check controller status
	in	al,	DRIVER_PS2_PORT_COMMAND_OR_STATUS
	test	al,	DRIVER_PS2_STATUS_output
	jz	.end	; there is nothig, good

	; release data from controller data port
	in	al,	DRIVER_PS2_PORT_DATA

	; try again
	jmp	.loop

.end:
	; restore original registers
	pop	rax

	; return from routine
	ret

; align routine
align	0x08,	db	EMPTY
;-------------------------------------------------------------------------------
; void
driver_ps2_keyboard:
	; preserve original registers
	push	rax
	push	rsi

	; receive key scancode
	xor	eax,	eax	; 64 bit index
	in	al,	DRIVER_PS2_PORT_DATA

	; no key?
	test	ax,	ax
	jz	.end	; yep

	; perform the operation depending on the opcode

	; controller started a sequence?
	cmp	ax,	DRIVER_PS2_KEYBOARD_sequence
	je	.sequence	; yes

	; controller starterd alternative version of sequence?
	cmp	ax,	DRIVER_PS2_KEYBOARD_sequence_alternative
	jne	.no_sequence	; nope

.sequence:
	; save sequence type
	shl	ax,	STATIC_MOVE_AL_TO_HIGH_shift
	mov	word [driver_ps2_keyboard_scancode],	ax

	; end of routine
	jmp	.end

.no_sequence:
	; complete the sequence?
	test	word [driver_ps2_keyboard_scancode],	EMPTY
	jz	.no_complete	; no

	; compose scancode
	or	ax,	word [driver_ps2_keyboard_scancode]

	; sequence processed
	mov	word [driver_ps2_keyboard_scancode],	EMPTY

	; continue
	jmp	.key

.no_complete:
	; current keyboard matrix
	mov	rsi,	qword [driver_ps2_keyboard_matrix]

	; scancode outside of keyboard matrix?
	cmp	ax,	DRIVER_PS2_KEYBOARD_key_release
	jb	.inside_matrix	; no

	; retrieve correct key from keyboard matrix
	sub	ax,	DRIVER_PS2_KEYBOARD_key_release
	mov	ax,	word [rsi + rax * STATIC_WORD_SIZE_byte]

	; update key with scancode
	add	ax,	DRIVER_PS2_KEYBOARD_key_release

	; continue
	jmp	.key

.inside_matrix:
	; retrieve correct key from keyboard matrix
	mov	ax,	word [rsi + rax * STATIC_WORD_SIZE_byte]

.key:
	; press SHIFT or CAPSLOCK?
	cmp	ax,	DRIVER_PS2_KEYBOARD_PRESS_CAPSLOCK
	je	.high
	cmp	ax,	DRIVER_PS2_KEYBOARD_PRESS_SHIFT_LEFT
	je	.high
	cmp	ax,	DRIVER_PS2_KEYBOARD_PRESS_SHIFT_RIGHT
	jne	.no_high

.high:
	; change matrix type
	mov	qword [driver_ps2_keyboard_matrix],	driver_ps2_keyboard_matrix_high
	jmp	.save

.no_high:
	; release SHIFT or CAPSLOCK?
	cmp	ax,	DRIVER_PS2_KEYBOARD_RELEASE_CAPSLOCK
	je	.low
	cmp	ax,	DRIVER_PS2_KEYBOARD_RELEASE_SHIFT_LEFT
	je	.low
	cmp	ax,	DRIVER_PS2_KEYBOARD_RELEASE_SHIFT_RIGHT
	jne	.save

.low:
	; change matrix type
	mov	qword [driver_ps2_keyboard_matrix],	driver_ps2_keyboard_matrix_low

.save:
	; save key code to keyboard cache
	call	driver_ps2_keyboard_key_save

.end:
	; accept this interrupt
	call	kernel_lapic_accept

	; restore original registers
	pop	rsi
	pop	rax

	; return from interrupt
	iretq

;-------------------------------------------------------------------------------
; out:
;	ax - key code
driver_ps2_keyboard_key_read:
	; preserve original registers
	push	rsi
	push	r9

	; kernel environment variables/rountines base address
	mov	rsi,	qword [kernel_environment_base_address]

	; by default there is no key in cache
	xor	eax,	eax

	; current task properties
	call	kernel_task_active

	; only framebuffer is allowed
	mov	r9,	qword [r9 + KERNEL_TASK_STRUCTURE.pid]
	cmp	r9,	qword [rsi + KERNEL_STRUCTURE.framebuffer_pid]
	jne	.end	; not allowed

.lock:
	; request an exclusive access
	mov	al,	LOCK
	lock xchg	byte [driver_ps2_keyboard_semaphore],	al

	; assigned?
	test	al,	al
	jnz	.lock	; no

	; retrieve first key from cache
	mov	ax,	word [driver_ps2_keyboard_storage]

	; reload keyboard cache
	shl	qword [driver_ps2_keyboard_storage],	STATIC_MOVE_HIGH_TO_AX_shift
	shl	qword [driver_ps2_keyboard_storage + STATIC_QWORD_SIZE_byte],	STATIC_MOVE_HIGH_TO_AX_shift

	; release access
	mov	byte [driver_ps2_keyboard_semaphore],	UNLOCK

.end:
	; restore original registers
	pop	r9
	pop	rsi

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	ax - key code
driver_ps2_keyboard_key_save:
	; preserve original registers
	push	rcx
	push	rdi

.lock:
	; request an exclusive access
	mov	cl,	LOCK
	lock xchg	byte [driver_ps2_keyboard_semaphore],	cl

	; assigned?
	test	cl,	cl
	jnz	.lock	; no

	; keyboard cache address and length
	xor	ecx,	ecx
	mov	rdi,	driver_ps2_keyboard_storage

.cache:
	; available entry?
	cmp	word [rdi + rcx * STATIC_WORD_SIZE_byte],	EMPTY
	je	.insert

	; next cache entry
	add	rdi,	STATIC_WORD_SIZE_byte

	; cache is full?
	inc	cl
	cmp	cl,	DRIVER_PS2_KEYBOARD_CACHE_limit
	jb	.cache	; no
	
	; ignore key
	jmp	.end

.insert:
	; save key to keyboard cache
	stosw

.end:
	; release access
	mov	byte [driver_ps2_keyboard_semaphore],	UNLOCK

	; restore original registers
	pop	rdi
	pop	rcx

	; return from routine
	ret

; align routine
align	0x08,	db	EMPTY
;-------------------------------------------------------------------------------
; void
driver_ps2_mouse:
	; preserve original registers
	push	rax
	push	rcx
	push	r8

	; kernel environment variables/rountines base address
	mov	r8,	qword [kernel_environment_base_address]

	; receive data from PS2 controller output buffer
	xor	ax,	ax	; behave as 16 bit value
	in	al,	DRIVER_PS2_PORT_DATA

	; status byte?
	cmp	byte [driver_ps2_mouse_packet_id],	EMPTY
	jne	.x	; X axis

	; ALWAYS ON bit is set?
	test	al,	DRIVER_PS2_DEVICE_MOUSE_PACKET_ALWAYS_ONE
	jz	.reset	; malfunction, ignore packet

	; overflow on X axis?
	test	al,	DRIVER_PS2_DEVICE_MOUSE_PACKET_OVERFLOW_x
	jnz	.reset	; ignore packet

	; overflow on Y axis?
	test	al,	DRIVER_PS2_DEVICE_MOUSE_PACKET_OVERFLOW_y
	jnz	.reset	; ignore packet

	; next packet
	inc	byte [driver_ps2_mouse_packet_id]

	; save mouse status
	mov	byte [r8 + KERNEL_STRUCTURE.driver_ps2_mouse_status],	al

	; interrupt end
	jmp	.end

.x:
	; X axis byte?
	cmp	byte [driver_ps2_mouse_packet_id],	1
	jne	.y	; Y axis

	; next packet
	inc	byte [driver_ps2_mouse_packet_id]

	; value with sign?
	mov	cl,	byte [r8 + KERNEL_STRUCTURE.driver_ps2_mouse_status]
	test	cl,	DRIVER_PS2_DEVICE_MOUSE_PACKET_X_SIGNED
	jz	.x_unsigned	; no

	; convert to absolute value
	xor	ah,	ah
	not	al

	; set new pointer position
	sub	word [r8 + KERNEL_STRUCTURE.driver_ps2_mouse_x],	ax
	jns	.end

	; overflow, correct a position
	mov	word [r8 + KERNEL_STRUCTURE.driver_ps2_mouse_x],	EMPTY

	; interrupt end
	jmp	.end

.x_unsigned:
	; retrieve framebuffer limit of X axis
	mov	cx,	word [r8 + KERNEL_STRUCTURE.framebuffer_width_pixel]
	dec	cx

	; set new pointer position
	add	word [r8 + KERNEL_STRUCTURE.driver_ps2_mouse_x],	ax
	js	.x_overflow	; strange...

	; outside of framebuffer properties
	cmp	word [r8 + KERNEL_STRUCTURE.driver_ps2_mouse_x],	cx
	jbe	.end	; inside scope

.x_overflow:
	; overflow, correct a position
	mov	word [r8 + KERNEL_STRUCTURE.driver_ps2_mouse_x],	cx

	; interrupt end
	jmp	.end

.y:
	; value with sign?
	mov	cl,	byte [r8 + KERNEL_STRUCTURE.driver_ps2_mouse_status]
	test	cl,	DRIVER_PS2_DEVICE_MOUSE_PACKET_Y_SIGNED
	jnz	.y_signed	; yes

	; retrieve framebuffer limit of X axis
	mov	cx,	word [r8 + KERNEL_STRUCTURE.framebuffer_height_pixel]
	dec	cx

	; set new pointer position
	sub	word [r8 + KERNEL_STRUCTURE.driver_ps2_mouse_y],	ax
	jns	.reset

	; overflow, correct a position
	mov	word [r8 + KERNEL_STRUCTURE.driver_ps2_mouse_y],	EMPTY

	; interrupt end
	jmp	.reset

.y_signed:
	; retrieve framebuffer limit of X axis
	mov	cx,	word [r8 + KERNEL_STRUCTURE.framebuffer_height_pixel]
	dec	cx

	; convert to absolute value
	xor	ah,	ah
	not	al

	; set new pointer position
	add	word [r8 + KERNEL_STRUCTURE.driver_ps2_mouse_y],	ax
	js	.y_overflow	; strange...

	; outside of framebuffer properties
	cmp	word [r8 + KERNEL_STRUCTURE.driver_ps2_mouse_y],	cx
	jbe	.reset	; inside scope

.y_overflow:
	; overflow, correct a position
	mov	word [r8 + KERNEL_STRUCTURE.driver_ps2_mouse_y],	cx

.reset:
	; reset status byte
	mov	byte [driver_ps2_mouse_packet_id],	EMPTY

.end:
	; accept this interrupt
	call	kernel_lapic_accept

	; restore original registers
	pop	r8
	pop	rcx
	pop	rax

	; return from interrupt
	iretq

;-------------------------------------------------------------------------------
; void
driver_ps2_read_check:
	; preserve original registers
	push	rax

.loop:
	; check controller status
	in	al,	DRIVER_PS2_PORT_COMMAND_OR_STATUS
	test	al,	DRIVER_PS2_STATUS_output
	jz	.loop	; there is no data

	; restore original registers
	pop	rax

	; return from routine
	ret

;-------------------------------------------------------------------------------
; out:
;	al - answer
driver_ps2_receive_data:
	; wait for read opportunity
	call	driver_ps2_read_check

	; receive answer
	in	al,	DRIVER_PS2_PORT_DATA

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	al - value to send
driver_ps2_send_command:
	; wait for command send opportunity
	call	driver_ps2_write_check

	; send command
	out	DRIVER_PS2_PORT_COMMAND_OR_STATUS,	al

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	al - command
; out:
;	al - answer
driver_ps2_send_command_receive_answer:
	; wait for send command opportunity
	call	driver_ps2_write_check

	; send command
	out	DRIVER_PS2_PORT_COMMAND_OR_STATUS,	al

	; receive answer from controller
	call	driver_ps2_receive_data

	; return from routine
	ret

;-------------------------------------------------------------------------------
; in:
;	al - value to send
driver_ps2_send_data:
	; wait for data send opportunity
	call	driver_ps2_write_check

	; send data to controller
	out	DRIVER_PS2_PORT_DATA,	al

	; return from routine
	ret

;-------------------------------------------------------------------------------
; void
driver_ps2_write_check:
	; preserve original registers
	push	rax

.loop:
	; check controller status
	in	al,	DRIVER_PS2_PORT_COMMAND_OR_STATUS
	test	al,	DRIVER_PS2_STATUS_input
	jnz	.loop	; controller not ready

	; restore original registers
	pop	rax

	; return from routine
	ret