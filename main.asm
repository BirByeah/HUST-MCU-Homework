$include (C8051F310.inc)
EXTRN   CODE    (Init_Device)

/* 
 * SOME NOTES:
 * R3: REAL FREQ
 * R4: BUTT TEMP
 * T0: SEG4 TIMER
 * T1: LED TIMER
 * T2: INT0 AS TIMER
 * T3: DELAY TIMER
 */

// VARIABLES AND ITS DESCRIPTIONS
NIX     DATA    P1
MATKEY  DATA    P2

BUTT    DATA    020H    // PRESSED BUTTON
// 00 IF K0 IS PRESSED
// THIS IS 20H FOR BIT ADDRESSABLE

SHAPE   DATA    021H    // SHAPE OF SNAKE
// IT IS INITIALLY 1100 0000B, AND SHOULD
// TRAVEL BETWEEN A AND P1.

T0_H    DATA    030H    // RELOAD VALUE H
T0_L    DATA    031H    // RELOAD VALUE L
BUTT_R  DATA    032H    // THE ROW FOR BUTTON
BUTT_C  DATA    033H    // THE COL FOR BUTTON
FREQ_1  DATA    034H    // NUM FOR SEG1    
FREQ_2  DATA    035H    // NUM FOR SEG2
ADC_T1H DATA    036H    // ADC TO T1 HIGH
ADC_T1L DATA    037H    // ADC TO T1 LOW
SEG0    DATA    03AH    // SEG0 SHAPE
SEG1    DATA    03BH    // SEG1 SHAPE
SEG2    DATA    03CH    // SEG2 SHAPE
SEG3    DATA    03DH    // SEG3 SHAPE
ROSIGN  DATA    026H    // LED ROTATION SIGN
STUIDL  DATA    039H    // STUID LENGTH
STUIDS  DATA    040H    // STUID START POINT

LIGHT   BIT     P0.0
KEY     BIT     P0.1
NIX_A   BIT     P0.6
NIX_B   BIT     P0.7
BEEPER	BIT		P3.1
DIN     BIT     P3.3
CLK     BIT     P3.4
STATE   BIT     F0      // GO OR STOP
// 1 FOR GO, 0 FOR STOP
PRESSED BIT     F1      // PRESSED OR NOT
// 1 FOR ANY KEY, 0 FOR NO KEY
KEYERR  BIT     02FH.0  // KEY INCORRECT
// 1 FOR INCORRECT KEY VALUE, 0 FOR OK
HZ01    BIT     02FH.1  // 0.1HZ
// 1 FOR 0.1HZ, 0 OTHERWISE
HZ01CNT BIT     02FH.2  // 0.1HZ COUNTER
// 1 FOR 1 TIMES, 0 FOR NOT STARTED
ROT_DIR BIT     02FH.3  // ROTATION DIR
// 0 FOR CLOCKWISE(CW), 1 OTHERWISE(ACW)
D_Z     BIT     02FH.4  // D OR Z
// 1 FOR DIGIT MODE(Z), 0 FOR DECIMAL MODE
SHOWMOD BIT     02FH.5  // SHOW ID MODE
// 1 FOR SHOWING, 0 OTHERWISE 

CSEG AT 0000H
ORG		0000H
LJMP    INIT

ORG     0003H
LJMP    E0_IRQ

ORG     000BH
LJMP    T0_IRQ

ORG     001BH
LJMP    T1_IRQ

ORG     0053H
LJMP    ADC_IRQ

ORG     0100H
INIT:
    LCALL   Init_Device
    CLR     EA
    CLR     TR0
    MOV     SP,     #060H
    MOV     BUTT,   #001H
    MOV     DPTR,   #TIMT   // POINT TO TIME DATA
    MOV     MATKEY, #0F0H   // OUTPUT 0, READ 1
    MOV     FREQ_1, #000H
    MOV     FREQ_2, #000H
    MOV     ADC_T1H,#083H   // 0.5S
    MOV     ADC_T1L,#063H   // 0.5S
    MOV     SHAPE,  #0C0H
    MOV     ROSIGN, #007H
    MOV     STUIDL, #16     // ID WITH SPACE
    MOV     STUIDS, #000H
	CLR		BEEPER
	CLR		LIGHT
    CLR     PRESSED
    CLR     KEYERR
    CLR     HZ01
    CLR     HZ01CNT
    CLR     ROT_DIR
    CLR     D_Z
    CLR     SHOWMOD
    
    LCALL   WELCOME
    SETB    EA
    SETB    TR1
    LCALL   LEDINIT
