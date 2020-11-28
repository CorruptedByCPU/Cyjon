;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; wejście:
;	rbx - rozmiar pierwszego słowa w ciągu
;	rcx - rozmiar całego ciągu w znakach
;	rsi - wskaźnik do początku przestrzeni ciągu
shell_exec:
	; sprawdź czy polecenie wewnętrzne
	call	shell_prompt_internal
	jnc	shell.restart	; tak, przetworzono polecenie użyszkodnika

	; zachowaj rozmiar listy argumentów w Bajtach
	sub	rcx,	rbx
	push	rcx

	; każdy uruchamiony program ma prawo do nowej linii
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out_char
	mov	ecx,	STATIC_BYTE_SIZE_byte	; wyślij jeden znak
	mov	dl,	STATIC_SCANCODE_NEW_LINE	; nowej linii
	int	KERNEL_SERVICE

	; ilość znaków reprezentujących nazwę programu
	mov	rcx,	rbx

	; program został wyznaczony za pomocą ścieżki pośredniej/bezpośredniej?
	cmp	byte [rsi],	STATIC_SCANCODE_DOT
	je	.in_direct	; tak, pośredniej
	cmp	byte [rsi],	STATIC_SCANCODE_SLASH
	je	.in_direct	; tak, bezpośredniej

	; odszukaj program w katalogu wykonawczym
	add	rcx,	shell_exec_path_end - shell_exec_path
	mov	rsi,	shell_exec_path

.in_direct:
	; sprawdź czy istnieje program o podanej nazwie
	mov	ax,	KERNEL_SERVICE_VFS_exist
	int	KERNEL_SERVICE
	jc	.error	; brak programu lub niepoprawna ścieżka

	; uruchom program przesyłając wszystkie podane wraz z nim agrumenty
	mov	ax,	KERNEL_SERVICE_PROCESS_run
	mov	bl,	KERNEL_SERVICE_PROCESS_RUN_FLAG_copy_out_of_parent
	pop	r8	; rozmiar listy argumentów w Bajtach
	int	KERNEL_SERVICE
	jc	shell.restart	; nie udało się uruchomić programu

	; czekaj na zakończenie procesu

.wait_for_end:
	; zwolnij pozostały czas procesora
	mov	ax,	KERNEL_SERVICE_PROCESS_release
	int	KERNEL_SERVICE

	; proces zakończył pracę?
	mov	ax,	KERNEL_SERVICE_PROCESS_check
	int	KERNEL_SERVICE
	jc	.end	; tak

	; pobierz komunikat
	mov	ax,	KERNEL_SERVICE_PROCESS_ipc_receive
	mov	rdi,	shell_ipc_data
	int	KERNEL_SERVICE
	jc	.wait_for_end	; brak wiadomości

	; wszelkie przychodzące wyjątki, przesyłaj do procesu
	call	shell_event_transfer

	; kontynuuj
	jmp	.wait_for_end

.end:
	; przywróć tytuł nagłówka
	call	shell_header

	; włącz kursor tekstowy
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	shell_string_cursor_enable_end - shell_string_cursor_enable
	mov	rsi,	shell_string_cursor_enable
	int	KERNEL_SERVICE

	; powrót do pętli głównej
	jmp	shell.restart

.error:
	; wyświetl komunikat
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	shell_command_unknown_end - shell_command_unknown
	mov	rsi,	shell_command_unknown
	int	KERNEL_SERVICE

	; zwolnij zmienną lokalną
	add	rsp,	STATIC_QWORD_SIZE_byte

	; powrót do pętli głównej
	jmp	shell.restart
