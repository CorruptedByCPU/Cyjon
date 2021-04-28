;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

ZERO_GRAPHICS_DEPTH_bit			equ	32
ZERO_GRAPHICS_DEPTH_shift		equ	2
ZERO_GRAPHICS_MODE_clean		equ	0x8000
ZERO_GRAPHICS_MODE_linear		equ	0x4000

ZERO_GRAPHICS_RESOLUTION_list		equ	25

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
	; wyczyść przestrzeń trybu tekstowego
	mov	ax,	0x0003
	int	0x10

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
	mov	si,	zero_string_header
	call	zero_print_string
	mov	si,	zero_string_resolution
	call	zero_print_string

	; ustaw kursor na początek wtorzonej listy dostępnych rozdzielczości
	mov	ah,	0x02
	mov	dx,	0x0002
	int	0x10

	; zmień kształt kursora na "blok"
	mov	al,	0x0A
	mov	dx,	0x03D4
	out	dx,	al
	mov	al,	0x00
	inc	dx
	out	dx,	al

	; wyświetl maksymalnie N trybów
	mov	dx,	ZERO_GRAPHICS_RESOLUTION_list

	; przygotuj przestrzeń pod listę trybów
	sub	sp,	ZERO_GRAPHICS_RESOLUTION_list * 0x02
	mov	bp,	sp
	sub	bp,	0x02	; korekcja względem pętli

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

	; rozmiar scanline odpowiada szerokości w pikselach?
	mov	ax,	word [di + ZERO_STRUCTURE_GRAPHICS_MODE_INFO_BLOCK.x_resolution]
	shl	ax,	ZERO_GRAPHICS_DEPTH_shift
	cmp	ax,	word [di + ZERO_STRUCTURE_GRAPHICS_MODE_INFO_BLOCK.bytes_per_scanline]
	jne	.next	; nie

	; ustaw wskaźnik na wolny rekord
	add	bp,	0x02

	; zachowaj identyfikator rozdzielczości
	mov	ax,	word [esi]
	mov	word [bp],	ax

	; wyświetl dostępną rozdzielczość
	call	.show

	; wyświetlono N trybów graficznych?
	dec	dx
	jz	.ready	; tak

.next:
	; przesuń wskaźnik na następny wpis
	add	esi,	0x02

	; sprawdź następny tryb
	jmp	.loop

.error:
	; wyświetl komunikat błędu
	mov	si,	zero_string_error_vbe
	call	zero_print_string

	; zatrzymaj dalsze wykonywanie kodu
	jmp	$

.show:
	; zachowaj oryginalne rejestry
	push	ax
	push	si

	; szerokość w pikselaxch
	mov	ax,	word [di + ZERO_STRUCTURE_GRAPHICS_MODE_INFO_BLOCK.x_resolution]
	call	zero_print_number

	mov	al,	"x"
	call	zero_print_char

	; wysokość w pikselach
	mov	ax,	word [di + ZERO_STRUCTURE_GRAPHICS_MODE_INFO_BLOCK.y_resolution]
	call	zero_print_number

	; ustaw kursor na następną linię
	mov	si,	zero_string_new_line
	call	zero_print_string

	; przywróć oryginalne rejestry
	pop	si
	pop	ax

	; powrót z podprocedury
	ret

.select:
	; zachowaj informacje
	push	cx

	; rozpocznij od pierwszego trybu
	xor	cx,	cx

	; ustaw kursor na pierwszy element listy
	mov	ah,	0x02
	xor	dx,	dx
	int	0x10

.key:
	; pobierz klawisz od użyszkodnika
	xor	ah,	ah
	int	0x16

	; klawisz enter?
	cmp	al,	0x0D
	je	.done	; tak

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

	; następna pozycja na liście
	inc	cx

	; przesuń wskaźnik na wpis
	add	bp,	0x02

	; ustaw kursor na wybraną pozycję
	mov	ah,	0x02
	inc	dh
	int	0x10

	; kontynuuj
	jmp	.key

.done:
	; usuń zmienną lokalną
	pop	cx

	; pobierz wybrany tryb graficzny
	mov	cx,	word [bp]

	; powrót z podprocedury
	ret

.ready:
	; ustaw wskaźnik na początek listy
	mov	bp,	sp

	; wylicz ilość wyświetlonych trybów
	mov	cx,	ZERO_GRAPHICS_RESOLUTION_list
	sub	cx,	dx
	dec	cx

	; czekaj na użyszkodnika aż wybierze jeden z trybów graficznych
	call	.select

	; pobierz właściwości danego trybu graficznego
	mov	ax,	0x4F01
	push	cx
	int	0x10

	; włącz dany tryb graficzny
	mov	ax,	0x4F02
	pop	bx
	or	bx,	ZERO_GRAPHICS_MODE_linear | ZERO_GRAPHICS_MODE_clean
	int	0x10

	; operacja wykonana pomyślnie?
	test	ah,	ah
	jnz	.error	; nie
