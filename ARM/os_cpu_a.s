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
; By        : Limao 李茂
;
; For       : ARMv7TDMI NXP-LPC2138
; Mode      : arm
; Toolchain ：Keil uVision
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
;                                           外部需要用到的函数
;********************************************************************************************************

    EXTERN  OSRunning                                           ; External references
    EXTERN  OSPrioCur
    EXTERN  OSPrioHighRdy
    EXTERN  OSTCBCur
    EXTERN  OSTCBHighRdy
    EXTERN  OSIntNesting
    EXTERN  OSIntExit
    EXTERN  OSTaskSwHook

    EXPORT  OS_CPU_SR_Save                                      ; 当前文件中函数的申明
    EXPORT  OS_CPU_SR_Restore
    EXPORT  __OSStartHighRdy
    EXPORT  OSCtxSw
    EXPORT  OSIntCtxSw
    EXPORT  OSPendSV
	EXPORT  SWIHandler											;软中断入口
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
;SWI中断入口，很多函数定义成SWI中断
;
;********************************************************************************************************
T_bit               EQU         0x20 ;Thumb状态判断值
              IMPORT    _OS_ENTER_OR_EXIT_CRITICAL
			  EXTERN    _OS_ENTER_OR_EXIT_CRITICAL
			  IMPORT    _OS_EXIT_CRITICAL
			  EXTERN	_OS_EXIT_CRITICAL