WORKLOOP:
    LCALL   SETTING
    LCALL   SHIFTING
    SJMP    WORKLOOP

WELCOME:
    MOV     P0,     #03FH   // SELECT NIXIE TUBE 0, TURN OFF D9
    MOV     NIX,    #0FCH   // ABCDEF ON

    LCALL   T0DL500
    LCALL   T0DL500
    LCALL   T0DL500
    LCALL   T0DL500

    MOV     NIX,    #000H   // NO LIGHT
    SETB    BEEPER			// RING
    LCALL   T0DL500
    CLR     BEEPER			// STOP RINGING
    CLR     LIGHT           // TURN ON LIGHT

    RET                     // WELCOME DONE, GO SETTING

// TO MAKE `JB      STATE,  EASYRET` RET
EASYRET:
    RET

SETTING:
    CLR     PRESSED
QUEUE_KEY:
    LCALL   GET_KEY
    JB      STATE,  EASYRET // A NEAR RET
    LCALL   NIX_DYNA		// CALL RECURRENTLY
    JNB     PRESSED,QUEUE_KEY
    MOV     R4,     BUTT
    CLR     PRESSED
    CJNE    R4,     #00AH,  KEYTYPE
KEYTYPE:
    JNC     ISFUNCK
ISDIGKEY:
    LCALL   ADDINDIG
    SJMP    SE_CALC

// FUNCTIONAL KEYS
ISFUNCK:
    CJNE    R4,     #00AH,  SETTNOTA
    LCALL   FUNCKEYA
    SJMP    SE_CALC
SETTNOTA:
    CJNE    R4,     #00BH,  SETTNOTB
    LCALL   FUNCKEYB
    SJMP    SE_CALC
SETTNOTB:
    CJNE    R4,     #00CH,  SETTNOTC
    LCALL   FUNCKEYC
    SJMP    SE_CALC
SETTNOTC:
    CJNE    R4,     #00DH,  SETTNOTD
    LCALL   FUNCKEYD
    SJMP    SE_CALC
SETTNOTD:
    CJNE    R4,     #00EH,  SETTNOTE
    LCALL   FUNCKEYE
    SJMP    SE_CALC
SETTNOTE:
    ;CJNE    R4,     #00FH,  SETFUNNO
    LCALL   FUNCKEYF
SE_CALC:
    MOV     B,      #10
    MOV     A,      FREQ_2
    MUL     AB
    
    ADD     A,      FREQ_1
    CLR     KEYERR
    JNB     D_Z,    SAVEKEYV
    // DIGIT MODE MUL 10
    MOV     B,      #10
    MUL     AB
    MOV     C,      OV
    MOV     KEYERR, C
    
SAVEKEYV:
    MOV     R3,     A       // SAVE VALUE
    // R3 GET THE REAL FREQ FROM NOW ON
    ADD     A,      ACC
    ORL     C,      KEYERR
    MOV     KEYERR, C       // C DETECT

    // WHETHER FREQ GREATER THAN 10 HZ
    CLR     C
    PUSH    ACC
    MOV     B,      R3
    MOV     A,      #100
    SUBB    A,      B
    ORL     C,      KEYERR
    MOV     KEYERR, C
    POP     ACC  

    // WHETHER FREQ GREATER THAN 0
    JNZ     FREQGT0
    // FREQ == 0
    SETB    KEYERR
    
FREQGT0:
    // LOAD THE TIMER
    MOV     DPTR,   #TIMT
    PUSH    ACC
    MOVC    A,      @A+DPTR
    MOV     T0_H,   A
    POP     ACC
    INC     A
    MOVC    A,      @A+DPTR
    MOV     T0_L,   A

    // CHECK 0.1 HZ
    CJNE    R3,     #001H,  SE_NHZ01
    SETB    HZ01
    CLR     HZ01CNT
    AJMP    SETTING
SE_NHZ01:
    CLR     HZ01

    AJMP    SETTING
SET_OVER:
    RET

SHIFTING:
	LCALL   NIX_DYNA
    JB      STATE,  SHIFTING
    RET
/*
 * GET MATRIX KEY VALUE, BUT BEFORE YOU
 * CALL THIS, CLR PRESSED! AFTER YOU CALL
 * THIS, CHECK PRESSED!
 */
