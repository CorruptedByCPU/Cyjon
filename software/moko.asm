;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

; Use:
; nasm - http://www.nasm.us/

; zestaw imiennych wartości stałych jądra systemu
%include	'config.asm'

%define	VARIABLE_PROGRAM_NAME		moko
%define VARIABLE_MOKO_PROGRAM_NAME_CHARS	4
%define	VARIABLE_PROGRAM_VERSION	"v0.21"

VARIABLE_MOKO_CURSOR_POSITION_INIT	equ	0x0000000200000000	; 3rd row, 0 column
VARIABLE_MOKO_INTERFACE_HEADER_HEIGHT	equ	2
VARIABLE_MOKO_INTERFACE_MENU_HEIGHT	equ	3
VARIABLE_MOKO_INTERFACE_INTERACTIVE	equ	VARIABLE_MOKO_INTERFACE_MENU_HEIGHT - VARIABLE_DECREMENT
VARIABLE_MOKO_INTERFACE_HEIGHT		equ	VARIABLE_MOKO_INTERFACE_HEADER_HEIGHT + VARIABLE_MOKO_INTERFACE_MENU_HEIGHT

; 64 Bitowy kod programu
[BITS 64]

; adresowanie względne (skoki, etykiety)
[DEFAULT REL]

; adres kodu programu w przestrzeni logicznej
[ORG VARIABLE_MEMORY_HIGH_REAL_ADDRESS]

start:
	; przygotowanie przestrzeni pod dokument i interfejsu
	call	initialization

.noKey:
	; pobierz znak z bufora klawiatury
	mov	ax,	VARIABLE_KERNEL_SERVICE_KEYBOARD_GET_KEY
	int	STATIC_KERNEL_SERVICE

	cmp	ax,	VARIABLE_EMPTY	
	je	.noKey

	cmp	ax,	VARIABLE_ASCII_CODE_ENTER
	je	key_enter

	cmp	ax,	VARIABLE_ASCII_CODE_BACKSPACE
	je	key_backspace

	cmp	ax,	0x8002
	je	key_arrow_left

	cmp	ax,	0x8003
	je	key_arrow_right

	cmp	ax,	0x8004
	je	key_arrow_up

	cmp	ax,	0x8005
	je	key_arrow_down

	cmp	ax,	0x8007
	je	key_home

	cmp	ax,	0x8008
	je	key_end

	cmp	ax,	0x001D
	je	key_ctrl_push	; lewy

	cmp	ax,	0x8006
	je	key_ctrl_push	; prawy

	cmp	ax,	0x009D
	je	key_ctrl_pull	; lewy

	cmp	ax,	0xB006
	je	key_ctrl_pull	; prawy

	cmp	byte [variable_semaphore_key_ctrl],	VARIABLE_FALSE
	je	.no_shortcut

	cmp	ax,	"x"
	je	key_function_exit

	cmp	ax,	"r"
	je	key_function_read

	cmp	ax,	"o"
	je	key_function_write

.no_shortcut:
	; sprawdź czy znak jest możliwy do wyświetlenia ------------------------

	; test pierwszy
	cmp	ax,	VARIABLE_ASCII_CODE_SPACE	; pierwszy znak z tablicy ASCII
	jb	.noKey	; jeśli mniejsze, pomiń

	; test drugi
	cmp	ax,	VARIABLE_ASCII_CODE_TILDE	; ostatni znak z tablicy ASCII
	ja	.noKey	; jeśli większe, pomiń

	; zapisz znak do dokumentu
	call	save_into_document

	inc	qword [variable_document_count_of_chars]
	inc	qword [variable_line_count_of_chars]
	inc	qword [variable_cursor_indicator]
	inc	dword [variable_cursor_position]
	inc	qword [variable_cursor_position_on_line]

	call	check_cursor
	call	update_line_on_screen

	cmp	byte [variable_semaphore_modified],	VARIABLE_EMPTY
	ja	start.noKey

	mov	byte [variable_semaphore_modified],	VARIABLE_TRUE

	; wyświetl znacznik "zmodyfikowany"
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	mov	ebx,	dword [variable_screen_size]
	sub	rbx,	qword [test_modified_chars_count]
	dec	rbx
	int	STATIC_KERNEL_SERVICE

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	ebx,	VARIABLE_COLOR_BLACK
	mov	rcx,	qword [test_modified_chars_count]
	mov	edx,	VARIABLE_COLOR_BACKGROUND_LIGHT_GRAY
	mov	rsi,	text_modified
	int	STATIC_KERNEL_SERVICE

	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_CURSOR_SET
	mov	rbx,	qword [variable_cursor_position]
	int	STATIC_KERNEL_SERVICE

	jmp	start.noKey

%include	"software/moko/init.asm"

%include	"software/moko/key_enter.asm"
%include	"software/moko/key_backspace.asm"
%include	"software/moko/key_home.asm"
%include	"software/moko/key_end.asm"
%include	"software/moko/key_arrow_left.asm"
%include	"software/moko/key_arrow_right.asm"
%include	"software/moko/key_arrow_up.asm"
%include	"software/moko/key_arrow_down.asm"
%include	"software/moko/key_ctrl.asm"

%include	"software/moko/function_key_exit.asm"
%include	"software/moko/function_key_read.asm"
%include	"software/moko/function_key_write.asm"

%include	"software/moko/save_into_document.asm"
%include	"software/moko/update_line_on_screen.asm"
%include	"software/moko/check_cursor.asm"
%include	"software/moko/count_chars_in_line.asm"
%include	"software/moko/count_chars_in_previous_line.asm"
%include	"software/moko/find_line_indicator.asm"

%include	"library/align_address_up_to_page.asm"
%include	"library/find_first_word.asm"
%include	"library/input.asm"

variable_document_address_start			dq	VARIABLE_EMPTY
variable_document_address_end			dq	VARIABLE_EMPTY
variable_document_count_of_chars		dq	VARIABLE_EMPTY
variable_document_count_of_lines		dq	VARIABLE_EMPTY
variable_document_line_start			dq	VARIABLE_EMPTY
variable_line_count_of_chars			dq	VARIABLE_EMPTY
variable_line_print_start			dq	VARIABLE_EMPTY
variable_cursor_indicator			dq	VARIABLE_EMPTY
variable_cursor_position			dq	VARIABLE_MOKO_CURSOR_POSITION_INIT
variable_cursor_position_on_line		dq	VARIABLE_EMPTY
variable_screen_size				dq	VARIABLE_EMPTY

variable_semaphore_key_ctrl			db	VARIABLE_EMPTY
variable_semaphore_status			db	VARIABLE_EMPTY
variable_semaphore_backspace			db	VARIABLE_EMPTY
variable_semaphore_modified			db	VARIABLE_EMPTY

variable_file_name_count_of_chars		dq	VARIABLE_EMPTY
variable_file_name_buffor	times	256	db	VARIABLE_EMPTY

; wczytaj lokalizacje programu systemu
%push
	%defstr		%$system_locale		VARIABLE_KERNEL_LOCALE
	%defstr		%$process_name		VARIABLE_PROGRAM_NAME
	%strcat		%$include_program_locale,	"software/", %$process_name, "/locale/", %$system_locale, ".asm"
	%include	%$include_program_locale
%pop

text_new_line			db	VARIABLE_ASCII_CODE_RETURN
text_exit_shortcut		db	'^x', VARIABLE_ASCII_CODE_TERMINATOR
text_open_shortcut		db	'^r', VARIABLE_ASCII_CODE_TERMINATOR
text_save_shortcut		db	'^o', VARIABLE_ASCII_CODE_TERMINATOR

document_area:
