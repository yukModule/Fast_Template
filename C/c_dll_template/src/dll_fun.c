/**
 * dll_fun.c — DLL 库的源文件
 *
 * 这个文件被编译成一个动态链接库（Windows 上是 .dll 文件）。
 * __declspec(dllexport) 告诉编译器："把这些函数暴露出去，让其他程序可以调用"。
 */

#include <stdio.h>
#include "dll_fun.h"

// DLL 对外提供的功能 —— 打印一个带前缀的数字
DLL_EXPORT void dll_print(int a)
{
    printf("[dll_fun.dll] dll_print() called, value = %d\n", a);
    for(int i=0; i<a;i++){
        printf("for %d \r\n", i);
    }
}
