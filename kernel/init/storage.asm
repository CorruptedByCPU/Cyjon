;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

kernel_init_storage:
	; sprawdź czy dostępny jest kontroler IDE
	mov	eax,	DRIVER_PCI_CLASS_SUBCLASS_ide
	call	driver_pci_find_class_and_subclass
	jc	.ide_end	; brak, np. na mojej płycie głównej

	; zarejestruj wszystkie dostępne nośniki danych
	call	driver_ide_init

.ide_end:
	; ; odszukaj kontroler AHCI na magistrali
	; mov	ax,	DRIVER_PCI_CLASS_SUBCLASS_ahci
	; call	driver_pci_find_class_and_subclass
	; jc	.end	; nie znaleziono
	;
	; ; inicjalizuj dostępne nośniki na kontrolerze AHCI
	; call	driver_ahci_init

.end:
