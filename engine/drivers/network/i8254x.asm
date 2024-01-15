;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Driver based on BareMetal OS https://github.com/ReturnInfinity/BareMetal-OS
;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

; Use:
; nasm - http://www.nasm.us/

VARIABLE_NIC_INTEL_82540EM_CTRL				equ	0x0000	; Control Register
VARIABLE_NIC_INTEL_82540EM_CTRL_FD			equ	0x00000001	; Full-Duplex
VARIABLE_NIC_INTEL_82540EM_CTRL_LRST			equ	0x00000008	; Link Reset
VARIABLE_NIC_INTEL_82540EM_CTRL_ASDE			equ	0x00000020	; Auto-Speed Detection Enable
VARIABLE_NIC_INTEL_82540EM_CTRL_SLU			equ	0x00000040	; Set Link Up
VARIABLE_NIC_INTEL_82540EM_CTRL_ILOS			equ	0x00000080	; Invert Loss-of-Signal (LOS).
VARIABLE_NIC_INTEL_82540EM_CTRL_SPEED_BIT_8		equ	0x00000100	; Speed selection
VARIABLE_NIC_INTEL_82540EM_CTRL_SPEED_BIT_9		equ	0x00000200	; Speed selection
VARIABLE_NIC_INTEL_82540EM_CTRL_FRCSPD			equ	0x00000800	; Force Speed
VARIABLE_NIC_INTEL_82540EM_CTRL_FRCPLX			equ	0x00001000	; Force Duplex
VARIABLE_NIC_INTEL_82540EM_CTRL_SDP0_DATA		equ	0x00040000	; SDP0 Data Value
VARIABLE_NIC_INTEL_82540EM_CTRL_SDP1_DATA		equ	0x00080000	; SDP1 Data Value
VARIABLE_NIC_INTEL_82540EM_CTRL_ADVD3WUC		equ	0x00100000	; D3Cold Wakeup Capability Advertisement Enable
VARIABLE_NIC_INTEL_82540EM_CTRL_EN_PHY_PWR_MGMT		equ	0x00200000	; PHY Power-Management Enable
VARIABLE_NIC_INTEL_82540EM_CTRL_SDP0_IODIR		equ	0x00400000	; SDP0 Pin Directionality
VARIABLE_NIC_INTEL_82540EM_CTRL_SDP1_IODIR		equ	0x00800000	; SDP1 Pin Directionality
VARIABLE_NIC_INTEL_82540EM_CTRL_RST			equ	0x04000000	; Device Reset
VARIABLE_NIC_INTEL_82540EM_CTRL_RFCE			equ	0x08000000	; Receive Flow Control Enable
VARIABLE_NIC_INTEL_82540EM_CTRL_TFCE			equ	0x10000000	; Transmit Flow Control Enable
VARIABLE_NIC_INTEL_82540EM_CTRL_VME			equ	0x40000000	; VLAN Mode Enable
VARIABLE_NIC_INTEL_82540EM_CTRL_PHY_RST			equ	0x80000000	; PHY Reset

VARIABLE_NIC_INTEL_82540EM_STATUS			equ	0x0008	; Device Status Register
VARIABLE_NIC_INTEL_82540EM_EERD				equ	0x0014	; EEPROM Read
VARIABLE_NIC_INTEL_82540EM_CTRLEXT			equ	0x0018	; Extended Control Register
VARIABLE_NIC_INTEL_82540EM_MDIC				equ	0x0020	; MDI Control Register
VARIABLE_NIC_INTEL_82540EM_FCAL				equ	0x0028	; Flow Control Address Low
VARIABLE_NIC_INTEL_82540EM_FCAH				equ	0x002C	; Flow Control Address High
VARIABLE_NIC_INTEL_82540EM_FCT				equ	0x0030	; Flow Control Type
VARIABLE_NIC_INTEL_82540EM_VET				equ	0x0038	; VLAN Ether Type
VARIABLE_NIC_INTEL_82540EM_ICR				equ	0x00C0	; Interrupt Cause Read
VARIABLE_NIC_INTEL_82540EM_ITR				equ	0x00C4	; Interrupt Throttling Register
VARIABLE_NIC_INTEL_82540EM_ICS				equ	0x00C8	; Interrupt Cause Set Register
VARIABLE_NIC_INTEL_82540EM_IMS				equ	0x00D0	; Interrupt Mask Set/Read Register
VARIABLE_NIC_INTEL_82540EM_IMC				equ	0x00D8	; Interrupt Mask Clear

VARIABLE_NIC_INTEL_82540EM_RCTL				equ	0x0100	; Receive Control Register
VARIABLE_NIC_INTEL_82540EM_RCTL_EN			equ	0x00000002	; Receiver Enable
VARIABLE_NIC_INTEL_82540EM_RCTL_SBP			equ	0x00000004	; Store Bad Packets
VARIABLE_NIC_INTEL_82540EM_RCTL_UPE			equ	0x00000008	; Unicast Promiscuaus Enabled
VARIABLE_NIC_INTEL_82540EM_RCTL_MPE			equ	0x00000010	; Multicast Promiscuous Enabled
VARIABLE_NIC_INTEL_82540EM_RCTL_LPE			equ	0x00000020	; Long Packet Reception Enable
VARIABLE_NIC_INTEL_82540EM_RCTL_LBM_BIT_6		equ	0x00000040	; Loopback mode
VARIABLE_NIC_INTEL_82540EM_RCTL_LBM_BIT_7		equ	0x00000080	; Loopback mode
VARIABLE_NIC_INTEL_82540EM_RCTL_RDMTS_BIT_8		equ	0x00000100	; Receive Descriptor Minimum Threshold Size
VARIABLE_NIC_INTEL_82540EM_RCTL_RDMTS_BIT_9		equ	0x00000200	; Receive Descriptor Minimum Threshold Size
VARIABLE_NIC_INTEL_82540EM_RCTL_MO_BIT_12		equ	0x00001000	; Multicast Offset
VARIABLE_NIC_INTEL_82540EM_RCTL_MO_BIT_13		equ	0x00002000	; Multicast Offset
VARIABLE_NIC_INTEL_82540EM_RCTL_BAM			equ	0x00008000	; Broadcast Accept Mode
VARIABLE_NIC_INTEL_82540EM_RCTL_BSIZE_BIT_16		equ	0x00010000	; Receive Buffer Size
VARIABLE_NIC_INTEL_82540EM_RCTL_BSIZE_BIT_17		equ	0x00020000	; Receive Buffer Size
VARIABLE_NIC_INTEL_82540EM_RCTL_VFE			equ	0x00040000	; VLAN Filter Enable
VARIABLE_NIC_INTEL_82540EM_RCTL_CFIEN			equ	0x00080000	; Canonical Form Indicator Enable
VARIABLE_NIC_INTEL_82540EM_RCTL_CFI			equ	0x00100000	; Canonical Form Indicator bit value
VARIABLE_NIC_INTEL_82540EM_RCTL_DPF			equ	0x00400000	; Discard Pause Frames
VARIABLE_NIC_INTEL_82540EM_RCTL_PMCF			equ	0x00800000	; Pass MAC Control Frames
VARIABLE_NIC_INTEL_82540EM_RCTL_BSEX			equ	0x02000000	; Buffer Size Extension
VARIABLE_NIC_INTEL_82540EM_RCTL_SECRC			equ	0x04000000	; Strip Ethernet CRC from incoming packet

VARIABLE_NIC_INTEL_82540EM_RDTR2			equ	0x0108	; RX Delay Timer Register
VARIABLE_NIC_INTEL_82540EM_RDBAL2			equ	0x0110	; RX Descriptor Base Address Low
VARIABLE_NIC_INTEL_82540EM_RDBAH2			equ	0x0114	; RX Descriptor Base Address High
VARIABLE_NIC_INTEL_82540EM_RDLEN2			equ	0x0118	; RX Descriptor Length
VARIABLE_NIC_INTEL_82540EM_RDH2				equ	0x0120	; RDH for i82542
VARIABLE_NIC_INTEL_82540EM_RDT2				equ	0x0128	; RDT for i82542
VARIABLE_NIC_INTEL_82540EM_FCTTV			equ	0x0170	; Flow Control Transmit Timer Value

VARIABLE_NIC_INTEL_82540EM_TXCW				equ	0x0178	; Transmit Configuration Word
VARIABLE_NIC_INTEL_82540EM_TXCW_TXCONFIGWORD_BIT_5	equ	0x00000020	; Full Duplex
VARIABLE_NIC_INTEL_82540EM_TXCW_TXCONFIGWORD_BIT_6	equ	0x00000040	; Half Duplex
VARIABLE_NIC_INTEL_82540EM_TXCW_TXCONFIGWORD_BIT_7	equ	0x00000080	; Pause
VARIABLE_NIC_INTEL_82540EM_TXCW_TXCONFIGWORD_BIT_8	equ	0x00000100	; Pause
VARIABLE_NIC_INTEL_82540EM_TXCW_TXCONFIGWORD_BIT_12	equ	0x00001000	; Remote fault indication
VARIABLE_NIC_INTEL_82540EM_TXCW_TXCONFIGWORD_BIT_13	equ	0x00002000	; Remote fault indication
VARIABLE_NIC_INTEL_82540EM_TXCW_TXCONFIGWORD_BIT_15	equ	0x00008000	; Next page request
VARIABLE_NIC_INTEL_82540EM_TXCW_TXCONFIGWORD		equ	0x40000000	; Transmit Config Control bit
VARIABLE_NIC_INTEL_82540EM_TXCW_ANE			equ	0x80000000	; Auto-Negotiation Enable

