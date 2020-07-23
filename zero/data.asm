;===============================================================================
; Copyright (C) by blackdev.org
;===============================================================================

zero_microtime				dq	0x0000000000000000

zero_memory_map_address			dd	0x00000000
zero_graphics_mode_info_block_address	dd	0x00000000

; wyrównaj pozycję nagłówka do pełnego adresu
align	0x08,				db	0x90
zero_idt_header:
					dw	0x1000
					dq	ZERO_IDT_address

; wyrównaj rozmiar programu rozruchowego do pełnego rozmiaru sektora
align	0x0200
