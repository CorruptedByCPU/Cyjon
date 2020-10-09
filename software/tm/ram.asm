;===============================================================================
; Copyright (C) by blackdev.org
;===============================================================================

;===============================================================================
tm_ram_bar:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdx
	push	rsi

	; pierwsza część paska, zielony
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	tm_string_bar_low_end - tm_string_bar_low
	mov	rsi,	tm_string_bar_low
	int	KERNEL_SERVICE

	; słowo "RAM" i wartość wyświetlana, zajmują 14 znaków w wierszu
	; wylicz ilość znaków pozostałych dla paska
	mov	cx,	word [tm_stream_meta + CONSOLE_STRUCTURE_STREAM_META.width]
	sub	ecx,	14
	jle	.end	; brak miejsca na pasek

	; zachowaj maksymalny rozmiar paska
	push	rcx

	; oblicz procent zajętości
	mov	rax,	r8	; rozmiar całkowity
	sub	rax,	r9	; rozmiar wolny
	mul	rcx	; skala na podstawie pozostałych znaków w szerokości konsoli
	xor	edx,	edx
	div	r8d

	; zachowaj szerokość paska w znakach
	push	rax
	push	rax

	; wylicz obszar "low"
	mov	eax,	3
	xchg	rax,	rcx
	xor	edx,	edx
	div	rcx

	; zachowaj szerokość kolejnych obszarów
	push	rax

	; reszta z dzielenia?
	test	edx,	edx
	jz	.no_modulo	; nie

	; rozmiar przestrzeni "low" o jeden znak większy
	inc	rax

.no_modulo:
	; szerokość obszaru "low"
	mov	rcx,	qword [rsp + STATIC_QWORD_SIZE_byte]

	; rozmiar zajętej przestrzeni RAM mniejszy lub równy względem obszaru "low"?
	cmp	rcx,	rax
	jbe	.low	; tak

	; wyświetl obszar "low" w pełnej krasie
	mov	rcx,	rax

.low:
	; wyświetl pasek reprezentujący zajętość pamięci RAM
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out_char
	mov	dl,	TM_STRING_BAR_char
	int	KERNEL_SERVICE

	; koryguj pozostałą przestrzeń do wyświetlenia
	sub	qword [rsp + STATIC_QWORD_SIZE_byte],	rcx

	; druga część paska, żółty
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	tm_string_bar_medium_end - tm_string_bar_medium
	mov	rsi,	tm_string_bar_medium
	int	KERNEL_SERVICE

	; pobierz pozostałą szerokość
	mov	rcx,	qword [rsp + STATIC_QWORD_SIZE_byte]
	test	ecx,	ecx	; koniec wyświetlania?
	jz	.ready	; tak

	; rozmiar zajętej przestrzeni RAM mniejszy lub równy względem obszaru "medium"?
	cmp	rcx,	qword [rsp]
	jbe	.medium	; tak

	; wyświetl obszar "medium" w pełnej krasie
	mov	rcx,	qword [rsp]

.medium:
	; wyświetl pasek reprezentujący zajętość pamięci RAM
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out_char
	int	KERNEL_SERVICE

	; koryguj pozostałą przestrzeń do wyświetlenia
	sub	qword [rsp + STATIC_QWORD_SIZE_byte],	rcx

	; trzecia część paska, czerwony
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	tm_string_bar_high_end - tm_string_bar_high
	mov	rsi,	tm_string_bar_high
	int	KERNEL_SERVICE

	; pobierz pozostałą szerokość
	mov	rcx,	qword [rsp + STATIC_QWORD_SIZE_byte]
	test	ecx,	ecx	; koniec wyświetlania?
	jz	.ready	; tak

.high:
	; wyświetl pasek reprezentujący zajętość pamięci RAM
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out_char
	int	KERNEL_SERVICE

.ready:
	; usuń zmienną szerokość obszaru
	add	rsp,	STATIC_QWORD_SIZE_byte * 0x02

	; wyczyść pozostałą przestrzeń paska
	pop	rax
	pop	rcx	; wyświetlona szerokość
	sub	rcx,	rax
	inc	rcx	; separator

	; wypełnij przestrzeń znakami spacji
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out_char
	mov	dl,	STATIC_ASCII_SPACE
	int	KERNEL_SERVICE

.end:
	; przywróć oryginalne rejestry
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
tm_ram:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi

	; przelicz ilość wolnej przestrzeni na odpowiedni typ oraz resztę w procentach
	mov	rax,	r9
	shl	rax,	STATIC_MULTIPLE_BY_PAGE_shift	; zamień strony na Bajty
	call	library_value_to_size

	; formatuj ciąg wyjściowy rozmiaru
	mov	rdi,	tm_string_ram_value
	call	tm_ram_format

	; pobierz typ wartości
	mov	rsi,	tm_string_size_values
	mov	bl,	byte [rsi + rbx]

	; dołącz do ciągu
	mov	byte [rdi + TR_STRING_RAM_length - 0x01],	bl

	; wyświetl całkowitą część wartości
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	tm_string_ram_part_one_end - tm_string_ram_part_one
	mov	rsi,	tm_string_ram_part_one
	int	KERNEL_SERVICE
	mov	ecx,	0x04
	mov	rsi,	tm_string_ram_value
	int	KERNEL_SERVICE

	; wyświetl procent reszty wartości
	mov	ecx,	tm_string_ram_part_two_end - tm_string_ram_part_two
	mov	rsi,	tm_string_ram_part_two
	int	KERNEL_SERVICE
	mov	ecx,	0x02
	mov	rsi,	tm_string_ram_value + 0x04
	int	KERNEL_SERVICE

	; wyświetl oznaczenie wartości
	mov	ecx,	tm_string_ram_part_tree_end - tm_string_ram_part_tree
	mov	rsi,	tm_string_ram_part_tree
	int	KERNEL_SERVICE
	mov	ecx,	0x01
	mov	rsi,	tm_string_ram_value + 0x06
	int	KERNEL_SERVICE

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	rax - wartość całkowita
;	rdx - procent z reszty
;	rdi - wskaźnik docelowy konstruowanego ciągu
tm_ram_format:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdi
	push	rdx

	; zamień wartość całkowitą na ciąg
	mov	ebx,	STATIC_NUMBER_SYSTEM_decimal
	mov	ecx,	0x04	; maksymalny rozmiar prefiksu
	mov	dl,	STATIC_ASCII_SPACE	; prefiks
	call	library_integer_to_string

	; zamień procent reszty na ciąg
	mov	rax,	qword [rsp]	; pobierz procent reszty
	add	rdi,	rcx	; przesuń wskaźnik za wartość całkowitą
	mov	ecx,	2	; maksymalny rozmiar prefiksu
	mov	dl,	STATIC_ASCII_DIGIT_0	; prefiks
	call	library_integer_to_string

	; przywróć oryginalne rejestry
	pop	rdx
	pop	rdi
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret
