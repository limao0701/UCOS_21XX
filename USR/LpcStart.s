;title Start.s
;作者：李茂
;日期：2012年12月15日
;描述：

    PRESERVE8
    AREA    vector,CODE,READONLY
    ARM
	ENTRY
;中断向量表
        IMPORT     SWIHandler
Reset
        LDR     PC, ResetAddr	 ;程序的入口，
        LDR     PC, UndefinedAddr
        LDR     PC, SWI_Addr
        LDR     PC, PrefetchAddr
        LDR     PC, DataAbortAddr
        DCD     0xb9205f80		  ;IRQ中断跳转，由芯片提供商决定跳转地址
        LDR     PC, [PC, #-0xff0]
        LDR     PC, FIQ_Add

ResetAddr      DCD    ResetInit
UndefinedAddr  DCD	  UndefinedHandler
SWI_Addr	   DCD	  SWIHandler
PrefetchAddr   DCD	  PrefetchHandler
DataAbortAddr  DCD	  DataAbortHandler
FIQ_Add		   DCD	  FIQHandler



ResetInit 				  ;复位后执行
	   IMPORT   TargetInit
	   IMPORT    __main
	   
	   
	    BL     InitStack  ;初始化堆栈
		
		BL     TargetInit ;初始化各种堆栈
		LDR    R0,   =__main
		BX     R0   	  ;跳转到用户程序


InitStack				   ;设置各种模式的堆栈
        MOV     R0    ,LR			 ;SVC模式下的堆栈顶
		LDR     SP    ,SVCSTACKSPACE +(SVC_STACK_LEGTH-1)*4
		
		MSR     CPSR_c, #0xd2	     ;IRQ中断模式
        LDR     SP, IRQSTACKSPACE + (IRQ_STACK_LEGTH - 1)* 4    ;指向堆栈栈顶
                
        MSR     CPSR_c, #0xd1		 ;设置快速中断模式堆栈
        LDR     SP, FIQSTACKSPACE + (FIQ_STACK_LEGTH - 1)* 4
		
        MSR     CPSR_c, #0xd7	 		;设置中止模式堆栈
        LDR     SP, ABTSTACKSPACE + (ABT_STACK_LEGTH - 1)* 4

        MSR     CPSR_c, #0xdb		   ;设置未定义模式堆栈
        LDR     SP, UNDSTACKSPACE + (UND_STACK_LEGTH - 1)* 4

        MSR     CPSR_c, #0xdf			;设置系统模式堆栈
        LDR     SP, USRSTACKSPACE + (USR_STACK_LEGTH - 1)* 4

		MSR     CPSR_c, #0Xd
		
		MOV     LR    ,R0
		MOV     PC    ,LR  ;返回到TargetInit处


UndefinedHandler  ;其他暂时不会用到的异常模式
        B   .
PrefetchHandler
        B   . 
DataAbortHandler
		B   .
FIQHandler		  ;快速中断模式
	    MOV     R8    ,LR     ;保存返回地址
		BL	    FIQInterrupt    ;跳转到中断处理程序 
		MOV     PC    ,R8		;中断返回
FIQInterrupt
       b  .





;定义堆栈的大小，为上面的堆栈初始化做好准备
FIQ_STACK_LEGTH         EQU         0
IRQ_STACK_LEGTH         EQU         9*8             ;每层嵌套需要9个字堆栈，允许8层嵌套
ABT_STACK_LEGTH         EQU         0
UND_STACK_LEGTH         EQU         0
USR_STACK_LEGTH         EQU         10*5
SVC_STACK_LEGTH         EQU         50
;定义堆栈空间
    AREA    stack,DATA,NOINIT,ALIGN=2
IRQSTACKSPACE     SPACE       IRQ_STACK_LEGTH*4    
FIQSTACKSPACE     SPACE       FIQ_STACK_LEGTH*4	     
ABTSTACKSPACE     SPACE       FIQ_STACK_LEGTH*4
UNDSTACKSPACE	  SPACE       UND_STACK_LEGTH*4 
USRSTACKSPACE	  SPACE       UND_STACK_LEGTH*4
SVCSTACKSPACE     SPACE       SVC_STACK_LEGTH*4
		
        END		          