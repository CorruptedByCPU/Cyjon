;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; wejście:
;	rbx - wskaźnik do procedury rysowania
;	r8 - x1
;	r9 - y1
;	r10 - x2
;	r11 - y2
library_bresenham:
	; zachowaj oryginalne rejestry
	push	rax
	push	rdx
	push	rsi
	push	rdi
	push	r8
	push	r9
	push	r12
	push	r13
	push	r14
	push	r15

	; sprawdź oś X
	; x1 > x2
	cmp	r8,	r10
	ja	.reverse_x

	; kierunek osi X rosnąco
	mov	r12,	1	; xi =  1
	mov	r14,	r10	; dx =  x2
	sub	r14,	r8	; dx -= x1

	; sprawdź oś Y
	jmp	.check_y

.reverse_x:
	; kierunek osi X malejąco
	mov	r12,	-1	 ; xi =  -1
	mov	r14,	r8	 ; dx =  x1
	sub	r14,	r10	; dx -= x2

.check_y:
	; sprawdź oś Y
	; y1 > y2
	cmp	r9,	r11
	ja	.reverse_y

	; kierunek osi Y rosnąco
	mov	r13,	1	; yi =  1
	mov	r15,	r11	; dy =  y2
	sub	r15,	r9	; dy -= y1

	; kontynuuj
	jmp	.done

.reverse_y:
	; kierunek osi Y malejąco
	mov	r13,	-1	; yi =  -1
	mov	r15,	r9	; dy =  y1
	sub	r15,	r11	; dy -= y2

.done:
	; względem której osi rysować linię?
	; dy > dx
	cmp	r15,	r14
	ja	.osY

	; rysuj linię względem osi X
	mov	rsi,	r15	; ai =  dy
	sub	rsi,	r14	; ai -= dx
	shl	rsi,	STATIC_MULTIPLE_BY_2_shift
	mov	rdx,	r15	; d =   dy
	shl	rdx,	STATIC_MULTIPLE_BY_2_shift
	mov	rdi,	rdx	; bi =  d
	sub	rdx,	r14	; d -=  dx

.loop_x:
	; wyświetl piksel o zdefiniowanym kolorze
	call	rbx

	; jeśli wyświetlony piksel znajduje się w punkcie końca linii, koniec
	; x1 == x2
	cmp	r8,	r10
	je	.end

	; współczynnik ujemny?
	; d
	bt	rdx,	STATIC_QWORD_BIT_sign
	jc	.loop_x_minus

	; oblicz pozycję następnego piksela w linii
	add	r8,	r12	; x +=  xi
	add	r9,	r13	; y +=  yi
	add	rdx,	rsi	; d +=  ai

	; rysuj linię
	jmp	.loop_x

.loop_x_minus:
	; oblicz pozycję następnego piksela w linii
	add	rdx,	rdi	; d +=  bi
	add	r8,	r12	; x +=  xi

	; rysuj linię
	jmp	.loop_x

.osY:
	; rysuj linię względem osi Y
	mov	rsi,	r14	; ai =  dx
	sub	rsi,	r15	; ai -= dy
	shl	rsi,	STATIC_MULTIPLE_BY_2_shift
	mov	rdx,	r14	; d =   dx
	shl	rdx,	STATIC_MULTIPLE_BY_2_shift
	mov	rdi,	rdx	; bi =  d
	sub	rdx,	r15	; d -=  dy

.loop_y:
	; wyświetl piksel o zdefiniowanym kolorze
	call	rbx

	; jeśli wyświetlony piksel znajduje się w punkcie końca linii, koniec
	; y1 == y2
	cmp	r9,	r11
	je	.end

	; współczynnik ujemny?
	; d
	bt	rdx,	STATIC_QWORD_BIT_sign
	jc	.loop_y_minus

	; oblicz pozycję następnego piksela w linii
	add	r8,	r12	; x +=  xi
	add	r9,	r13	; y +=  yi
	add	rdx,	rsi	; d +=  ai

	; rysuj linię
	jmp	.loop_y

.loop_y_minus:
	; oblicz pozycję następnego piksela w linii
	add	rdx,	rdi	; d +=  bi
	add	r9,	r13	; y +=  yi

	; rysuj linię
	jmp	.loop_y

.end:
	; przywtóć oryginalne rejestry
	pop	r15
	pop	r14
	pop	r13
	pop	r12
	pop	r9
	pop	r8
	pop	rdi
	pop	rsi
	pop	rdx
	pop	rax

	; powrót z procedury
	ret
