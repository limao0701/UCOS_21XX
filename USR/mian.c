/*TITLE: main.c
*
*
*/


#include "..\INCLUDES.H"
#define TaskStkLengh    64          //Define the Task0 stack length 定义用户任务0的堆栈长度
 
OS_STK  TaskStk0 [TaskStkLengh];     //Define the Task0 stack 定义用户任务0的堆栈
OS_STK  TaskStk1[TaskStkLengh];
OS_STK  TaskStk2[TaskStkLengh];

void    Task0(void *pdata);         //Task0 任务0
void    Task1(void *pdata);
void    Task2(void *pdata);

int main(){
 OSInit();
 OSTaskCreate (Task0,(void *)0, &TaskStk0[TaskStkLengh - 1], 2);	/*创建第一个用户任务，第二个参数因该是数组最后一个元素的地址*/
 OSTaskCreate (Task1,(void *)0, &TaskStk1[TaskStkLengh - 1], 3);
 OSTaskCreate (Task2,(void *)0, &TaskStk2[TaskStkLengh - 1], 4);
 OSStart ();

 return 0;

}

void    Task0(void *pdata){	  //Task0 任务0
 pdata=pdata;
 TargetResetInit();
 TargetInit ();
 while(1){
  OSTimeDly(3);
 
 }
}        
void    Task1(void *pdata){
 pdata=pdata;
 while(1){
 OSTimeDly(1);
 }
}

 void    Task2(void *pdata){
  int a=0;
  while(1)
  a=1;
   
 }


