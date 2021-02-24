;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;-------------------------------------------------------------------------------

;===============================================================================
; wejście:
;	rax - wskaźnik do rekordu tablicy obiektów
kernel_wm_zone_insert_by_object:
	; zachowaj oryginalne rejestry
	push	rdx
	push	rdi
	push	rsi
	push	rax

	; zablokuj dostęp do modyfikacji listy stref
	macro_lock	kernel_wm_zone_semaphore,	0

	; lista stref jest pełna?
	cmp	qword [kernel_wm_zone_list_records],	KERNEL_WM_ZONE_LIST_limit
	jb	.insert	; nie

	xchg	bx,bx
	jmp	$

.insert:
	; wskaźnik pośredni na koniec listy stref
	mov	eax,	KERNEL_WM_STRUCTURE_ZONE.SIZE
	mul	qword [kernel_wm_zone_list_records]	; pozycja za ostatnią strefą listy

	; ustaw wskaźniki na miejsca
	mov	rsi,	qword [rsp]
	mov	rdi,	qword [kernel_wm_zone_list_address]
	add	rdi,	rax

	; wstaw właściwości strefy
	movsw	; pozycja na osi X
	movsw	; pozycja na osi Y
	movsw	; szerokość
	movsw	; wysokość

	; oraz informacje o obiekcie zależnym
	mov	rax,	qword [rsp]
	mov	qword [rdi],	rax

	; ilość stref na liście
	inc	qword [kernel_wm_zone_list_records]

	; odblokuj listę stref do modyfikacji
	mov	byte [kernel_wm_zone_semaphore],	STATIC_FALSE

	; przywróć oryginalne rejestry
	pop	rax
	pop	rsi
	pop	rdi
	pop	rdx

	; powrót z procedury
	ret

	macro_debug	"kernel_wm_zone_insert_by_object"

;===============================================================================
; wejście:
;	rdi - wskaźnik do rekordu tablicy obiektów
;	r8 - pozycja na osi X
;	r9 - pozycja na osi Y
;	r10 - szerokość strefy
;	r11 - wysokość strefy
kernel_wm_zone_insert_by_register:
	; zachowaj oryginalne rejestry
	push	rax
	push	rdx
	push	rsi

	; zablokuj dostęp do modyfikacji listy stref
	macro_lock	kernel_wm_zone_semaphore,	0

	; lista stref jest pełna?
	cmp	qword [kernel_wm_zone_list_records],	KERNEL_WM_ZONE_LIST_limit
	jb	.insert	; nie

	xchg	bx,bx
	jmp	$

.insert:
	; wskaźnik pośredni na koniec listy stref
	mov	eax,	KERNEL_WM_STRUCTURE_ZONE.SIZE
	mul	qword [kernel_wm_zone_list_records]	; pozycja za ostatnią strefą listy

	; wskaźnik bezpośredni końca listy stref
	mov	rsi,	qword [kernel_wm_zone_list_address]
	add	rsi,	rax

	; dodaj do listy nową strefę
	mov	word [rsi + KERNEL_WM_STRUCTURE_ZONE.field + KERNEL_WM_STRUCTURE_FIELD.x],	r8w
	mov	word [rsi + KERNEL_WM_STRUCTURE_ZONE.field + KERNEL_WM_STRUCTURE_FIELD.y],	r9w
	mov	word [rsi + KERNEL_WM_STRUCTURE_ZONE.field + KERNEL_WM_STRUCTURE_FIELD.width],	r10w
	mov	word [rsi + KERNEL_WM_STRUCTURE_ZONE.field + KERNEL_WM_STRUCTURE_FIELD.height],	r11w

	; oraz jej obiekt zależny
	mov	qword [rsi + KERNEL_WM_STRUCTURE_ZONE.object],	rdi

	; ilość stref na liście
	inc	qword [kernel_wm_zone_list_records]

	; odblokuj listę stref do modyfikacji
	mov	byte [kernel_wm_zone_semaphore],	STATIC_FALSE

	; przywróć oryginalne rejestry
	pop	rsi
	pop	rdx
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"kernel_wm_zone_insert_by_register"

;===============================================================================
kernel_wm_zone:
	; zachowaj oryginalne rejestry
	push	rax
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

	; brak stref na liście?
	cmp	qword [kernel_wm_zone_list_records],	STATIC_EMPTY
	je	.end	; tak

	; ustaw wskaźnik na pierwszą opisaną strefę na liście
	mov	rdi,	qword [kernel_wm_zone_list_address]

	; rozpocznij przetwarzanie
	jmp	.entry

