;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

;===============================================================================
kernel_init_network:
	; przeszukaj magistrale PCI za kontrolerem sieci
	mov	eax,	DRIVER_PCI_CLASS_SUBCLASS_network
	call	driver_pci_find_class_and_subclass
	jc	.end	; nie znaleziono

	; pobierz producenta i model
	mov	eax,	DRIVER_PCI_REGISTER_vendor_and_device
	call	driver_pci_read

	; kontroler typu i82540EM?
	cmp	eax,	DRIVER_NIC_I82540EM_VENDOR_AND_DEVICE
	jne	.end	; nie

	; inicjalizuj kontroler
	call	driver_nic_i82540em

.end:
