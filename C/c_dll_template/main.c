/**
 * main.c — 主程序
 *
 * 演示如何在运行时动态加载 DLL 并调用其中的函数。
 * 核心流程：LoadLibrary → GetProcAddress → 调用函数 → FreeLibrary
 *
 * 与"编译时链接"不同，运行时加载不需要 .lib 导入库，
 * 也不需要 DLL 的头文件 —— 函数签名由我们自己定义。
 */

#include <stdio.h>
#include <windows.h>

int main(void)
{
    // ----------------------------------------------------
    // 第 1 步：加载 DLL
    // LoadLibrary 将 dll_fun.dll 加载到当前进程的地址空间。
    // 返回值是 DLL 模块的句柄（HINSTANCE / HMODULE）。
    // 失败时返回 NULL。
    // ----------------------------------------------------
    HINSTANCE hDll = LoadLibrary(TEXT("dll_fun.dll"));
    if (hDll == NULL) {
        printf("[main.exe] ERROR: Cannot load dll_fun.dll\n");
        printf("[main.exe] Make sure the .dll file is in the same directory.\n");
        return 1;
    }
    printf("[main.exe] dll_fun.dll loaded successfully.\n");

    // ----------------------------------------------------
    // 第 2 步：获取函数地址
    // GetProcAddress 在已加载的 DLL 中查找指定名称的函数，
    // 返回函数指针。需要将返回值强转成正确的函数指针类型。
    // ----------------------------------------------------

    // 先定义一个函数指针类型：void (*)(int)
    typedef void (*dll_print_func)(int);

    // 在 DLL 中查找 "dll_print" 函数
    dll_print_func dll_print = (dll_print_func)GetProcAddress(hDll, "dll_print");
    if (dll_print == NULL) {
        printf("[main.exe] ERROR: Cannot find 'dll_print' in dll_fun.dll\n");
        FreeLibrary(hDll);
        return 1;
    }
    printf("[main.exe] Function 'dll_print' found at %p.\n", (void *)dll_print);

    // ----------------------------------------------------
    // 第 3 步：调用 DLL 中的函数
    // ----------------------------------------------------
    printf("[main.exe] Calling dll_print(42)...\n");
    dll_print(42);

    // ----------------------------------------------------
    // 第 4 步：释放 DLL
    // 用完后释放 DLL，减少进程的内存占用。
    // ----------------------------------------------------
    FreeLibrary(hDll);
    printf("[main.exe] dll_fun.dll unloaded. Done.\n");

    return 0;
}
