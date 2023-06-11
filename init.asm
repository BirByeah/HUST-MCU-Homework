;------------------------------------
;-  Generated Initialization File  --
;------------------------------------

$include (C8051F310.inc)

public  Init_Device

INIT SEGMENT CODE
    rseg INIT

; Peripheral specific initialization functions,
; Called from the Init_Device label
PCA_Init:
    anl  PCA0MD,    #0BFh
    mov  PCA0MD,    #000h
    ret

Timer_Init:
    mov  TCON,      #001h
    mov  TMOD,      #011h
    mov  CKCON,     #002h
    mov  TL1,       #083h
    mov  TH1,       #086h
    mov  TMR2RLL,   #008h
    mov  TMR2RLH,   #0F6h
    mov  TMR2L,     #008h
    mov  TMR2H,     #0F6h
    mov  TMR3RLL,   #008h
    mov  TMR3RLH,   #0F6h
    mov  TMR3L,     #008h
    mov  TMR3H,     #0F6h
    ret

ADC_Init:
    mov  AMX0P,     #012h
    mov  AMX0N,     #01Fh
    mov  ADC0CF,    #0FCh
    mov  ADC0CN,    #080h
    ret

Voltage_Reference_Init:
    mov  REF0CN,    #008h
    ret

Port_IO_Init:
    ; P0.0  -  Unassigned,  Push-Pull,  Digital
    ; P0.1  -  Unassigned,  Open-Drain, Digital
    ; P0.2  -  Unassigned,  Open-Drain, Digital
    ; P0.3  -  Unassigned,  Open-Drain, Digital
    ; P0.4  -  Unassigned,  Open-Drain, Digital
    ; P0.5  -  Unassigned,  Open-Drain, Digital
    ; P0.6  -  Unassigned,  Push-Pull,  Digital
    ; P0.7  -  Unassigned,  Push-Pull,  Digital

    ; P1.0  -  Unassigned,  Push-Pull,  Digital
    ; P1.1  -  Unassigned,  Push-Pull,  Digital
    ; P1.2  -  Unassigned,  Push-Pull,  Digital
    ; P1.3  -  Unassigned,  Push-Pull,  Digital
    ; P1.4  -  Unassigned,  Push-Pull,  Digital
    ; P1.5  -  Unassigned,  Push-Pull,  Digital
    ; P1.6  -  Unassigned,  Push-Pull,  Digital
    ; P1.7  -  Unassigned,  Push-Pull,  Digital
    ; P2.0  -  Unassigned,  Open-Drain, Digital
    ; P2.1  -  Unassigned,  Open-Drain, Digital
    ; P2.2  -  Unassigned,  Open-Drain, Digital
    ; P2.3  -  Unassigned,  Open-Drain, Digital

    mov  P3MDIN,    #0FBh
    mov  P0MDOUT,   #0C1h
    mov  P1MDOUT,   #0FFh
    mov  P3MDOUT,   #002h
    mov  XBR1,      #040h
    ret

Interrupts_Init:
    mov  IP,        #001h
    mov  EIE1,      #008h
    mov  IE,        #08Bh
    ret

; Initialization function for device,
; Call Init_Device from your main program
Init_Device:
    lcall PCA_Init
    lcall Timer_Init
    lcall ADC_Init
    lcall Voltage_Reference_Init
    lcall Port_IO_Init
    lcall Interrupts_Init
    ret

end
