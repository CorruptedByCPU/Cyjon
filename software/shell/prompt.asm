;===============================================================================
; Copyright (C) by Blackend.dev
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
;	rbx - rozmiar pierwszego słowa a ciągu
;	rcx - rozmiar całego ciągu w znakach
;	rsi - wskaźnik do początku ciągu
shell_prompt:
	; zapamiętaj rozmiar całego ciągu
	mov	r8,	rcx

	;-----------------------------------------------------------------------
	; pierwsze "słowo" mieści się w granicach polecenia "clean"?
	cmp	rbx,	shell_command_clean_end - shell_command_clean
	jne	.no_clean	; nie

	; sprawdź czy polecenie "clean"
	mov	ecx,	ebx
	mov	rdi,	shell_command_clean
	call	library_string_compare
	jc	.no_clean	; nie

	; wyczyść zawartość ekranu
	mov	ax,	KERNEL_SERVICE_VIDEO_clean
	int	KERNEL_SERVICE

	; koniec obsługi polecenia
	jmp	.end

.no_clean:
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
	nop

.end:
	; powróć o pętli głównej
	jmp	shell