GET_KEY:
    // CALL THIS RECURRENTLY
    MOV     MATKEY, #0F0H
    MOV     A,      MATKEY
    ANL     A,      #0F0H
    XRL     A,      #0F0H
    JNZ     SE_PARSE
    // NO BUTTON IS PRESSED
SE_NO_BUT:
    RET
SE_PARSE:
    LCALL   T3_DL_AS
    MOV     A,      MATKEY
    XRL     A,      #0F0H
    JZ      SE_NO_BUT
    // A BUTTON IS PRESSED!
    MOV     R2,     A
    // ROW SCAN
    // FIRST ROW
    MOV     MATKEY, #0FEH   // P2.0=0
    MOV     A,      MATKEY
    ANL     A,      #0F0H
    XRL     A,      #0F0H
    MOV     BUTT_R, #0      // FIRST ADD 0
    JNZ     SE_ROW_G
// SECOND ROW
SE_SEC_R:
    MOV     MATKEY, #0FDH   // P2.1=0
    MOV     A,      MATKEY
    ANL     A,      #0F0H
    XRL     A,      #0F0H
    MOV     BUTT_R, #1
    JNZ     SE_ROW_G
// THIRD ROW
SE_THI_R:
    MOV     MATKEY, #0FBH   // P2.2=0
    MOV     A,      MATKEY
    ANL     A,      #0F0H
    XRL     A,      #0F0H
    MOV     BUTT_R, #2
    JNZ     SE_ROW_G
// FOURTH ROW
SE_FOU_R:
    MOV     MATKEY, #0F7H   // P2.3=0
    MOV     A,      MATKEY
    ANL     A,      #0F0H
    XRL     A,      #0F0H
    MOV     BUTT_R, #3
    JNZ     SE_ROW_G
    // FAILED TO GET BUTTON VALUE :(
    LJMP    SE_NO_BUT
// GET ROW VALUE
SE_ROW_G:
    JB      ACC.4,  COL_0
    JB      ACC.5,  COL_1
    JB      ACC.6,  COL_2
    JB      ACC.7,  COL_3
COL_0:
    MOV     BUTT_C, #0
    SJMP    SE_SYNTH
COL_1:
    MOV     BUTT_C, #1
    SJMP    SE_SYNTH
COL_2:
    MOV     BUTT_C, #2
    SJMP    SE_SYNTH
COL_3:
    MOV     BUTT_C, #3
    SJMP    SE_SYNTH
// CALCULATE KEY VALUE
SE_SYNTH:
    MOV     A,      BUTT_C
    MOV     B,      #4
    MUL     AB
    ADD     A,      BUTT_R
    MOV     BUTT,   A
    SETB    PRESSED
    SETB    AD0BUSY
//    CJNE    A,      #14,    SPECIKEY
//SPECIKEY:
//    JNC     GK_SKIP
GK_WAIT:
    MOV     MATKEY, #0F0H
    MOV     A,      MATKEY
    ANL     A,      #0F0H
    XRL     A,      #0F0H
    JNZ     GK_WAIT
    LCALL   T3_DL_AS
SE_OVER:
    RET
//GK_SKIP:
//    LCALL   T3_DL_AS
//    LCALL   T3_DL_AS
//    LCALL   T3_DL_AS
//    LCALL   T3_DL_AS
//    LCALL   T3_DL_AS
//    SJMP    SE_OVER
// GET_KEY FUNCTION END

/*
 * NIXIE DYNAMICALLY DISPLAY
 * CALL THIS RECURRENTLY
 * 
 */
NIX_DYNA:
    JNB     SHOWMOD,NOSHOW
    MOV     A,      STUIDS
    
    PUSH    ACC
    MOV     DPTR,   #STUIDT
    MOVC    A,      @A+DPTR
    MOV     DPTR,   #SEGT
    MOVC    A,      @A+DPTR
    MOV     NIX,    #000H
    SETB    NIX_A           // FOURTH NIXIE 
    SETB    NIX_B           // CUBE
    MOV     NIX,    A

    POP     ACC
    INC     A
    PUSH    ACC
    MOV     DPTR,   #STUIDT
    MOVC    A,      @A+DPTR
    MOV     DPTR,   #SEGT
    MOVC    A,      @A+DPTR
    MOV     NIX,    #000H
    CLR     NIX_A           // THIRD NIXIE 
    SETB    NIX_B           // CUBE
    MOV     NIX,    A

    POP     ACC
    INC     A
    PUSH    ACC
    MOV     DPTR,   #STUIDT
    MOVC    A,      @A+DPTR
    MOV     DPTR,   #SEGT
    MOVC    A,      @A+DPTR
    MOV     NIX,    #000H
    SETB    NIX_A           // SECOND NIXIE 
    CLR     NIX_B           // CUBE
    MOV     NIX,    A

    POP     ACC
    INC     A
    MOV     DPTR,   #STUIDT
    MOVC    A,      @A+DPTR
    MOV     DPTR,   #SEGT
    MOVC    A,      @A+DPTR
    MOV     NIX,    #000H
    CLR     NIX_A           // FIRST NIXIE 
    CLR     NIX_B           // CUBE
    MOV     NIX,    A
    NOP
    NOP
    NOP
    NOP
    NOP
    MOV     NIX,    #000H
    RET