VARIABLE_NIC_INTEL_82540EM_RXCW				equ	0x0180	; Receive Configuration Word

VARIABLE_NIC_INTEL_82540EM_TCTL				equ	0x0400	; Transmit Control Register
VARIABLE_NIC_INTEL_82540EM_TCTL_EN			equ	0x00000002	; Transmit Enable
VARIABLE_NIC_INTEL_82540EM_TCTL_PSP			equ	0x00000008	; Pad Short Packets
VARIABLE_NIC_INTEL_82540EM_TCTL_CT_BIT_4		equ	0x00000010	; Collision Threshold
VARIABLE_NIC_INTEL_82540EM_TCTL_CT_BIT_5		equ	0x00000020	; Collision Threshold
VARIABLE_NIC_INTEL_82540EM_TCTL_CT_BIT_6		equ	0x00000040	; Collision Threshold
VARIABLE_NIC_INTEL_82540EM_TCTL_CT_BIT_7		equ	0x00000080	; Collision Threshold
VARIABLE_NIC_INTEL_82540EM_TCTL_CT_BIT_8		equ	0x00000100	; Collision Threshold
VARIABLE_NIC_INTEL_82540EM_TCTL_CT_BIT_9		equ	0x00000200	; Collision Threshold
VARIABLE_NIC_INTEL_82540EM_TCTL_CT_BIT_10		equ	0x00000400	; Collision Threshold
VARIABLE_NIC_INTEL_82540EM_TCTL_CT_BIT_11		equ	0x00000800	; Collision Threshold	
VARIABLE_NIC_INTEL_82540EM_TCTL_COLD_BIT_12		equ	0x00001000	; Collision Distance
VARIABLE_NIC_INTEL_82540EM_TCTL_COLD_BIT_13		equ	0x00002000	; Collision Distance
VARIABLE_NIC_INTEL_82540EM_TCTL_COLD_BIT_14		equ	0x00004000	; Collision Distance
VARIABLE_NIC_INTEL_82540EM_TCTL_COLD_BIT_15		equ	0x00008000	; Collision Distance
VARIABLE_NIC_INTEL_82540EM_TCTL_COLD_BIT_16		equ	0x00010000	; Collision Distance
VARIABLE_NIC_INTEL_82540EM_TCTL_COLD_BIT_17		equ	0x00020000	; Collision Distance
VARIABLE_NIC_INTEL_82540EM_TCTL_COLD_BIT_18		equ	0x00040000	; Collision Distance
VARIABLE_NIC_INTEL_82540EM_TCTL_COLD_BIT_19		equ	0x00080000	; Collision Distance
VARIABLE_NIC_INTEL_82540EM_TCTL_COLD_BIT_20		equ	0x00100000	; Collision Distance
VARIABLE_NIC_INTEL_82540EM_TCTL_COLD_BIT_21		equ	0x00200000	; Collision Distance
VARIABLE_NIC_INTEL_82540EM_TCTL_SWXOFF			equ	0x00400000	; Software OFF Transmission
VARIABLE_NIC_INTEL_82540EM_TCTL_RTLC			equ	0x01000000	; Re-transmit on Late Collision
VARIABLE_NIC_INTEL_82540EM_TCTL_NRTU			equ	0x02000000	; No Re-transmit on underrun (82544GC/EI only)

