;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

; Use:
; nasm - http://www.nasm.us/

struc	BRESENHAM
	.x2	resd	1
	.y2	resd	1
	.dx	resd	1
	.dy	resd	1
	.ai	resd	1
	.bi	resd	1
	.SIZE	resb	1
endstruc

; 16 Bitowy kod programu
[BITS 16]

; edx - x1
; eax - y1
; ebx - x2
; ecx - y2
library_draw_line:
	; zachowaj oryginalne rejestry
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di

	; przygotuj miejsce pod zmienne
	sub	esp,	BRESENHAM.SIZE

	; zachowaj pozycje początku linii
	mov	esi,	edx
	mov	edi,	eax

	; zachowaj pozycje końca linii
	mov	dword [esp + BRESENHAM.x2],	ebx
	mov	dword [esp + BRESENHAM.y2],	ecx

	; sprawdź oś x
	; x1 > x2
	cmp	esi,	dword [esp + BRESENHAM.x2]
	ja	.reverse_x

	; kierunek osi x rosnąco
	mov	dword [esp + BRESENHAM.dx],	ebx	; dx =	x2
	sub	dword [esp + BRESENHAM.dx],	esi	; dx -=	x1
	mov	ebx,	1	; xi =	1

	; sprawdź oś y
	jmp	.check_y

.reverse_x:
	; kierunek osi x malejąco
	mov	dword [esp + BRESENHAM.dx],	esi	; dx =	x1
	sub	dword [esp + BRESENHAM.dx],	ebx	; dx -=	x2
	mov	ebx,	-1	; xi =	-1

.check_y:
	; sprawdź oś y
	; y1 > y2
	cmp	edi,	dword [esp + BRESENHAM.y2]
	ja	.reverse_y

	; kierunek osi y rosnąco
	mov	dword [esp + BRESENHAM.dy],	ecx	; dy =	y2
	sub	dword [esp + BRESENHAM.dy],	edi	; dy -=	y1
	mov	ecx,	1	; yi =	1

	; kontynuuj
	jmp	.done

.reverse_y:
	; kierunek osi y malejąco
	mov	dword [esp + BRESENHAM.dy],	edi	; dy =	y1
	sub	dword [esp + BRESENHAM.dy],	ecx	; dy -=	y2
	mov	ecx,	-1	; yi =	-1

.done:
	; względem której osi rysować linię?
	; dy > dx
	mov	eax,	dword [esp + BRESENHAM.dy]
	cmp	eax,	dword [esp + BRESENHAM.dx]
	ja	.osY

	; rysuj linię względem osi X
	; ai = dy
	; d = dy
	mov	edx,	eax	; d =	dy
	sub	eax,	dword [esp + BRESENHAM.dx]	; ai -=	dx
	shl	eax,	VARIABLE_MULTIPLE_BY_2
	mov	dword [esp + BRESENHAM.ai],	eax
	shl	edx,	VARIABLE_MULTIPLE_BY_2	; d *	2
	mov	dword [esp + BRESENHAM.bi],	edx	; bi =	d
	mov	eax,	dword [esp + BRESENHAM.dx]
	sub	edx,	eax	; d -=	dx

.loop_x:
	; wyświetl piksel o zdefiniowanym kolorze
	; ZAMIEŃ NA WŁASNĄ PROCEDURĘ WYŚWIETLANIA PIKSELI
	; X = ESI, Y = EDI
	nop

	; jeśli wyświetlony piksel znajduje się w punkcie końca linii, koniec
	; x1 == x2
	cmp	esi,	dword [esp + BRESENHAM.x2]
	je	.end

	; współczynnik ujemny?
	; d
	bt	edx,	VARIABLE_DWORD_SIGN
	jc	.loop_x_minus

	; oblicz pozycję następnego piksela w linii
	add	esi,	ebx	; x +=	xi
	add	edi,	ecx	; y +=	yi
	add	edx,	dword [esp + BRESENHAM.ai]	; d +=	ai

	; rysuj linię
	jmp	.loop_x

.loop_x_minus:
	; oblicz pozycję następnego piksela w linii
	add	edx,	dword [esp + BRESENHAM.bi]	; d +=	bi
	add	esi,	ebx	; x +=	xi

	; rysuj linię
	jmp	.loop_x

.osY:
	; rysuj linię względem osi Y
	mov	eax,	dword [esp + BRESENHAM.dx]	; ai = dx
	mov	edx,	eax	; d =	dx
	sub	eax,	dword [esp + BRESENHAM.dy]	; ai -=	dy
	shl	eax,	VARIABLE_MULTIPLE_BY_2
	mov	dword [esp + BRESENHAM.ai],	eax
	shl	edx,	VARIABLE_MULTIPLE_BY_2	; d *	2
	mov	dword [esp + BRESENHAM.bi],	edx	; bi =	d
	mov	eax,	dword [esp + BRESENHAM.dy]
	sub	edx,	eax	; d -=	dy
	
.loop_y:
	; wyświetl piksel o zdefiniowanym kolorze
	; ZAMIEŃ NA WŁASNĄ PROCEDURĘ WYŚWIETLANIA PIKSELI
	; X = ESI, Y = EDI
	nop

	; jeśli wyświetlony piksel znajduje się w punkcie końca linii, koniec
	; y1 == y2
	cmp	edi,	dword [esp + BRESENHAM.y2]
	je	.end

	; współczynnik ujemny?
	; d
	bt	edx,	VARIABLE_DWORD_SIGN
	jc	.loop_y_minus

	; oblicz pozycję następnego piksela w linii
	add	esi,	ebx	; x +=	xi
	add	edi,	ecx	; y +=	yi
	add	edx,	dword [esp + BRESENHAM.ai]	; d +=	ai

	; rysuj linię
	jmp	.loop_y

.loop_y_minus:
	; oblicz pozycję następnego piksela w linii
	add	edx,	dword [esp + BRESENHAM.bi]	; d +=	bi
	add	edi,	ecx	; y +=	yi

	; rysuj linię
	jmp	.loop_y

.end:
	; usuń zmienne lokalne
	add	esp,	BRESENHAM.SIZE

	; przywróć oryginalne rejestry
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax

	; powrót z procedury
	ret
