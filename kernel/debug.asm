;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

KERNEL_DEBUG_FLOW_offset		equ	0x02
KERNEL_DEBUG_REGISTER_offset		equ	0x05
KERNEL_DEBUG_CODE_offset		equ	0x15
KERNEL_DEBUG_TASK_offset		equ	0x15
KERNEL_DEBUG_PAGE_offset		equ	0x15
KERNEL_DEBUG_PAGE_offset_in_row		equ	0x05
KERNEL_DEBUG_TASK_offset_in_row		equ	0x02
KERNEL_DEBUG_STACK_offset		equ	0x40
KERNEL_DEBUG_MEMORY_offset		equ	0x15

struc	KERNEL_DEBUG_STRUCTURE_PRESERVED
	.rax				resb	8
	.rbx				resb	8
	.rcx				resb	8
	.rdx				resb	8
	.rsi				resb	8
	.rdi				resb	8
	.rbp				resb	8
	.r8				resb	8
	.r9				resb	8
	.r10				resb	8
	.r11				resb	8
	.r12				resb	8
	.r13				resb	8
	.r14				resb	8
	.r15				resb	8
	.eflags				resb	8
	.SIZE:
endstruc

kernel_debug_string_welcome		db	STATIC_COLOR_ASCII_MAGENTA_LIGHT, "Press ESC key to enter GOD mode."
kernel_debug_string_welcome_end:
kernel_debug_string_process_name	db	STATIC_COLOR_ASCII_GRAY_LIGHT, "Process name ", STATIC_COLOR_ASCII_GRAY, "(PID)", STATIC_COLOR_ASCII_GRAY_LIGHT, ": ", STATIC_COLOR_ASCII_WHITE
kernel_debug_string_process_name_end:
kernel_debug_string_pid			db	" ", STATIC_COLOR_ASCII_GRAY, "("
kernel_debug_string_pid_end:
kernel_debug_string_pid_close		db	")", STATIC_ASCII_NEW_LINE
kernel_debug_string_pid_close_end:

kernel_debug_string_eflags		db	STATIC_COLOR_ASCII_GRAY_LIGHT, "Eflags: ", STATIC_COLOR_ASCII_WHITE
kernel_debug_string_eflags_end:

kernel_debug_string_rax			db	STATIC_COLOR_ASCII_GRAY_LIGHT, "rax ", STATIC_COLOR_ASCII_WHITE
kernel_debug_string_rax_end:
kernel_debug_string_rbx			db	STATIC_ASCII_NEW_LINE, STATIC_COLOR_ASCII_GRAY_LIGHT, "rbx ", STATIC_COLOR_ASCII_WHITE
kernel_debug_string_rbx_end:
kernel_debug_string_rcx			db	STATIC_ASCII_NEW_LINE, STATIC_COLOR_ASCII_GRAY_LIGHT, "rcx ", STATIC_COLOR_ASCII_WHITE
kernel_debug_string_rcx_end:
kernel_debug_string_rdx			db	STATIC_ASCII_NEW_LINE, STATIC_COLOR_ASCII_GRAY_LIGHT, "rdx ", STATIC_COLOR_ASCII_WHITE
kernel_debug_string_rdx_end:
kernel_debug_string_rsi			db	STATIC_ASCII_NEW_LINE, STATIC_COLOR_ASCII_GRAY_LIGHT, "rsi ", STATIC_COLOR_ASCII_WHITE
kernel_debug_string_rsi_end:
kernel_debug_string_rdi			db	STATIC_ASCII_NEW_LINE, STATIC_COLOR_ASCII_GRAY_LIGHT, "rdi ", STATIC_COLOR_ASCII_WHITE
kernel_debug_string_rdi_end:
kernel_debug_string_rbp			db	STATIC_ASCII_NEW_LINE, STATIC_COLOR_ASCII_GRAY_LIGHT, "rbp ", STATIC_COLOR_ASCII_WHITE
kernel_debug_string_rbp_end:
kernel_debug_string_rsp			db	STATIC_ASCII_NEW_LINE, STATIC_COLOR_ASCII_GRAY_LIGHT, "rsp ", STATIC_COLOR_ASCII_WHITE
kernel_debug_string_rsp_end:
kernel_debug_string_r8			db	STATIC_ASCII_NEW_LINE, STATIC_COLOR_ASCII_GRAY_LIGHT, "r8  ", STATIC_COLOR_ASCII_WHITE
kernel_debug_string_r8_end:
kernel_debug_string_r9			db	STATIC_ASCII_NEW_LINE, STATIC_COLOR_ASCII_GRAY_LIGHT, "r9  ", STATIC_COLOR_ASCII_WHITE
kernel_debug_string_r9_end:
kernel_debug_string_r10			db	STATIC_ASCII_NEW_LINE, STATIC_COLOR_ASCII_GRAY_LIGHT, "r10 ", STATIC_COLOR_ASCII_WHITE
kernel_debug_string_r10_end:
kernel_debug_string_r11			db	STATIC_ASCII_NEW_LINE, STATIC_COLOR_ASCII_GRAY_LIGHT, "r11 ", STATIC_COLOR_ASCII_WHITE
kernel_debug_string_r11_end:
kernel_debug_string_r12			db	STATIC_ASCII_NEW_LINE, STATIC_COLOR_ASCII_GRAY_LIGHT, "r12 ", STATIC_COLOR_ASCII_WHITE
kernel_debug_string_r12_end:
kernel_debug_string_r13			db	STATIC_ASCII_NEW_LINE, STATIC_COLOR_ASCII_GRAY_LIGHT, "r13 ", STATIC_COLOR_ASCII_WHITE
kernel_debug_string_r13_end:
kernel_debug_string_r14			db	STATIC_ASCII_NEW_LINE, STATIC_COLOR_ASCII_GRAY_LIGHT, "r14 ", STATIC_COLOR_ASCII_WHITE
kernel_debug_string_r14_end:
kernel_debug_string_r15			db	STATIC_ASCII_NEW_LINE, STATIC_COLOR_ASCII_GRAY_LIGHT, "r15 ", STATIC_COLOR_ASCII_WHITE
kernel_debug_string_r15_end:
kernel_debug_string_cr0			db	STATIC_ASCII_NEW_LINE, STATIC_COLOR_ASCII_GRAY_LIGHT, "cr0 ", STATIC_COLOR_ASCII_WHITE
kernel_debug_string_cr0_end:
kernel_debug_string_cr2			db	STATIC_ASCII_NEW_LINE, STATIC_COLOR_ASCII_GRAY_LIGHT, "cr2 ", STATIC_COLOR_ASCII_WHITE
kernel_debug_string_cr2_end:
kernel_debug_string_cr3			db	STATIC_ASCII_NEW_LINE, STATIC_COLOR_ASCII_GRAY_LIGHT, "cr3 ", STATIC_COLOR_ASCII_WHITE
kernel_debug_string_cr3_end:
kernel_debug_string_cr4			db	STATIC_ASCII_NEW_LINE, STATIC_COLOR_ASCII_GRAY_LIGHT, "cr4 ", STATIC_COLOR_ASCII_WHITE
kernel_debug_string_cr4_end:

kernel_debug_string_memory		db	STATIC_COLOR_ASCII_GRAY, "Address          Memory                                          Content", STATIC_COLOR_ASCII_GRAY_LIGHT, STATIC_ASCII_NEW_LINE
kernel_debug_string_memory_end:

kernel_debug_string_task		db	STATIC_COLOR_ASCII_GRAY_LIGHT, "Task queue properties (Size [Bytes]/Task Count/Free):", STATIC_COLOR_ASCII_WHITE, STATIC_ASCII_NEW_LINE
kernel_debug_string_task_end:
kernel_debug_string_separator	db	STATIC_COLOR_ASCII_GRAY, "/", STATIC_COLOR_ASCII_WHITE
kernel_debug_string_separator_end:

kernel_debug_string_page		db	STATIC_COLOR_ASCII_GRAY_LIGHT, "Pages (Total/Used/Free)", STATIC_COLOR_ASCII_WHITE, STATIC_ASCII_NEW_LINE
kernel_debug_string_page_end:

kernel_debug_assembly_table:
	db	0x02,	0x00,	0x31,	0xC9,	0x0C,	"xor	ecx,	ecx"
	db	0x02,	0x08,	0x48,	0xBE,	0x09,	"mov	rsi,	"
	db	0x01,	0x01,	0x72,	0x04,	"jb	+"
	db	0x01,	0x01,	0x73,	0x05,	"jnb	+"
	db	0x01,	0x04,	0xB9,	0x09,	"mov	ecx,	"
	db	0x01,	0x04,	0xBB,	0x09,	"mov	ebx,	"
	db	0x01,	0x01,	0xCD,	0x04,	"int	"
	db	0x01,	0x04,	0xE8,	0x05,	"call	"
	db	0x01,	0x01,	0xEB,	0x05,	"jmp	-"
	db	STATIC_EMPTY
kernel_debug_assembly_table_end:

;===============================================================================
; wejście:
;	WSZYSTKO :)
kernel_debug:
	xchg	bx,bx

	; zachowaj wszystkie rejestry
	pushf
	push	r15
	push	r14
	push	r13
	push	r12
	push	r11
	push	r10
	push	r9
	push	r8
	push	rbp
	push	rdi
	push	rsi
	push	rdx
	push	rcx
	push	rbx
	push	rax

	; wyłącz wirtualny kursor, nie będzie potrzebny
	call	kernel_video_cursor_disable

	; włącz tryb debugowania w kolejce zadań dla Bochs
	; mov	byte [kernel_task_debug_semaphore],	STATIC_TRUE

	;-----------------------------------------------------------------------
	; wyświetl informacje
	mov	ecx,	kernel_debug_string_welcome_end - kernel_debug_string_welcome
	mov	rsi,	kernel_debug_string_welcome
	call	kernel_video_string

.any:
;	; pobierz klawisz z bufora klawiatury
;	call	driver_ps2_keyboard_pull
;	jz	.any	; brak, sprawdź raz jeszcze
;
;	; klawisz ESC?
;	cmp	ax,	STATIC_ASCII_ESCAPE
;	jne	.any	; nie, czekaj dalej

	; wyczyść przestrzeń konsoli
	call	kernel_video_drain

	; pobierz wskaźnik do zadania w kolejce
	call	kernel_task_active

	;-----------------------------------------------------------------------
	; wyświetl nazwę procesu, w podczas którego wystąpił błąd
	mov	ecx,	kernel_debug_string_process_name_end - kernel_debug_string_process_name
	mov	rsi,	kernel_debug_string_process_name
	call	kernel_video_string
	mov	cl,	byte [rdi + KERNEL_TASK_STRUCTURE.length]
	mov	rsi,	rdi
	add	rsi,	KERNEL_TASK_STRUCTURE.name
	call	kernel_video_string

	; wyświetl PID procesu
	mov	ecx,	kernel_debug_string_pid_end - kernel_debug_string_pid
	mov	rsi,	kernel_debug_string_pid
	call	kernel_video_string
	mov	rax,	qword [rdi + KERNEL_TASK_STRUCTURE.pid]
	mov	bl,	STATIC_NUMBER_SYSTEM_hexadecimal
	xor	ecx,	ecx
	call	kernel_video_number
	mov	ecx,	kernel_debug_string_pid_close_end - kernel_debug_string_pid_close
	mov	rsi,	kernel_debug_string_pid_close
	call	kernel_video_string

	; wyświetl stan rejestrów
	call	kernel_debug_registers

	; pobierz zawartość rejestru RIP podczas wygenerowanego błędu
	mov	rsi,	qword [rsp + KERNEL_DEBUG_STRUCTURE_PRESERVED.SIZE]

	; na stosie znajduje się kod błędu?
	cmp	qword [rsp + KERNEL_DEBUG_STRUCTURE_PRESERVED.SIZE + KERNEL_TASK_STRUCTURE_IRETQ.cs],	KERNEL_STRUCTURE_GDT.cs_ring0
	je	.rip	; nie

	; spradź od strony procesu
	cmp	qword [rsp + KERNEL_DEBUG_STRUCTURE_PRESERVED.SIZE + KERNEL_TASK_STRUCTURE_IRETQ.cs],	KERNEL_STRUCTURE_GDT.cs_ring3
	je	.rip	; nie ma

	; zawartość rejestru RIP znajduje się za kodem błędu
	mov	rsi,	qword [rsp + KERNEL_DEBUG_STRUCTURE_PRESERVED.SIZE + STATIC_QWORD_SIZE_byte]

.rip:
	; wyświetl zawartość pamięci na podstawie adresu RIP procesu
	call	kernel_debug_memory

	; wyświetl informacje o kolejce zadań
	call	kernel_debug_task

	; wyświetl informacje o stronach
	call	kernel_debug_page

	jmp	$

	macro_debug	"kernel_debug"

kernel_debug_assembly:


	; powrót z procedury
	ret

;===============================================================================
kernel_debug_page:
	; ustaw kursor na pozycję
	mov	dword [kernel_video_cursor.x],	KERNEL_DEBUG_PAGE_offset
	mov	dword [kernel_video_cursor.y],	KERNEL_DEBUG_PAGE_offset_in_row
	call	kernel_video_cursor_set

	; wyświetl nagłówek
	mov	ecx,	kernel_debug_string_page_end - kernel_debug_string_page
	mov	rsi,	kernel_debug_string_page
	call	kernel_video_string

	; staw kursor na pozycję
	mov	dword [kernel_video_cursor.x],	KERNEL_DEBUG_PAGE_offset
	call	kernel_video_cursor_set

	; wyświetl całkowitą ilość stron
	mov	rax,	qword [kernel_page_total_count]
	mov	bl,	STATIC_NUMBER_SYSTEM_decimal
	xor	ecx,	ecx
	call	kernel_video_number

	; separator
	mov	ecx,	kernel_debug_string_separator_end - kernel_debug_string_separator
	mov	rsi,	kernel_debug_string_separator
	call	kernel_video_string

	; wyświetl wykorzystanych stron
	sub	rax,	qword [kernel_page_free_count]
	xor	ecx,	ecx
	call	kernel_video_number

	; separator
	mov	ecx,	kernel_debug_string_separator_end - kernel_debug_string_separator
	mov	rsi,	kernel_debug_string_separator
	call	kernel_video_string

	; wyświetl ilość wolnych stron
	mov	rax,	qword [kernel_page_free_count]
	xor	ecx,	ecx
	call	kernel_video_number

	; powrót z procedury
	ret

	macro_debug	"kernel_debug_page"

;===============================================================================
kernel_debug_task:
	; ustaw kursor na pozycję
	mov	dword [kernel_video_cursor.x],	KERNEL_DEBUG_TASK_offset
	mov	dword [kernel_video_cursor.y],	KERNEL_DEBUG_TASK_offset_in_row
	call	kernel_video_cursor_set

	; wyświetl nagłówek
	mov	ecx,	kernel_debug_string_task_end - kernel_debug_string_task
	mov	rsi,	kernel_debug_string_task
	call	kernel_video_string

	; staw kursor na pozycję
	mov	dword [kernel_video_cursor.x],	KERNEL_DEBUG_TASK_offset
	call	kernel_video_cursor_set

	; oblicz rozmiar kolejki w Bajtach
	mov	rax,	qword [kernel_task_size_page]
	mov	rcx,	rax
	shl	rax,	STATIC_MULTIPLE_BY_PAGE_shift
	shl	rcx,	STATIC_MULTIPLE_BY_QWORD_shift
	sub	rax,	rcx

	; wyświetl rozmiar kolejki zadań w Bajtach
	mov	bl,	STATIC_NUMBER_SYSTEM_decimal
	xor	ecx,	ecx
	call	kernel_video_number

	; separator
	mov	ecx,	kernel_debug_string_separator_end - kernel_debug_string_separator
	mov	rsi,	kernel_debug_string_separator
	call	kernel_video_string

	; wyświetl ilość zarejestrowanych zadań
	mov	rax,	qword [kernel_task_count]
	xor	ecx,	ecx
	call	kernel_video_number

	; separator
	mov	ecx,	kernel_debug_string_separator_end - kernel_debug_string_separator
	mov	rsi,	kernel_debug_string_separator
	call	kernel_video_string

	; wyświetl ilość wolnych rekordów
	mov	rax,	qword [kernel_task_free]
	xor	ecx,	ecx
	call	kernel_video_number

	; powrót z procedury
	ret

	macro_debug	"kernel_debug_task"

;===============================================================================
; wejście:
;	rsi - początek rozpatrywanej przestrzeni pamięci
kernel_debug_memory:
	; zachowaj oryginalne rejestry
	push	rsi

	; wyświetl N wierszy przestrzeni pamięci po 16 Bajtów każdy
	mov	r8,	0x10

	; ustaw wirtualny wskaźnik kursora na miejsce
	mov	dword [kernel_video_cursor.x],	STATIC_EMPTY
	mov	dword [kernel_video_cursor.y],	18
	call	kernel_video_cursor_set

	; wyświetl nagłówek
	mov	ecx,	kernel_debug_string_memory_end - kernel_debug_string_memory
	mov	rsi,	kernel_debug_string_memory
	call	kernel_video_string

	; przywróć adres przestrzeni, wyrównany do 0x10 w dół
	mov	rsi,	qword [rsp]
	and	si,	STATIC_WORD_mask - STATIC_BYTE_LOW_mask

mov	rsi,	qword [kernel_memory_map_address]

.row:
	; wyświetl adres pierwszego wiersza danych
	mov	rax,	rsi
	mov	bl,	STATIC_NUMBER_SYSTEM_hexadecimal
	mov	ecx,	STATIC_QWORD_DIGIT_length
	mov	edx,	STATIC_ASCII_DIGIT_0
	call	kernel_video_number

	; zapamiętaj początek wiersza
	push	rsi

	; wyświetl w postaci Bajtów, 16 kolumn
	mov	r9,	16

.memory:
	; odstęp
	mov	eax,	STATIC_ASCII_SPACE
	mov	ecx,	0x01
	call	kernel_video_char

	; wyświetl wartość z pierwszej kolumny
	lodsb
	mov	cl,	0x02	; uzupełnienie do Bajta na ekranie
	call	kernel_video_number

	; koniec kolumn do przetworzenia?
	dec	r9
	jnz	.memory	; nie, następna

	; odstęp
	mov	eax,	STATIC_ASCII_SPACE
	mov	ecx,	0x01
	call	kernel_video_char

	; przywróć adres początku przestrzeni wiersza
	mov	rsi,	qword [rsp]

	; wyświetl w postaci ASCII, 16 kolumn
	mov	r9,	16

.ascii:
	; pobierz znak ASCII
	lodsb

	; znak drukowalny?
	cmp	al,	STATIC_ASCII_SPACE
	jb	.hidden	; nie
	cmp	al,	STATIC_ASCII_TILDE
	jb	.show	; tak

.hidden:
	; zamień niedrukowalny znak w "."
	mov	al,	STATIC_ASCII_DOT

.show:
	; wyświetl znak ASCII
	mov	cl,	0x01
	call	kernel_video_char

	; koniec kolumn do przetworzenia?
	dec	r9
	jnz	.ascii	; nie, następna

	; przesuń kursor do następnego wiersza
	mov	al,	STATIC_ASCII_NEW_LINE
	call	kernel_video_char

	; przywróć adres początku wiersza
	pop	rsi

	; przesuń do następnego wiersza danych
	add	rsi,	0x10

	; koniec wierszy danych pamięci?
	dec	r8
	jnz	.row	; nie, kontynuuj

	; przywróć oryginalne rejestry
	pop	rsi

	; powrót z procedury
	ret

	macro_debug	"kernel_debug_memory"

;===============================================================================
kernel_debug_registers:
	; ustaw wirtualny wskaźnik kursora na miejsce
	mov	dword [kernel_video_cursor.x],	STATIC_EMPTY
	mov	dword [kernel_video_cursor.y],	KERNEL_DEBUG_FLOW_offset
	call	kernel_video_cursor_set

	; wyświetlaj wartości w systemie szesnastkowym
	mov	bl,	STATIC_NUMBER_SYSTEM_hexadecimal

	; uzupełniaj liczby cyframi ZERO
	mov	edx,	STATIC_ASCII_DIGIT_0

	; wyświetl zawartość rejestru RAX
	mov	ecx,	kernel_debug_string_rax_end - kernel_debug_string_rax
	mov	rsi,	kernel_debug_string_rax
	call	kernel_video_string
	mov	rax,	qword [rsp + KERNEL_DEBUG_STRUCTURE_PRESERVED.rax + STATIC_QWORD_SIZE_byte]
	mov	ecx,	STATIC_QWORD_DIGIT_length
	call	kernel_video_number

	; wyświetl zawartość rejestru RBX
	mov	ecx,	kernel_debug_string_rbx_end - kernel_debug_string_rbx
	mov	rsi,	kernel_debug_string_rbx
	call	kernel_video_string
	mov	rax,	qword [rsp + KERNEL_DEBUG_STRUCTURE_PRESERVED.rbx + STATIC_QWORD_SIZE_byte]
	mov	ecx,	STATIC_QWORD_DIGIT_length
	call	kernel_video_number

	; wyświetl zawartość rejestru RCX
	mov	ecx,	kernel_debug_string_rcx_end - kernel_debug_string_rcx
	mov	rsi,	kernel_debug_string_rcx
	call	kernel_video_string
	mov	rax,	qword [rsp + KERNEL_DEBUG_STRUCTURE_PRESERVED.rcx + STATIC_QWORD_SIZE_byte]
	mov	ecx,	STATIC_QWORD_DIGIT_length
	call	kernel_video_number

	; wyświetl zawartość rejestru RDX
	mov	ecx,	kernel_debug_string_rdx_end - kernel_debug_string_rdx
	mov	rsi,	kernel_debug_string_rdx
	call	kernel_video_string
	mov	rax,	qword [rsp + KERNEL_DEBUG_STRUCTURE_PRESERVED.rdx + STATIC_QWORD_SIZE_byte]
	mov	ecx,	STATIC_QWORD_DIGIT_length
	call	kernel_video_number

	; wyświetl zawartość rejestru RSI
	mov	ecx,	kernel_debug_string_rsi_end - kernel_debug_string_rsi
	mov	rsi,	kernel_debug_string_rsi
	call	kernel_video_string
	mov	rax,	qword [rsp + KERNEL_DEBUG_STRUCTURE_PRESERVED.rsi + STATIC_QWORD_SIZE_byte]
	mov	ecx,	STATIC_QWORD_DIGIT_length
	call	kernel_video_number

	; wyświetl zawartość rejestru RDI
	mov	ecx,	kernel_debug_string_rdi_end - kernel_debug_string_rdi
	mov	rsi,	kernel_debug_string_rdi
	call	kernel_video_string
	mov	rax,	qword [rsp + KERNEL_DEBUG_STRUCTURE_PRESERVED.rdi + STATIC_QWORD_SIZE_byte]
	mov	ecx,	STATIC_QWORD_DIGIT_length
	call	kernel_video_number

	; wyświetl zawartość rejestru RBP
	mov	ecx,	kernel_debug_string_rbp_end - kernel_debug_string_rbp
	mov	rsi,	kernel_debug_string_rbp
	call	kernel_video_string
	mov	rax,	qword [rsp + KERNEL_DEBUG_STRUCTURE_PRESERVED.rbp + STATIC_QWORD_SIZE_byte]
	mov	ecx,	STATIC_QWORD_DIGIT_length
	call	kernel_video_number

	; ; wyświetl zawartość rejestru RSP
	; mov	ecx,	kernel_debug_string_rsp_end - kernel_debug_string_rsp
	; mov	rsi,	kernel_debug_string_rsp
	; call	kernel_video_string
	; mov	rax,	qword [rsp + KERNEL_DEBUG_STRUCTURE_PRESERVED.rsp + STATIC_QWORD_SIZE_byte]
	; mov	ecx,	STATIC_QWORD_DIGIT_length
	; call	kernel_video_number

	; wyświetl zawartość rejestru R8
	mov	ecx,	kernel_debug_string_r8_end - kernel_debug_string_r8
	mov	rsi,	kernel_debug_string_r8
	call	kernel_video_string
	mov	rax,	qword [rsp + KERNEL_DEBUG_STRUCTURE_PRESERVED.r8 + STATIC_QWORD_SIZE_byte]
	mov	ecx,	STATIC_QWORD_DIGIT_length
	call	kernel_video_number

	; wyświetl zawartość rejestru R9
	mov	ecx,	kernel_debug_string_r9_end - kernel_debug_string_r9
	mov	rsi,	kernel_debug_string_r9
	call	kernel_video_string
	mov	rax,	qword [rsp + KERNEL_DEBUG_STRUCTURE_PRESERVED.r9 + STATIC_QWORD_SIZE_byte]
	mov	ecx,	STATIC_QWORD_DIGIT_length
	call	kernel_video_number

	; wyświetl zawartość rejestru R10
	mov	ecx,	kernel_debug_string_r10_end - kernel_debug_string_r10
	mov	rsi,	kernel_debug_string_r10
	call	kernel_video_string
	mov	rax,	qword [rsp + KERNEL_DEBUG_STRUCTURE_PRESERVED.r10 + STATIC_QWORD_SIZE_byte]
	mov	ecx,	STATIC_QWORD_DIGIT_length
	call	kernel_video_number

	; wyświetl zawartość rejestru R11
	mov	ecx,	kernel_debug_string_r11_end - kernel_debug_string_r11
	mov	rsi,	kernel_debug_string_r11
	call	kernel_video_string
	mov	rax,	qword [rsp + KERNEL_DEBUG_STRUCTURE_PRESERVED.r11 + STATIC_QWORD_SIZE_byte]
	mov	ecx,	STATIC_QWORD_DIGIT_length
	call	kernel_video_number

	; wyświetl zawartość rejestru R12
	mov	ecx,	kernel_debug_string_r12_end - kernel_debug_string_r12
	mov	rsi,	kernel_debug_string_r12
	call	kernel_video_string
	mov	rax,	qword [rsp + KERNEL_DEBUG_STRUCTURE_PRESERVED.r12 + STATIC_QWORD_SIZE_byte]
	mov	ecx,	STATIC_QWORD_DIGIT_length
	call	kernel_video_number

	; wyświetl zawartość rejestru R13
	mov	ecx,	kernel_debug_string_r13_end - kernel_debug_string_r13
	mov	rsi,	kernel_debug_string_r13
	call	kernel_video_string
	mov	rax,	qword [rsp + KERNEL_DEBUG_STRUCTURE_PRESERVED.r13 + STATIC_QWORD_SIZE_byte]
	mov	ecx,	STATIC_QWORD_DIGIT_length
	call	kernel_video_number

	; wyświetl zawartość rejestru R14
	mov	ecx,	kernel_debug_string_r14_end - kernel_debug_string_r14
	mov	rsi,	kernel_debug_string_r14
	call	kernel_video_string
	mov	rax,	qword [rsp + KERNEL_DEBUG_STRUCTURE_PRESERVED.r14 + STATIC_QWORD_SIZE_byte]
	mov	ecx,	STATIC_QWORD_DIGIT_length
	call	kernel_video_number

	; wyświetl zawartość rejestru R15
	mov	ecx,	kernel_debug_string_r15_end - kernel_debug_string_r15
	mov	rsi,	kernel_debug_string_r15
	call	kernel_video_string
	mov	rax,	qword [rsp + KERNEL_DEBUG_STRUCTURE_PRESERVED.r15 + STATIC_QWORD_SIZE_byte]
	mov	ecx,	STATIC_QWORD_DIGIT_length
	call	kernel_video_number

	; powrót z procedury
	ret

	macro_debug	"kernel_debug_registers"
