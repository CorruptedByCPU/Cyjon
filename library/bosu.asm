;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

	;-----------------------------------------------------------------------
	; stałe, zmienne, struktury, obiekty
	;-----------------------------------------------------------------------
	%include	"library/bosu/config.asm"
	%include	"library/bosu/data.asm"
	%include	"library/bosu/font.asm"
	;-----------------------------------------------------------------------

;===============================================================================
; wejście:
;	rsi - wskaźnik do struktury okna
library_bosu:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdi
	push	rsi

	; pobierz szerokość o wysokość okna
	mov	r8,	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
	mov	r9,	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.height]

	;-----------------------------------------------------------------------
	; wyświetlić nagłówek okna?
	test	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags],	LIBRARY_BOSU_WINDOW_FLAG_header
	jz	.no_header	; nie

	; wysokość okna powiększona o nagłówek
	add	r9,	LIBRARY_BOSU_ELEMENT_HEADER_HEIGHT_pixel
	mov	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.height],	r9

.no_header:
	;-----------------------------------------------------------------------
	; scanline okna
	mov	r10,	r8
	shl	r10,	KERNEL_VIDEO_DEPTH_shift
	mov	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.scanline],	r10

	;-----------------------------------------------------------------------
	; oblicz rozmiar przestrzeni danych okna w Bajtach
	mov	rax,	r10
	mul	r9
	mov	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.size],	rax

	;-----------------------------------------------------------------------
	; przydziel przestrzeń po dane okna
	mov	rcx,	rax
	call	library_page_from_size
	call	kernel_memory_alloc
	mov	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.address],	rdi	; zachowaj wskaźnik do przestrzeni danych okna

	;-----------------------------------------------------------------------
	; wypełnij przestrzeń okna domyślnym kolorem tła
	mov	eax,	LIBRARY_BOSU_WINDOW_BACKGROUND_color
	mov	rcx,	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.size]
	shr	rcx,	KERNEL_VIDEO_DEPTH_shift
	rep	stosd

	;-----------------------------------------------------------------------
	; przetwórz wszystkie elementy wchodzące w skład okna
	call	library_bosu_elements

	;-----------------------------------------------------------------------
	; zarejestruj okno w menedżerze okien
	call	service_desu_object_insert

	; przywróć oryginalne rejestry
	pop	rsi
	pop	rdi
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z liblioteki
	ret

;===============================================================================
; wejście:
;	rsi - wskaźnik do struktury okna
; wyjście:
;	r8 - minimalna szerokość okna na podstawie zawartych elementów
;	r9 - minimalna wysokość okna na podstawie zawartych elementów
library_bosu_elements_specification:
	; zachowaj oryginalne rejestry
	push	rax
	push	rsi

	; pozycja najdalszego elementu na osi X
	xor	r8,	r8

	; pozycja najdalszego elementu na osi Y
	xor	r9,	r9

	; przesuń wskaźnik na listę elementów
	add	rsi,	LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.SIZE

.loop:
	; koniec elementów?
	cmp	dword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT.type],	STATIC_EMPTY
	je	.end	; tak

	; element typu "nagłówek"?
	cmp	dword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT.type],	LIBRARY_BOSU_ELEMENT_TYPE_header
	je	.next	; tak, pomiń

	; pozycja elementu na osi X
	mov	rax,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.x]
	add	rax,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]

	; dalej niż poprzedni?
	cmp	rax,	r8
	jb	.y	; nie

	; zachowaj informację
	mov	r8,	rax

.y:
	; pozycja elementu na osi Y
	mov	rax,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.y]
	add	rax,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.height]

	; dalej niż poprzedni?
	cmp	rax,	r9
	jb	.next	; nie

	; zachowaj informację
	mov	r9,	rax

.next:
	; przesuń wskaźnik na następny element z listy
	add	rsi,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT.size]

	; kontynuuj
	jmp	.loop

.end:
	; przywróć oryginalne rejestry
	pop	rsi
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	rsi - wskaźnik do elementów okna
library_bosu_elements:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rsi

	; zachowaj wskaźnik do struktury okna
	mov	rdi,	rsi

	; przesuń wskaźnik na początek listy elementów okna
	add	rsi,	LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.SIZE

.loop:
	; koniec elementów?
	mov	eax,	dword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT.type]
	cmp	eax,	STATIC_EMPTY
	je	.ready	; tak

	; przejdź do procedury obsługi elementu
	call	qword [library_bosu_element_entry + rax * STATIC_QWORD_SIZE_byte]

	; przesuń wskaźnik na następny element
	add	rsi,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT.size]

	; kontyuuj
	jmp	.loop

.ready:
	; przywróć oryginalny rejestr
	pop	rsi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	rdi - wskaźnik do struktury okna
;	rsi - wskaźnik do elementu
;	r8 - szerokość okna w pikselach
;	r9 - wysokość okna w pikselach
;	r10 - scanline okna w Bajtach
library_bosu_element_header:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	r11
	push	r12
	push	r13
	push	rdi

	; pobierz wskaźnik do przestrzeni danych okna
	mov	rdi,	qword [rdi + LIBRARY_BOSU_STRUCTURE_WINDOW.address]

	; wylicz szerokość, wysokość i scanline elementu
	mov	r11,	r8	; szerokość na równi z oknem
	mov	r12,	LIBRARY_BOSU_ELEMENT_HEADER_HEIGHT_pixel
	mov	r13,	r10	; scanline na równi z oknem

	; wylicz względny wskaźnik przestrzeni tekstu elementu nagłówka w przestrzeni danych okna
	mov	rax,	LIBRARY_BOSU_ELEMENT_HEADER_PADDING_pixel
	mul	r13	; * scanline
	add	rax,	LIBRARY_BOSU_ELEMENT_HEADER_PADDING_pixel << KERNEL_VIDEO_DEPTH_shift
	add	rdi,	rax

	; przygotuj ciąg do wyświetlenia
	movzx	rcx,	byte [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_HEADER.length]
	add	rsi,	LIBRARY_BOSU_STRUCTURE_ELEMENT_HEADER.string

	;-----------------------------------------------------------------------
	; wyświetl ciąg
	mov	ebx,	LIBRARY_BOSU_ELEMENT_HEADER_FOREGROUND_color
	call	library_bosu_string

	; przywróć oryginalne rejestry
	pop	rdi
	pop	r13
	pop	r12
	pop	r11
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedry
	ret

;===============================================================================
; wejście:
;	ebx - kolor czcionki
;	rcx - rozmiar ciągu w znakach
;	rsi - wskaźnik do ciągu
;	rdi - wskaźnik do przestrzeni elementu
;	r8 - szerokość przestrzeni okna w pikselach
;	r9 - wysokość przestrzeni okna w pikselach
;	r10 - scanline okna w Bajtach
;	r11 - szerokość przestrzeni elementu w pikselach
;	r12 - wysokość przestrzeni elementu w pikselach
;	r13 - scanline elementu w Bajtach
library_bosu_string:
	; zachowaj oryginalne rejestry
	push	rax
	push	rdi
	push	r9
	push	r13

	; wyczyść akumulator
	xor	rax,	rax

.loop:
	; pobierz znak z ciągu
	lodsb

	; wyświetl znak
	call	library_bosu_char

	; przesuń wskaźnik na następną pozycję w przestrzeni elementu
	add	rdi,	LIBRARY_BOSU_FONT_WIDTH_pixel << KERNEL_VIDEO_DEPTH_shift

	; koniec ciągu?
	dec	rcx
	jz	.end	; nie, wyświetl następny

	; koniec przestrzeni elementu?
	sub	r11,	LIBRARY_BOSU_FONT_WIDTH_pixel
	jns	.loop	; nie, zmieścimy jeszcze jeden znak

.end:
	; przywróć oryginalne rejestry
	pop	r13
	pop	r9
	pop	rdi
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	rax - kod ASCII znaku do wyświetlenia
;	rbx - kolor czcionki
;	rdi - wskaźnik do początku przestrzeni elementu
;	r8 - szerokość przestrzeni okna w pikselach
;	r9 - wysokość przestrzeni okna w pikselach
;	r10 - scanline okna w Bajtach
;	r11 - szerokość przestrzeni elementu w pikselach
;	r12 - wysokość przestrzeni elementu w pikselach
;	r13 - scanline elementu w Bajtach
library_bosu_char:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	r12
	push	r11

	; ustaw wskaźnik na macierz czcionki
	mov	rsi,	library_bosu_font_matrix

	; koryguj kod ASCII o prdesunięcie w macierzy czcionki
	sub	al,	byte [library_bosu_font_offset]
	js	.end	; przekręcono licznik, znak niedrukowalny - pomiń

	; ustaw wskaźnik na matrycę znaku
	mul	qword [library_bosu_font_height_pixel]
	add	rsi,	rax

	; ustaw kolor kolejnych pikseli ciągu
	mov	eax,	ebx

	; wysokość matrycy w pikselach
	mov	rdx,	qword [library_bosu_font_height_pixel]

.next:
	; przywróć pozostałą szerokość obiektu
	mov	r11,	qword [rsp]

	; szerokość matrycy
	mov	rcx,	qword [library_bosu_font_width_pixel]
	dec	rcx	; liczymy od zera

.loop:
	; zmienić kolor piksela?
	bt	word [rsi],	cx
	jnc	.omit	; nie

	; zmień kolor
	stosd

	; kontynuuj
	jmp	.continue