SWIHandler
      STMFD   SP!,   {R0-R3,R12,LR}  ;这些寄存器马上会用到，先暂时存储在SVC模式堆栈里
      MRS     R3,    SPSR  		 ;判断之前的状态，ARM或THUMB
	  TST     R3,    #T_bit		 ;与T_bit相与
	  LDRNEH  R0, [LR,#-2]       ;不等于0， 是Thumb状态: 取得Thumb状态SWI号
	  BICNE   R0, #0XFF000000	 ;清除高8位，SWI模式只用了24位的数字作swi的号
	  LDREQ   R0, [LR,#-4]			 ;等于0，ARM状态：
	  BICEQ   R0, #0XFF000000	  
	  CMP     R0, #0X02          ;任务切换__swi(0x02) void OS_TASK_SW();
	  LDREQ	  PC, =OSCtxSw			 ;跳转到任务切换过程，LR没变
	  MOV     R1, LR
	  STMFD   SP!, {R1}
	  BLLO   _OS_ENTER_OR_EXIT_CRITICAL  ;是否为进入禁止或允许中断状态
	  LDMFD   SP!, {R1}
	  MOV     LR,  R1
	  CMP     R0, #0X03
	  ;LDREQ   PC, =__OSStartHighRdy  ;跳转到__OSStartHighRdy，去执行最高任务的执行，该函数在OSStart（）函数中调用，因此，只会执行一次，所以判定条件放在最后
	   LDREQ   PC, =_MyOSStartHighRdy

;*********************************************************************************************************
      LDMFD   SP!, {R0-R3,R12, PC}^	  
	  

;*********************************************************************************************************
;
;*********************************************************************************************************
;IMPORT  OSTCPHighRdy     
__OSStartHighRdy		  ;OSPriroCur已经等于最高优先级的任务
                          ;OStcbHighRdy也为正确值
						  ;OSTCBCur也为当前最高任务的TCP地址
						  ;相关任务堆栈已经保存
	                      
	  ADD     SP,     SP,    #20	  ;进入任务运行前，先将堆栈不用的数据清除
;下面进入SYS模式！！！！！，以后任务就运行在SYS模式下
	  MSR     CPSR_c, #(NoInt:OR:SYS32Mode) ;切换到SYS模式
	  LDR     R0,     =OSTCBHighRdy	  ;R0此时为OSTCPHighRdy的地址
	  LDR     R0,     [R0]	  		  ;R0此时为OSTCBHighRdy的值，该值为TCP地址指向最高就绪任务的TCP
	  LDR     SP,     [R0]	          ;执行完后，SP指向当前最高任务的TCP，该地址也是TCP中任务堆栈的栈顶
      LDMFD   SP!,    {R0-R12, LR, PC }^ ;进入第一个任务




;下面是自己写的启动最高任务函数，该函数没有改变处理器状态，
;该函数只能使用一次，不能在中断函数里调用，因为无法恢复CPSR
_MyOSStartHighRdy 
      ;需要在特权模式，所以，此处要使用SWI进入  
      LDR     R0,     =OSTCBHighRdy
	  LDR     R1,     [R0]           ;此语句执行完后，R0指向OSTCBHighRdy
	  LDR	  R0,     [R1]			 ;此语句执行完后，R1指向堆栈,用户定义的数组的最后一个元素的地址
          ;进入其他模式，防止破坏任务模式下和SVC模式下的堆栈     
	  MSR     CPSR_c,  #0x1b           ;进入UND模式
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
	  SUB    R3,      R3,#4		  ;原来任务被中断处的PC值
	  LDR    R2,      =OSTCBCur
	  LDR    R2,      [R2]
	  LDR    R2,      [R2]
	  ADD    SP,      R2,#60
	  STMDB  SP!,     {R3} ;保存LR
	  STMDB  SP!,     {R4-R12}
	  MOV    R4,      SP		 ;保存任务栈顶的SP
	  MOV    SP,      R0		  ;恢复IRQ的SP
	  LDMIA  SP!,     {R0-R3}
	  ADD    R5,      SP,#32        ;保存IRQ的SP
	  MOV    SP,      R4		;恢复任务堆栈栈顶
	  STMFD  SP!,     {R0-R3}
	  MRS    R0,      SPSR
	  STMFD  SP!,     {R0}
	  MOV    SP,      R5

	  MSR    CPSR_c,   #0X1B ;进入UND模式
	  LDR    R0,      =OSTCBCur
	  LDR    R1,      =OSTCBHighRdy
	  LDR    R1,      [R1]
	  STR    R1,      [R0]			;把OSTCBHighRdy的值赋值给OSTCBCur  
	  LDR    R1,      [R1]
	  MOV    SP,      R1
	  LDMFD  SP!,     {R0}			;堆栈最顶端是SPSR
	  MOV    R4,      SP			;保存堆栈
	  ;ADD    R4,      SP,#4    
	  ;MSR    CPSR_c,  0X1B		    ;进入UND模式 
	  MVN    R2,      #0XC0
	  AND    R0,      R0,R2	;/*允许中断*/
	  MSR    SPSR_cxsf,   R0	  
	  LDR    R1,      =OSPrioHighRdy ;最高就绪任务的优先级号的地址 
	  LDR    R0,      =OSPrioCur	 ;当前任务优先级号的地址
	  LDRB   R1,      [R1]			 ;优先级号最高的任务的优先级号
	  STRB   R1,      [R0]			 ;存储在OSPrioCur中
	  MOV    SP,      R4			 ;载入之前存的堆栈
	  LDMIA  SP!,     {R0-R12,PC}^	  ;只能在中断或者异常模式下使用
      B   .
        
		IMPORT OSTCBCur				;引入所需的全局变量
		IMPORT OSTCBHighRdy
		IMPORT OSPrioCur
		IMPORT OSPrioHighRdy

OSCtxSw		;SVC模式                                                                                                                                                                                                                                                                                                                                                                                                                                                                   	  
   	  MRS    R0,     CPSR
	  MOV    R1,     R0
	  ORR    R0,     R0,#0X1F
	  MSR	 CPSR_c,  R0	        ;切换到sys模式下
	  ADD    SP,      SP,#8		;SP指向任务切换时TimeDly函数的下一条语句 
	  LDR    R6,     [SP,#12]
	  LDR    R2,      =OSTCBCur		;将当前任务相关数据保存到对应的堆栈中
	  LDR    R2,      [R2]
	  LDR	 R2,      [R2]
	  MOV    R3,      SP			;将当前sys的SP保存,
	                         ;切换模式时要改回来
	  ADD    SP,      R2,#60	    ;使SP指向任务堆栈栈低
	  STMFD  SP!,     {R6}
	  STMFD  SP!,     {R7-R12}   ;先保存一些值
	  MOV    R7,      SP			;再保存任务堆栈栈顶
	  MOV    SP,	  R3			;将sys堆栈顶地址找到
	  LDMIA  SP!,     {R4-R6}       ;取出SYS模式中保存的3个寄存器值
	  LDMIA  SP!,	  {R0}
	  MOV    SP,      R7			;任务堆栈顶地址赋值给SP
	  STMFD  SP!,     {R4-R6}
	  MOV    R5,      SP     
	  MOV    SP,      R3     ;切换模式时SP要改回来
	  MSR    CPSR_c,  R1	 ;回到SVC模式下
	  LDMFD  SP!,     {R0-R3,R12,LR}
	  MSR    CPSR_c,  #0x1b	 ;进入UND模式
	  MOV    SP,      R5
	  STMFD  SP!,     {R0-R3}
	  MRS    R0,      SPSR
	  STMFD  SP!,     {R0}
	        						 ;static  void  OS_SchedNew (void)函数
									 ;只是把就绪表中最高的优先级找到并赋值给
	    							 ;OSPrioHighRdy，还需要再将此值赋值给OSPrioCur
	  LDR    R0,      =OSTCBCur
	  LDR    R1,      =OSTCBHighRdy
	  LDR    R1,      [R1]
	  STR    R1,      [R0]			;把OSTCBHighRdy的值赋值给OSTCBCur  
	  LDR    R1,      [R1]
	  MOV    SP,      R1
	  LDMFD  SP!,     {R0}			;堆栈最顶端是SPSR
	  MVN    R2,      #0xc0
	  AND    R0,      R0,R2	;/*允许中断*/
	  MSR    SPSR_c,   R0
	  LDR    R1,      =OSPrioHighRdy ;最高就绪任务的优先级号的地址 
	  LDR    R0,      =OSPrioCur	 ;当前任务优先级号的地址
	  LDRB    R1,      [R1]			 ;优先级号最高的任务的优先级号
	  STRB    R1,      [R0]			 ;存储在OSPrioCur中
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
