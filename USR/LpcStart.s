;title Start.s
;���ߣ���ï
;���ڣ�2012��12��15��
;������

    PRESERVE8
    AREA    vector,CODE,READONLY
    ARM
	ENTRY
;�ж�������
        IMPORT     SWIHandler
Reset
        LDR     PC, ResetAddr	 ;�������ڣ�
        LDR     PC, UndefinedAddr
        LDR     PC, SWI_Addr
        LDR     PC, PrefetchAddr
        LDR     PC, DataAbortAddr
        DCD     0xb9205f80		  ;IRQ�ж���ת����оƬ�ṩ�̾�����ת��ַ
        LDR     PC, [PC, #-0xff0]
        LDR     PC, FIQ_Add

ResetAddr      DCD    ResetInit
UndefinedAddr  DCD	  UndefinedHandler
SWI_Addr	   DCD	  SWIHandler
PrefetchAddr   DCD	  PrefetchHandler
DataAbortAddr  DCD	  DataAbortHandler
FIQ_Add		   DCD	  FIQHandler



ResetInit 				  ;��λ��ִ��
	   IMPORT   TargetInit
	   IMPORT    __main
	   
	   
	    BL     InitStack  ;��ʼ����ջ
		
		BL     TargetInit ;��ʼ�����ֶ�ջ
		LDR    R0,   =__main
		BX     R0   	  ;��ת���û�����


InitStack				   ;���ø���ģʽ�Ķ�ջ
        MOV     R0    ,LR			 ;SVCģʽ�µĶ�ջ��
		LDR     SP    ,SVCSTACKSPACE +(SVC_STACK_LEGTH-1)*4
		
		MSR     CPSR_c, #0xd2	     ;IRQ�ж�ģʽ
        LDR     SP, IRQSTACKSPACE + (IRQ_STACK_LEGTH - 1)* 4    ;ָ���ջջ��
                
        MSR     CPSR_c, #0xd1		 ;���ÿ����ж�ģʽ��ջ
        LDR     SP, FIQSTACKSPACE + (FIQ_STACK_LEGTH - 1)* 4
		
        MSR     CPSR_c, #0xd7	 		;������ֹģʽ��ջ
        LDR     SP, ABTSTACKSPACE + (ABT_STACK_LEGTH - 1)* 4

        MSR     CPSR_c, #0xdb		   ;����δ����ģʽ��ջ
        LDR     SP, UNDSTACKSPACE + (UND_STACK_LEGTH - 1)* 4

        MSR     CPSR_c, #0xdf			;����ϵͳģʽ��ջ
        LDR     SP, USRSTACKSPACE + (USR_STACK_LEGTH - 1)* 4

		MSR     CPSR_c, #0Xd
		
		MOV     LR    ,R0
		MOV     PC    ,LR  ;���ص�TargetInit��


UndefinedHandler  ;������ʱ�����õ����쳣ģʽ
        B   .
PrefetchHandler
        B   . 
DataAbortHandler
		B   .
FIQHandler		  ;�����ж�ģʽ
	    MOV     R8    ,LR     ;���淵�ص�ַ
		BL	    FIQInterrupt    ;��ת���жϴ������ 
		MOV     PC    ,R8		;�жϷ���
FIQInterrupt
       b  .





;�����ջ�Ĵ�С��Ϊ����Ķ�ջ��ʼ������׼��
FIQ_STACK_LEGTH         EQU         0
IRQ_STACK_LEGTH         EQU         9*8             ;ÿ��Ƕ����Ҫ9���ֶ�ջ������8��Ƕ��
ABT_STACK_LEGTH         EQU         0
UND_STACK_LEGTH         EQU         0
USR_STACK_LEGTH         EQU         10*5
SVC_STACK_LEGTH         EQU         50
;�����ջ�ռ�
    AREA    stack,DATA,NOINIT,ALIGN=2
IRQSTACKSPACE     SPACE       IRQ_STACK_LEGTH*4    
FIQSTACKSPACE     SPACE       FIQ_STACK_LEGTH*4	     
ABTSTACKSPACE     SPACE       FIQ_STACK_LEGTH*4
UNDSTACKSPACE	  SPACE       UND_STACK_LEGTH*4 
USRSTACKSPACE	  SPACE       UND_STACK_LEGTH*4
SVCSTACKSPACE     SPACE       SVC_STACK_LEGTH*4
		
        END		          