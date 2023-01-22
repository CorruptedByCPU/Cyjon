;===============================================================================
;Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;===============================================================================

; information for linker
section	.data

driver_ps2_mouse_semaphore				db	FALSE
driver_ps2_mouse_type					db	EMPTY
driver_ps2_mouse_packet_id				db	EMPTY

driver_ps2_scancode					dw	EMPTY

; align list
align	0x08,	db	0x00
driver_ps2_keyboard_storage:
		times	DRIVER_PS2_KEYBOARD_CACHE_limit	dw	EMPTY

; align array
align	0x08,	db	0x00
driver_ps2_keyboard_matrix				dq	driver_ps2_keyboard_matrix_low
driver_ps2_keyboard_matrix_low				dw	EMPTY
							dw	DRIVER_PS2_KEYBOARD_PRESS_ESC
							db	"1",	0x00				; 0x02
							db	"2",	0x00				; 0x03
							db	"3",	0x00				; 0x04
							db	"4",	0x00				; 0x05
							db	"5",	0x00				; 0x06
							db	"6",	0x00				; 0x07
							db	"7",	0x00				; 0x08
							db	"8",	0x00				; 0x09
							db	"9",	0x00				; 0x0A
							db	"0",	0x00				; 0x0B
							db	"-",	0x00				; 0x0C
							db	"=",	0x00				; 0x0D
							dw	DRIVER_PS2_KEYBOARD_PRESS_BACKSPACE
							dw	DRIVER_PS2_KEYBOARD_PRESS_TAB
							db	"q",	0x00				; 0x10
							db	"w",	0x00				; 0x11
							db	"e",	0x00				; 0x12
							db	"r",	0x00				; 0x13
							db	"t",	0x00				; 0x14
							db	"y",	0x00				; 0x15
							db	"u",	0x00				; 0x16
							db	"i",	0x00				; 0x17
							db	"o",	0x00				; 0x18
							db	"p",	0x00				; 0x19
							db	"[",	0x00				; 0x1A
							db	"]",	0x00				; 0x1B
							dw	DRIVER_PS2_KEYBOARD_PRESS_ENTER
							dw	DRIVER_PS2_KEYBOARD_PRESS_CTRL_LEFT
							db	"a",	0x00				; 0x1E
							db	"s",	0x00				; 0x1F
							db	"d",	0x00				; 0x20
							db	"f",	0x00				; 0x21
							db	"g",	0x00				; 0x22
							db	"h",	0x00				; 0x23
							db	"j",	0x00				; 0x24
							db	"k",	0x00				; 0x25
							db	"l",	0x00				; 0x26
							db	";",	0x00				; 0x27
							db	"'",	0x00				; 0x28
							db	"`",	0x00				; 0x29
							dw	DRIVER_PS2_KEYBOARD_PRESS_SHIFT_LEFT
							db	"\",	0x00				; 0x2B
							db	"z",	0x00				; 0x2C
							db	"x",	0x00				; 0x2D
							db	"c",	0x00				; 0x2E
							db	"v",	0x00				; 0x2F
							db	"b",	0x00				; 0x30
							db	"n",	0x00				; 0x31
							db	"m",	0x00				; 0x32
							db	",",	0x00				; 0x33
							db	".",	0x00				; 0x34
							db	"/",	0x00				; 0x35
							dw	DRIVER_PS2_KEYBOARD_PRESS_SHIFT_RIGHT	; 0x36
							dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_MULTIPLY
							dw	DRIVER_PS2_KEYBOARD_PRESS_ALT_LEFT	; 0x38
							db	" ",	0x00				; 0x39
							dw	DRIVER_PS2_KEYBOARD_PRESS_CAPSLOCK	; 0x3A
							dw	DRIVER_PS2_KEYBOARD_PRESS_F1
							dw	DRIVER_PS2_KEYBOARD_PRESS_F2
							dw	DRIVER_PS2_KEYBOARD_PRESS_F3
							dw	DRIVER_PS2_KEYBOARD_PRESS_F4
							dw	DRIVER_PS2_KEYBOARD_PRESS_F5
							dw	DRIVER_PS2_KEYBOARD_PRESS_F6		; 0x40
							dw	DRIVER_PS2_KEYBOARD_PRESS_F7
							dw	DRIVER_PS2_KEYBOARD_PRESS_F8
							dw	DRIVER_PS2_KEYBOARD_PRESS_F9
							dw	DRIVER_PS2_KEYBOARD_PRESS_F10
							dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK
							dw	DRIVER_PS2_KEYBOARD_PRESS_SCROLL_LOCK
							dw	EMPTY
							dw	EMPTY
							dw	EMPTY
							dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_7	; 0x47
							dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_8	; 0x48
							dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_9	; 0x49
							dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_MINUS	; 0x4A
							dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_4	; 0x4B
							dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_5	; 0x4C
							dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_6	; 0x4D
							dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_PLUS	; 0x4E
							dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_1	; 0x4F
							dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_2	; 0x50
							dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_3	; 0x51
							dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_0	; 0x52
							dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_DOT	; 0x53
							dw	EMPTY
							dw	EMPTY
							dw	EMPTY
							dw	EMPTY
							dw	DRIVER_PS2_KEYBOARD_PRESS_F11
							dw	DRIVER_PS2_KEYBOARD_PRESS_F12
