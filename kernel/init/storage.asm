;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

;===============================================================================
kernel_init_storage:
	; sprawdź czy dostępny jest kontroler IDE
	mov	eax,	DRIVER_PCI_CLASS_SUBCLASS_ide
	call	driver_pci_find_class_and_subclass
	jc	.no_ide	; brak

	; inicjalizuj dostępne nośniki na kontrolerze IDE
	call	driver_ide_init

.no_ide:
