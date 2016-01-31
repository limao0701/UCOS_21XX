;********************************************************************************************************
;                                               uC/OS-II
;                                         The Real-Time Kernel
;
;                               (c) Copyright 1992-2012, CUIT, CHINA
;                                          All Rights Reserved
;
;                                           Generic ARM Port
;
; File      : OS_CPU_A.ASM
; Version   : V1.00
; By        : Limao ��ï
;
; For       : ARMv7TDMI NXP-LPC2138
; Mode      : arm
; Toolchain ��Keil uVision
;             
;********************************************************************************************************
Mode_USR        EQU     0x10
Mode_FIQ        EQU     0x11
Mode_IRQ        EQU     0x12
Mode_SVC        EQU     0x13
Mode_ABT        EQU     0x17
Mode_UND        EQU     0x1B
Mode_SYS        EQU     0x1F

I_Bit           EQU     0x80            ; when I bit is set, IRQ is disabled
F_Bit           EQU     0x40            ; when F bit is set, FIQ is disabled
NoInt       EQU 0x80

USR32Mode   EQU 0x10
SVC32Mode   EQU 0x13
SYS32Mode   EQU 0x1f
IRQ32Mode   EQU 0x12
FIQ32Mode   EQU 0x11

;********************************************************************************************************
;                                           �ⲿ��Ҫ�õ��ĺ���
;********************************************************************************************************

    EXTERN  OSRunning                                           ; External references
    EXTERN  OSPrioCur
    EXTERN  OSPrioHighRdy
    EXTERN  OSTCBCur
    EXTERN  OSTCBHighRdy
    EXTERN  OSIntNesting
    EXTERN  OSIntExit
    EXTERN  OSTaskSwHook

    EXPORT  OS_CPU_SR_Save                                      ; ��ǰ�ļ��к���������
    EXPORT  OS_CPU_SR_Restore
    EXPORT  __OSStartHighRdy
    EXPORT  OSCtxSw
    EXPORT  OSIntCtxSw
    EXPORT  OSPendSV
	EXPORT  SWIHandler											;���ж����
;	EXPORT  MyOSStartHighRdy
;********************************************************************************************************
;                                                EQUATES
;********************************************************************************************************

NVIC_INT_CTRL   EQU     0xE000ED04                              ; Interrupt control state register
;NVIC_SYSPRI2    EQU     0xE000ED20                              ; System priority register (2)
NVIC_SYSPRI2    EQU     0xE000ED22                              ; System priority register (yan).
;NVIC_PENDSV_PRI EQU     0x00   ; 0xFF00                         ; PendSV priority value (highest)
NVIC_PENDSV_PRI EQU           0xFF                              ; PendSV priority value (LOWEST yan).
NVIC_PENDSVSET  EQU     0x10000000                              ; Value to trigger PendSV exception

;********************************************************************************************************
;                                      CODE GENERATION DIRECTIVES
;********************************************************************************************************

    AREA |.text|, CODE, READONLY, ALIGN=2
    ARM
    REQUIRE8
    PRESERVE8


;********************************************************************************************************
;SWI�ж���ڣ��ܶຯ�������SWI�ж�
;
;********************************************************************************************************
T_bit               EQU         0x20 ;Thumb״̬�ж�ֵ
              IMPORT    _OS_ENTER_OR_EXIT_CRITICAL
			  EXTERN    _OS_ENTER_OR_EXIT_CRITICAL
			  IMPORT    _OS_EXIT_CRITICAL
			  EXTERN	_OS_EXIT_CRITICAL
