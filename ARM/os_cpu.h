/*
*********************************************************************************************************
*                                               uC/OS-II
*                                         The Real-Time Kernel
*
*
*                                (c) Copyright 2006, Micrium, Weston, FL
*                                          All Rights Reserved
*
*                                           ARM Cortex-M3 Port
*
* File      : OS_CPU.H
* Version   : v1.00
* By        : 李茂
*
* For       : ARMv7TDMI NXP-LPC2138
* Mode      : Thumb2
* Toolchain : RealView Development Suite
*             RealView Microcontroller Development Kit (MDK)
*             ARM Developer Suite (ADS)
*             Keil uVision
*
*********************************************************************************************************
*/


#ifndef  OS_CPU_H
#define  OS_CPU_H


#ifdef   OS_CPU_GLOBALS
#define  OS_CPU_EXT
#else
#define  OS_CPU_EXT  extern
#endif
#define  OS_STK_GROWTH        1                   /* Stack grows from HIGH to LOW memory on ARM        */
#define  TURE                 1
#define  FALSE                0


/*
*********************************************************************************************************
*                                             数据类型申明
*                                            (与编译器相关)
*********************************************************************************************************
*/

typedef unsigned char  BOOLEAN;
typedef unsigned char  INT8U;                    /* Unsigned  8 bit quantity                           */
typedef signed   char  INT8S;                    /* Signed    8 bit quantity                           */
typedef unsigned short INT16U;                   /* Unsigned 16 bit quantity                           */
typedef signed   short INT16S;                   /* Signed   16 bit quantity                           */
typedef unsigned long  INT32U;                   /* Unsigned 32 bit quantity                           */
typedef signed   long  INT32S;                   /* Signed   32 bit quantity                           */
typedef float          FP32;                     /* Single precision floating point                    */
typedef double         FP64;                     /* Double precision floating point                    */

typedef INT32U   OS_STK;                   /* Each stack entry is 32-bit wide                    */
typedef INT32U   OS_CPU_SR;                /* Define size of CPU status register (PSR = 32 bits) */

#ifndef NoInit
#define NoInt        0xc0
#define AllowInt     (~0xc0)

#define USR32Mode    0x10
#define SVC32Mode    0x13
#define SYS32Mode    0x1f
#define IRQ32Mode    0x12
#define FIQ32Mode    0x11
#endif

/*
*********************************************************************************************************
*                                              Cortex-M1
*                                      Critical Section Management
*
* Method #1:  Disable/Enable interrupts using simple instructions.  After critical section, interrupts
*             will be enabled even if they were disabled before entering the critical section.
*             NOT IMPLEMENTED
*
* Method #2:  Disable/Enable interrupts by preserving the state of interrupts.  In other words, if
*             interrupts were disabled before entering the critical section, they will be disabled when
*             leaving the critical section.
*             NOT IMPLEMENTED
*
* Method #3:  Disable/Enable interrupts by preserving the state of interrupts.  Generally speaking you
*             would store the state of the interrupt disable flag in the local variable 'cpu_sr' and then
*             disable interrupts.  'cpu_sr' is allocated in all of uC/OS-II's functions that need to
*             disable interrupts.  You would restore the interrupt disable state by copying back 'cpu_sr'
*             into the CPU's status register.
*********************************************************************************************************
*/

#define  OS_CRITICAL_METHOD   3

//INT32U  OsEnterSum;                  /*  关中断计数器（开关中断的信号量）    */


__swi(0x03) void MyOSStartHighRdy(void);
extern void OSIntCtxSw(void);
#if OS_CRITICAL_METHOD == 3
__swi(0x00) void OS_ENTER_CRITICAL(void);
__swi(0x01)	void OS_EXIT_CRITICAL(void);
__swi(0x02)	void OS_TASK_SW(void);
__swi(0x03) void _OSStartHighRdy(void);  /*该中断实现切换到最高任务*/
void _OS_ENTER_CRITICAL(void);
void _OS_EXIT_CRITICAL(void);
void __irq IRQ_Timer0(void);
#endif









/*
*********************************************************************************************************
*                                        任务切换宏
*********************************************************************************************************
*/



#define   OSCtxSw()	 OS_TASK_SW()               







/*
*********************************************************************************************************
*                                              PROTOTYPES
*********************************************************************************************************
*/

#if OS_CRITICAL_METHOD == 3                       /* See OS_CPU_A.ASM                                  */
OS_CPU_SR  OS_CPU_SR_Save(void);
void       OS_CPU_SR_Restore(OS_CPU_SR cpu_sr);
#endif

//void       OSCtxSw(void);
//void       OSIntCtxSw(void);
void       OSStartHighRdy(void);

void       OSPendSV(void);
#endif