NOSHOW:
    MOV     DPTR,   #SEGT

    CLR     NIX_A           // FIRST NIXIE 
    CLR     NIX_B           // CUBE
    JB      KEYERR, NIXWRSHP
    MOV     NIX,    SHAPE
	SJMP	AFTER_FN        // FIRST NIXIE
NIXWRSHP:
    MOV     NIX,    #002H   // G ON, WRONG
	
AFTER_FN:
    MOV     A,      #010H   // 10H OFF ALL
    MOVC    A,      @A+DPTR
    MOV     NIX,    #000H
    SETB    NIX_A           // SECOND NIXIE 
    CLR     NIX_B           // CUBE
    MOV     NIX,    A

    MOV     A,      FREQ_1
    MOVC    A,      @A+DPTR
    MOV     NIX,    #000H
    CLR     NIX_A           // THIRD NIXIE 
    SETB    NIX_B           // CUBE
    JNB     D_Z,    NO_DP_D // DIGIT NO DP
    ORL     A,      #001H   // DP ON
NO_DP_D:
    MOV     NIX,    A

    MOV     A,      FREQ_2
    JNZ     NOFFZERO
    JNB     D_Z,    NOFFZERO
    MOV     A,      #010H
NOFFZERO:
    MOVC    A,      @A+DPTR
    MOV     NIX,    #000H
    SETB    NIX_A           // FOURTH NIXIE 
    SETB    NIX_B           // CUBE
    JB      D_Z,    NO_DP_Z // DIGIT NO DP
    ORL     A,      #001H   // DP ON
NO_DP_Z:
    MOV     NIX,    A
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
	
	MOV		NIX,	#000H	// TO BALANCE THE
							// BRIGHTNESS

    RET

// USE T0 TO DELAY FOR 500MS
T0DL500:
    CLR     TF0
    CLR     TR0
    MOV     TL0,    #063H
    MOV     TH0,    #083H   // 31901, 1S
    SETB    TR0             // START T0
    JNB     TF0,    $
	CLR		TF0
	CLR		TR0
    RET

// USE T3 TO DELAY FOR 10MS, FOR ANTI-SHAKING
T3_DL_AS:
    PUSH    ACC
    ANL     TMR3CN, #07BH
    ORL     TMR3CN, #004H   // START T3
T3_CHECK:
    MOV     A,      TMR3CN
    JNB     ACC.7,  T3_CHECK
	ANL     TMR3CN, #07BH
    POP     ACC
    RET

// USE T2 TO DELAY FOR 10MS, FOR ANTI-SHAKING
// THIS IS ESPECIALLY DESIGNED FOR INT0
T2_DL_AS:
    SETB    TR2
    JNB     TF2H,   $
    CLR     TF2H
    CLR     TR2
    RET

E0_IRQ:
    LCALL   T2_DL_AS
    JB      KEY,    E0_BUT  // TEST PRESS
    // THE SWITCH BUTTON IS PRESSED!
    JNB     KEY,    $
    CPL     STATE
    CPL     LIGHT
    CPL     TR0
    CPL     TR1
    LCALL   T2_DL_AS
E0_BUT:
    RETI
    
T0_IRQ:
    PUSH	ACC

    JNB     KEYERR, KEYSAFE
    // IF KEY VALUE IS WRONG, END IT
    SJMP    T0IRQEND

// IF KEY VALUE IS RIGHT
KEYSAFE:
    // CHECK 0.1 HZ
    JNB     HZ01,   T0N01HZ
    // IS 0.1 HZ
    JB      HZ01CNT,T001HZ1
    // 0.1 HZ IN HALFWAY
    SETB    HZ01CNT
    // DELETEABLE, FOR TH0=00H WHEN OV
    ;MOV     TH0,    #000H
    ;MOV     TL0,    #000H
    SJMP    T0IRQEND
