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
; wyjście:
;	rsi - wskaźnik zarejestrowanego okna
library_bosu:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdi
	push	rsi

	; pobierz szerokość i wysokość okna
	mov	r8,	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
	mov	r9,	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.height]

	; oblicz scanline okna w Bajtach
	mov	r10,	r8
	shl	r10,	KERNEL_VIDEO_DEPTH_shift
	; zachowaj
	mov	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.scanline],	r10

	; oblicz rozmiar przestrzeni danych okna w Bajtach
	mov	rax,	r10
	mul	r9
	; zachowaj
	mov	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.size],	rax

	; przydziel przestrzeń pod dane okna
	mov	rcx,	rax
	call	library_page_from_size
	call	kernel_memory_alloc
	; zachowaj wskaźnik do przestrzeni danych okna
	mov	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.address],	rdi

	; wypełnij przestrzeń okna domyślnym kolorem tła
	mov	eax,	LIBRARY_BOSU_WINDOW_BACKGROUND_color
	mov	rcx,	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.size]
	shr	rcx,	KERNEL_VIDEO_DEPTH_shift
	rep	stosd

	; oznaczyć krawędzie okna?
	test	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags],	LIBRARY_BOSU_WINDOW_FLAG_border
	jz	.no_border	; nie

	; oznacz krawędź okna
	mov	rdi,	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.address]
	call	library_bosu_border

.no_border:
	; przetwórz wszystkie elementy wchodzące w skład okna
	call	library_bosu_elements

	; zarejestruj okno w menedżerze okien
	call	service_desu_object_insert

	; zwróć wskaźnik zarejestrowanego okna
	mov	qword [rsp],	rsi

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

	; element typu "łańcuch"?
	cmp	dword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT.type],	LIBRARY_BOSU_ELEMENT_TYPE_chain
	je	.next	; tak, pomiń

	; pozycja elementu na osi X
	mov	rax,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.x]
	add	rax,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]

	; dalej niż poprzedni?
	cmp	rax,	r8
	jbe	.y	; nie

	; zachowaj informację
	mov	r8,	rax

.y:
	; pozycja elementu na osi Y
	mov	rax,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.y]
	add	rax,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.height]

	; dalej niż poprzedni?
	cmp	rax,	r9
	jbe	.next	; nie

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
	push	r11
	push	r12
	push	r13
	push	r15
	push	rdi
	push	rsi

	; zachowaj wskaźnik do struktury okna
	mov	rbx,	rdi

	; domyślna szerokość elementu nagłówka
	mov	r11,	r8

	; korygowac o krawędź okna?
	test	qword [rbx + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags],	LIBRARY_BOSU_WINDOW_FLAG_border
	jz	.no_border	; nie

	; zmniejsz szerokość elementu o obrys
	sub	r11,	LIBRARY_BOSU_BORDER_SIZE_pixel << STATIC_MULTIPLE_BY_2_shift

.no_border:
	; ustaw wysokość i scanline elementu
	mov	r12,	LIBRARY_BOSU_ELEMENT_HEADER_HEIGHT_pixel
	mov	r13,	r11
	shl	r13,	KERNEL_VIDEO_DEPTH_shift

	; pobierz wskaźnik do przestrzeni danych okna
	mov	rdi,	qword [rbx + LIBRARY_BOSU_STRUCTURE_WINDOW.address]
	push	rdi	; zachowaj

	; wylicz bezwzględny adres elementu w przestrzeni okna

	; pozycja na osi Y
	mov	rax,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_HEADER.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.y]
	mul	r10	; * scanline
	add	rdi,	rax
	; pozycja na osi X
	mov	rax,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_HEADER.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.x]
	shl	rax,	KERNEL_VIDEO_DEPTH_shift
	add	rdi,	rax

	; wyczyść przestrzeń elementu danym kolorem
	mov	eax,	LIBRARY_BOSU_ELEMENT_HEADER_BACKGROUND_color
	call	library_bosu_element_drain

	; wyświetl etykietę nagłówka
	mov	ebx,	LIBRARY_BOSU_ELEMENT_HEADER_FOREGROUND_color
	movzx	rcx,	byte [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_HEADER.length]
	add	rsi,	LIBRARY_BOSU_STRUCTURE_ELEMENT_HEADER.string
	add	rdi,	LIBRARY_BOSU_ELEMENT_HEADER_PADDING_LEFT_pixel << KERNEL_VIDEO_DEPTH_shift
	call	library_bosu_string

	; oblicz pozycję względną pod nagłówkiem
	mov	rsi,	qword [rsp + STATIC_QWORD_SIZE_byte]
	mov	rax,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_HEADER.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.y]
	add	rax,	LIBRARY_BOSU_ELEMENT_HEADER_HEIGHT_pixel - LIBRARY_BOSU_ELEMENT_HEADER_FOOT_pixel
	mul	r10

	; ustaw wskaźnik na stopkę nagłówka w przestrzeni danych okna
	pop	rdi	; przywróć
	add	rdi,	rax

	; rysuj krawędź dolną krawędź nagłówka
	mov	rax,	(LIBRARY_BOSU_BORDER_DEFAULT_color >> STATIC_MOVE_EAX_TO_HIGH_shift) | (LIBRARY_BOSU_BORDER_DEFAULT_color << STATIC_MOVE_EAX_TO_HIGH_shift)
	mov	rcx,	r8
	rep	stosd

	; rysuj górną krawędź przestrzeni okna
	rol	rax,	STATIC_REPLACE_EAX_WITH_HIGH_shift
	mov	rcx,	r8
	rep	stosd

	; przywróć oryginalne rejestry
	pop	rsi
	pop	rdi
	pop	r15
	pop	r13
	pop	r12
	pop	r11
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedry
	ret