VARIABLE_NIC_INTEL_82540EM_TIPG				equ	0x0410	; Transmit Inter Packet Gap
VARIABLE_NIC_INTEL_82540EM_TIPG_IPGT_BIT_0		equ	0x00000001	; IPG Transmit Time
VARIABLE_NIC_INTEL_82540EM_TIPG_IPGT_BIT_1		equ	0x00000002	; IPG Transmit Time
VARIABLE_NIC_INTEL_82540EM_TIPG_IPGT_BIT_2		equ	0x00000004	; IPG Transmit Time
VARIABLE_NIC_INTEL_82540EM_TIPG_IPGT_BIT_3		equ	0x00000008	; IPG Transmit Time
VARIABLE_NIC_INTEL_82540EM_TIPG_IPGT_BIT_4		equ	0x00000010	; IPG Transmit Time
VARIABLE_NIC_INTEL_82540EM_TIPG_IPGT_BIT_5		equ	0x00000020	; IPG Transmit Time
VARIABLE_NIC_INTEL_82540EM_TIPG_IPGT_BIT_6		equ	0x00000040	; IPG Transmit Time
VARIABLE_NIC_INTEL_82540EM_TIPG_IPGT_BIT_7		equ	0x00000080	; IPG Transmit Time
VARIABLE_NIC_INTEL_82540EM_TIPG_IPGT_BIT_8		equ	0x00000100	; IPG Transmit Time
VARIABLE_NIC_INTEL_82540EM_TIPG_IPGT_BIT_9		equ	0x00000200	; IPG Transmit Time
VARIABLE_NIC_INTEL_82540EM_TIPG_IPGR1_BIT_10		equ	0x00000400	; IPG Receive Time 1
VARIABLE_NIC_INTEL_82540EM_TIPG_IPGR1_BIT_11		equ	0x00000800	; IPG Receive Time 1
VARIABLE_NIC_INTEL_82540EM_TIPG_IPGR1_BIT_12		equ	0x00001000	; IPG Receive Time 1
VARIABLE_NIC_INTEL_82540EM_TIPG_IPGR1_BIT_13		equ	0x00002000	; IPG Receive Time 1
VARIABLE_NIC_INTEL_82540EM_TIPG_IPGR1_BIT_14		equ	0x00004000	; IPG Receive Time 1
VARIABLE_NIC_INTEL_82540EM_TIPG_IPGR1_BIT_15		equ	0x00008000	; IPG Receive Time 1
VARIABLE_NIC_INTEL_82540EM_TIPG_IPGR1_BIT_16		equ	0x00010000	; IPG Receive Time 1
VARIABLE_NIC_INTEL_82540EM_TIPG_IPGR1_BIT_17		equ	0x00020000	; IPG Receive Time 1
VARIABLE_NIC_INTEL_82540EM_TIPG_IPGR1_BIT_18		equ	0x00040000	; IPG Receive Time 1
VARIABLE_NIC_INTEL_82540EM_TIPG_IPGR1_BIT_19		equ	0x00080000	; IPG Receive Time 1
VARIABLE_NIC_INTEL_82540EM_TIPG_IPGR2_BIT_20		equ	0x00100000	; IPG Receive Time 2
VARIABLE_NIC_INTEL_82540EM_TIPG_IPGR2_BIT_21		equ	0x00200000	; IPG Receive Time 2
VARIABLE_NIC_INTEL_82540EM_TIPG_IPGR2_BIT_22		equ	0x00400000	; IPG Receive Time 2
VARIABLE_NIC_INTEL_82540EM_TIPG_IPGR2_BIT_23		equ	0x00800000	; IPG Receive Time 2
VARIABLE_NIC_INTEL_82540EM_TIPG_IPGR2_BIT_24		equ	0x01000000	; IPG Receive Time 2
VARIABLE_NIC_INTEL_82540EM_TIPG_IPGR2_BIT_25		equ	0x02000000	; IPG Receive Time 2
VARIABLE_NIC_INTEL_82540EM_TIPG_IPGR2_BIT_26		equ	0x04000000	; IPG Receive Time 2
VARIABLE_NIC_INTEL_82540EM_TIPG_IPGR2_BIT_27		equ	0x08000000	; IPG Receive Time 2
VARIABLE_NIC_INTEL_82540EM_TIPG_IPGR2_BIT_28		equ	0x10000000	; IPG Receive Time 2
VARIABLE_NIC_INTEL_82540EM_TIPG_IPGR2_BIT_29		equ	0x20000000	; IPG Receive Time 2