// 0.1 HZ DONE
T001HZ1:
    CLR     HZ01CNT

T0N01HZ:
    MOV     A,      SHAPE
    JB      ROT_DIR,T0_ACW
T0_CW:
    RR      A
    JNB     ACC.1,  T0_CW_OK
    // G IS 1
    SETB    ACC.7
    CLR     ACC.1
T0_CW_OK:
    SJMP    T0_GIVE
T0_ACW:
    RL      A
    JNB     ACC.0,  T0_GIVE
    // DP IS 1
    SETB    ACC.2
    CLR     ACC.0
T0_GIVE:
    MOV     SHAPE,  A
    MOV     TH0,    T0_H
    MOV     TL0,    T0_L
T0IRQEND:
    POP		ACC
    RETI

ADDINDIG:
    MOV     FREQ_2, FREQ_1
    MOV     FREQ_1, BUTT
    RET

FUNCKEYA:
    CPL     D_Z
    RET

FUNCKEYB:
    CPL     ROT_DIR
    RET

FUNCKEYC:
    MOV     FREQ_1, FREQ_2
    MOV     FREQ_2, #000H
    RET

FUNCKEYD:
    MOV     FREQ_1, #000H
    MOV     FREQ_2, #000H
    RET

FUNCKEYE:
    PUSH    ACC
    PUSH    B
    PUSH    PSW
    MOV     A,      FREQ_2
    MOV     B,      #10
    MUL     AB
    ADD     A,      FREQ_1
    // CHECK IF A == 0
    JZ      FUNESHOW
    JB      D_Z,    FUNEDIGC
    DEC     A

FUNEPASS:
    MOV     B,      #10
    DIV     AB
    MOV     FREQ_2, A
    MOV     FREQ_1, B
FUNERET:
    POP     PSW
    POP     B
    POP     ACC
    RET
FUNESHOW:
    MOV     STUIDS, #000H
    SETB    SHOWMOD
    SJMP    FUNERET
FUNEDIGC:
    PUSH    ACC
    MOV     B,      #12
    SUBB    A,      B
    JC      FUNEDECE
    POP     ACC
    MOV     FREQ_2, #1
    MOV     FREQ_1, #0
    SJMP    FUNERET
FUNEDECE:
    POP     ACC
    DEC     A
    SJMP    FUNEPASS

FUNCKEYF:
    PUSH    ACC
    PUSH    B
    PUSH    PSW
    MOV     A,      FREQ_2
    MOV     B,      #10
    MUL     AB
    ADD     A,      FREQ_1
    INC     A

    JB      D_Z,    DIGCH100
    // DECIMAL CHECK 99
    CJNE    A,      #100,   FUNFCHEC
FUNFCHEC:
    JC      FUNFPASS
    // GREATER THAN PERMITTED
    JNB     D_Z,    DECSKIPC
    MOV     FREQ_2, #1
    MOV     FREQ_1, #0
DECSKIPC:
    SJMP    FUNFRET

DIGCH100:
    // DIGIT CHECK 100
    CJNE    A,      #11,   FUNFCHEC
    SJMP    FUNFRET

FUNFPASS:
    MOV     B,      #10
    DIV     AB
    MOV     FREQ_2, A
    MOV     FREQ_1, B
FUNFRET:
    POP     PSW
    POP     B
    POP     ACC
    RET

T1_IRQ:
    PUSH    ACC
    MOV     TH1,    ADC_T1H 
    MOV     TL1,    ADC_T1L
    JNB     SHOWMOD,T1NOSHOW
    INC     STUIDS
    MOV     R5,     STUIDS
    CJNE    R5,     #13,    T1IRQEND
    CLR     SHOWMOD
    MOV     STUIDS, #000H
    SJMP    T1IRQEND
T1NOSHOW:
    MOV     A,      ROSIGN
    JB      ROT_DIR,T1LEFT
    RL      A
    SJMP    T1NOSEND
T1LEFT:
    RR      A
T1NOSEND:
    MOV     ROSIGN, A
    LCALL   LEDINIT
T1IRQEND:
    POP     ACC
    RETI

