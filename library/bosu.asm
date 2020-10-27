;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

	;-----------------------------------------------------------------------
	; stałe, zmienne, struktury, obiekty
	;-----------------------------------------------------------------------
	%include	"library/bosu/config.asm"
	%include	"library/bosu/data.asm"
	;-----------------------------------------------------------------------

;===============================================================================
; wejście:
;	rsi - wskaźnik do struktury okna
; wyjście:
;	rcx - identyfikator okna
library_bosu:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rdi
	push	rsi
	push	rcx

	; skorygować położenie elementów względem krawędzi okna?
	test	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags],	LIBRARY_BOSU_WINDOW_FLAG_border
	jz	.no_border	; nie

	; koryguj szerokość i wysokość okna o grubość krawędzi
	add	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.width],	LIBRARY_BOSU_WINDOW_BORDER_THICKNESS_pixel << STATIC_MULTIPLE_BY_2_shift
	add	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.height],	LIBRARY_BOSU_WINDOW_BORDER_THICKNESS_pixel << STATIC_MULTIPLE_BY_2_shift

	; koryguj wszystkie elementy okna
	call	library_bosu_border_correction

.no_border:
	; pobierz szerokość i wysokość okna
	mov	r8,	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
	mov	r9,	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.height]

	; oblicz scanline okna w Bajtach
	mov	r10,	r8
	shl	r10,	KERNEL_VIDEO_DEPTH_shift
	mov	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.scanline_byte],	r10	; zachowaj

	; oblicz rozmiar przestrzeni danych okna w Bajtach
	mov	rax,	r10
	mul	r9
	mov	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.size],	rax	; zachowaj

	; zarejestrować okno w menedżerze okien?
	test	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags],	LIBRARY_BOSU_WINDOW_FLAG_unregistered
	jnz	.unregistered	; nie

	; utwórz okno
	mov	al,	KERNEL_WM_WINDOW_create
	int	KERNEL_WM_IRQ
	jc	.end	; brak przestrzeni pamięci

	; zwróć wskaźnik/identyfikator zarejestrowanego okna
	mov	qword [rsp],	rcx

.unregistered:
	; wypełnij przestrzeń okna domyślnym kolorem tła
	mov	eax,	LIBRARY_BOSU_WINDOW_BACKGROUND_color
	mov	rcx,	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.size]
	shr	rcx,	KERNEL_VIDEO_DEPTH_shift
	mov	rdi,	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.address]
	rep	stosd

	; rysować krawędź okna?
	test	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags],	LIBRARY_BOSU_WINDOW_FLAG_border
	jz	.no_draw_border	; nie

	; zachowaj oryginalne rejestry
	push	r8
	push	r9

	; kolorystyka
	mov	rax,	LIBRARY_BOSU_WINDOW_BORDER_color

	; górna krawędź
	mov	rcx,	r8
	mov	rdi,	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.address]
	rep	stosd

	; przesunięcie między krawędziami oraz wysokość
	sub	r8,	(LIBRARY_BOSU_WINDOW_BORDER_THICKNESS_pixel << STATIC_MULTIPLE_BY_2_shift)
	shl	r8,	KERNEL_VIDEO_DEPTH_shift
	sub	r9,	LIBRARY_BOSU_WINDOW_BORDER_THICKNESS_pixel << STATIC_MULTIPLE_BY_2_shift

.draw_border:
	; lewa krawędź
	stosd

	; zmień kolor krawędzi
	rol	rax,	STATIC_REPLACE_EAX_WITH_HIGH_shift

	; przesuń wskaźnik na prawą krawędź
	add	rdi,	r8

	; prawa krawędź
	stosd

	; zmień kolor krawędzi
	rol	rax,	STATIC_REPLACE_EAX_WITH_HIGH_shift

	; koniec rysowania lewej i prawej krawędzi?
	dec	r9
	jnz	.draw_border	; nie

	; zmień kolor krawędzi
	rol	rax,	STATIC_REPLACE_EAX_WITH_HIGH_shift

	; dolna krawędź
	mov	rcx,	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
	rep	stosd

	; przywróć oryginalne rejestry
	pop	r9
	pop	r8

.no_draw_border:
	; przetwórz wszystkie elementy wchodzące w skład okna
	call	library_bosu_elements

.end:
	; przywróć oryginalne rejestry
	pop	rcx
	pop	rsi
	pop	rdi
	pop	rbx
	pop	rax

	; powrót z liblioteki
	ret

;===============================================================================
; wejście:
;	rsi - wskaźnik do specyfikacji okna
library_bosu_border_correction:
	; zachowaj oryginalne rejestry
	push	rax
	push	rsi

	; przesuń wskaźnik na początek listy elementów okna
	add	rsi,	LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.SIZE

.loop:
	; koniec elementów do korekcji?
	mov	eax,	dword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT.type]
	cmp	eax,	STATIC_EMPTY
	je	.ready	; tak

	; element typu "button close"?
	cmp	eax,	LIBRARY_BOSU_ELEMENT_TYPE_button_close
	je	.next	; tak, pomiń

	; element typu "button minimize"?
	cmp	eax,	LIBRARY_BOSU_ELEMENT_TYPE_button_minimize
	je	.next	; tak, pomiń

	; element typu "button maximize"?
	cmp	eax,	LIBRARY_BOSU_ELEMENT_TYPE_button_maximize
	je	.next	; tak, pomiń

	; element typu "chain"?
	cmp	eax,	LIBRARY_BOSU_ELEMENT_TYPE_chain
	je	.chain	; tak

	; koryguj pozycję elementu o rozmiar krawędzi
	add	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.x],	LIBRARY_BOSU_WINDOW_BORDER_THICKNESS_pixel
	add	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.y],	LIBRARY_BOSU_WINDOW_BORDER_THICKNESS_pixel

.next:
	; przesuń wskaźnik na następny element
	add	rsi,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT.size]

	; kontyuuj
	jmp	.loop

.chain:
	; "łańcuch" jest pusty?
	cmp	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_CHAIN.size],	STATIC_EMPTY
	je	.next	; tak, pomiń

	; zachowaj wskaźnik aktualnego elementu
	push	rsi

	; pobierz adres "łańcucha"
	mov	rsi,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_CHAIN.address]
	call	library_bosu_border_correction	; koryguj wszystkie elementy łańcucha

	; przywróć wskaźnik aktualnego elementu
	pop	rsi

	; przesuń wskaźnik na następny element
	add	rsi,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT.size]

	; kontynuuj
	jmp	.loop

.ready:
	; przywróć oryginalne rejestry
	pop	rsi
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	rsi - wskaźnik do właściwości okna
library_bosu_close:
	; zachowaj oryginalne rejestry
	push	rax

	; zamknij okno
	mov	ax,	KERNEL_WM_WINDOW_close
	int	KERNEL_WM_IRQ

	; przywróć oryginalne rejestry
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	rsi - wskaźnik do właściwości okna
;	r8 - szerokość okna w pikselach
;	r10 - scanline okna w Bajtach
library_bosu_element_button_close:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rsi
	push	rdi

	; zachowaj wskaźnik do struktury okna
	mov	rsi,	rdi

	; ustaw wskaźnik na pozycję elementu
	xor	rdi,	rdi

	; pozycjq na osi X
	mov	rax,	r8
	sub	rax,	LIBRARY_BOSU_ELEMENT_BUTTON_CLOSE_width

	; okno posiada krawędzie?
	test	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags],	LIBRARY_BOSU_WINDOW_FLAG_border
	jz	.no_border	; nie

	; koryguj pozycję na osi X
	sub	rax,	LIBRARY_BOSU_WINDOW_BORDER_THICKNESS_pixel

	; koryguj pozycję na osi Y
	add	rdi,	r10

.no_border:
	; docelowa pozycja pierwszej kreski elementu w przestrzeni danych okna
	add	rax,	0x05	; 5 pikseli w prawo na osi X
	shl	rax,	KERNEL_VIDEO_DEPTH_shift
	add	rdi,	rax
	mov	rax,	r10				; oraz 5 pikseli w dół na osi Y
	shl	rax,	STATIC_MULTIPLE_BY_4_shift	; |
	add	rax,	r10				; |
	add	rdi,	rax				; /
	add	rdi,	qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.address]

	; kolor i rozmiar pierwszej kreski
	mov	eax,	LIBRARY_BOSU_ELEMENT_BUTTON_FOREGROUND_color
	mov	ecx,	0x08

.left:
	; rysuj
	stosd

	; przesuń wskaźnik na następną pozycję
	add	rdi,	r10

	; koniec pierwszej kreski?
	dec	rcx
	jnz	.left	; nie

	; pozycja prawej kreski na osi X
	sub	rdi,	0x08 << KERNEL_VIDEO_DEPTH_shift

	; rozmiar drugiej kreski
	mov	ecx,	0x08

.right:
	; przesuń wskaźnik na następną pozycję
	sub	rdi,	r10

	; rysuj
	stosd

	; koniec drugiej kreski?
	dec	rcx
	jnz	.right	; nie

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	rsi - wskaźnik do właściwości okna
library_bosu_element_button_minimize:
	xchg	bx,bx

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	rsi - wskaźnik do właściwości okna
library_bosu_element_button_maximize:
	xchg	bx,bx

	; powrót z procedury
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
	push	rbx
	push	rcx
	push	rsi

	; lista skoków do procedur
	mov	rbx,	library_bosu_element_entry

	; zachowaj wskaźnik do struktury okna
	mov	rdi,	rsi

	; przesuń wskaźnik na początek listy elementów okna
	add	rsi,	LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.SIZE

.loop:
	; koniec elementów?
	mov	eax,	dword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT.type]
	cmp	eax,	STATIC_EMPTY
	je	.ready	; tak

	; element typu "draw"?
	cmp	eax,	LIBRARY_BOSU_ELEMENT_TYPE_draw
	je	.leave	; tak, brak obłsugi

	; element typu "chain"?
	cmp	eax,	LIBRARY_BOSU_ELEMENT_TYPE_chain
	jne	.other	; nie

	; "łańcuch" jest pusty?
	cmp	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_CHAIN.size],	STATIC_EMPTY
	je	.empty	; tak, pomiń

	; zachowaj wskaźnik aktualnego elementu
	push	rsi

	; pobierz adres "łańcucha"
	mov	rsi,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_CHAIN.address]
	call	library_bosu_elements	; przetwórz wszystkie elementy łańcucha

	; przywróć wskaźnik aktualnego elementu
	pop	rsi

.empty:
	; przesuń wskaźnik na następny element
	add	rsi,	LIBRARY_BOSU_STRUCTURE_ELEMENT_CHAIN.SIZE

	; kontynuuj
	jmp	.loop

.other:
	; przejdź do procedury obsługi elementu
	call	qword [rbx + rax * STATIC_QWORD_SIZE_byte]

.leave:
	; przesuń wskaźnik na następny element
	add	rsi,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT.size]

	; kontyuuj
	jmp	.loop

.ready:
	; przywróć oryginalny rejestr
	pop	rsi
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	rsi - wskaźnik do właściwości elementu
;	rdi - wskaźnik do struktury okna
library_bosu_element_taskbar:
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
	mov	r10,	qword [rdi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.scanline_byte]

	; wylicz szerokość, wysokość i scanline elementu
	mov	r11,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
	mov	r12,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.height]
	mov	r13,	r11
	shl	r13,	KERNEL_VIDEO_DEPTH_shift

	; zachowaj wskaźnik do właściwości okna
	mov	rbx,	rdi

	; wylicz pozycję bezwzględną elementu w przestrzeni danych okna
	mov	rax,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.y]
	mul	r13	; * scanline
	mov	rdi,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.x]
	shl	rdi,	KERNEL_VIDEO_DEPTH_shift
	add	rdi,	rax
	add	rdi,	qword [rbx + LIBRARY_BOSU_STRUCTURE_WINDOW.address]

	; wyczyść przestrzeń elementu
	mov	eax,	dword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.background]
	call	library_bosu_element_drain

	; zachowaj wskaźnik początku przestrzeni elementu
	push	rdi

	; wylicz pozycję bezwzględną linii w przestrzeni elementu
	mov	rax,	r12
	dec	rax	; ostatni wiersz pikseli w przestrzeni elementu
	mul	r10	; * scanline

	; szerokość linii
	mov	rcx,	r11

	; wskaźnik bezpośredni do rysowanej linii
	add	rdi,	rax

	; rysuj dolną krawędź elementu
	mov	eax,	0x00ff0000
	rep	stosd

.under_line:

	; przywróć wksaźnik początku przestrzeni elementu
	pop	rdi

	; rozmiar ciągu do wypisania w etykiecie
	movzx	rcx,	byte [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.length]

	; wycentruj tekst w pionie
	mov	rax,	r12
	sub	rax,	LIBRARY_FONT_HEIGHT_pixel
	shr	rax,	STATIC_DIVIDE_BY_2_shift
	mul	r10
	add	rdi,	rax

	; wyświetl ciąg o domyślnym kolorze czcionki
	mov	ebx,	LIBRARY_BOSU_ELEMENT_TASKBAR_FOREGROUND_color
	movzx	ecx,	byte [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.length]
	add	rsi,	LIBRARY_BOSU_STRUCTURE_ELEMENT_TASKBAR.string
	add	rdi,	LIBRARY_BOSU_ELEMENT_TASKBAR_PADDING_LEFT_pixel << KERNEL_VIDEO_DEPTH_shift
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
;	rsi - wskaźnik do elementu "łańcuch"
;	rdi - wskaźnik do struktury okna
library_bosu_element_chain:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rsi
	push	r8
	push	r9
	push	r10

	; pobierz szerokość, wysokość i scanline okna
	mov	r8,	qword [rdi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
	mov	r9,	qword [rdi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.height]
	mov	r10,	qword [rdi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.scanline_byte]

	; lista skoków do procedur
	mov	rbx,	library_bosu_element_entry

	; przetwórz wszystkie elementy łańcucha
	mov	rsi,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_CHAIN.address]

.loop:
	; koniec elementów?
	mov	eax,	dword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT.type]
	cmp	eax,	STATIC_EMPTY
	je	.ready	; tak

	; element typu "draw"?
	cmp	eax,	LIBRARY_BOSU_ELEMENT_TYPE_draw
	je	.leave	; tak, brak obłsugi

	; przejdź do procedury obsługi elementu
	call	qword [rbx + rax * STATIC_QWORD_SIZE_byte]

.leave:
	; przesuń wskaźnik na następny element
	add	rsi,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT.size]

	; kontyuuj
	jmp	.loop

.ready:
	; przywróć oryginalne rejestry
	pop	r10
	pop	r9
	pop	r8
	pop	rsi
	pop	rbx
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	rsi - wskaźnik do elementu
;	rdi - wskaźnik do struktury okna
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

	; okno posiada krawędzie?
	test	qword [rdi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags],	LIBRARY_BOSU_WINDOW_FLAG_border
	jz	.no_border	; nie

	; koryguj szerokość elementu
	sub	r11,	LIBRARY_BOSU_WINDOW_BORDER_THICKNESS_pixel << STATIC_MULTIPLE_BY_2_shift

.no_border:
	; ustaw wysokość i scanline elementu
	mov	r12,	LIBRARY_BOSU_ELEMENT_HEADER_HEIGHT_pixel
	mov	r13,	r11
	shl	r13,	KERNEL_VIDEO_DEPTH_shift

	; pobierz wskaźnik do przestrzeni danych okna
	mov	rdi,	qword [rbx + LIBRARY_BOSU_STRUCTURE_WINDOW.address]

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

	; wycentruj tekst w pionie
	mov	rax,	r12
	sub	rax,	LIBRARY_FONT_HEIGHT_pixel
	shr	rax,	STATIC_DIVIDE_BY_2_shift
	mul	r10
	add	rdi,	rax

	; wyświetl etykietę nagłówka
	mov	ebx,	LIBRARY_BOSU_ELEMENT_HEADER_FOREGROUND_color
	movzx	rcx,	byte [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_HEADER.length]
	add	rsi,	LIBRARY_BOSU_STRUCTURE_ELEMENT_HEADER.string
	add	rdi,	LIBRARY_BOSU_ELEMENT_HEADER_PADDING_LEFT_pixel << KERNEL_VIDEO_DEPTH_shift
	call	library_bosu_string

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
	add	rdi,	LIBRARY_FONT_WIDTH_pixel << KERNEL_VIDEO_DEPTH_shift

	; koniec ciągu?
	dec	rcx
	jz	.end	; nie, wyświetl następny

	; koniec przestrzeni elementu?
	sub	r11,	LIBRARY_FONT_WIDTH_pixel
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
	mov	rsi,	library_font_matrix

	; koryguj kod ASCII o przesunięcie w macierzy czcionki
	sub	al,	LIBRARY_FONT_MATRIX_offset
	js	.end	; przekręcono licznik, znak niedrukowalny - pomiń

	; ustaw wskaźnik na matrycę znaku
	mul	qword [library_font_height_pixel]
	add	rsi,	rax

	; ustaw kolor kolejnych pikseli ciągu
	mov	eax,	ebx

	; wysokość matrycy w pikselach
	mov	rdx,	qword [library_font_height_pixel]

.next:
	; przywróć pozostałą szerokość obiektu
	mov	r11,	qword [rsp]

	; szerokość matrycy
	mov	rcx,	qword [library_font_width_pixel]
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
	sub	rdi,	LIBRARY_FONT_WIDTH_pixel << KERNEL_VIDEO_DEPTH_shift
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
;	rsi - wskaźnik do elementu
;	rdi - wskaźnik do struktury okna
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
	mov	r10,	qword [rdi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.scanline_byte]

	; wylicz szerokość, wysokość i scanline elementu
	mov	r11,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_BUTTON.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
	mov	r12,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_BUTTON.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.height]
	mov	r13,	r11
	shl	r13,	KERNEL_VIDEO_DEPTH_shift

	; zachowaj wskaźnik do właściwości okna
	mov	rbx,	rdi

	; wylicz pozycję bezwzględną elementu w przestrzeni danych okna
	mov	rax,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_BUTTON.element + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.y]
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

	; wycentruj tekst w pionie
	mov	rax,	r12
	sub	rax,	LIBRARY_FONT_HEIGHT_pixel
	shr	rax,	STATIC_DIVIDE_BY_2_shift
	mul	r10
	add	rdi,	rax

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
;	rsi - wskaźnik do elementu
;	rdi - wskaźnik do struktury okna
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
	mov	r10,	qword [rdi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.scanline_byte]

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

	; wycentruj tekst w pionie
	mov	rax,	r12
	sub	rax,	LIBRARY_FONT_HEIGHT_pixel
	shr	rax,	STATIC_DIVIDE_BY_2_shift
	mul	r10
	add	rdi,	rax

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

;===============================================================================
; wejście:
;	rsi - wskaźnik do struktury okna
;	r8 - pozycja kursora na osi X
;	r9 - pozycja kursora na osi Y
; wyjście:
;	Flaga CF - jeśli nie znaleziono elementu na danej pozycji
;	rsi - wskaźnik do elementu okna
library_bosu_element:
	; zachowaj oryginalne rejestry
	push	rdi
	push	rsi

	; zachowaj wskaźnik do struktury okna
	mov	rdi,	rsi

	; przesuń wskaźnik na elementy okna
	add	rsi,	LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.SIZE

	; przeszukaj elementy
	call	library_bosu_element_subroutine
	jc	.end	; nie znaleziono

	; zwróć wskaźnik do elementu
	mov	qword [rsp],	rsi

.end:
	; przywróć oryginalne rejestry
	pop	rsi
	pop	rdi

	; powrót z procedury
	ret

;===============================================================================
library_bosu_element_subroutine:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	r8
	push	r9
	push	rsi

.loop:
	; sprawdzaj kolejno elementy okna

	; koniec listy elementów?
	cmp	dword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT.type],	STATIC_EMPTY
	je	.error	; tak

	; pobierz rozmiar elementu
	mov	rcx,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT.size]

	; element typu "łańcuch"?
	cmp	dword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT.type],	LIBRARY_BOSU_ELEMENT_TYPE_chain
	jne	.no_chain	; nie

	; zachowaj wskaźnik do elementu łańcucha
	push	rsi

	; sprawdź elementy wew. łańcucha
	mov	rsi,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT_CHAIN.address]
	call	library_bosu_element_subroutine
	jnc	.found	; znaleziono element w łańcuchu

	; przywróć wskaźnik do elementu łańcucha
	pop	rsi

	; brak elementu w łańcuchu, kontynuuj
	jmp	.next_from_chain

.found:
	; zwróć wskaźnik do elementu
	mov	qword [rsp + STATIC_QWORD_SIZE_byte],	rsi

	; przywróć wskaźnik do elementu łańcucha
	pop	rsi

	; koniec obsługi procedury
	jmp	.end

.no_chain:
	; zachowaj rozmiar elementu
	push	rcx

	; element typu: button close?
	cmp	dword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT.type],	LIBRARY_BOSU_ELEMENT_TYPE_button_close
	jne	.no_button_close	; nie

	; pozycja elementu na osi X
	mov	rax,	qword [rdi + LIBRARY_BOSU_STRUCTURE_WINDOW.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
	sub	rax,	LIBRARY_BOSU_ELEMENT_BUTTON_CLOSE_width

	; pozycja elementu na osi Y
	xor	ecx,	ecx

	; okno zawiera krawędzie?
	test	qword [rdi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags],	LIBRARY_BOSU_WINDOW_FLAG_border
	jz	.no_button_close_border	; nie

	; koryguj pozycję na osi X,Y
	add	rax,	LIBRARY_BOSU_WINDOW_BORDER_THICKNESS_pixel
	add	rcx,	LIBRARY_BOSU_WINDOW_BORDER_THICKNESS_pixel

.no_button_close_border:
	; porównaj pozycję wskaźnika z lewą krawędzią elementu
	cmp	r8,	rax
	jl	.next	; poza przestrzenią elementu

	; porównaj pozycję wskaźnika z prawą krawędzią elementu
	add	rax,	LIBRARY_BOSU_ELEMENT_BUTTON_CLOSE_width
	cmp	r8,	rax
	jge	.next	; poza przestrzenią elementu

	; porównaj pozycję wskaźnika z górną krawędzią elementu
	cmp	r9,	rcx
	jl	.next	; poza przestrzenią elementu

	; porównaj pozycję wskaźnika z dolną krawędzią elementu
	add	rcx,	LIBRARY_BOSU_ELEMENT_BUTTON_CLOSE_width
	cmp	r9,	rcx
	jge	.next	; poza przestrzenią elementu

	; rozpoznano element: button close
	jmp	.element_recognized

.no_button_close:
	; porównaj pozycję wskaźnika z lewą krawędzią elementu
	mov	rax,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.x]
	cmp	r8,	rax
	jl	.next	; poza przestrzenią elementu

	; porównaj pozycję wskaźnika z prawą krawędzią elementu
	add	rax,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
	cmp	r8,	rax
	jge	.next	; poza przestrzenią elementu

	; porównaj pozycję wskaźnika z górną krawędzią elementu
	mov	rax,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.y]
	cmp	r9,	rax
	jl	.next	; poza przestrzenią elementu

	; porównaj pozycję wskaźnika z dolną krawędzią elementu
	add	rax,	qword [rsi + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.height]
	cmp	r9,	rax
	jge	.next	; poza przestrzenią elementu

.element_recognized:
	; usuń rozmiar elementu z stosu
	add	rsp,	STATIC_QWORD_SIZE_byte

	; flaga, sukces
	clc

	; zwróć wskaźnik do elementu
	mov	qword [rsp],	rsi

	; koniec procedury
	jmp	.end

.next:
	; przywróć rozmiar elementu
	pop	rcx

.next_from_chain:
	; przesuń wskaźnik na następny element z listy
	add	rsi,	rcx

	; kontynuuj
	jmp	.loop

.error:
	; flaga, błąd
	stc

.end:
	; przywróć oryginalne rejestry
	pop	rsi
	pop	r9
	pop	r8
	pop	rcx
	pop	rax

	; powrót z podprocedury
	ret
