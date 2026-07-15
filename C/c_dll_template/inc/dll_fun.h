#ifndef _DLL_FUN_H
#define _DLL_FUN_H

// ============================================================
//  DLL 导出宏
//  Windows 下用 __declspec(dllexport) 标记要导出的函数
//  其他平台（Linux/macOS）默认所有符号可见，无需特殊处理
// ============================================================
#ifdef _WIN32
    #define DLL_EXPORT __declspec(dllexport)
#else
    #define DLL_EXPORT
#endif

// 在 DLL 中导出 dll_print 函数
DLL_EXPORT void dll_print(int a);

#endif // _DLL_FUN_H