ADC_IRQ:
    PUSH    ACC
    PUSH    DPL
    PUSH    DPH
    PUSH    PSW
    PUSH    B
    CLR     AD0INT
    MOV     A,      ADC0H
    SWAP    A
    ANL     A,      #00FH
    ADD     A,      #002H
    MOV     B,      #004H
    DIV     AB
    PUSH    ACC
    MOV     DPTR,   #ADCHT
    MOVC    A,      @A+DPTR
    MOV     ADC_T1H,A
    POP     ACC
    MOV     DPTR,   #ADCLT
    MOVC    A,      @A+DPTR
    MOV     ADC_T1L,A
    POP     B
    POP     PSW
    POP     DPH
    POP     DPL
    POP     ACC
    RETI

LEDINIT:
    PUSH    PSW

    MOV     C,      ROSIGN.0
    CLR     CLK
    CPL     C
    MOV     DIN,    C
    SETB    CLK

    MOV     C,      ROSIGN.1
    CLR     CLK
    CPL     C
    MOV     DIN,    C
    SETB    CLK

    MOV     C,      ROSIGN.2
    CLR     CLK
    CPL     C
    MOV     DIN,    C
    SETB    CLK

    MOV     C,      ROSIGN.3
    CLR     CLK
    CPL     C
    MOV     DIN,    C
    SETB    CLK

    MOV     C,      ROSIGN.4
    CLR     CLK
    CPL     C
    MOV     DIN,    C
    SETB    CLK

    MOV     C,      ROSIGN.5
    CLR     CLK
    CPL     C
    MOV     DIN,    C
    SETB    CLK

    MOV     C,      ROSIGN.6
    CLR     CLK
    CPL     C
    MOV     DIN,    C
    SETB    CLK

    MOV     C,      ROSIGN.7
    CLR     CLK
    CPL     C
    MOV     DIN,    C
    SETB    CLK

    POP     PSW
    RET

// TIME TABLE
SEGT:
    //      0123456789ABCDEF U
    DB      0FCH, 060H, 0DAH, 0F2H, 066H, 0B6H, 0BEH, 0E0H, 0FEH, 0F6H, 0EEH, 03EH, 09CH, 07AH, 09EH, 08EH, 000H, 07CH
TIMT:
    DW      00000H, 0609FH
    DW      03044H, 0757EH, 0981CH, 0ACE1H, 0BAB9H, 0C49DH, 0CC08H, 0D1CDH, 0D66AH, 0DA31H, 0DD57H, 0E000H, 0E249H, 0E443H, 0E5FEH, 0E785H, 0E8E0H, 0EA17H, 0EB2FH, 0EC2CH, 0ED13H, 0EDE5H, 0EEA5H, 0EF57H, 0EFFAH, 0F092H, 0F11EH, 0F1A1H, 0F21BH, 0F28EH, 0F2F9H, 0F35EH, 0F3BCH, 0F416H, 0F46AH, 0F4BAH, 0F506H, 0F54DH, 0F592H, 0F5D2H, 0F610H, 0F64BH, 0F683H, 0F6B9H, 0F6ECH, 0F71EH, 0F74DH, 0F77AH, 0F7A5H, 0F7CFH, 0F7F7H, 0F81EH, 0F843H, 0F867H, 0F889H, 0F8AAH, 0F8CBH, 0F8EAH, 0F908H, 0F925H, 0F941H, 0F95CH, 0F976H, 0F990H, 0F9A9H, 0F9C1H, 0F9D8H, 0F9EFH, 0FA05H, 0FA1AH, 0FA2FH, 0FA43H, 0FA57H, 0FA6AH, 0FA7DH, 0FA8FH, 0FAA1H, 0FAB2H, 0FAC3H, 0FAD3H, 0FAE3H, 0FAF3H, 0FB02H, 0FB11H, 0FB20H, 0FB2EH, 0FB3CH, 0FB49H, 0FB56H, 0FB63H, 0FB70H, 0FB7DH, 0FB89H, 0FB95H, 0FBA0H, 0FBACH, 0FBB7H, 0FBC2H, 0FBCDH
STUIDT:
    DB      010H, 010H, 010H, 011H, 002H, 000H, 002H, 001H, 006H, 006H, 006H, 006H, 006H, 010H, 010H, 010H
// 0.1S 0.25S 0.5S 0.75S 1S
ADCHT:
    DB      0E7H, 0C1H, 083H, 045H, 006H
ADCLT:
    DB      014H, 0B1H, 063H, 014H, 0C6H
END