;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; wejście:
;	rcx - rozmiar ciągu
;	rsi - wskaźnik do aktualnego początku danych w buforze
shell_prompt_relocate:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rdi

	; początek przestrzeni bufora
	mov	rdi,	shell_cache

	; zawartość bufora na początku jego przestrzeni?
	cmp	rsi,	shell_cache
	je	.at_begin	; tak

	; przesuń zawartość bufora na początek przestrzeni
	rep	movsb

	; zwróć nowy wskaźnik początku ciągu
	mov	rsi,	shell_cache

.at_begin:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx

	; powrót z procedury
	ret

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
;	rbx - rozmiar polecenia w znakach
;	rsi - wskaźnik do polecenia
shell_prompt_internal:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdi

	; prawdopodobnie polecenie: clear
	cmp	rbx,	shell_command_clear_end - shell_command_clear
	jne	.no_clear	; nie

	; sprawdź czy polecenie "clear"
	mov	ecx,	ebx	; rozmiar porównywanego ciągu
	mov	rdi,	shell_command_clear
	call	library_string_compare
	jc	.no_clear	; ciągi rózne

	; wyślij sekwencje czyszczenia przestrzeni znakowej
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	shell_string_sequence_clear_end - shell_string_sequence_clear
	mov	rsi,	shell_string_sequence_clear
	int	KERNEL_SERVICE

	; wykonano polecenie
	jmp	.end

.no_clear:
	;-----------------------------------------------------------------------
	; prawdopodobnie polecenie: exit
	cmp	rbx,	shell_command_exit_end - shell_command_exit
	jne	.no_exit	; nie

	; sprawdź czy polecenie "exit"
	mov	ecx,	ebx	; rozmiar porównywanego ciągu
	mov	rdi,	shell_command_exit
	call	library_string_compare
	jc	.no_exit	; ciągi różne

	; zakończ działanie powłoki
	xor	ax,	ax
	int	KERNEL_SERVICE

.no_exit:
.end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	rbx - rozmiar pierwszego słowa w ciągu
;	rcx - rozmiar całego ciągu w znakach
;	rsi - wskaźnik do początku przestrzeni ciągu
shell_prompt:
	; sprawdź czy polecenie wewnętrzne
	call	shell_prompt_internal
	jnc	shell.restart	; tak, przetworzono polecenie użyszkodnika

	; ilość znaków reprezentujących nazwę programu
	mov	rcx,	rbx

	; program został wyznaczony za pomocą ścieżki pośredniej/bezpośredniej?
	cmp	byte [rsi],	STATIC_ASCII_DOT
	je	.in_direct	; tak, pośredniej
	cmp	byte [rsi],	STATIC_ASCII_SLASH
	je	.in_direct	; tak, bezpośredniej

	; odszukaj program w katalogu wykonawczym
	add	rcx,	shell_exec_path_end - shell_exec_path
	mov	rsi,	shell_exec_path

.in_direct:
	; sprawdź czy istnieje program o podanej nazwie
	mov	ax,	KERNEL_SERVICE_VFS_exist
	int	KERNEL_SERVICE
	jc	.error	; brak programu lub niepoprawna ścieżka

	; każdy nowo uruchamiony progam ma prawo do nowej linii
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out_char
	mov	ecx,	STATIC_BYTE_SIZE_byte	; wyślij jeden znak nowej linii
	mov	dl,	STATIC_ASCII_NEW_LINE
	int	KERNEL_SERVICE

; 	; uruchom program przesyłając wszystkie podane wraz z nim agrumenty
; 	mov	ax,	KERNEL_SERVICE_PROCESS_run
; 	mov	bl,	KERNEL_SERVICE_PROCESS_RUN_FLAG_copy_out_of_parent
; 	mov	rcx,	r8
; 	int	KERNEL_SERVICE
; 	jc	shell.restart	; nie udało się uruchomić programu
;
; 	; czekaj na zakończenie procesu
;
; .wait_for_end:
; 	; zwolnij pozostały czas procesora
; 	mov	ax,	KERNEL_SERVICE_PROCESS_release
; 	int	KERNEL_SERVICE
;
; 	; proces zakończył pracę?
; 	mov	ax,	KERNEL_SERVICE_PROCESS_check
; 	int	KERNEL_SERVICE
; 	jc	.end	; tak
;
; 	; pobierz komunikat
; 	mov	ax,	KERNEL_SERVICE_PROCESS_ipc_receive
; 	mov	rdi,	shell_ipc_data
; 	int	KERNEL_SERVICE
; 	jc	.wait_for_end	; brak wiadomości
;
; 	; wszelkie przychodzące wyjątki, przesyłaj do procesu
; 	call	shell_event_transfer
;
; 	; kontynuuj
; 	jmp	.wait_for_end

.end:
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
	jmp	shell.restart
