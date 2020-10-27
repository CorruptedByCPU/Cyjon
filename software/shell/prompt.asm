;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; wejście:
;	rbx - poprzedni rozmiar "słowa"
;	r8 - aktualny rozmiar ciągu
;	rsi - wskaźnik do aktualnej pozycji w ciągu
; wyjście:
;	Flaga CF, jeśli ciąg pusty
;	rejestry zaktualizowane
shell_prompt_clean:
	; przesuń wskaźnik za polecenie "ip" i zmniejsz ilość znaków w pozostałym ciągu
	add	rsi,	rbx
	sub	r8,	rbx

	; usuń białe znaki z początku i końca reszty ciągu
	mov	rcx,	r8
	call	library_string_trim

	; zachowaj pozostały rozmiar polecenia
	mov	r8,	rcx

.error:
	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	rbx - rozmiar pierwszego słowa w ciągu
;	rcx - rozmiar całego ciągu w znakach
;	rsi - wskaźnik do początku ciągu
shell_prompt:
	; zapamiętaj rozmiar całego ciągu
	mov	r8,	rcx

	;-----------------------------------------------------------------------
	; pierwsze "słowo" mieści się w granicach polecenia "clear"?
	cmp	rbx,	shell_command_clear_end - shell_command_clear
	jne	.no_clear	; nie

	; sprawdź czy polecenie "clear"
	mov	ecx,	ebx
	mov	rdi,	shell_command_clear
	call	library_string_compare
	jc	.no_clear	; nie

	; wyślij sekwencje czyszczenia przestrzeni znakowej
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	shell_string_sequence_clear_end - shell_string_sequence_clear
	mov	rsi,	shell_string_sequence_clear
	int	KERNEL_SERVICE

	; powrót do pętli głównej
	jmp	shell.prompt_no_new_line

.no_clear:
	; sprawdź czy polecenie "exit"
	cmp	rbx,	shell_command_exit_end - shell_command_exit
	jne	.no_exit	; nie

	; sprawdź czy polecenie "exit"
	mov	ecx,	ebx
	mov	rdi,	shell_command_exit
	call	library_string_compare
	jc	.no_exit	; nie

	; zakończ działanie powłoki
	xor	ax,	ax
	int	KERNEL_SERVICE

.no_exit:
	; sprawdź czy istnieje program o podanej nazwie w systemie plików
	mov	ax,	KERNEL_SERVICE_VFS_exist
	add	r8,	shell_exec_path_end - shell_exec_path
	mov	rcx,	r8
	mov	rsi,	shell_exec_path
	int	KERNEL_SERVICE
	jc	.error	; brak programu lub niepoprawna ścieżka

	; każdy nowo uruchamiony progam ma prawo do nowej linii
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out_char
	mov	ecx,	0x01	; wyślij jeden znak nowej linii
	mov	dl,	STATIC_ASCII_NEW_LINE
	int	KERNEL_SERVICE

	; uruchom program
	mov	ax,	KERNEL_SERVICE_PROCESS_run
	mov	bl,	KERNEL_SERVICE_PROCESS_RUN_FLAG_copy_out_of_parent
	mov	rcx,	r8
	int	KERNEL_SERVICE
	jc	shell.restart	; nie udało się uruchomić programu

	; czekaj na zakończenie procesu
	mov	ax,	KERNEL_SERVICE_PROCESS_check

.wait_for_end:
	; wszelkie przychodzące wyjątki, przesyłaj do procesu
	call	shell_event_transfer

	; proces zakończył swoją pracę
	int	KERNEL_SERVICE
	jnc	.wait_for_end	; nie

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

	; powrót do pętli głównej
	jmp	shell.prompt_no_new_line
