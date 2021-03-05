;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

zero_microtime				dq	0x0000000000000000

zero_memory_map_address			dd	0x00000000
zero_graphics_mode_info_block_address	dd	0x00000000
zero_page_table_address			dd	0x00000000
zero_idt_table_address			dd	0x00000000

;-------------------------------------------------------------------------------
; format danych w postaci tablicy, wykorzystywany przez funkcję AH=0x42, przerwanie 0x13
; http://www.ctyme.com/intr/rb-0708.htm
;-------------------------------------------------------------------------------
; wszystkie tablice trzymamy pod pełnym adresem
align 0x04
zero_table_disk_address_packet:
					db	0x10	; rozmiar tablicy
					db	0x00	; wartość zastrzeżona
					dw	KERNEL_FILE_SIZE_bytes / 0x0200	; rozmiar kodu jądra systemu w sektorach
					dw	0x0000	; przesunięcie
					dw	0x1000	; segment
					dq	((zero_end - zero) + 0x200) / 0x200	; adres LBA pierwszego sektora dołączonego pliku jądra systemu

; wyrównaj pozycję nagłówka do pełnego adresu
align	0x08,				db	0x90
zero_idt_header:
					dw	0x1000
					dq	ZERO_IDT_address

; wyrównaj rozmiar programu rozruchowego do pełnego rozmiaru sektora
align	0x0200
