;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

ZERO_GRAPHICS_DEPTH_bit			equ	32
ZERO_GRAPHICS_MODE_clean		equ	0x8000
ZERO_GRAPHICS_MODE_linear		equ	0x4000

ZERO_GRAPHICS_RESOLUTION_list		equ	20

struc	ZERO_STRUCTURE_GRAPHICS_VGA_INFO_BLOCK
	.vesa_signature			resb	4
	.vesa_version			resb	2
	.oem_string_ptr			resb	4
	.capabilities			resb	4
	.video_mode_ptr			resb	4
	.total_memory			resb	2
	.reserved			resb	236
endstruc

struc	ZERO_STRUCTURE_GRAPHICS_MODE_INFO_BLOCK
	.mode_attributes		resb	2
	.win_a_attributes		resb	1
	.win_b_attributes		resb	1
	.win_granularity		resb	2
	.win_size			resb	2
	.win_a_segment			resb	2
	.win_b_segment			resb	2
	.win_func_ptr			resb	4
	.bytes_per_scanline		resb	2
	.x_resolution			resb	2
	.y_resolution			resb	2
	.x_char_size			resb	1
	.y_char_size			resb	1
	.number_of_planes		resb	1
	.bits_per_pixel			resb	1
	.number_of_banks		resb	1
	.memory_model			resb	1
	.bank_size			resb	1
	.number_of_image_pages		resb	1
	.reserved0			resb	1
	.red_mask_size			resb	1
	.red_field_position		resb	1
	.green_mask_size		resb	1
	.green_field_position		resb	1
	.blue_mask_size			resb	1
	.blue_field_position		resb	1
	.rsvd_mask_size			resb	1
	.direct_color_mode_info		resb	2
	.physical_base_address		resb	4
	.reserved1			resb	212
	.SIZE:
endstruc

;===============================================================================
zero_graphics:
	; wyrównaj adres końca mapy pamięci do pełnej strony
	call	zero_page_align_up

	; zachowaj adres tablicy GRAPHICS_MODE_INFO_BLOCK
	mov	dword [zero_graphics_mode_info_block_address],	edi

	; pobierz dostępne tryby graficzne
	mov	ax,	0x4F00
	add	edi,	ZERO_STRUCTURE_GRAPHICS_MODE_INFO_BLOCK.SIZE
	int	0x10

	; funkcja wywołana prawidłowo?
	test	ax,	0x4F00
	jnz	.error	; nie

	; wyświetl dostępne rozdzielczości
	mov	si,	zero_string_resolution
	call	zero_print_string

	; zmień kształt kursora na "blok"
	mov	al,	0x0A
	mov	dx,	0x03D4
	out	dx,	al
	mov	al,	0x00
	inc	dx
	out	dx,	al

	; wyświetl maksymalnie 19 trybów
	mov	dx,	ZERO_GRAPHICS_RESOLUTION_list

	; przygotuj przestrzeń pod listę trybów
	sub	sp,	ZERO_GRAPHICS_RESOLUTION_list * 0x02
	mov	bp,	sp

	; przeszukaj tablicę dostępnych trybów za porządanym
	mov	esi,	dword [di + ZERO_STRUCTURE_GRAPHICS_VGA_INFO_BLOCK.video_mode_ptr]

.loop:
	; koniec tablicy?
	cmp	word [esi],	0xFFFF
	je	.ready	; tak

	; pobierz właściwości danego trybu graficznego
	mov	ax,	0x4F01
	mov	cx,	word [esi]
	mov	edi,	dword [zero_graphics_mode_info_block_address]
	int	0x10

	; oczekiwana głębia kolorów?
	cmp	byte [di + ZERO_STRUCTURE_GRAPHICS_MODE_INFO_BLOCK.bits_per_pixel],	ZERO_GRAPHICS_DEPTH_bit
	jne	.next	; nie

	; zachowaj identyfikator rozdzielczości
	mov	ax,	word [esi]
	mov	word [bp],	ax

	; wyświetlono całą kolumnę trybów?
	dec	dx
	jz	.ready	; tak

	; następna pozycja
	add	bp,	0x02

	; wyświetl dostępną rozdzielczość
	call	.show

.next:
	; przesuń wskaźnik na następny wpis
	add	esi,	0x02

	; sprawdź następny tryb
	jmp	.loop

.ready:
	; koryguj na ostatnią pozycję na liście
	sub	bp,	0x02

	; wylicz ilość wyświetlonych trybów
	mov	cx,	ZERO_GRAPHICS_RESOLUTION_list
	sub	cx,	dx
	dec	cx

	; zachowaj licznik
	push	cx

	; pobierz aktualną pozycję kursora
	mov	ah,	0x03
	xor	bh,	bh	; brak strony
	int	0x10

	; zawsze pierwsza kolumna
	xor	dl,	dl

	; przywróć licznik
	mov	cx,	word [esp]

.select:
	; ustaw kursor na początek linii ostatnio wyświetlonego trybu
	mov	al,	0x0D
	call	zero_print_char

.key:
	; pobierz klawisz od użyszkodnika
	xor	ah,	ah
	int	0x16

	; klawisz enter?
	cmp	al,	0x0D
	je	.found	; tak

	; klawisz "strzałka w górę?"
	cmp	ah,	0x48
	jne	.no_arrow_up	; nie

	; kursor znajduje się już na początku listy?
	test	cx,	cx
	jz	.key	; tak, zignoruj

	; poprzednia pozycja na liście
	dec	cx

	; przesuń wskaźnik na wpis
	sub	bp,	0x02

	; ustaw kursor na wybraną pozycję
	mov	ah,	0x02
	dec	dh
	int	0x10

	; kontynuuj
	jmp	.key

.no_arrow_up:
	; klawisz "strzałka w dół"?
	cmp	ah,	0x50
	jne	.key	; nie

	; kursor znajduje się już na końcu listy?
	cmp	cx,	word [esp]
	je	.key	; tak, zignoruj

	; poprzednia pozycja na liście
	inc	cx

	; przesuń wskaźnik na wpis
	add	bp,	0x02

	; ustaw kursor na wybraną pozycję
	mov	ah,	0x02
	inc	dh
	int	0x10

	; kontynuuj
	jmp	.key

.error:
	jmp	$

	; wyświetl komunikat błędu
	mov	si,	zero_string_error_vbe
	call	zero_print_string

	; zatrzymaj dalsze wykonywanie kodu
	jmp	$

.show:
	; zachowaj oryginalne rejestry
	push	ax
	push	si

	; ustaw kursor na linię
	mov	si,	zero_string_new_line
	call	zero_print_string

	; szerokość w pikselaxch
	mov	ax,	word [di + ZERO_STRUCTURE_GRAPHICS_MODE_INFO_BLOCK.x_resolution]
	call	zero_print_number

	mov	al,	"x"
	call	zero_print_char

	; wysokość w pikselach
	mov	ax,	word [di + ZERO_STRUCTURE_GRAPHICS_MODE_INFO_BLOCK.y_resolution]
	call	zero_print_number

	; przywróć oryginalne rejestry
	pop	si
	pop	ax

	; powrót z podprocedury
	ret

.found:
	; usuń zmienne lokalne
	mov	sp,	bp

	; włącz dany tryb graficzny
	mov	ax,	0x4F02
	pop	bx
	or	bx,	ZERO_GRAPHICS_MODE_linear | ZERO_GRAPHICS_MODE_clean
	int	0x10

	; operacja wykonana pomyślnie?
	test	ah,	ah
	jnz	.error	; nie
