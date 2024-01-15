;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Main developer:
;	Darek (devport) Kwieciński [e-mail: kwiecinskidarek from gmail.com]
;
; Support:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;
; Program name:
;	BFI - Brain Fuck Interpreter
;-------------------------------------------------------------------------------

; Use:
; 	bfi hello.bf
;
; nasm - http://www.nasm.us/

; zestaw imiennych wartości stałych jądra systemu
%include	'config.asm'

%define	VARIABLE_PROGRAM_NAME		bfi
%define	VARIABLE_PROGRAM_NAME_CHARS	3
%define	VARIABLE_PROGRAM_VERSION	"v0.2"

VARIABLE_BFI_TABLE_SIZE			equ	1024

; 64 Bitowy kod programu
[BITS 64]

; adresowanie względne (skoki, etykiety)
[DEFAULT REL]

; adres kodu programu w przestrzeni logicznej
[ORG VARIABLE_MEMORY_HIGH_REAL_ADDRESS]

start:
	; pobierz przesłane argumenty
	mov	ax,	VARIABLE_KERNEL_SERVICE_PROCESS_ARGS
	mov	rdi,	end
	call	library_align_address_up_to_page
	int	STATIC_KERNEL_SERVICE
		
	; czy argumenty istnieją?
	cmp	rcx,	VARIABLE_PROGRAM_NAME_CHARS
	jbe	print_help

	; pomiń nazwę procesu w argumentach
	add	rdi,	VARIABLE_PROGRAM_NAME_CHARS
	sub	rcx,	VARIABLE_PROGRAM_NAME_CHARS

	; poszukaj argumentu
	call	library_find_first_word
	jc	no_file_or_end	; brak argumentów
	
	; wczytaj plik do pamięci procesu
	mov	ax,	VARIABLE_KERNEL_SERVICE_VFS_FILE_READ
	mov	rsi,	end	; na koniec programu
	xchg	rsi,	rdi
	int	STATIC_KERNEL_SERVICE
	
	
	; zapisz rozmiar pliku w Bajtach
	mov	 qword [variable_script_size],	rcx
	
	; zapisz adres początku kodu zrodlowego
	mov	qword [variable_script_start],	rdi
	
	; zapisz adres końca skryptu
	mov qword [variable_script_end], rdi
	add qword [variable_script_end], rcx
	
	; podmień rejestry
	xchg	rsi,	rdi
	
	; zapisz adres tablicy znaków do zmiennej Memory_ptr
	mov	rdi,	variable_memory
	mov	qword [variable_memory_ptr],	rdi
			
;------------------------------------------------------------------------------	
;
; procedura sprawdza na co wskazuje Memory_ptr w tablicy znaków
;
;------------------------------------------------------------------------------
.switch:
	
	; wczytaj znak
	mov al, byte [rsi]
	
	; jezeli koniec to wyjdź z programu
	cmp	al,	VARIABLE_EMPTY
	je	no_file_or_end

	cmp	al,	'>'
	je	.inc_pointer
	
	cmp	al,	'<'
	je	.dec_pointer
	
	cmp	al,	'+'
	je	.inc_memory
	
	cmp	al,	'-'
	je	.dec_memory
	
	cmp al,	','
	je	.get_char
	
	cmp	al,	'.'
	je	.print_memory
	
	cmp al,	'['
	je	open_parent
	
	cmp al,	']'
	je	close_parent
	
	inc rsi
	jmp	.switch
	

.inc_pointer:
	; zwiększ wskaźnik o 1
	inc	qword [variable_memory_ptr]
	
	inc rsi
	; sprawdz kolejny znak
	jmp	.switch
	
.dec_pointer:
	;zmniejsz wskaźnik o 1
	dec	qword [variable_memory_ptr]

	inc rsi
	; sprawdz kolejny znak
	jmp	.switch
	
.inc_memory:
	; zachowaj oryginalne rejestry
	push	rax
	push	rsi	

	; inkrementuj wartość komórki 
	mov	rsi,	qword [variable_memory_ptr]
	mov	al,	byte [rsi]
	inc	al
	mov	byte	[rsi], al
	
	; przywróć oryginalne rejestry
	pop rsi
	pop rax
	
	inc rsi
	jmp	.switch
	
