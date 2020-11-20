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
