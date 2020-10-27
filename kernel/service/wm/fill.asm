;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; wejście:
;	rsi - wskaźnik do obiektu wypełniającego
;	r8 - pozycja na osi X
;	r9 - pozycja na osi Y
;	r10 - szerokość strefy
;	r11 - wysokość strefy
kernel_wm_fill_insert_by_register:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rdi

	; maksymalna ilość miejsc na liście
	mov	ecx,	KERNEL_WM_FILL_LIST_limit

	; ustaw wskaźnik na listy
	mov	rdi,	qword [kernel_wm_fill_list_address]

.loop:
	; wolne miejsce?
	cmp	qword [rdi + KERNEL_WM_STRUCTURE_FILL.object],	STATIC_EMPTY
	jne	.next	; nie

	; dodaj do listy nową strefę
	mov	qword [rdi + KERNEL_WM_STRUCTURE_FILL.field + KERNEL_WM_STRUCTURE_FIELD.x],	r8
	mov	qword [rdi + KERNEL_WM_STRUCTURE_FILL.field + KERNEL_WM_STRUCTURE_FIELD.y],	r9
	mov	qword [rdi + KERNEL_WM_STRUCTURE_FILL.field + KERNEL_WM_STRUCTURE_FIELD.width],	r10
	mov	qword [rdi + KERNEL_WM_STRUCTURE_FILL.field + KERNEL_WM_STRUCTURE_FIELD.height],	r11

	; oraz jej obiekt zależny
	mov	qword [rdi + KERNEL_WM_STRUCTURE_FILL.object],	rsi

	; zrealizowano
	jmp	.end

.next:
	; przesuń wskaźnik na następny wpis
	add	rdi,	KERNEL_WM_STRUCTURE_FILL.SIZE

	; koniec wpisów
	dec	rcx
	jnz	.loop	; nie

	; błąd
	xchg	bx,bx
	jmp	$

.end:
	; przywróć oryginalne rejestry
	pop	rdi
	pop	rcx

	; powrót z procedury
	ret

	macro_debug	"kernel_wm_fill_insert_by_register"

;===============================================================================
; wejście:
;	rsi - wskaźnik do obiektu
kernel_wm_fill_insert_by_object:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdi
	push	rsi

	; maksymalna ilość miejsc na liście
	mov	ecx,	KERNEL_WM_FILL_LIST_limit

	; ustaw wskaźnik na listy
	mov	rdi,	qword [kernel_wm_fill_list_address]

.loop:
	; wolne miejsce?
	cmp	qword [rdi + KERNEL_WM_STRUCTURE_FILL.object],	STATIC_EMPTY
	jne	.next	; nie

	; wstaw właściwości wypełnienia
	movsq	; pozycja na osi X
	movsq	; pozycja na osi Y
	movsq	; szerokość
	movsq	; wysokość

	; oraz informacje o obiekcie zależnym
	mov	rax,	qword [rsp]
	mov	qword [rdi],	rax

	; zrealizowano
	jmp	.end

.next:
	; przesuń wskaźnik na następny wpis
	add	rdi,	KERNEL_WM_STRUCTURE_FILL.SIZE

	; koniec wpisów
	dec	rcx
	jnz	.loop	; nie

	; błąd
	xchg	bx,bx
	jmp	$

.end:
	; przywróć oryginalne rejestry
	pop	rsi
	pop	rdi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"kernel_wm_fill_insert_by_object"

;===============================================================================
kernel_wm_fill:
	; zachowaj oryginalne rejestry
	push	rax
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
	push	r14
	push	r15

	; maksymalna ilość miejsc na liście
	mov	ecx,	KERNEL_WM_FILL_LIST_limit

	; ustaw wskaźnik na listę wypełnień
	mov	rsi,	qword [kernel_wm_fill_list_address]

.loop:
	; pusta pozycja?
	cmp	qword [rsi + KERNEL_WM_STRUCTURE_FILL.object],	STATIC_EMPTY
	je	.next	; tak

	; zachowaj wskaźnik i rozmiar listy
	push	rcx
	push	rsi

	;-----------------------------------------------------------------------
	; pobierz właściwości wypełnienia
	;-----------------------------------------------------------------------
	mov	r8,	qword [rsi + KERNEL_WM_STRUCTURE_FILL.field + KERNEL_WM_STRUCTURE_FIELD.x]
	mov	r9,	qword [rsi + KERNEL_WM_STRUCTURE_FILL.field + KERNEL_WM_STRUCTURE_FIELD.y]
	mov	r10,	qword [rsi + KERNEL_WM_STRUCTURE_FILL.field + KERNEL_WM_STRUCTURE_FIELD.width]
	mov	r11,	qword [rsi + KERNEL_WM_STRUCTURE_FILL.field + KERNEL_WM_STRUCTURE_FIELD.height]

	; opisana strefa znajduje się na ujemnej osi X?
	bt	r8,	STATIC_QWORD_BIT_sign
	jnc	.x_positive	; nie

	; wytnij niewidoczny fragment
	not	r8
	inc	r8
	sub	r10,	r8

	; przesuń na początek osi X
	xor	r8,	r8

.x_positive:
	; opisana strefa znajduje się na ujemnej osi Y?
	bt	r9,	STATIC_QWORD_BIT_sign
	jnc	.y_positive	; nie

	; wytnij niewidoczny fragment
	not	r9
	inc	r9
	sub	r11,	r9

	; przesuń na początek osi Y
	xor	r9,	r9

.y_positive:
	; opisana strefa wykracza poza oś X?
	mov	rax,	r8
	add	rax,	r10
	cmp	rax,	qword [kernel_video_width_pixel]
	jb	.x_inside	; nie

	; ogranicz strefę do przestrzeni ekranu
	sub	rax,	qword [kernel_video_width_pixel]
	sub	r10,	rax

.x_inside:
	; opisana strefa wykracza poza oś Y?
	mov	rax,	r9
	add	rax,	r11
	cmp	rax,	qword [kernel_video_height_pixel]
	jb	.y_inside	; nie

	; ogranicz strefę do przestrzeni ekranu
	sub	rax,	qword [kernel_video_height_pixel]
	sub	r11,	rax

.y_inside:
	;-----------------------------------------------------------------------
	; wylicz zmienne do opracji kopiowania przestrzeni
	;-----------------------------------------------------------------------

	; pobierz wskaźnik do obiektu wypełniającego
	mov	rsi,	qword [rsi + KERNEL_WM_STRUCTURE_FILL.object]

	;-----------------------------------------------------------------------
	; scanlines
	; r12 - scanline wypelnienia w Bajtach
	mov	r12,	r10
	shl	r12,	KERNEL_VIDEO_DEPTH_shift
	; r13 - scanline obiektu w Bajtach
	mov	r13,	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.width]
	shl	r13,	KERNEL_VIDEO_DEPTH_shift
	; r14 - scanline bufora w Bajtach
	mov	r14,	qword [kernel_wm_object_framebuffer + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.width]
	shl	r14,	KERNEL_VIDEO_DEPTH_shift

	; wylicz wskaźnik początku wypełnienia w przestrzeni bufora
	;-----------------------------------------------------------------------

	; pozycja względem osi X
	mov	rdi,	r8
	shl	rdi,	KERNEL_VIDEO_DEPTH_shift

	; pozycja względem osi Y
	mov	rax,	r14
	mul	r9

	; wskaźnik bezpośredni do przestrzeni wypełnienia w buforze
	add	rdi,	rax
	add	rdi,	qword [kernel_wm_object_framebuffer + KERNEL_WM_STRUCTURE_OBJECT.address]

	; korekta pozycji wypełnienia względem obiektu
	; -----------------------------------------------------------------------
	sub	r8,	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.x]
	js	.overflow	; obiekt wypełniający poza obszarem fragmentu
	sub	r9,	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.y]
	js	.overflow	; obietk wypełniający poza obszarem fragmentu

	; wylicz wskaźnik początku wypełnienia w przestrzeni obiektu
	;-----------------------------------------------------------------------

	; pozycja na osi Y w Bajtach (względna)
	mov	rax,	r9
	mul	r13

	; pozycja na osi X w Bajtach (względna)
	shl	r8,	KERNEL_VIDEO_DEPTH_shift

	; przelicz na wskaźnik bezwzględny
	mov	rsi,	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.address]
	add	rsi,	rax
	add	rsi,	r8

	;-----------------------------------------------------------------------
	; Wypełnianie
	;-----------------------------------------------------------------------

.row:
	; następny wiersz N pikseli
	mov	rcx,	r10

.print:
	; piksel całkowicie przeźroczysty?
	cmp	byte [rsi + 0x03],	STATIC_MAX_unsigned
	je	.transparent_max	; tak

	; ; przeliczyć wartość koloru na podstawie kanału alfa?
	; cmp	byte [rsi + 0x03],	STATIC_EMPTY
	; ja	.alpha	; tak

	; wypełnij wiersz pikseli wypełniaczem
	movsd
	; rep	movsd

	; kontynuuj
	jmp	.continue

.overflow:
	; przetwórz ponownie fragment jako strefę
	mov	rsi,	qword [rsp]
	call	kernel_wm_zone_insert_by_object
	call	kernel_wm_zone

	; pomiń fragment
	jmp	.leave

; .alpha:
; 	; zachowaj oryginalne rejestry
; 	push	rax
;
; 	; wylicz kolor na podstawie kanału alfa
; 	call	qword [LIBRARY_STRUCTURE_ENTRY_POINT.color_alpha]
;
; 	; aktualizuj
; 	mov	dword [rdi],	eax
;
; 	; przywróć orygnalne rejestry
; 	pop	rax
;
.transparent_max:
	; pomiń piksel
	add	rsi,	STATIC_DWORD_SIZE_byte
	add	rdi,	STATIC_DWORD_SIZE_byte

.continue:
	; następny piksel?
	dec	rcx
	jnz	.print	; tak

	; przesuń wskaźniki na następną linię
	; bufor
	sub	rdi,	r12
	add	rdi,	r14
	; wypełniacz
	sub	rsi,	r12
	add	rsi,	r13

	; pozostały wiersze wypełnienia?
	dec	r11
	jnz	.row	; tak

	; zawartość bufora uległa modyfikacji
	or	qword [kernel_wm_object_framebuffer + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_flush

.leave:
	; przywróć wskaźnik i rozmiar listy
	pop	rsi
	pop	rcx

	; zwolnij wypełnienie na liście
	mov	qword [rsi + KERNEL_WM_STRUCTURE_FILL.object],	STATIC_EMPTY

.next:
	; przesuń wskaźnik na następne wypełnienie
	add	rsi,	KERNEL_WM_STRUCTURE_FILL.SIZE

	; następny wpis na liście?
	dec	rcx
	jnz	.loop	; tak

.end:
	; przywróć oryginalne rejestry
	pop	r15
	pop	r14
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
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"kernel_wm_fill"