VARIABLE_NIC_INTEL_82540EM_TDBAL2			equ	0x0420	; TX Descriptor Base Address Low
VARIABLE_NIC_INTEL_82540EM_TDBAH2			equ	0x0424	; TX Descriptor Base Address Low
VARIABLE_NIC_INTEL_82540EM_TDLEN2			equ	0x0428	; TX Descriptor Length
VARIABLE_NIC_INTEL_82540EM_TDH2				equ	0x0430	; TDH for i82542
VARIABLE_NIC_INTEL_82540EM_TDT2				equ	0x0438	; TDT for i82542
VARIABLE_NIC_INTEL_82540EM_LEDCTL			equ	0x0E00	; LED Control
VARIABLE_NIC_INTEL_82540EM_PBA				equ	0x1000	; Packet Buffer Allocation
VARIABLE_NIC_INTEL_82540EM_RDBAL			equ	0x2800	; RX Descriptor Base Address Low
VARIABLE_NIC_INTEL_82540EM_RDBAH			equ	0x2804	; RX Descriptor Base Address High
VARIABLE_NIC_INTEL_82540EM_RDLEN			equ	0x2808	; RX Descriptor Length
VARIABLE_NIC_INTEL_82540EM_RDH				equ	0x2810	; RX Descriptor Head
VARIABLE_NIC_INTEL_82540EM_RDT				equ	0x2818	; RX Descriptor Tail
VARIABLE_NIC_INTEL_82540EM_RDTR				equ	0x2820	; RX Delay Timer Register
VARIABLE_NIC_INTEL_82540EM_RXDCTL			equ	0x3828	; RX Descriptor Control
VARIABLE_NIC_INTEL_82540EM_RADV				equ	0x282C	; RX Int. Absolute Delay Timer
VARIABLE_NIC_INTEL_82540EM_RSRPD			equ	0x2C00	; RX Small Packet Detect Interrupt
VARIABLE_NIC_INTEL_82540EM_TXDMAC			equ	0x3000	; TX DMA Control
VARIABLE_NIC_INTEL_82540EM_TDBAL			equ	0x3800	; TX Descriptor Base Address Low
VARIABLE_NIC_INTEL_82540EM_TDBAH			equ	0x3804	; TX Descriptor Base Address High
VARIABLE_NIC_INTEL_82540EM_TDLEN			equ	0x3808	; TX Descriptor Length
VARIABLE_NIC_INTEL_82540EM_TDH				equ	0x3810	; TX Descriptor Head
VARIABLE_NIC_INTEL_82540EM_TDT				equ	0x3818	; TX Descriptor Tail
VARIABLE_NIC_INTEL_82540EM_TIDV				equ	0x3820	; TX Interrupt Delay Value
VARIABLE_NIC_INTEL_82540EM_TXDCTL			equ	0x3828	; TX Descriptor Control
VARIABLE_NIC_INTEL_82540EM_TADV				equ	0x382C	; TX Absolute Interrupt Delay Value
VARIABLE_NIC_INTEL_82540EM_TSPMT			equ	0x3830	; TCP Segmentation Pad & Min Threshold
VARIABLE_NIC_INTEL_82540EM_RXCSUM			equ	0x5000	; RX Checksum Control
VARIABLE_NIC_INTEL_82540EM_MTA				equ	0x5200	; Multicast Table Array
VARIABLE_NIC_INTEL_82540EM_RA				equ	0x5400	; Receive Address

struc	NIC_MAC_ADDRESS
	.0	resb	1
	.1	resb	1
	.2	resb	1
	.3	resb	1
	.4	resb	1
	.5	resb	1
endstruc

; 64 Bitowy kod programu
[BITS 64]

cyjon_network_i8254x_init:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rdx
	push	rsi
	push	r8
	push	r9
	push	r11

	xor	rax,	rax

	; pobierz adres przestrzeni pamięci do zarządzania kartą sieciową
	mov	dl,	0x04	; BAR0
	call	cyjon_pci_read

	; czy adres jest 64 bitowy?
	bt	eax,	2
	jnc	.no

	; zachowaj młodszą część adresu
	push	rax

	; pobierz starszą część
	mov	dl,	0x05	; BAR1
	call	cyjon_pci_read

	; połącz z młodszą częścią adresu
	mov	dword [rsp + VARIABLE_QWORD_HIGH],	eax

	; pobierz pełny adres 64 bitowy
	pop	rax

.no:
	; wyrównaj do pełnego słowa
	and	al,	0xF0
	mov	qword [variable_network_i8254x_base_address],	rax

	; zachowaj numer szyny i urządzenia
	push	rbx
	push	rcx

	; udostępnij przestrzeń pamięci
	mov	rbx,	3	; flagi: 4 KiB, Administrator, Odczyt/Zapis, Dostępna
	mov	rcx,	32	; dokumentacja, strona: 88/410, tabelka: 4-2 // The memory register space is 128K bytes. //
	; załaduj adres fizyczny/logiczny tablicy PML4 jądra
	mov	r11,	cr3
	; mapuj opisaną przestrzeń fizyczną
	call	cyjon_page_map_physical_area

	; przywróć numer szyny i urządzenia
	pop	rcx
	pop	rbx

	; pobierz numer przerwania sprzętowego
	mov	dl,	0x0F	; IRQ
	call	cyjon_pci_read
	; zapamiętaj
	mov	byte [variable_network_i8254x_irq],	al

	; włącz PCI Bus Mastering
	; dokumentacja, strona: 91/410, tabelka: 4-3
	; // Enable Mastering. Ethernet controller in PCI-X   //
	; // mode is permitted to initiate a split completion //
	; // transaction regardless of the state of this bit. //
	mov	dl,	0x01	; Command Register
	call	cyjon_pci_read
	bts	eax,	2	; Enable Mastering
	call	cyjon_pci_write

	; pobierz adres MAC
	mov	rsi,	qword [variable_network_i8254x_base_address]
	mov	eax,	dword [rsi + VARIABLE_NIC_INTEL_82540EM_RA]

	; brak danych?
	cmp	eax,	VARIABLE_EMPTY
	je	.try_via_eprom

	; zapisz adres MAC urzędzenia
	mov	dword [variable_network_i8254x_mac_address + NIC_MAC_ADDRESS.0],	eax
	mov	eax,	dword [rsi + VARIABLE_NIC_INTEL_82540EM_RA]
	mov	dword [variable_network_i8254x_mac_address + NIC_MAC_ADDRESS.4],	eax

	jmp	.done

