;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

kernel_debug_string_welcome		db	STATIC_COLOR_ASCII_MAGENTA_LIGHT, "Press ESC key to enter GOD mode."
kernel_debug_string_welcome_end:
kernel_debug_string_process_name	db	STATIC_COLOR_ASCII_GRAY_LIGHT, "Process name: ", STATIC_COLOR_ASCII_WHITE
kernel_debug_string_process_name_end:

kernel_debug_string_rax			db	""
kernel_debug_string_rax_end:
kernel_debug_string_rbx			db	""
kernel_debug_string_rbx_end:
kernel_debug_string_rcx			db	""
kernel_debug_string_rcx_end:
kernel_debug_string_rdx			db	""
kernel_debug_string_rdx_end:
kernel_debug_string_rsi			db	""
kernel_debug_string_rsi_end:
kernel_debug_string_rdi			db	""
kernel_debug_string_rdi_end:
kernel_debug_string_rbp			db	""
kernel_debug_string_rbp_end:
kernel_debug_string_rsp			db	""
kernel_debug_string_rsp_end:
kernel_debug_string_r8			db	""
kernel_debug_string_r8_end:
kernel_debug_string_r9			db	""
kernel_debug_string_r9_end:
kernel_debug_string_r10			db	""
kernel_debug_string_r10_end:
kernel_debug_string_r11			db	""
kernel_debug_string_r11_end:
kernel_debug_string_r12			db	""
kernel_debug_string_r12_end:
kernel_debug_string_r13			db	""
kernel_debug_string_r13_end:
kernel_debug_string_r14			db	""
kernel_debug_string_r14_end:
kernel_debug_string_r15			db	""
kernel_debug_string_r15_end:
kernel_debug_string_eflags		db	""
kernel_debug_string_eflags_end:
kernel_debug_string_cr0			db	""
kernel_debug_string_cr0_end:
kernel_debug_string_cr2			db	""
kernel_debug_string_cr2_end:
kernel_debug_string_cr3			db	""
kernel_debug_string_cr3_end:
kernel_debug_string_cr4			db	""
kernel_debug_string_cr4_end:

;===============================================================================
; wejście:
;	WSZYSTKO :)
kernel_debug:
	; zachowaj wszystkie rejestry
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

	; włącz tryb debugowania w kolejce zadań dla Bochs
	mov	byte [kernel_task_debug_semaphore],	STATIC_TRUE

	; włącz spowrotem przerwania
	sti

	;-----------------------------------------------------------------------
	; wyświetl informacje
	mov	ecx,	kernel_debug_string_welcome_end - kernel_debug_string_welcome
	mov	rsi,	kernel_debug_string_welcome
	call	kernel_video_string

.any:
	; pobierz klawisz z bufora klawiatury
	call	driver_ps2_keyboard_read
	jz	.any	; brak, sprawdź raz jeszcze

	; klawisz ESC?
	cmp	ax,	STATIC_ASCII_ESCAPE
	jne	.any	; nie, czekaj dalej

	; wyczyść przestrzeń konsoli
	call	kernel_video_drain

	;-----------------------------------------------------------------------
	; wyświetl nazwę procesu, w podczask którego wystąpił błąd
	mov	ecx,	kernel_debug_string_process_name_end - kernel_debug_string_process_name
	mov	rsi,	kernel_debug_string_process_name
	call	kernel_video_string

	; pobierz wskaźnik do zadania w kolejce
	call	kernel_task_active

	; wyświetl nazwę
	mov	cl,	byte [rdi + KERNEL_TASK_STRUCTURE.length]
	mov	rsi,	rdi
	add	rsi,	KERNEL_TASK_STRUCTURE.name
	call	kernel_video_string

	jmp	$

	macro_debug	"kernel_debug"