.dec_memory:
	; zachowaj oryginalne rejestry
	push	rax
	push	rsi
	
	; dekrementuj wartość komórki
	mov	rsi,	qword [variable_memory_ptr]
	mov	al,	byte [rsi]
	dec	al
	mov	byte [rsi],	al
	
	; przywróć oryginalne rejestry
	pop	rsi
	pop	rax
	
	inc rsi
	jmp	.switch
	
	
.get_char:
	
	mov	ax,	VARIABLE_KERNEL_SERVICE_KEYBOARD_GET_KEY
	int	STATIC_KERNEL_SERVICE
	
	; test pierwszy
	cmp	ax,	VARIABLE_ASCII_CODE_SPACE	; pierwszy znak z tablicy ASCII
	jb	.get_char	; jeśli mniejsze, pomiń

	; test drugi
	cmp	ax,	VARIABLE_ASCII_CODE_TILDE	; ostatni znak z tablicy ASCII
	ja	.get_char	; jeśli większe, pomiń
	
	; zachowaj oryginalne rejestry
	push rsi
	
	; zapisz znak
	mov rsi, qword [variable_memory_ptr]
	mov byte [rsi], al
	
	; przywróć oryginalne rejestry
	pop rsi
	
	inc rsi
	jmp .switch
	
.print_memory:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	
	mov	rsi,	qword [variable_memory_ptr]
	; wyświetl zawartość komórki
	
	mov	r8b,	byte [rsi]
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_CHAR
	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	rcx,	1	; po jednym znaku
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	int	STATIC_KERNEL_SERVICE
			
	; przywróć oryginalne rejestry
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax
	
	inc rsi
	jmp	.switch
	
;---------------------------------------------------------------------------
;
; Obsługa pętli '[' 
;
;---------------------------------------------------------------------------
open_parent:	
	; jezeli w komórce mamy 0 pomiń instrukcje między nawiasami
	push rsi
	
	mov rsi, qword [variable_memory_ptr]
	cmp byte [rsi], VARIABLE_EMPTY
	je .else
	
	pop rsi
	; przejdź do kolejnej instrukcji
	inc rsi
	
	; skok do pętli głównej
	jmp start.switch
	
.else:
	pop rsi
	;zachowaj oryginalne rejestry
	push rcx
	; ustaw variable_depth = 1
	mov rcx, 0x01
	mov qword [variable_depth], rcx
	; rcx - iterrator 
	mov rcx, rsi
	inc rcx

.while:
	cmp rcx, qword[variable_script_end]
	ja .while_end	; jeżeli równe lub większe to skok do while_end
	
	; Jeżeli rcx mniejsze od variable_script_end to 
	; Wczytaj znak
	mov al, byte [rcx]
	; if [rsi] == '['
	cmp al,	'['
	je .inc_depth
	; if [rsi] == ']'
	cmp al,	']'
	je .dec_depth
	
.while_next:
	; zwieksz iterrator
	inc rcx
	
	; jeżeli variable_depth = 0 to skocz do while_end
	cmp qword [variable_depth], VARIABLE_EMPTY
	je .while_end
	
	; na początek pętli
	jmp .while
	
	
.while_end:
		
	; jeżeli variable_depth różne od 0
	cmp qword [variable_depth], VARIABLE_EMPTY
	jne .missing_close_pair ; wyświetl komunikat o braku pary zamykającej pętle
	
	; aktualizuj pozycje instrukcji
	mov rsi, rcx
	
	;przywróć oryginalne rejestry
	pop rcx
	
	;skocz do pętli głównej
	jmp start.switch

.inc_depth:
	; zwieksz głębokość pętli
	inc qword [variable_depth]
	
	jmp .while_next
	
.dec_depth:
	; zmniejsz głębokość pętli
	
	dec qword [variable_depth]
	
	jmp .while_next
	
.missing_close_pair:
	; wyświetl komunikat o braku pary nawiasów
	; zachowaj oryginalne rejestry
	push rax
	push rbx
	push rcx
	push rdx
	push rsi
	
	; wyświetl komunikat o braku pary zamykającej pętle
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	rcx,	VARIABLE_FULL
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_missing_close_pair
	int	STATIC_KERNEL_SERVICE
	
	; przywróć oryginalne rejestry
	pop rsi
	pop rdx
	pop rcx
	pop rbx
	pop rax
	
	pop rcx
	; zakończ program
	jmp 	no_file_or_end

