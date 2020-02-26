;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

;===============================================================================
; wejście:
;	rsi - wskaźnik do obiektu wypełniającego
;	r8 - pozycja na osi X
;	r9 - pozycja na osi Y
;	r10 - szerokość strefy
;	r11 - wysokość strefy
service_desu_fill_insert_by_register:
	; zachowaj oryginalne rejestry
	push	rcx
	push	rdi

	; maksymalna ilość miejsc na liście
	mov	ecx,	SERVICE_DESU_FILL_LIST_limit

	; ustaw wskaźnik na listy
	mov	rdi,	qword [service_desu_fill_list_address]

.loop:
	; wolne miejsce?
	cmp	qword [rdi + SERVICE_DESU_STRUCTURE_FILL.object],	STATIC_EMPTY
	jne	.next	; nie

	; dodaj do listy nową strefę
	mov	qword [rdi + SERVICE_DESU_STRUCTURE_FILL.field + SERVICE_DESU_STRUCTURE_FIELD.x],	r8
	mov	qword [rdi + SERVICE_DESU_STRUCTURE_FILL.field + SERVICE_DESU_STRUCTURE_FIELD.y],	r9
	mov	qword [rdi + SERVICE_DESU_STRUCTURE_FILL.field + SERVICE_DESU_STRUCTURE_FIELD.width],	r10
	mov	qword [rdi + SERVICE_DESU_STRUCTURE_FILL.field + SERVICE_DESU_STRUCTURE_FIELD.height],	r11

	; oraz jej obiekt zależny
	mov	qword [rdi + SERVICE_DESU_STRUCTURE_FILL.object],	rsi

	; zrealizowano
	jmp	.end

.next:
	; przesuń wskaźnik na następny wpis
	add	rdi,	SERVICE_DESU_STRUCTURE_FILL.SIZE

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

	macro_debug	"service_desu_fill_insert_by_register"

;===============================================================================
; wejście:
;	rsi - wskaźnik do obiektu
service_desu_fill_insert_by_object:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdi
	push	rsi

	; maksymalna ilość miejsc na liście
	mov	ecx,	SERVICE_DESU_FILL_LIST_limit

	; ustaw wskaźnik na listy
	mov	rdi,	qword [service_desu_fill_list_address]

.loop:
	; wolne miejsce?
	cmp	qword [rdi + SERVICE_DESU_STRUCTURE_FILL.object],	STATIC_EMPTY
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
	add	rdi,	SERVICE_DESU_STRUCTURE_FILL.SIZE

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

	macro_debug	"service_desu_fill_insert_by_object"

;===============================================================================
service_desu_fill:
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

	; ustaw wskaźnik na listę wypełnień
	mov	rsi,	qword [service_desu_fill_list_address]

.loop:
	; zachowaj wskaźnik i rozmiar listy
	push	rcx
	push	rsi

	;-----------------------------------------------------------------------
	; pobierz właściwości wypełnienia
	;-----------------------------------------------------------------------
	mov	r8,	qword [rsi + SERVICE_DESU_STRUCTURE_FILL.field + SERVICE_DESU_STRUCTURE_FIELD.x]
	mov	r9,	qword [rsi + SERVICE_DESU_STRUCTURE_FILL.field + SERVICE_DESU_STRUCTURE_FIELD.y]
	mov	r10,	qword [rsi + SERVICE_DESU_STRUCTURE_FILL.field + SERVICE_DESU_STRUCTURE_FIELD.width]
	mov	r11,	qword [rsi + SERVICE_DESU_STRUCTURE_FILL.field + SERVICE_DESU_STRUCTURE_FIELD.height]

	;-----------------------------------------------------------------------
	; wytnij niewidoczne części wypełnienia
	;-----------------------------------------------------------------------

.left: ;)
	;-----------------------------------------------------------------------
	; wypełnienie wykracza poza ekran z lewej strony?
	bt	r8,	STATIC_WORD_BIT_sign
	jnc	.top	; nie

	; zmiejsz szerokość wypełnienia
	add	r10,	r8

	; nowa pozycja na osi X
	xor	r8,	r8

.top:
	;-----------------------------------------------------------------------
	; wypełnienie wykracza poza ekran od górnej strony?
	bt	r9,	STATIC_WORD_BIT_sign
	jnc	.right	; nie

	; zmniejsz wysokość wypełnienia
	add	r11,	r9

	; nowa pozycja na osi Y
	xor	r9,	r9

.right:
	;-----------------------------------------------------------------------
	; wypełnienie wykracza poza ekran od prawej strony?
	mov	rax,	r8
	add	rax,	r10
	cmp	rax,	qword [kernel_video_width_pixel]
	jb	.down	; nie

	; wytnij niewidoczne wypełnienie
	sub	rax,	qword [kernel_video_width_pixel]
	sub	r10,	rax

.down:
	;-----------------------------------------------------------------------
	; wypełnienie wykracza poza ekran od dolnej strony?
	mov	rax,	r9
	add	rax,	r11
	cmp	rax,	qword [kernel_video_height_pixel]
	jb	.ready	; nie

	; wytnij niewidoczne wypełnienie
	sub	rax,	qword [kernel_video_height_pixel]
	sub	r11,	rax

.ready:
	;-----------------------------------------------------------------------
	; wylicz zmienne do opracji kopiowania przestrzeni
	;-----------------------------------------------------------------------

	mov	rsi,	qword [rsi + SERVICE_DESU_STRUCTURE_FILL.object]

	; scanline fragmentu w Bajtach
	mov	r12,	r10
	shl	r12,	KERNEL_VIDEO_DEPTH_shift

	; scanline obiektu w Bajtach
	mov	r13,	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.width]
	shl	r13,	KERNEL_VIDEO_DEPTH_shift

	; scanline bufora w Bajtach
	mov	r14,	qword [kernel_video_scanline_byte]

	; pozycja Y obszaru wypełniającego
	mov	rax,	r9
	sub	rax,	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.y]
	mul	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.width]
	shl	rax,	KERNEL_VIDEO_DEPTH_shift
	mov	r15,	rax

	; pozycja X obszaru wypełniającego
	mov	rax,	r8
	sub	rax,	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.field + SERVICE_DESU_STRUCTURE_FIELD.x]
	shl	rax,	KERNEL_VIDEO_DEPTH_shift
	add	r15,	rax
	add	r15,	qword [rsi + SERVICE_DESU_STRUCTURE_OBJECT.address]

	; ustaw wskaźnik przestrzeni kawałka w przestrzeni bufora
	mov	rax,	r9
	mul	qword [kernel_video_scanline_byte]
	mov	rdi,	rax
	shl	r8,	KERNEL_VIDEO_DEPTH_shift
	add	rdi,	r8
	add	rdi,	qword [service_desu_object_framebuffer + SERVICE_DESU_STRUCTURE_OBJECT.address]

	; ustaw wskaźnik na przestrzeń kawałka w przestrzeni wypełniacza
	mov	rsi,	r15

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
	or	qword [service_desu_object_framebuffer + SERVICE_DESU_STRUCTURE_OBJECT.SIZE + SERVICE_DESU_STRUCTURE_OBJECT_EXTRA.flags],	SERVICE_DESU_OBJECT_FLAG_flush

.leave:
	; przywróć wskaźnik i rozmiar listy
	pop	rsi
	pop	rcx

	; przesuń wskaźnik na następne wypełnienie
	add	rsi,	SERVICE_DESU_STRUCTURE_OBJECT.SIZE

	; pozostały rekordy na liście wypełnień?
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

	macro_debug	"service_desu_fill"