driver_ps2_keyboard_matrix_high				dw	EMPTY
							dw	DRIVER_PS2_KEYBOARD_PRESS_ESC
							db	"!",	0x00				; 0x02
							db	"@",	0x00				; 0x03
							db	"#",	0x00				; 0x04
							db	"$",	0x00				; 0x05
							db	"%",	0x00				; 0x06
							db	"^",	0x00				; 0x07
							db	"&",	0x00				; 0x08
							db	"*",	0x00				; 0x09
							db	"(",	0x00				; 0x0A
							db	")",	0x00				; 0x0B
							db	"_",	0x00				; 0x0C
							db	"+",	0x00				; 0x0D
							dw	DRIVER_PS2_KEYBOARD_PRESS_BACKSPACE
							dw	DRIVER_PS2_KEYBOARD_PRESS_TAB
							db	"Q",	0x00				; 0x10
							db	"W",	0x00				; 0x11
							db	"E",	0x00				; 0x12
							db	"R",	0x00				; 0x13
							db	"T",	0x00				; 0x14
							db	"Y",	0x00				; 0x15
							db	"U",	0x00				; 0x16
							db	"I",	0x00				; 0x17
							db	"O",	0x00				; 0x18
							db	"P",	0x00				; 0x19
							db	"{",	0x00				; 0x1A
							db	"}",	0x00				; 0x1B
							dw	DRIVER_PS2_KEYBOARD_PRESS_ENTER
							dw	DRIVER_PS2_KEYBOARD_PRESS_CTRL_LEFT
							db	"A",	0x00				; 0x1E
							db	"S",	0x00				; 0x1F
							db	"D",	0x00				; 0x20
							db	"F",	0x00				; 0x21
							db	"G",	0x00				; 0x22
							db	"H",	0x00				; 0x23
							db	"J",	0x00				; 0x24
							db	"K",	0x00				; 0x25
							db	"L",	0x00				; 0x26
							db	":",	0x00				; 0x27
							db	'"',	0x00				; 0x28	"
							db	"~",	0x00				; 0x29
							dw	DRIVER_PS2_KEYBOARD_PRESS_SHIFT_LEFT
							db	"|",	0x00				; 0x2B
							db	"Z",	0x00				; 0x2C
							db	"X",	0x00				; 0x2D
							db	"C",	0x00				; 0x2E
							db	"V",	0x00				; 0x2F
							db	"B",	0x00				; 0x30
							db	"N",	0x00				; 0x31
							db	"M",	0x00				; 0x32
							db	"<",	0x00				; 0x33
							db	">",	0x00				; 0x34
							db	"?",	0x00				; 0x35
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
							dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_7	; 0x47
							dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_8	; 0x48
							dw	DRIVER_PS2_KEYBOARD_PRESS_NUMLOCK_9	; 0x49
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
	mov	al,	DRIVER_PS2_DEVICE_SET_default
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
	mov	al,	DRIVER_PS2_DEVICE_PACKETS_enable
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

	; current keyboard matrix
	mov	rsi,	qword [driver_ps2_keyboard_matrix]

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
	mov	word [driver_ps2_scancode],	ax

	; end of routine
	jmp	.end

.no_sequence:
	; complete started sequence?
	test	word [driver_ps2_scancode],	EMPTY
	jz	.no_complete	; no

	; compose scancode
	or	ax,	word [driver_ps2_scancode]

	; sequence processed
	mov	word [driver_ps2_scancode],	EMPTY

	; continue
	jmp	.key

.no_complete:
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
	call	kernel_task_current

	; only framebuffer is allowed
	mov	r9,	qword [r9 + KERNEL_TASK_STRUCTURE.pid]
	cmp	r9,	qword [rsi + KERNEL_STRUCTURE.framebuffer_pid]
	jne	.end	; not allowed

	; retrieve first key from cache
	mov	ax,	word [driver_ps2_keyboard_storage]

	test	ax,	ax
	jz	.empty
	call	driver_serial_char
.empty:
	; reload keyboard cache
	shl	qword [driver_ps2_keyboard_storage],	STATIC_MOVE_HIGH_TO_AX_shift
	shl	qword [driver_ps2_keyboard_storage + STATIC_QWORD_SIZE_byte],	STATIC_MOVE_HIGH_TO_AX_shift

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