.try_via_eprom:
	; dokumentacja, strona: 248/410, tabelka: 13-7
	mov	dword [rsi + VARIABLE_NIC_INTEL_82540EM_EERD],	0x0001
	mov	eax,	dword [rsi + VARIABLE_NIC_INTEL_82540EM_EERD]
	shr	eax,	16
	mov	word [variable_network_i8254x_mac_address + NIC_MAC_ADDRESS.0],	ax
	mov	dword [rsi + VARIABLE_NIC_INTEL_82540EM_EERD],	0x0101
	mov	eax,	dword [rsi + VARIABLE_NIC_INTEL_82540EM_EERD]
	shr	eax,	16
	mov	word [variable_network_i8254x_mac_address + NIC_MAC_ADDRESS.2],	ax
	mov	dword [rsi + VARIABLE_NIC_INTEL_82540EM_EERD],	0x0201
	mov	eax,	dword [rsi + VARIABLE_NIC_INTEL_82540EM_EERD]
	shr	eax,	16
	mov	word [variable_network_i8254x_mac_address + NIC_MAC_ADDRESS.4],	ax

.done:
	; zresetuj kontroler
	call	cyjon_network_i8254x_reset

	; wyświetl podstawową informację o karcie sieciowej
	mov	rbx,	VARIABLE_COLOR_LIGHT_GREEN
	mov	rcx,	-1
	mov	rdx,	VARIABLE_COLOR_BACKGROUND_DEFAULT
	mov	rsi,	text_caution
	call	cyjon_screen_print_string
	mov	rbx,	VARIABLE_COLOR_DEFAULT
	mov	rsi,	text_nic_i8254x
	call	cyjon_screen_print_string

	; separator adresu MAC
	mov	rsi,	text_colon

	; liczniki
	xor	r8,	r8
	xor	r9,	r9

.loop:
	; wyświetl pierwszy numer adresu MAC
	mov	rbx,	VARIABLE_COLOR_WHITE
	mov	cx,	0x0210	; podstawa 16
	movzx	rax,	byte [variable_network_i8254x_mac_address + r9]
	call	cyjon_screen_print_number

	; wyświetlono cały adres?
	inc	r9
	cmp	r9,	5
	ja	.end

	; separator
	mov	ebx,	VARIABLE_COLOR_DEFAULT
	call	cyjon_screen_print_string

	; wyświetl pozostałe numery
	jmp	.loop

.end:
	; wyświeyl informacje o przerwaniu
	mov	bl,	VARIABLE_COLOR_DEFAULT
	mov	rsi,	text_irq
	call	cyjon_screen_print_string

	; wyświetl numer przerwania
	mov	rbx,	VARIABLE_COLOR_WHITE
	mov	cx,	0x000A	; podstawa 16
	movzx	rax,	byte [variable_network_i8254x_irq]
	call	cyjon_screen_print_number

	; koniec linii
	mov	rsi,	text_paragraph
	call	cyjon_screen_print_string

	; przywróć oryginalne rejestry
	pop	r11
	pop	r9
	pop	r8
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rbx
	pop	rax

	; zwróć numer przerwania
	movzx	rax,	byte [variable_network_i8254x_irq]

	; powrót z procedury
	jmp	network_init.configured

cyjon_network_i8254x_reset:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rdi
	push	rdi

	mov	rsi,	qword [variable_network_i8254x_base_address]

	; wyłącz przerwania
	mov	eax,	VARIABLE_FULL
	mov	dword [rsi + VARIABLE_NIC_INTEL_82540EM_IMC],	eax
	; wyczyść zalegające
	mov	eax,	dword [rsi + VARIABLE_NIC_INTEL_82540EM_ICR]

	; wyłącz throttling logic
	xor	eax,	eax
	mov	dword [rsi + VARIABLE_NIC_INTEL_82540EM_ITR],	eax

	; ustaw rozmiar bufora RX na 48 KiB
	mov	eax,	0x30
	mov	dword [rsi + VARIABLE_NIC_INTEL_82540EM_PBA],	eax

	; ustaw ANE, TxConfigWord (Half/Full duplex, Next Page Request)
	mov	eax,	VARIABLE_NIC_INTEL_82540EM_TXCW_TXCONFIGWORD_BIT_5 | VARIABLE_NIC_INTEL_82540EM_TXCW_TXCONFIGWORD_BIT_6 | VARIABLE_NIC_INTEL_82540EM_TXCW_TXCONFIGWORD_BIT_15 | VARIABLE_NIC_INTEL_82540EM_TXCW_ANE
	mov	dword [rsi + VARIABLE_NIC_INTEL_82540EM_TXCW],	eax

	; wyczyść: LRST, PHY_RST, VME, ILOS, ustaw: SLU, ASDE
	mov	eax,	dword [rsi + VARIABLE_NIC_INTEL_82540EM_CTRL]
	or	eax,	VARIABLE_NIC_INTEL_82540EM_CTRL_SLU
	or	eax,	VARIABLE_NIC_INTEL_82540EM_CTRL_ASDE
	sub	eax,	VARIABLE_NIC_INTEL_82540EM_CTRL_LRST
	sub	eax,	VARIABLE_NIC_INTEL_82540EM_CTRL_ILOS
	sub	eax,	VARIABLE_NIC_INTEL_82540EM_CTRL_VME
	sub	eax,	VARIABLE_NIC_INTEL_82540EM_CTRL_PHY_RST
	mov	dword [rsi + VARIABLE_NIC_INTEL_82540EM_CTRL],	eax

	; uzupełnij Multicast Table Array
	mov	rdi,	rsi
	add	rdi,	VARIABLE_NIC_INTEL_82540EM_MTA
	mov	rax,	VARIABLE_FULL
	stosd
	stosd
	stosd
	stosd

	; przygotuj miejsce pod deskryptor pakietów przychodzących
	call	cyjon_page_allocate
	call	cyjon_page_clear

	; zapisz adres do konfiguracji karty sieciowej
	mov	qword [variable_network_i8254x_rx_descriptor],	rdi
	mov	dword [rsi + VARIABLE_NIC_INTEL_82540EM_RDBAL],	edi
	shr	rdi,	32
	mov	dword [rsi + VARIABLE_NIC_INTEL_82540EM_RDBAH],	edi

	; rozmiar deskryptora odbioru
	mov	eax,	32 * 16
	mov	dword [rsi + VARIABLE_NIC_INTEL_82540EM_RDLEN],	eax

	; aktualny wskaźnik początku w buforze odbioru
	xor	eax,	eax
	mov	dword [rsi + VARIABLE_NIC_INTEL_82540EM_RDH],	eax

	; aktualny wskaźnik końca w buforze odbioru
	mov	eax,	1
	mov	dword [rsi + VARIABLE_NIC_INTEL_82540EM_RDT],	eax

	; ustaw EN, SBP, BAM, SECRC
	mov	eax,	VARIABLE_NIC_INTEL_82540EM_RCTL_EN | VARIABLE_NIC_INTEL_82540EM_RCTL_UPE | VARIABLE_NIC_INTEL_82540EM_RCTL_SBP | VARIABLE_NIC_INTEL_82540EM_RCTL_BAM | VARIABLE_NIC_INTEL_82540EM_RCTL_SECRC
	mov	dword [rsi + VARIABLE_NIC_INTEL_82540EM_RCTL],	eax

	; przygotuj miejsce pod bufor pakietów przychodzących
	mov	rcx,	10	; 48 KiB
	call	cyjon_page_find_free_memory_physical
	; zapamiętaj adres bufora
	mov	qword [variable_network_i8254x_rx_cache],	rdi

	; zapisz adres do deskryptora
	mov	rax,	qword [variable_network_i8254x_rx_descriptor]
	mov	qword [rax],	rdi

	; przygotuj miejsce pod bufor pakietów wychodzących
	mov	rcx,	16	; 64 KiB
	call	cyjon_page_find_free_memory_physical

	; zapisz adres do konfiguracji karty sieciowej
	mov	qword [variable_network_i8254x_tx_cache],	rdi
	mov	dword [rsi + VARIABLE_NIC_INTEL_82540EM_TDBAL],	edi
	shr	rdi,	32
	mov	dword [rsi + VARIABLE_NIC_INTEL_82540EM_TDBAH],	edi

	; rozmiar deskryptora odbioru
	mov	eax,	32 * 16
	mov	dword [rsi + VARIABLE_NIC_INTEL_82540EM_TDLEN],	eax

	; aktualny wskaźnik początku w buforze odbioru
	xor	eax,	eax
	mov	dword [rsi + VARIABLE_NIC_INTEL_82540EM_TDH],	eax
	; aktualny wskaźnik końca w buforze odbioru
	mov	dword [rsi + VARIABLE_NIC_INTEL_82540EM_TDT],	eax

	; ustaw: Enabled, Pad Short Packets, 15 retries, 64-byte COLD, Re-transmit on Late Collision
	mov	eax,	VARIABLE_NIC_INTEL_82540EM_TCTL_EN | VARIABLE_NIC_INTEL_82540EM_TCTL_PSP | VARIABLE_NIC_INTEL_82540EM_TCTL_RTLC | VARIABLE_NIC_INTEL_82540EM_TCTL_COLD_BIT_18 | VARIABLE_NIC_INTEL_82540EM_TCTL_CT_BIT_4 | VARIABLE_NIC_INTEL_82540EM_TCTL_CT_BIT_5 | VARIABLE_NIC_INTEL_82540EM_TCTL_CT_BIT_6 | VARIABLE_NIC_INTEL_82540EM_TCTL_CT_BIT_7
	mov	dword [rsi + VARIABLE_NIC_INTEL_82540EM_TCTL],	eax

	; ustaw: IPGT 10, IPGR1 8, IPGR2 6
	mov	eax,	VARIABLE_NIC_INTEL_82540EM_TIPG_IPGT_BIT_1 | VARIABLE_NIC_INTEL_82540EM_TIPG_IPGT_BIT_3 | VARIABLE_NIC_INTEL_82540EM_TIPG_IPGR1_BIT_13 | VARIABLE_NIC_INTEL_82540EM_TIPG_IPGR2_BIT_21 | VARIABLE_NIC_INTEL_82540EM_TIPG_IPGR2_BIT_22
	mov	dword [rsi + VARIABLE_NIC_INTEL_82540EM_TIPG],	eax

	xor	eax,	eax
	; wyczyść Receive Delay Timer Register
	mov	dword [rsi + VARIABLE_NIC_INTEL_82540EM_RDTR],	eax
	; wyczyść Receive Interrupt Absolute Delay Timer
	mov	dword [rsi + VARIABLE_NIC_INTEL_82540EM_RADV],	eax
	; wyczyść Receive Small Packet Detect Interrupt
	mov	dword [rsi + VARIABLE_NIC_INTEL_82540EM_RSRPD],	eax

	; włącz wszystkie typy przerwań
	mov	eax,	0x0001FFFF
	mov	dword [rsi + VARIABLE_NIC_INTEL_82540EM_IMS],	eax

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

;-------------------------------------------------------------------------------
; procedura zatwierdza obsłużenie przerwania sprzętowego kontrolera sieciowego
; IN:
;	brak
; OUT:
;	rax - status
;
; pozostałe rejestry zachowane
cyjon_network_i8254x_irq:
	; zachowaj oryginalny rejestr
	push	rdi

	; pobierz status kontrolera sieci
	mov	rdi,	qword [variable_network_i8254x_base_address]
	mov	eax,	dword [rdi + VARIABLE_NIC_INTEL_82540EM_ICR]

	; przywróć oryginalny rejestr
	pop	rdi

	; powrót z procedury
	ret

;-------------------------------------------------------------------------------
; procedura wysyła przygotowany pakiet
; IN:
;	rcx - rozmiar pakietu
;	rsi - wskaźnik do pakietu
;
; OUT:
;	brak
;
; wszystkie rejestry zachowane
cyjon_network_i8254x_receive_packet:
	; zachowaj oryginalne rejestry
	push	rsi

	; pobierz rozmiar pakietu
	mov	rsi,	qword [variable_network_i8254x_rx_descriptor]
	movzx	rcx,	word [rsi + VARIABLE_QWORD_SIZE]
	push	rcx

	; pobierz pakiet z bufora
	mov	rsi,	qword [variable_network_i8254x_rx_cache]
	rep	movsb

	; poinformuj kontroler o przetworzonym pakiecie
	mov	rsi,	qword [variable_network_i8254x_base_address]
	mov	dword [rsi + VARIABLE_NIC_INTEL_82540EM_RDH],	VARIABLE_EMPTY
	mov	dword [rsi + VARIABLE_NIC_INTEL_82540EM_RDT],	VARIABLE_TRUE

	; zresetuj deskryptor rx
	mov	rcx,	qword [variable_network_i8254x_rx_cache]
	mov	dword [variable_network_i8254x_rx_descriptor],	ecx

	; przywróć oryginalne rejestry
	pop	rcx
	pop	rsi

	; powrót z procedury
	ret

;-------------------------------------------------------------------------------
; procedura wysyła przygotowany pakiet
; IN:
;	rcx - rozmiar pakietu
;	rsi - wskaźnik do pakietu
;
; OUT:
;	brak
;
; wszystkie rejestry zachowane
cyjon_network_i8254x_transmit_packet:
	; zachowaj oryginalne rejestry
	push	rax
	push	rdi

	; załaduj do bufora wskaźnik pakietu do wysłania
	mov	rdi,	qword [variable_network_i8254x_tx_cache]
	mov	rax,	rsi
	stosq

	; załaduj rozmiar pakietu
	mov	rax,	rcx
	bts	rax,	24	; EOP
	bts	rax,	25	; IFCS
	bts	rax,	27	; RS
	stosq


	mov	rdi,	qword [variable_network_i8254x_base_address]
	xor	rax,	rax
	mov	dword [rdi + VARIABLE_NIC_INTEL_82540EM_TDH],	eax
	add	eax,	1
	mov	dword [rdi + VARIABLE_NIC_INTEL_82540EM_TDT],	eax

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rax

	; powrót z procedury
	ret
