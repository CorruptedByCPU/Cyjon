;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

; Use:
; nasm - http://www.nasm.us/

variable_video_mode_semaphore	db	VARIABLE_FALSE

; tablice wyrównaj do pełnego adresu
align 0x0100

variable_vga_info_block		times	256	db	VARIABLE_EMPTY

; tablice wyrównaj do pełnego adresu
align 0x0100

variable_mode_info_block	times	512	db	VARIABLE_EMPTY

; 16 Bitowy kod programu
[BITS 16]

stage2_change_graphics_mode:
	; pobierz informacje o SuperVGA
	mov	ax,	0x4F00
	mov	di,	variable_vga_info_block
	int	0x10

	; SuperVGA dostępne i informacje pobrane bezbłędnie?
	cmp	ax,	0x004F
	jne	.error

	; pobierz wskaźnik do tablicy dostępnych trybów
	mov	esi,	dword [di + STRUCTURE_VGA_INFO_BLOCK.VideoModePtr]

	; będziemy sprawdzać kolejne tryby pracy w poszukiwaniu nas interesującego

	; informacje o trybie zapisuj tutaj
	mov	di,	variable_mode_info_block

.check_mode:
	; koniec dostępnych trybów pracy?
	cmp	word [si],	VARIABLE_FULL
	je	.error	; nie znaleziono interesującego nas trybu

	; pobierz informacje o trybie pracy
	mov	ax,	0x4F01
	mov	cx,	word [si]
	int	0x10

	; pobrano informacje?
	cmp	ah,	0x00
	jne	.error

	; sprawdź czy szerokość ekranu 800px
	cmp	word [di + STRUCTURE_MODE_INFO_BLOCK.XResolution],	VARIABLE_SCREEN_VIDEO_WIDTH
	jne	.continue

	; sprawdź czy wysokość ekranu 600px
	cmp	word [di + STRUCTURE_MODE_INFO_BLOCK.YResolution],	VARIABLE_SCREEN_VIDEO_HEIGHT
	jne	.continue

	; błębokość kolorów 32 bity?
	cmp	byte [di + STRUCTURE_MODE_INFO_BLOCK.BitsPerPixel],	32
	je	.found

.continue:
	; następny rekord
	add	si,	0x02

	; kontynuuj
	jmp	.check_mode

.found:
	; przełącz tryb graficzny
	mov	ax,	0x4F02
	mov	bx,	word [si]
	or	bx,	0x4000	; liniowa przestrzeń pamięci
	int	0x10

	; tryb graficzny włączony
	mov	byte [variable_video_mode_semaphore],	VARIABLE_TRUE

.error:
	; powrót z procedury
	ret
