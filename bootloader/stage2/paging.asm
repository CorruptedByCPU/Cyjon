;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

; Use:
; nasm - http://www.nasm.us/

; 32 Bitowy kod programu
[BITS 32]

stage2_paging:
	; wyczyść przestrzeń pod stronicowanie
	mov	edi,	VARIABLE_MEMORY_PAGING_ADDRESS	; adres tablic stronicowania (PML4, PML3, PML2)
	xor	eax,	eax	; wyczyść
	mov	ecx,	0x1000 * 5 / 4	; cała 32 bitowa fizyczna przestrzeń (4 GiB)
	rep	stosd	; wykonaj

	; pml4[ 0 ]
	mov	edi,	VARIABLE_MEMORY_PAGING_ADDRESS
	mov	eax,	0x11000 + 0x03	; bity Administrator, Zapis, Aktywna
	stosd	; zapisz do pml4[ 0 ]
	xor	eax,	eax	; starsza część adresu pml3
	stosd	; zapisz do pml4[ 0 ]

	; pml3[ 0 ]
	mov	edi,	VARIABLE_MEMORY_PAGING_ADDRESS + 0x1000
	mov	eax,	VARIABLE_MEMORY_PAGING_ADDRESS + 0x2000 + 0x03	; bity Administrator, Zapis, Aktywna
	stosd	; zapisz do pml3[ 0 ]
	xor	eax,	eax	; starsza część adresu pml2
	stosd	; zapisz do pml3[ 0 ]

	; pml3[ 1 ]
	mov	eax,	VARIABLE_MEMORY_PAGING_ADDRESS + 0x3008 + 0x03	; bity Administrator, Zapis, Aktywna
	stosd	; zapisz do pml3[ 1 ]
	xor	eax,	eax	; starsza część adresu pml2
	stosd	; zapisz do pml3[ 1 ]

	; pml3[ 2 ]
	mov	eax,	VARIABLE_MEMORY_PAGING_ADDRESS + 0x4010 + 0x03	; bity Administrator, Zapis, Aktywna
	stosd	; zapisz do pml3[ 2 ]
	xor	eax,	eax	; starsza część adresu pml2
	stosd	; zapisz do pml3[ 2 ]

	; pml3[ 3 ]
	mov	eax,	VARIABLE_MEMORY_PAGING_ADDRESS + 0x5018 + 0x03	; bity Administrator, Zapis, Aktywna
	stosd	; zapisz do pml3[ 3 ]
	xor	eax,	eax	; starsza część adresu pml2
	stosd	; zapisz do pml3[ 3 ]

	; pml2[ x ]
	mov	edi,	VARIABLE_MEMORY_PAGING_ADDRESS + 0x2000	; pml2[ 0 ]
	mov	eax,	0x00000000 + 0x83	; pierwsze 2 MiB pamięci fizycznej + bity "2 MiB", Administrator, Zapis, Aktywna
	mov	ecx,	512 * 4	; ilość wpisów: 512 * 2 MiB => 1 GiB * 4 = 4 GiB

.loop:
	; zapisz do pml2[ x ]
	stosd

	; zapamiętaj adres aktualnej strony
	push	eax

	; starsza część adresu strony
	xor	eax,	eax
	stosd	; zapisz do pml2[ x ]

	; przywróć adres aktualnej strony
	pop	eax

	; następny adres przestrzeni pamięci dla strony
	add	eax,	0x00200000

	; kontynuuj
	loop	.loop

	; powrót z procedury
	ret