;===============================================================================
; wejscie:
;	r8 - szerokość okna w pikselach
;	r9 - wysokość okna w pikselach
;	r10 - scanline okna w Bajtach
;	rdi - wskaźnik do przestrzeni danych okna
library_bosu_border:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdi
	push	r9
	push	r8

	; ustaw kolorystykę krawędzi
	mov	rax,	LIBRARY_BOSU_BORDER_DEFAULT_color

	; szerokość okna w pikselach
	mov	rcx,	r8

	; rysuj górną krawędź
	rep	stosd

	; zamień kolory krawędzi miejscami
	rol	rax,	STATIC_REPLACE_EAX_WITH_HIGH_shift

	; scanline okna bez krawędzi
	sub	r8,	LIBRARY_BOSU_BORDER_SIZE_pixel << STATIC_MULTIPLE_BY_2_shift
	shl	r8,	KERNEL_VIDEO_DEPTH_shift

	; wysokość okna bez krawędzi
	sub	r9,	LIBRARY_BOSU_BORDER_SIZE_pixel << STATIC_MULTIPLE_BY_2_shift

.loop:
	; rysuj lewą krawędź
	rol	rax,	STATIC_REPLACE_EAX_WITH_HIGH_shift
	stosd

	; przesuń wskaźnik na prawą krawędź
	add	rdi,	r8

	; rysuj prawą krawędź
	rol	rax,	STATIC_REPLACE_EAX_WITH_HIGH_shift
	stosd

	; kontynuować?
	dec	r9
	jnz	.loop	; tak

	; szerokość okna w pikselach
	mov	rcx,	qword [rsp]

	; rysuj dolną krawędź
	rep	stosd

	; przywróć oryginalne rejestry
	pop	r8
	pop	r9
	pop	rdi
	pop	rcx
	pop	rax

	; powrót z procedury
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

	; wyświetl cień za pikselem
	mov	dword [rdi],	STATIC_EMPTY

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

	; pobierz szerokość, wysokość i scanline okna
	mov	r8,	qword [rdi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
	mov	r9,	qword [rdi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.height]
	mov	r10,	qword [rdi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.scanline]

	; wylicz szerokość, wysokość i scanline elementu
	mov	r11,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_BUTTON.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
	mov	r12,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_BUTTON.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.height]
	mov	r13,	r11
	shl	r13,	KERNEL_VIDEO_DEPTH_shift

	; pozycja bezwzględna elementu na osi Y
	xor	eax,	eax

	; okno posiada nagłówek?
	test	qword [rdi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags],	LIBRARY_BOSU_WINDOW_FLAG_header
	jz	.no_header	; nie

	; koryguj pozycje na osi Y o nagówek
	mov	rax,	LIBRARY_BOSU_ELEMENT_HEADER_HEIGHT_pixel

.no_header:
	; zachowaj wskaźnik do właściwości okna
	mov	rbx,	rdi

	; wylicz pozycję bezwzględną elementu w przestrzeni danych okna
	add	rax,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_BUTTON.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.y]
	mul	r13	; * scanline
	mov	rdi,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_BUTTON.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.x]
	shl	rdi,	KERNEL_VIDEO_DEPTH_shift
	add	rdi,	rax
	add	rdi,	qword [rbx + LIBRARY_BOSU_STRUCTURE_WINDOW.address]

	; wyczyść przestrzeń elementu domyślnym kolorem
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

;===============================================================================
; wejście:
;	rsi - wskaźnik do elementu "łańcuch"
library_bosu_element_chain:
	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	rdi - wskaźnik do struktury okna
;	rsi - wskaźnik do elementu
library_bosu_element_label:
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

	; pobierz szerokość, wysokość i scanline okna
	mov	r8,	qword [rdi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
	mov	r9,	qword [rdi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.height]
	mov	r10,	qword [rdi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.scanline]

	; wylicz szerokość, wysokość i scanline elementu
	mov	r11,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
	mov	r12,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.height]
	mov	r13,	r11
	shl	r13,	KERNEL_VIDEO_DEPTH_shift

	; zachowaj wskaźnik do właściwości okna
	mov	rbx,	rdi

	; wylicz pozycję bezwzględną elementu w przestrzeni danych okna
	mov	rax,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.y]
	mul	r10	; * scanline
	mov	rdi,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.x]
	shl	rdi,	KERNEL_VIDEO_DEPTH_shift
	add	rdi,	rax
	add	rdi,	qword [rbx + LIBRARY_BOSU_STRUCTURE_WINDOW.address]

	; wyczyść przestrzeń elementu domyślnym kolorem tła
	mov	eax,	LIBRARY_BOSU_ELEMENT_LABEL_BACKGROUND_color
	call	library_bosu_element_drain

	; rozmiar ciągu do wypisania w etykiecie
	movzx	rcx,	byte [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.length]

	; wyświetl ciąg o domyślnym kolorze czcionki
	mov	ebx,	LIBRARY_BOSU_ELEMENT_LABEL_FOREGROUND_color
	movzx	ecx,	byte [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.length]
	add	rsi,	LIBRARY_BOSU_STRUCTURE_ELEMENT_LABEL.string
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