;---------------------------------------------------------------------------
;
; Obsługa pętli ']' 
;
;---------------------------------------------------------------------------	
	
close_parent:
	
	;zachowaj oryginalne rejestry
	push rcx
	; ustaw variable_depth = VARIABLE_FULL - 1
	mov rcx,  VARIABLE_FULL
	dec rcx
	mov qword [variable_depth], rcx

	; rcx - iterrator 
	mov rcx, rsi ;     >  ']'
	dec rcx		; > .
	
.while:
	cmp rcx, qword [variable_script_start]
	jbe .while_end	; jeżeli równe lub mniejsze to skok do while_end
	
	; Jeżeli rcx większe od variable_instruction_start to
	; Wczytaj znak
	mov al, byte [rcx]
	
	; if [rsi] == '['
	cmp al,	'['
	je .inc_depth
	; if [rsi] == ']'
	cmp al,	']'
	je .dec_depth	
	
.while_next:
	; zmniejsz iterrator
	dec rcx
	
	; jeżeli variable_depth = VARIABLE_FULL
	cmp qword [variable_depth], VARIABLE_FULL
	je .while_end ; zakończ pętle

	; na początek pętli
	jmp .while
	
.while_end:
	
	; jeżeli variable_depth <> VARIABLE_FULL
	cmp qword [variable_depth], VARIABLE_FULL
	jne .missing_open_pair	; wyświetl komunikat o braku nawiasu otwierającego

	; aktualizuj pozycje instrukcji
	mov rsi, rcx
	inc rsi
	
	;przywróć oryginalne rejestry
	pop rcx
	
	;skocz do pętli głównej
	jmp start.switch
	
.inc_depth:
	; zwieksz głębokość pętli
	inc qword [variable_depth]
	
	jmp .while_next
	
.dec_depth:
	; zmniejsz głębokość pętli
	
	dec qword [variable_depth]
	
	jmp .while_next
	
.missing_open_pair:
	; wyświetl komunikat o braku pary nawiasów
	; zachowaj oryginalne rejestry
	push rax
	push rbx
	push rcx
	push rdx
	push rsi
		
	; wyświetl komunikat o braku pary zamykającej pętle
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	rcx,	VARIABLE_FULL
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_missing_open_pair
	int	STATIC_KERNEL_SERVICE
	
	; przywróć oryginalne rejestry
	pop rsi
	pop rdx
	pop rcx
	pop rbx
	pop rax
	
	pop rcx
	; zakończ program
	jmp 	no_file_or_end	
	
	
print_help:
	; wyświetl powitanie
	mov	ax,	VARIABLE_KERNEL_SERVICE_SCREEN_PRINT_STRING
	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	rcx,	VARIABLE_FULL
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_hello
	int	STATIC_KERNEL_SERVICE
	
	
	
	
no_file_or_end:
	; koniec procesu
	xor	ax,	ax
	int	STATIC_KERNEL_SERVICE
	
%include	'library/align_address_up_to_page.asm'
%include	'library/find_first_word.asm'

variable_script_start				dq	VARIABLE_EMPTY	; wskaźnik na dane wejściowe
variable_script_size				dq	VARIABLE_EMPTY	; rozmiar skryptu
variable_script_end				dq	VARIABLE_EMPTY	; wskaźnik na koniec skryptu
variable_memory	times VARIABLE_BFI_TABLE_SIZE	db	VARIABLE_EMPTY	; tablica znaków
variable_memory_ptr				dq	VARIABLE_EMPTY	; wskaźnik w tablicy znaków

variable_depth					dq	VARIABLE_EMPTY

; wczytaj lokalizacje programu systemu
%push
	%defstr		%$system_locale		VARIABLE_KERNEL_LOCALE
	%defstr		%$process_name		VARIABLE_PROGRAM_NAME
	%strcat		%$include_program_locale,	"software/", %$process_name, "/locale/", %$system_locale, ".asm"
	%include	%$include_program_locale
%pop

; koniec kodu programu
end:
