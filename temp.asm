; ;------------------------------------
; ;-  Generated Initialization File  --
; ;------------------------------------

; $include (C8051F310.inc)

; // VARIABLES AND ITS DESCRIPTIONS
; INFO    DATA    030H    // 0~3 bit:freq, 4 bit:direction
; // 0 FOR CLOCKWISE(CW), 1 OTHERWISE(ACW)
; REAL    DATA    031H    // CURRENT POSITION
; // VALUE IS 0000 0011B INITIALLY
; // KEEP ON LEFT SHIFTING
; BUTT    DATA    032H    // PRESSED BUTTON
; // FF IF NO BUTTON
; SORS    DATA    033H    // SETTING OR SHINING
; // 0 FOR SETTING, 1 FOR SHINING

; ORG     0000H
; LJMP    INIT
; ORG     000BH
; LJMP    Timer0_Interupt
; ORG     002BH
; LJMP    Timer2_Interupt
; ORG     0100H
; INIT:
;     LCALL   Init_Device
;     MOV     SP,     #060H
;     MOV     INFO,   #001H   // CW 1
;     MOV     REAL,   #00CH   // AB 0000 0011B
;     MOV     BUTT,   #0FFH
;     MOV     SORS,   #000H
;     MOV     DPL,    #000H
;     MOV     DPH,    #010H   // POINT TO TIME DATA
; MAIN:
;     LCALL   Welcome_action
;     LCALL   Setting

; PCA_Init:
;     ANL  PCA0MD,    #0BFH
;     MOV  PCA0MD,    #000H
;     RET

; Timer_Init:
;     MOV  TCON,      #001H    // IE1 level trigger
;     MOV  TMOD,      #021H    // 8 bit auto timer1, 16 bit timer0
;     MOV  CKCON,     #032H    // 2us ONE INC FOR T0/T1, 1/24.5 FOR T2
;     //SETB
;     RET

; Port_IO_Init:
;     MOV  P0MDOUT,   #0FFh
;     MOV  P1MDOUT,   #0FFh
;     MOV  P2MDOUT,   #0FFh
;     MOV  P3MDOUT,   #01Fh
;     MOV  XBR1,      #040h
;     RET

; Interrupts_Init:
;     MOV  IP,        #001h    //IE0 high priority
;     MOV  IE,        #0ABh    //EA ET2 ET1 ET0 EX0
;     RET

; Init_Device:
;     LCALL PCA_Init
;     LCALL Timer_Init
;     LCALL Port_IO_Init
;     LCALL Interrupts_Init
;     RET

; Welcome_action:
;     MOV     P0,     #000H    // SELECT NIXIE TUBE 0
;     MOV     P1,     #0FCH    // LIGHT UP ABCDEF
;     MOV     TL0,    #017H
;     MOV     TH0,    #0FCH    // 1000, 2s
;     SETB    TR0              // START T0
;     JB      TR0,    $
;     MOV     P1,     #000H    // NO LIGHT
;     SETB    P3.1
;     MOV     TL0,    #005H
;     MOV     TH0,    #0FFH    // 250, 0.5s
;     SETB    TR0              // START T0
;     JB      TR0,    $
;     RET                      // WELCOME DONE, GO SETTING

; Setting:
; FIRST_ROW:
;     MOV     P2,     #0FEH    // SET K0 ROW
;     MOV     A,      P2
;     XRL     A,      #0FEH
;     ANL     A,      #0F0H
;     CJNE    A,      #000H,  FIRST_ROW_BUTTONS
;     LJMP    SECOND_ROW
; FIRST_ROW_BUTTONS:
;     JB      ACC.4,  K0
;     JB      ACC.5,  K4
;     JB      ACC.6,  K8
;     JB      ACC.7,  K12
; K0:
;     MOV     BUTT,   #00FH
;     LJMP    GET_BUTTON_RESULT
; K4:
;     MOV     BUTT,   #04FH
;     LJMP    GET_BUTTON_RESULT
; K8:
;     MOV     BUTT,   #08FH
;     LJMP    GET_BUTTON_RESULT
; K12:
;     MOV     BUTT,   #0CFH
;     LJMP    GET_BUTTON_RESULT
; SECOND_ROW:
;     MOV     P2,     #0FDH    // SET K1 ROW
;     MOV     A,      P2
;     XRL     A,      #0FDH
;     ANL     A,      #0F0H
;     CJNE    A,      #000H,  SECOND_ROW_BUTTONS
;     LJMP    THIRD_ROW
; SECOND_ROW_BUTTONS:
;     JB      ACC.4,  K1
;     JB      ACC.5,  K5
;     JB      ACC.6,  K9
;     JB      ACC.7,  K13
; K1:
;     MOV     BUTT,   #01FH
;     LJMP    GET_BUTTON_RESULT
; K5:
;     MOV     BUTT,   #05FH
;     LJMP    GET_BUTTON_RESULT
; K9:
;     MOV     BUTT,   #09FH
;     LJMP    GET_BUTTON_RESULT
; K13:
;     MOV     BUTT,   #0DFH
;     LJMP    GET_BUTTON_RESULT
; THIRD_ROW:
;     MOV     P2,     #0FBH    // SET K2 ROW
;     MOV     A,      P2
;     XRL     A,      #0FBH
;     ANL     A,      #0F0H
;     CJNE    A,      #000H,  THIRD_ROW_BUTTONS
;     LJMP    FOURTH_ROW
; THIRD_ROW_BUTTONS:
;     JB      ACC.4,  K2
;     JB      ACC.5,  K6
;     JB      ACC.6,  K10
;     JB      ACC.7,  K14
; K2:
;     MOV     BUTT,   #02FH
;     LJMP    GET_BUTTON_RESULT
; K6:
;     MOV     BUTT,   #06FH
;     LJMP    GET_BUTTON_RESULT
; K10:
;     MOV     BUTT,   #0AFH
;     LJMP    GET_BUTTON_RESULT
; K14:
;     MOV     BUTT,   #0EFH
;     LJMP    GET_BUTTON_RESULT
; FOURTH_ROW:
;     MOV     P2,     #0FBH    // SET K3 ROW
;     MOV     A,      P2
;     XRL     A,      #0FBH
;     ANL     A,      #0F0H
;     CJNE    A,      #000H,  FOURTH_ROW_BUTTONS
;     LJMP    GET_BUTTON_RESULT
; FOURTH_ROW_BUTTONS:
;     JB      ACC.4,  K3
;     JB      ACC.5,  K7
;     JB      ACC.6,  K11
;     JB      ACC.7,  K15
; K3:
;     MOV     BUTT,   #03FH
;     LJMP    GET_BUTTON_RESULT
; K7:
;     MOV     BUTT,   #07FH
;     LJMP    GET_BUTTON_RESULT
; K11:
;     MOV     BUTT,   #0BFH
;     LJMP    GET_BUTTON_RESULT
; K15:
;     MOV     BUTT,   #0FFH   // OMIT "LJMP    GET_BUTTON_RESULT"
; GET_BUTTON_RESULT:
;     CJNE    SORS,   #000H,  SHINING
;     CJNE    BUTT,   #0FFH,  FREQ_SET
;     LJMP    FIRST_ROW
; FREQ_SET:
;     //MOV     
;     LJMP    FIRST_ROW

; SHINING:
;     CJNE    SORS,   #001H,  SETTING
;     MOVC    A,      @DPTR+A      // consider substitute BUTT with A
;     //MOV     
;     //SETB    TR2

; Timer0_Interupt:
;     // USED IN WEILCOME ONLY
;     CLR     TR0
;     RETI
; Timer2_Interupt:
; ORG     1000H
; DB      173, 215, 229, 236, 240, 243, 245, 246, 247
; end
