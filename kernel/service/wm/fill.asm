;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; wejście:
;	rax - wskaźnik do obiektu wypełniającego
;	r8w - pozycja na osi X
;	r9w - pozycja na osi Y
;	r10w - szerokość strefy
;	r11w - wysokość strefy
kernel_wm_fill_insert_by_register:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rdi

	; maksymalna ilość miejsc na liście
	mov	ecx,	KERNEL_WM_FRAGMENT_LIST_limit

	; ustaw wskaźnik na listy
	mov	rdi,	qword [kernel_wm_fill_list_address]

.loop:
	; wolne miejsce?
	cmp	qword [rdi + KERNEL_WM_STRUCTURE_FRAGMENT.object],	STATIC_EMPTY
	jne	.next	; nie

	; dodaj do listy nową strefę
	mov	word [rdi + KERNEL_WM_STRUCTURE_FRAGMENT.field + KERNEL_WM_STRUCTURE_FIELD.x],	r8w
	mov	word [rdi + KERNEL_WM_STRUCTURE_FRAGMENT.field + KERNEL_WM_STRUCTURE_FIELD.y],	r9w
	mov	word [rdi + KERNEL_WM_STRUCTURE_FRAGMENT.field + KERNEL_WM_STRUCTURE_FIELD.width],	r10w
	mov	word [rdi + KERNEL_WM_STRUCTURE_FRAGMENT.field + KERNEL_WM_STRUCTURE_FIELD.height],	r11w

	; oraz jej obiekt zależny
	mov	qword [rdi + KERNEL_WM_STRUCTURE_FRAGMENT.object],	rax

	; zrealizowano
	jmp	.end

.next:
	; przesuń wskaźnik na następny wpis
	add	rdi,	KERNEL_WM_STRUCTURE_FRAGMENT.SIZE

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
	push	rcx
	push	rdi
	push	rsi

	; maksymalna ilość miejsc na liście
	mov	ecx,	KERNEL_WM_FRAGMENT_LIST_limit

	; ustaw wskaźnik na listy
	mov	rdi,	qword [kernel_wm_fill_list_address]

.loop:
	; wolne miejsce?
	cmp	qword [rdi + KERNEL_WM_STRUCTURE_FRAGMENT.object],	STATIC_EMPTY
	jne	.next	; nie

	; wstaw właściwości wypełnienia
	movsq

	; oraz informacje o obiekcie zależnym
	mov	rcx,	qword [rsp]
	mov	qword [rdi],	rcx

	; zrealizowano
	jmp	.end

.next:
	; przesuń wskaźnik na następny wpis
	add	rdi,	KERNEL_WM_STRUCTURE_FRAGMENT.SIZE

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
	mov	ecx,	KERNEL_WM_FRAGMENT_LIST_limit

	; ustaw wskaźnik na listę wypełnień
	mov	rsi,	qword [kernel_wm_fill_list_address]

.loop:
	; pusta pozycja?
	cmp	qword [rsi + KERNEL_WM_STRUCTURE_FRAGMENT.object],	STATIC_EMPTY
	je	.next	; tak

	; zachowaj wskaźnik i rozmiar listy
	push	rcx
	push	rsi

	; przygotuj rejestry do pracy
	call	.prepare

	;-----------------------------------------------------------------------
	; Wypełnianie
	;-----------------------------------------------------------------------

.row:
	; następny wiersz N pikseli
	mov	cx,	r10w

.print:
	; piksel całkowicie przeźroczysty?
	cmp	byte [rsi + 0x03],	STATIC_MAX_unsigned
	je	.transparent_max	; tak

	; przeliczyć wartość koloru na podstawie kanału alfa?
	cmp	byte [rsi + 0x03],	STATIC_EMPTY
	ja	.alpha	; tak

.fill:
	; wypełnij wiersz pikseli wypełniaczem
	movsd

	; kontynuuj
	jmp	.continue

.alpha:
	; wylicz kolor na podstawie kanału alfa
	macro_library	LIBRARY_STRUCTURE_ENTRY.color_alpha

	; aktualizuj
	mov	dword [rdi],	eax

.transparent_max:
	; pomiń piksel
	add	rsi,	STATIC_DWORD_SIZE_byte
	add	rdi,	STATIC_DWORD_SIZE_byte

.continue:
	; kontynuuować z aktualnym wierszem?
	dec	cx
	jnz	.print	; tak

	; przesuń wskaźniki na następną linię
	; bufor
	sub	rdi,	r12
	add	rdi,	r14
	; wypełniacz
	sub	rsi,	r12
	add	rsi,	r13

	; pozostały wiersze wypełnienia?
	dec	r11w
	jnz	.row	; tak

	; zawartość bufora uległa modyfikacji
	or	word [kernel_wm_object_framebuffer + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_flush

.leave:
	; przywróć wskaźnik i rozmiar listy
	pop	rsi
	pop	rcx

	; zwolnij wypełnienie na liście
	mov	qword [rsi + KERNEL_WM_STRUCTURE_FRAGMENT.object],	STATIC_EMPTY

.next:
	; przesuń wskaźnik na następne wypełnienie
	add	rsi,	KERNEL_WM_STRUCTURE_FRAGMENT.SIZE

	; następny wpis na liście?
	dec	cx
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

;-------------------------------------------------------------------------------
.prepare:
	;-----------------------------------------------------------------------
	; pobierz właściwości wypełnienia
	;-----------------------------------------------------------------------
	movzx	r8d,	word [rsi + KERNEL_WM_STRUCTURE_FRAGMENT.field + KERNEL_WM_STRUCTURE_FIELD.x]
	movzx	r9d,	word [rsi + KERNEL_WM_STRUCTURE_FRAGMENT.field + KERNEL_WM_STRUCTURE_FIELD.y]
	movzx	r10d,	word [rsi + KERNEL_WM_STRUCTURE_FRAGMENT.field + KERNEL_WM_STRUCTURE_FIELD.width]
	movzx	r11d,	word [rsi + KERNEL_WM_STRUCTURE_FRAGMENT.field + KERNEL_WM_STRUCTURE_FIELD.height]

	; opisana strefa znajduje się na ujemnej osi X?
	bt	r8w,	STATIC_QWORD_BIT_sign
	jnc	.x_positive	; nie

	; wytnij niewidoczny fragment
	not	r8w
	inc	r8w
	sub	r10w,	r8w

	; przesuń na początek osi X
	xor	r8w,	r8w

	.x_positive:
	; opisana strefa znajduje się na ujemnej osi Y?
	bt	r9w,	STATIC_QWORD_BIT_sign
	jnc	.y_positive	; nie

	; wytnij niewidoczny fragment
	not	r9w
	inc	r9w
	sub	r11w,	r9w

	; przesuń na początek osi Y
	xor	r9w,	r9w

	.y_positive:
	; opisana strefa wykracza poza oś X?
	mov	ax,	r8w
	add	ax,	r10w
	cmp	ax,	word [kernel_video_width_pixel]
	jb	.x_inside	; nie

	; ogranicz strefę do przestrzeni ekranu
	sub	ax,	word [kernel_video_width_pixel]
	sub	r10w,	ax

	.x_inside:
	; opisana strefa wykracza poza oś Y?
	mov	ax,	r9w
	add	ax,	r11w
	cmp	ax,	word [kernel_video_height_pixel]
	jb	.y_inside	; nie

	; ogranicz strefę do przestrzeni ekranu
	sub	ax,	word [kernel_video_height_pixel]
	sub	r11w,	ax

	.y_inside:
	;-----------------------------------------------------------------------
	; wylicz zmienne do opracji kopiowania przestrzeni
	;-----------------------------------------------------------------------

	; pobierz wskaźnik do obiektu wypełniającego
	mov	rsi,	qword [rsi + KERNEL_WM_STRUCTURE_FRAGMENT.object]

	;-----------------------------------------------------------------------
	; scanlines
	; r12 - scanline wypelnienia w Bajtach
	movzx	r12d,	r10w
	shl	r12d,	KERNEL_VIDEO_DEPTH_shift
	; r13 - scanline obiektu w Bajtach
	movzx	r13d,	word [rsi + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.width]
	shl	r13d,	KERNEL_VIDEO_DEPTH_shift
	; r14 - scanline bufora w Bajtach
	movzx	r14d,	word [kernel_wm_object_framebuffer + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.width]
	shl	r14d,	KERNEL_VIDEO_DEPTH_shift

	;-----------------------------------------------------------------------
	; wylicz wskaźnik początku wypełnienia w przestrzeni bufora
	;-----------------------------------------------------------------------

	; pozycja względem osi X
	movzx	edi,	r8w
	shl	edi,	KERNEL_VIDEO_DEPTH_shift

	; pozycja względem osi Y
	mov	eax,	r14d
	mul	r9d

	; wskaźnik bezpośredni do przestrzeni wypełnienia w buforze
	add	rdi,	rax
	add	rdi,	qword [kernel_wm_object_framebuffer + KERNEL_WM_STRUCTURE_OBJECT.address]

	; korekta pozycji wypełnienia względem obiektu
	; -----------------------------------------------------------------------
	sub	r8w,	word [rsi + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.x]
	sub	r9w,	word [rsi + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.y]

	; wylicz wskaźnik początku wypełnienia w przestrzeni obiektu
	;-----------------------------------------------------------------------

	; pozycja na osi Y w Bajtach (względna)
	movzx	eax,	r9w
	mul	r13d

	; pozycja na osi X w Bajtach (względna)
	shl	r8d,	KERNEL_VIDEO_DEPTH_shift

	; przelicz na wskaźnik bezwzględny
	mov	rsi,	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT.address]
	add	rsi,	rax
	add	rsi,	r8

	; powrót z podprocedury
	ret

	macro_debug	"kernel_wm_fill.prepare"
