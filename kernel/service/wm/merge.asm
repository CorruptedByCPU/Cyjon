;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
kernel_wm_merge:
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
	cmp	qword [kernel_wm_merge_list_records],	STATIC_EMPTY
	je	.end	; tak

	xchg	bx,bx

	; ustaw wskaźnik na początek przestrzeni listy obiektów
	mov	rsi,	qword [kernel_wm_object_list_length]
	shl	rsi,	STATIC_MULTIPLE_BY_8_shift
	add	rsi,	qword [kernel_wm_object_list_address]

.next:
	; przesuń wskaźnik na następny obiekt
	sub	rsi,	KERNEL_WM_STRUCTURE_OBJECT_LIST_ENTRY.SIZE

.object:
	; pobierz wskaźnik do obiektu
	mov	rax,	qword [rsi + KERNEL_WM_STRUCTURE_OBJECT_LIST_ENTRY.object_address]

	; sprawdzono wszystkie obiekty?
	test	rax,	rax
	jz	.end	; tak

	; obiekt widoczny?
	test	word [rax + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_visible
	jz	.next	; nie

	; pobierz właściwości obiektu
	mov	r8w,	word [rax + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.x]	; lewa krawędź na oxi X
	mov	r9w,	word [rax + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.y]	; górna krawędź na osi Y
	mov	r10w,	word [rax + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.width]
	add	r10w,	r8w	; prawa krawędź na osi X
	mov	r11w,	word [rax + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.height]
	add	r11w,	r9w	; dolna krawędź na osi Y

	; obiekt znajduje się w przestrzeni ekranu?
	cmp	r8w,	word [kernel_video_width_pixel]
	jge	.next	; za daleko w prawo
	cmp	r9w,	word [kernel_video_height_pixel]
	jge	.next	; za daleko w dół
	cmp	r10w,	STATIC_EMPTY
	jle	.next	; za daleko w lewo
	cmp	r11w,	STATIC_EMPTY
	jle	.next	; za daleko w górę

	;--------------------------------
	;      r9	       r13	X
	;    -------	     -------
	; r8 | rsi | r10 r12 | rdi | r14
	;    -------	     -------
	;      r11	       r15
	; Y

	; ustaw wskaźnik na początek listy fragmentów scaleń
	mov	rdi,	qword [kernel_wm_merge_list_address]
	sub	rdi,	KERNEL_WM_STRUCTURE_FRAGMENT.SIZE	; korekcja

.merge:
	; ustaw wskaźnik na rozpatrywany fragment scalenia
	add	rdi,	KERNEL_WM_STRUCTURE_FRAGMENT.SIZE

.continue:
	; koniec fragmentów do sprawdzenia?
	cmp	qword [rdi + KERNEL_WM_STRUCTURE_FRAGMENT.object],	STATIC_EMPTY
	je	.next	; tak

	; pobierz właściwości fragmentu scaleń
	mov	r12w,	word [rdi + KERNEL_WM_STRUCTURE_FRAGMENT.field + KERNEL_WM_STRUCTURE_FIELD.x]	; lewa krawędź na osi X
	mov	r13w,	word [rdi + KERNEL_WM_STRUCTURE_FRAGMENT.field + KERNEL_WM_STRUCTURE_FIELD.y]	; górna krawędź na osi Y
	mov	r14w,	word [rdi + KERNEL_WM_STRUCTURE_FRAGMENT.field + KERNEL_WM_STRUCTURE_FIELD.width]
	add	r14w,	r12w	; prawa krawędź na osi X
	mov	r15w,	word [rdi + KERNEL_WM_STRUCTURE_FRAGMENT.field + KERNEL_WM_STRUCTURE_FIELD.height]
	add	r15w,	r13w	; dolna krawędź na osi Y

	; fragment znajduje się w przestrzeni obiektu?
	cmp	r12w,	word [kernel_video_width_pixel]
	jge	.merge	; za dalego w prawo
	cmp	r13w,	word [kernel_video_height_pixel]
	jge	.merge	; za dalego w dół
	cmp	r14w,	STATIC_EMPTY
	jle	.merge	; za dalego w lewo
	cmp	r15w,	STATIC_EMPTY
	jle	.merge	; za dalego w górę

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

	; obiekt posiada cechę przeźroczystości?
	test	word [rax + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_visible
	jnz	.left_omit	; tak

	; odłóż na listę stref
	call	kernel_wm_merge_insert_by_register

.left_omit:
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

	; obiekt posiada cechę przeźroczystości?
	test	word [rax + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_visible
	jnz	.up_omit	; tak

	; odłóż na listę stref
	call	kernel_wm_merge_insert_by_register

.up_omit:
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

	; obiekt posiada cechę przeźroczystości?
	test	word [rax + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_visible
	jnz	.right_omit	; tak

	; odłóż na listę stref
	call	kernel_wm_merge_insert_by_register

.right_omit:
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
	jle	.done	; nie

	; wytnij wystający fragment strefy

	; wysokość odcinanej strefy
	sub	r11w,	r15w

	; zachowaj oryginalną pozycję górnej krawędzi strefy
	push	r9

	; pozycja górnej krawędzi odcinanej strefy
	mov	r9w,	r15w

	; obiekt posiada cechę przeźroczystości?
	test	word [rax + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_visible
	jnz	.down_omit	; tak

	; odłóż na listę stref
	call	kernel_wm_merge_insert_by_register

.down_omit:
	; przywróć oryginalną pozycję lewej krawędzi strefy
	pop	r9

	; nowa pozycja dolnej krawędzi strefy
	sub	word [rsp],	r11w
	mov	r11w,	r15w

.done:
	; wypełnij pozostały fragment danym obiektem
	sub	r10w,	r8w	; zwróć szerokość strefy
	sub	r11w,	r9w	; zwróć wysokość strefy
	cmp	r10w,	STATIC_EMPTY
	jle	.merge	; błąd, fragment niewidoczny

	; obiekt posiada cechę przeźroczystości?
	test	word [rax + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_visible
	jnz	.fill	; tak

	; usuń fragment z listy
	call	kernel_wm_merge_remove

	; kontynuuj
	jmp	.continue

.fill:
	; zarejestruj do wypełnienia
	call	kernel_wm_fill_insert_by_register

	; kontynuuj
	jmp	.merge

.end:
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

	macro_debug	"kernel_wm_merge"

;===============================================================================
; wejście:
;	rdi - wskaźnik do strefy
kernel_wm_merge_remove:
	; zachowaj oryginalne rejestry
	push	rdi

	; zablokuj dostęp do modyfikacji listy stref
	macro_lock	kernel_wm_merge_semaphore,	0

.move:
	; przesuń następny element listy na aktualną pozycję
	push	qword [rdi + KERNEL_WM_STRUCTURE_FRAGMENT.SIZE + KERNEL_WM_STRUCTURE_FRAGMENT.field]
	push	qword [rdi + KERNEL_WM_STRUCTURE_FRAGMENT.SIZE + KERNEL_WM_STRUCTURE_FRAGMENT.object]
	pop	qword [rdi + KERNEL_WM_STRUCTURE_FRAGMENT.object]
	pop	qword [rdi + KERNEL_WM_STRUCTURE_FRAGMENT.field]

	; przesuń wskaźnik na następny element
	add	rdi,	KERNEL_WM_STRUCTURE_FRAGMENT.SIZE

	; koniec elementów na liście?
	cmp	qword [rdi + KERNEL_WM_STRUCTURE_FRAGMENT.object],	STATIC_EMPTY
	jne	.move	; nie

	; zmniejszono ilość elementów na liście
	dec	qword [kernel_wm_merge_list_records]

.end:
	; odblokuj listę stref do modyfikacji
	mov	byte [kernel_wm_merge_semaphore],	STATIC_FALSE

	; przywróć oryginalne rejestry
	pop	rdi

	; powrót z procedury
	ret

	macro_debug	"kernel_wm_merge_remove"

;===============================================================================
; wejście:
;	rax - wskaźnik do obiektu wypełniającego
;	r8w - pozycja na osi X
;	r9w - pozycja na osi Y
;	r10w - szerokość strefy
;	r11w - wysokość strefy
kernel_wm_merge_insert_by_register:
	; zachowaj oryginalne rejestry
	push	rax

	; brak miejsca?
	cmp	qword [kernel_wm_merge_list_records],	KERNEL_WM_FRAGMENT_LIST_limit
	je	.end	; tak

	; zachowaj wskaźnik do obiektu wypełniającego
	push	rax

	; ustaw wskaźnik na koniec listy
	mov	rax,	qword [kernel_wm_merge_list_records]
	shl	rax,	STATIC_MULTIPLE_BY_16_shift
	add	rax,	qword [kernel_wm_merge_list_address]

	; dodaj do listy nową strefę
	mov	word [rax + KERNEL_WM_STRUCTURE_FRAGMENT.field + KERNEL_WM_STRUCTURE_FIELD.x],	r8w
	mov	word [rax + KERNEL_WM_STRUCTURE_FRAGMENT.field + KERNEL_WM_STRUCTURE_FIELD.y],	r9w
	mov	word [rax + KERNEL_WM_STRUCTURE_FRAGMENT.field + KERNEL_WM_STRUCTURE_FIELD.width],	r10w
	mov	word [rax + KERNEL_WM_STRUCTURE_FRAGMENT.field + KERNEL_WM_STRUCTURE_FIELD.height],	r11w

	; oraz jej obiekt zależny
	pop	qword [rax + KERNEL_WM_STRUCTURE_FRAGMENT.object]

	; zwiększono ilość elementów na liście
	inc	qword [kernel_wm_merge_list_records]

.end:
	; przywróć oryginalne rejestry
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"kernel_wm_merge_insert_by_register"