.loop:
	; zwolnij strefę z listy
	mov	qword [rdi + KERNEL_WM_STRUCTURE_ZONE.object],	STATIC_EMPTY

	; przesuń wskaźnik na pierwszą/następną strefę do przetworzenia
	add	rdi,	KERNEL_WM_STRUCTURE_ZONE.SIZE

.entry:
	; brak strefy do przetworzenia?
	cmp	qword [rdi + KERNEL_WM_STRUCTURE_ZONE.object],	STATIC_EMPTY
	je	.end	; tak

	;-----------------------------------------------------------------------
	; pobierz właściwości strefy
	;-----------------------------------------------------------------------

	; lewa krawędź na osi X
	mov	r8w,	word [rdi + KERNEL_WM_STRUCTURE_ZONE.field + KERNEL_WM_STRUCTURE_FIELD.x]
	; górna krawędź na osi Y
	mov	r9w,	word [rdi + KERNEL_WM_STRUCTURE_ZONE.field + KERNEL_WM_STRUCTURE_FIELD.y]
	; prawa krawędź na osi X
	mov	r10w,	word [rdi + KERNEL_WM_STRUCTURE_ZONE.field + KERNEL_WM_STRUCTURE_FIELD.width]
	add	r10w,	r8w
	; dolna krawędź na osi Y
	mov	r11w,	word [rdi + KERNEL_WM_STRUCTURE_ZONE.field + KERNEL_WM_STRUCTURE_FIELD.height]
	add	r11w,	r9w

	; opisana strefa znajduje się w przestrzeni "ekranu"?

	; poza prawą krawędzią ekranu?
	cmp	r8w,	word [kernel_video_width_pixel]
	jge	.loop	; tak
	; poza dolną krawędzią ekranu?
	cmp	r9w,	word [kernel_video_height_pixel]
	jge	.loop	; tak
	; poza lewą krawędzią ekranu?
	cmp	r10w,	STATIC_EMPTY
	jle	.loop	; tak
	; poza górną krawędzią ekranu?
	cmp	r11w,	STATIC_EMPTY
	jle	.loop	; nie

	;-----------------------------------------------------------------------
	; interferencja
	;-----------------------------------------------------------------------

	; wskaźnik pośredni na koniec listy obiektów
	mov	rsi,	qword [kernel_wm_object_list_length]
	shl	rsi,	KERNEL_WM_OBJECT_LIST_ENTRY_SIZE_shift	; pozycja za ostatnim obiektem listy
	add	rsi,	qword [kernel_wm_object_list_address]

.object:
	; ustaw wskaźnik na rozpatrywany obiekt
	sub	rsi,	KERNEL_WM_STRUCTURE_OBJECT_LIST_ENTRY.SIZE

	; pobierz wskaźnik rekordu tablicy obiektów
	mov	rax,	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT_LIST_ENTRY.object_address]

	; rozpatrywany obiekt jest pierwszy na liście?
	cmp	rsi,	qword [kernel_wm_object_list_address]
	je	.fill	; tak

	; obiekt widoczny?
	test	word [rax + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_visible
	jz	.object	; nie

	; wystąpiła interferencja z obiektem przetwarzanym? (samym sobą)
	cmp	rax,	qword [rdi + KERNEL_WM_STRUCTURE_ZONE.object]
	jne	.no_interference	; nie

	; obiekt posiada cechy przeźroczystości?
	test	word [rax + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_transparent
	jz	.fill	; nie

	; debug
	xchg	bx,bx

.no_interference:
	; pobierz współrzędne obiektu

	; lewa krawędź na oxi X
	mov	r12w,	word [rax + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.x]
	; górna krawędź na osi Y
	mov	r13w,	word [rax + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.y]
	; prawa krawędź na osi X
	mov	r14w,	word [rax + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.width]
	add	r14w,	r12w
	; dolna krawędź na osi Y
	mov	r15w,	word [rax + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.height]
	add	r15w,	r13w

	;--------------------------------
	;      r9	       r13	X
	;    -------	     -------
	; r8 |  S  | r10 r12 |  O  | r14
	;    -------	     -------
	;      r11	       r15
	; Y

	; obiekt znajduje się poza przetwarzaną strefą?
	cmp	r12w,	r10w	; lewa krawędź obiektu za prawą krawędzią strefy?
	jge	.object	; tak
	cmp	r13w,	r11w	; górna krawędź obiektu za dolną krawędzią strefy?
	jge	.object	; tak
	cmp	r14w,	r8w	; prawa krawędź obiektu przed lewą krawędzią strefy?
	jle	.object	; tak
	cmp	r15w,	r9w	; dolna krawędź obiektu przed górną krawędzią strefy?
	jle	.object	; tak

	;-----------------------------------------------------------------------
	; przycinanie
	;-----------------------------------------------------------------------

.left: ;)
	; lewa krawędź strefy przed lewą krawędzią obiektu?
	cmp	r8w,	r12w
	jge	.up	; nie

	; wytnij wystający fragment strefy

	; zachowaj oryginalną pozycję prawej krawędzi strefy
	push	r10

	; szerokość odcinanej strefy
	mov	r10w,	r12w
	sub	r10w,	r8w

	; wysokość odcinanej strefy
	sub	r11w,	r9w

	; odłóż na listę stref
	call	kernel_wm_zone_insert_by_register

	; przywróć oryginalną pozycję prawej krawędzi strefy
	pop	r10

	; przywróć oryginalną pozycję dolnej krawędzi strefy
	add	r11w,	r9w

	; nowa pozycja lewej krawędzi strefy
	mov	r8w,	r12w

.up:
	; górna krawędź strefy przed górną krawędzią obiektu?
	cmp	r9w,	r13w
	jge	.right	; nie

	; wytnij wystający fragment strefy

	; szerokość odcinanej strefy
	sub	r10w,	r8w

	; zachowaj oryginalną pozycję dolnej krawędzi strefy
	push	r11

	; wysokość odcinanej strefy
	mov	r11w,	r13w
	sub	r11w,	r9w

	; odłóż na listę stref
	call	kernel_wm_zone_insert_by_register

	; przywróć oryginalną pozycję prawej krawędzi strefy
	pop	r11

	; przywróć oryginalną pozycję dolnej krawędzi strefy
	add	r10w,	r8w

	; nowa pozycja górnej krawędzi strefy
	mov	r9w,	r13w

.right:
	; prawa krawędź strefy za prawą krawędzią obiektu?
	cmp	r10w,	r14w
	jle	.down	; nie

	; wytnij wystający fragment strefy

	; szerokość odcinanej strefy
	push	r10
	sub	r10w,	r14w

	; wysokość odcinanej strefy
	sub	r11w,	r9w

	; zachowaj oryginalną pozycję lewej krawędzi strefy
	push	r8

	; pozycja lewej krawędzi odcinanej strefy
	mov	r8w,	r14w

	; odłóż na listę stref
	call	kernel_wm_zone_insert_by_register

	; przywróć oryginalną pozycję lewej krawędzi strefy
	pop	r8

	; nowa pozycja prawej krawędzi strefy
	sub	word [rsp],	r10w
	pop	r10
	; mov	r10,	r14

	; przywróć pozycję dolnej krawędzi
	add	r11w,	r9w

.down:
	; dolna krawędź strefy za dolną krawędzią obiektu?
	cmp	r11w,	r15w
	jle	.fill	; nie

	; wytnij wystający fragment strefy

	; wysokość odcinanej strefy
	sub	r11w,	r15w

	; zachowaj oryginalną pozycję górnej krawędzi strefy
	push	r9

	; pozycja górnej krawędzi odcinanej strefy
	mov	r9w,	r15w

	; odłóż na listę stref
	call	kernel_wm_zone_insert_by_register

	; przywróć oryginalną pozycję lewej krawędzi strefy
	pop	r9

	; nowa pozycja dolnej krawędzi strefy
	sub	word [rsp],	r11w
	mov	r11w,	r15w

.fill:
	; wypełnij pozostały fragment danym obiektem
	sub	r10w,	r8w	; zwróć szerokość strefy
	sub	r11w,	r9w	; zwróć wysokość strefy
	cmp	r10w,	STATIC_EMPTY
	jle	.loop

	; zarejestruj do wypełnienia
	call	kernel_wm_fill_insert_by_register

	; kontynuuj
	jmp	.loop

.end:
	; wszystkie strefy na liście zostały przetworzone
	mov	qword [kernel_wm_zone_list_records],	STATIC_EMPTY

	; przywróć oryginalne rejestry
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
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"kernel_wm_zone"