SWIHandler
      STMFD   SP!,   {R0-R3,R12,LR}  ;��Щ�Ĵ������ϻ��õ�������ʱ�洢��SVCģʽ��ջ��
      MRS     R3,    SPSR  		 ;�ж�֮ǰ��״̬��ARM��THUMB
	  TST     R3,    #T_bit		 ;��T_bit����
	  LDRNEH  R0, [LR,#-2]       ;������0�� ��Thumb״̬: ȡ��Thumb״̬SWI��
	  BICNE   R0, #0XFF000000	 ;�����8λ��SWIģʽֻ����24λ��������swi�ĺ�
	  LDREQ   R0, [LR,#-4]			 ;����0��ARM״̬��
	  BICEQ   R0, #0XFF000000	  
	  CMP     R0, #0X02          ;�����л�__swi(0x02) void OS_TASK_SW();
	  LDREQ	  PC, =OSCtxSw			 ;��ת�������л����̣�LRû��
	  MOV     R1, LR
	  STMFD   SP!, {R1}
	  BLLO   _OS_ENTER_OR_EXIT_CRITICAL  ;�Ƿ�Ϊ�����ֹ�������ж�״̬
	  LDMFD   SP!, {R1}
	  MOV     LR,  R1
	  CMP     R0, #0X03
	  ;LDREQ   PC, =__OSStartHighRdy  ;��ת��__OSStartHighRdy��ȥִ����������ִ�У��ú�����OSStart���������е��ã���ˣ�ֻ��ִ��һ�Σ������ж������������
	   LDREQ   PC, =_MyOSStartHighRdy

;*********************************************************************************************************
      LDMFD   SP!, {R0-R3,R12, PC}^	  
	  

;*********************************************************************************************************
;
;*********************************************************************************************************
;IMPORT  OSTCPHighRdy     
__OSStartHighRdy		  ;OSPriroCur�Ѿ�����������ȼ�������
                          ;OStcbHighRdyҲΪ��ȷֵ
						  ;OSTCBCurҲΪ��ǰ��������TCP��ַ
						  ;��������ջ�Ѿ�����
	                      
	  ADD     SP,     SP,    #20	  ;������������ǰ���Ƚ���ջ���õ��������
;�������SYSģʽ�������������Ժ������������SYSģʽ��
	  MSR     CPSR_c, #(NoInt:OR:SYS32Mode) ;�л���SYSģʽ
	  LDR     R0,     =OSTCBHighRdy	  ;R0��ʱΪOSTCPHighRdy�ĵ�ַ
	  LDR     R0,     [R0]	  		  ;R0��ʱΪOSTCBHighRdy��ֵ����ֵΪTCP��ַָ����߾��������TCP
	  LDR     SP,     [R0]	          ;ִ�����SPָ��ǰ��������TCP���õ�ַҲ��TCP�������ջ��ջ��
      LDMFD   SP!,    {R0-R12, LR, PC }^ ;�����һ������




;�������Լ�д������������������ú���û�иı䴦����״̬��
;�ú���ֻ��ʹ��һ�Σ��������жϺ�������ã���Ϊ�޷��ָ�CPSR
_MyOSStartHighRdy 
      ;��Ҫ����Ȩģʽ�����ԣ��˴�Ҫʹ��SWI����  
      LDR     R0,     =OSTCBHighRdy
	  LDR     R1,     [R0]           ;�����ִ�����R0ָ��OSTCBHighRdy
	  LDR	  R0,     [R1]			 ;�����ִ�����R1ָ���ջ,�û��������������һ��Ԫ�صĵ�ַ
          ;��������ģʽ����ֹ�ƻ�����ģʽ�º�SVCģʽ�µĶ�ջ     
	  MSR     CPSR_c,  #0x1b           ;����UNDģʽ
	  MOV     SP,     R0
	  LDMIA   SP!,    {R0}
	  MSR     SPSR_c,  R0
	  LDMFD   SP!,	  {R0-R12,LR,PC}^






OSStartHang
      B       OSStartHang                                         ; Should never ge

OSIntCtxSw
	  STMFD  SP!,     {R0-R3}
	  MOV    R0,      SP		  
	  ADD    SP,      SP,#32+12
	  LDMIA  SP!,     {R3}		  
	  LDR    R12,      [SP,#-8]
	  LDR    R4,      [SP,#-32]
	  SUB    R3,      R3,#4		  ;ԭ�������жϴ���PCֵ
	  LDR    R2,      =OSTCBCur
	  LDR    R2,      [R2]
	  LDR    R2,      [R2]
	  ADD    SP,      R2,#60
	  STMDB  SP!,     {R3} ;����LR
	  STMDB  SP!,     {R4-R12}
	  MOV    R4,      SP		 ;��������ջ����SP
	  MOV    SP,      R0		  ;�ָ�IRQ��SP
	  LDMIA  SP!,     {R0-R3}
	  ADD    R5,      SP,#32        ;����IRQ��SP
	  MOV    SP,      R4		;�ָ������ջջ��
	  STMFD  SP!,     {R0-R3}
	  MRS    R0,      SPSR
	  STMFD  SP!,     {R0}
	  MOV    SP,      R5

	  MSR    CPSR_c,   #0X1B ;����UNDģʽ
	  LDR    R0,      =OSTCBCur
	  LDR    R1,      =OSTCBHighRdy
	  LDR    R1,      [R1]
	  STR    R1,      [R0]			;��OSTCBHighRdy��ֵ��ֵ��OSTCBCur  
	  LDR    R1,      [R1]
	  MOV    SP,      R1
	  LDMFD  SP!,     {R0}			;��ջ�����SPSR
	  MOV    R4,      SP			;�����ջ
	  ;ADD    R4,      SP,#4    
	  ;MSR    CPSR_c,  0X1B		    ;����UNDģʽ 
	  MVN    R2,      #0XC0
	  AND    R0,      R0,R2	;/*�����ж�*/
	  MSR    SPSR_cxsf,   R0	  
	  LDR    R1,      =OSPrioHighRdy ;��߾�����������ȼ��ŵĵ�ַ 
	  LDR    R0,      =OSPrioCur	 ;��ǰ�������ȼ��ŵĵ�ַ
	  LDRB   R1,      [R1]			 ;���ȼ�����ߵ���������ȼ���
	  STRB   R1,      [R0]			 ;�洢��OSPrioCur��
	  MOV    SP,      R4			 ;����֮ǰ��Ķ�ջ
	  LDMIA  SP!,     {R0-R12,PC}^	  ;ֻ�����жϻ����쳣ģʽ��ʹ��
      B   .
        
		IMPORT OSTCBCur				;���������ȫ�ֱ���
		IMPORT OSTCBHighRdy
		IMPORT OSPrioCur
		IMPORT OSPrioHighRdy

OSCtxSw		;SVCģʽ                                                                                                                                                                                                                                                                                                                                                                                                                                                                   	  
   	  MRS    R0,     CPSR
	  MOV    R1,     R0
	  ORR    R0,     R0,#0X1F
	  MSR	 CPSR_c,  R0	        ;�л���sysģʽ��
	  ADD    SP,      SP,#8		;SPָ�������л�ʱTimeDly��������һ����� 
	  LDR    R6,     [SP,#12]
	  LDR    R2,      =OSTCBCur		;����ǰ����������ݱ��浽��Ӧ�Ķ�ջ��
	  LDR    R2,      [R2]
	  LDR	 R2,      [R2]
	  MOV    R3,      SP			;����ǰsys��SP����,
	                         ;�л�ģʽʱҪ�Ļ���
	  ADD    SP,      R2,#60	    ;ʹSPָ�������ջջ��
	  STMFD  SP!,     {R6}
	  STMFD  SP!,     {R7-R12}   ;�ȱ���һЩֵ
	  MOV    R7,      SP			;�ٱ��������ջջ��
	  MOV    SP,	  R3			;��sys��ջ����ַ�ҵ�
	  LDMIA  SP!,     {R4-R6}       ;ȡ��SYSģʽ�б����3���Ĵ���ֵ
	  LDMIA  SP!,	  {R0}
	  MOV    SP,      R7			;�����ջ����ַ��ֵ��SP
	  STMFD  SP!,     {R4-R6}
	  MOV    R5,      SP     
	  MOV    SP,      R3     ;�л�ģʽʱSPҪ�Ļ���
	  MSR    CPSR_c,  R1	 ;�ص�SVCģʽ��
	  LDMFD  SP!,     {R0-R3,R12,LR}
	  MSR    CPSR_c,  #0x1b	 ;����UNDģʽ
	  MOV    SP,      R5
	  STMFD  SP!,     {R0-R3}
	  MRS    R0,      SPSR
	  STMFD  SP!,     {R0}
	        						 ;static  void  OS_SchedNew (void)����
									 ;ֻ�ǰѾ���������ߵ����ȼ��ҵ�����ֵ��
	    							 ;OSPrioHighRdy������Ҫ�ٽ���ֵ��ֵ��OSPrioCur
	  LDR    R0,      =OSTCBCur
	  LDR    R1,      =OSTCBHighRdy
	  LDR    R1,      [R1]
	  STR    R1,      [R0]			;��OSTCBHighRdy��ֵ��ֵ��OSTCBCur  
	  LDR    R1,      [R1]
	  MOV    SP,      R1
	  LDMFD  SP!,     {R0}			;��ջ�����SPSR
	  MVN    R2,      #0xc0
	  AND    R0,      R0,R2	;/*�����ж�*/
	  MSR    SPSR_c,   R0
	  LDR    R1,      =OSPrioHighRdy ;��߾�����������ȼ��ŵĵ�ַ 
	  LDR    R0,      =OSPrioCur	 ;��ǰ�������ȼ��ŵĵ�ַ
	  LDRB    R1,      [R1]			 ;���ȼ�����ߵ���������ȼ���
	  STRB    R1,      [R0]			 ;�洢��OSPrioCur��
	  LDMIA  SP!,     {R0-R12,PC}^
	  B   .  



OS_CPU_SR_Save
    B   .
OSPendSV
    B   .
OS_CPU_SR_Restore
    B   .

;*********************************************************************************************************
;                                     POINTERS TO VARIABLES
;*********************************************************************************************************

__OS_TaskSwHook
        DCD     OSTaskSwHook

__OS_IntExit
        DCD     OSIntExit

__OS_IntNesting
        DCD     OSIntNesting

__OS_PrioCur
        DCD     OSPrioCur

__OS_PrioHighRdy
        DCD     OSPrioHighRdy

__OS_Running
        DCD     OSRunning

__OS_TCBCur
        DCD     OSTCBCur

__OS_TCBHighRdy
        DCD     OSTCBHighRdy

        END
