; Configure the default AT89LP51RC2 in fast mode with biderectional ports

$NOLIST
$MODLP51RC2
$LIST

loadbyte mac
    mov dptr, #%0
    mov a, #%1
    movx @dptr, a
endmac

org 0000H
    ljmp myprogram

; When using a 22.1184MHz crystal in fast mode
; one cycle takes 1.0/22.1184MHz = 45.21123 ns
; In compatibility mode, this takes 45.21123 ns * 12 = 540.4 ns
WaitHalfSec:
    mov R2, #89
L3: mov R1, #250
L2: mov R0, #166
L1: djnz R0, L1 ; 3 cycles->3*45.21123ns*166=22.51519us
    djnz R1, L2 ; 22.51519us*250=5.629ms
    djnz R2, L3 ; 5.629ms*89=0.5s (approximately)
    ret

myprogram:
    mov SP, #7FH
    mov P3M0, #0 ; Configure P3 in bidirectional mode
    mov P3M1, #0 ; Configure P3 in bidirectional mode

	; Configure the 'fuses' to run in fast mode.  This becomes
	; effective only after the next power cycle.
	
    ; Load the page buffer with the fuse values
    mov FCON, #0x08 ; Page Buffer Mapping Enabled (FPS = 1)

    ; 00 – 01H Clock Source A – CSA[0:1]
    loadbyte(0x00, 0xff) ; FFh FFh High Speed Crystal Oscillator on XTAL1A/XTAL2A (XTAL)
    loadbyte(0x01, 0xff)

    ; 02 – 03H Start-up Time – SUT[0:1]
    loadbyte(0x02, 0xff) ; FFh FFh 16 ms (XTAL)
    loadbyte(0x03, 0xff)

    ; 04H Bootloader Jump Bit 
    loadbyte(0x04, 0xff) ; FFh: Reset to user application at 0000H

    ; 05H External RAM Enable
    loadbyte(0x05, 0xff) ; FFh: External RAM enabled at reset (EXTRAM = 1)

    ; 06H Compatibility Mode
    loadbyte(0x06, 0x00) ; 00h: CPU functions is single-cycle Fast mode
    
    ; 07H ISP Enable
    loadbyte(0x07, 0xff) ; FFh: In-System Programming Enabled
    
    ; 08H X1/X2 Mode
    loadbyte(0x08, 0x00) ; 00h: X2 Mode (System clock is not divided-by-two)

    ; 09H OCD Enable
    loadbyte(0x09, 0xff) ; FFh: On-Chip Debug is Disabled

    ; 0AH User Signature Programming
    loadbyte(0x0A, 0xff) ; FFh: Programming of User Signature Disabled

    ; 0BH Tristate Ports
    loadbyte(0x0B, 0x00) ; 00h: I/O Ports start in quasi-bidirectional mode after reset

    ; 0CH Reserved
    loadbyte(0x0C, 0xff)
    
    ; 0D – 0EH Low Power Mode – LPM[0:1]
    loadbyte(0x0D, 0xff) ; FFh: Low Power Mode
    loadbyte(0x0E, 0xff)
    
    ; 0FH R1 Enable
    loadbyte(0x0F, 0xff) ; FFh: 5 Mohm resistor on XTAL1A Disabled
    
    ; 10H Oscillator Select
    loadbyte(0x10, 0xff) ; FFh: Boot from Oscillator A
    
    ; 11 – 12h Clock Source B – CSB[0:1]
    loadbyte(0x11, 0xff) ; FFh: Low Frequency Crystal Oscillator on XTAL1B/XTAL2B (XTAL)
    loadbyte(0x12, 0xff)
    
    mov FCON, #0x00 ; Page Buffer Mapping Disabled (FPS = 0)
    
    orl EECON, #0b01000000 ; Enable auto-erase on next write sequence  
    ; Launch the programming by writing the data sequence 54H followed
    ; by A4H to FCON register.
    mov FCON, #0x54
    mov FCON, #0xA4
    ; If launched from internal memory, the CPU idles until programming completes.
loop:    
    mov a, FCON
    jb acc.0, loop

    mov FCON, #0x00 ; Page Buffer Mapping Disabled (FPS = 0)
	anl EECON, #0b10111111 ; Disable auto-erase
    
    ; 'blink' LED to indicate sequence is complete.  To switch to fast mode
    ; a power cycle is required.   
M0:
    cpl P3.7
    lcall WaitHalfSec
    sjmp M0

END