.omit:
	; przesuń wskaźnik na następny piksel
	add	rdi,	KERNEL_VIDEO_DEPTH_byte

.continue:
	; koniec przestrzeni elementu?
	dec	r11
	jnz	.continue_pixels	; nie

	; tak, koryguj pozostałą ilość pikseli w wierszu matrycy
	shl	rcx,	KERNEL_VIDEO_DEPTH_shift
	add	rdi,	rcx

	; następny wiersz matrycy znaku
	jmp	.end_of_line

.continue_pixels:
	; następny piksel z wiersza matrycy?
	dec	rcx
	jns	.loop	; tak

.end_of_line:
	; przesuń wskaźnik na następny wiersz matrycy w przestrzeni elementu
	sub	rdi,	LIBRARY_BOSU_FONT_WIDTH_pixel << KERNEL_VIDEO_DEPTH_shift
	add	rdi,	r10

	; przesuń wskaźnik na następny wiersz matrycy
	inc	rsi

	; przetworzyliśmy wszystkie wiersze przestrzeni elementu?
	dec	r12
	jz	.end	; tak

.line_invisible:
	; przetworzono całą matrycę znaku?
	dec	rdx
	jnz	.next	; nie

.end:
	; przywróć oryginalne rejestry
	pop	r11
	pop	r12
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	rdi - wskaźnik do struktury okna
;	rsi - wskaźnik do elementu
;	r8 - szerokość okna w pikselach
;	r9 - wysokość okna w pikselach
;	r10 - scanline okna w Bajtach
library_bosu_element_button:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	rdi
	push	r8
	push	r9
	push	r10
	push	r11
	push	r12
	push	r13

	; zachowaj wskaźnik do właściwości okna
	mov	rbx,	rdi

	; wylicz szerokość, wysokość i scanline elementu
	mov	r11,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_BUTTON.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
	mov	r12,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_BUTTON.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.height]
	mov	r13,	r11
	shl	r13,	KERNEL_VIDEO_DEPTH_shift

	; pozycja bezwzględna elementu na osi Y
	xor	eax,	eax

	; okno posiada nagłówek?
	test	qword [rbx + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags],	LIBRARY_BOSU_WINDOW_FLAG_header
	jz	.no_header	; nie

	; koryguj pozycje na osi Y o nagówek
	mov	rax,	LIBRARY_BOSU_ELEMENT_HEADER_HEIGHT_pixel

.no_header:
	; wylicz pozycję bezwzględną elementu w przestrzeni danych okna
	add	rax,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_BUTTON.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.y]
	mul	r13	; * scanline
	mov	rdi,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_BUTTON.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.x]
	shl	rdi,	KERNEL_VIDEO_DEPTH_shift
	add	rdi,	rax
	add	rdi,	qword [rbx + LIBRARY_BOSU_STRUCTURE_WINDOW.address]

	; wyczyść przestrzeń elementu domyślnym kolorem tła
	mov	eax,	LIBRARY_BOSU_ELEMENT_BUTTON_BACKGROUND_color
	call	library_bosu_element_drain

	; rozmiar ciągu do wypisania w etykiecie
	movzx	rcx,	byte [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.length]

	; wyświetl ciąg o domyślnym kolorze czcionki
	mov	ebx,	LIBRARY_BOSU_ELEMENT_BUTTON_FOREGROUND_color
	movzx	ecx,	byte [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_BUTTON.length]
	add	rsi,	LIBRARY_BOSU_STRUCTURE_ELEMENT_BUTTON.string
	call	library_bosu_string

	; przywróć oryginalne rejestry
	pop	r13
	pop	r12
	pop	r11
	pop	r10
	pop	r9
	pop	r8
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedry
	ret

;===============================================================================
; wejście:
;	eax - kolor tła interfejsu
;	rdi - wskaźnik do przestrzeni elementu w pikselach
;	r10 - scanline okna w Bajtach
;	r11 - szerokość elementu w pikselach
;	r12 - wysokość elementu w pikselach
;	r13 - scanline elmentu w Bajtach
library_bosu_element_drain:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rdx
	push	rdi
	push	r12

.loop:
	; zmień kolor pikseli na całej szerokości przestrzeni elementu
	mov	rcx,	r11
	rep	stosd

	; przesuń wskaźnik na następną linię pikseli w przestrzeni elementu
	sub	rdi,	r13	; scanline elementu
	add	rdi,	r10	; scanline okna

	; koniec przestrzeni elementu?
	dec	r12
	jnz	.loop	; nie, kontynuuj

	; przywróć oryginalne rejestry
	pop	r12
	pop	rdi
	pop	rdx
	pop	rcx

	; powrót z procedury
	ret
