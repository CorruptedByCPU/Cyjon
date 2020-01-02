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
service_shell_prompt_clean:
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
;	rcx - rozmiar ciągu w znakach
;	rsi - wskaźnik do ciągu
service_shell_prompt:
	; zachowaj rozmiar całego polecenia
	mov	r8,	rcx

	;-----------------------------------------------------------------------
	; polecenie zawiera odpowiednią ilość znaków?
	cmp	rbx,	service_shell_command_clean_end - service_shell_command_clean
	jne	.clean_omit	; nie
	; porównaj nazwy, takie same?
	mov	ecx,	ebx
	mov	rdi,	service_shell_command_clean
	call	library_string_compare
	jc	.clean_omit	; nie

	; przewiń zawartość ekranu o N linii w górę
	mov	ecx,	dword [kernel_video_cursor.y]
	inc	ecx

.clean:
	; wykonaj
	call	kernel_video_scroll

	; koniec przewijania?
	dec	ecx
	jnz	.clean	; nie

	; zresetuj pozycję wirtualnego kursora
	mov	dword [kernel_video_cursor.x],	STATIC_EMPTY
	mov	dword [kernel_video_cursor.y],	(KERNEL_VIDEO_HEIGHT_pixel / KERNEL_FONT_HEIGHT_pixel) - 0x01
	call	kernel_video_cursor_set

	; zresetuj pozycję

	; koniec obsługi polecenia
	jmp	.end

.clean_omit:
	;-----------------------------------------------------------------------
	; polecenie zawiera odpowienią ilość znaków?
	cmp	rbx,	service_shell_command_ip_end - service_shell_command_ip
	jne	.ip_omit	; nie
	; porównaj nazwy, takie same?
	mov	ecx,	ebx
	mov	rdi,	service_shell_command_ip
	call	library_string_compare
	jc	.ip_omit	; nie

	; wyczyść polecenie
	call	service_shell_prompt_clean
	jc	.ip_properties	; brak opcji/parametrów

	; znajdź pierwszą opcję polecenia
	call	library_string_word_next

	; opcja zawiera ilość znaków odpowiadająca słowu "set"?
	cmp	ebx,	service_shell_command_ip_set_end - service_shell_command_ip_set
	jne	.ip_unknown	; nie rozpoznano opcji...
	; porównaj nazwy, takie same?
	mov	ecx,	ebx
	mov	rdi,	service_shell_command_ip_set
	call	library_string_compare
	jc	.ip_unknown	; nie

	; wyczyść polecenie
	call	service_shell_prompt_clean
	jc	.ip_set_error	; brak parametru

	; odszukaj "słowo" określające adres IPv4
	call	library_string_word_next

	; podano więcej niż jeden parametr?
	cmp	rbx,	rcx
	jne	.ip_set_error	; tak, brak obsługi

	; spodziewamy się 4 oktetów
	mov	dl,	4

	; przetworzony adres IPV4
	xor	r8d,	r8d

	; zachowaj wskaźnik końca ciągu określającego adres IPv4
	mov	rdi,	rsi
	add	rdi,	rbx

.ip_set_loop:
	; znajdź wartość z ciągu znaków oddzieloną separatorem w postaci "."
	mov	al,	STATIC_ASCII_DOT
	call	library_string_cut

	; brak "wartości"?
	test	rcx,	rcx
	jz	.ip_set_error	; nieprawidłowy adres IPv4

	; sprawdź czy "wartość" składa się z samych cyfr
	call	library_string_digits
	jc	.ip_set_error	; nieprawidłowy adres IPv4

	; zamień "wartość" na liczbę
	call	library_string_to_integer

	; przepełnienie oktetu?
	cmp	rax,	255
	ja	.ip_set_error	; nieprawidłowy adres IPv4

	; zachowaj oktet
	shl	r8d,	STATIC_MOVE_AL_TO_HIGH_shift
	mov	r8b,	al

	; zachowaj nowy rozmiar ciąguprzesuń wskaźnik ciągu za separator
	inc	rcx
	add	rsi,	rcx

	; przetworzyć pozostałe oktety?
	dec	dl
	jnz	.ip_set_loop	; tak

	; koniec ciągu?
	dec	rsi
	cmp	rsi,	rdi
	jne	.ip_set_error	; nieprawidłowy adres IPv4

	; załaduj nowy adres IPv4 do kontrolera interfejsu sieciowego
	bswap	r8d
	mov	dword [driver_nic_i82540em_ipv4_address],	r8d

	; koniec obsługi polecenia
	jmp	.end

.ip_set_error:
	; wyświetl komunikat
	mov	ecx,	service_shell_string_error_ipv4_format_end - service_shell_string_error_ipv4_format
	mov	rsi,	service_shell_string_error_ipv4_format
	call	kernel_video_string

	; zrealizowano polecenie
	jmp	.end

.ip_properties:
	; wyświetl znak nowej linii
	mov	eax,	STATIC_ASCII_NEW_LINE
	mov	cl,	1	; jeden raz
	call	kernel_video_char

	; wyświetl aktualnie przypisany adres IPv4 od nowej linii

	; system liczbowy
	mov	bl,	STATIC_NUMBER_SYSTEM_decimal

	; brak przedrostka
	xor	cl,	cl

	; ilość oktetów
	mov	dl,	4

	; ustaw wskaźnik na przestrzeń adresu IPv4 kontrolera sieciowego
	mov	rsi,	driver_nic_i82540em_ipv4_address

.ip_properties_loop:
	; pobierz pierwszy oktet
	lodsb

	; wyświetl pierwszy oktet
	call	kernel_video_number

	; wyświetlić pozostałe oktety?
	dec	dl
	jz	.end	; nie

	; wyświetl separator oktetów w adresie IPV4
	mov	eax,	STATIC_ASCII_DOT
	mov	cl,	1	; jeden raz
	call	kernel_video_char

	; powrót do pętli
	jmp	.ip_properties_loop

.ip_unknown:
	; wyświetl znak nowej linii
	mov	al,	STATIC_ASCII_NEW_LINE
	mov	ecx,	1	; jeden raz
	call	kernel_video_char

	; wyświetl nierozpoznaną opcję
	mov	ecx,	ebx
	call	kernel_video_string

	; wyświetl znak zapytania i przesuń kursor do nowej linii
	mov	ecx,	service_shell_command_unknown_end - service_shell_command_unknown
	mov	rsi,	service_shell_command_unknown
	call	kernel_video_string

	; koniec obsługi polecenia
	jmp	.end

.ip_omit:

.end:
	; powróć o pętli głównej
	jmp	service_shell
