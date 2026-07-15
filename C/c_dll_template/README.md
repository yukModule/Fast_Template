# DLL 开发入门模板（C 语言 / Windows）

一个面向初学者的 DLL（Dynamic Link Library，动态链接库）开发演示项目。使用 C 语言编写，通过 Windows API 在运行时动态加载 DLL 并调用其中的函数。

---

## 目录

- [项目结构](#项目结构)
- [快速开始](#快速开始)
- [什么是 DLL](#什么是-dll)
- [两种使用 DLL 的方式](#两种使用-dll-的方式)
- [设计思路](#设计思路)
- [核心 API 详解](#核心-api-详解)
- [执行流程图](#执行流程图)
- [常见问题](#常见问题)
- [扩展阅读](#扩展阅读)

---

## 项目结构

```
dll_test/
├── inc/
│   └── dll_fun.h        # DLL 的头文件（函数声明 + 导出宏）
├── src/
│   └── dll_fun.c        # DLL 的源代码（函数实现）
├── main.c               # 主程序（加载并调用 DLL）
├── makefile             # 构建脚本
└── README.md            # 本文件
```

编译后生成：

| 文件 | 说明 |
|------|------|
| `main.exe` | 主程序，运行时加载 DLL |
| `dll_fun.dll` | 动态链接库，提供 `dll_print()` 函数 |

---

## 快速开始

### 环境要求

- **操作系统**：Windows
- **编译器**：[MinGW-w64](https://www.mingw-w64.org/) 或 [MSYS2](https://www.msys2.org/) 中的 GCC
- **构建工具**：GNU Make

### 编译 & 运行

```bash
# 在项目根目录下执行：

# 编译（生成 main.exe 和 dll_fun.dll）
make

# 运行
./main.exe

# 清理
make clean
```

### 预期输出

```
[main.exe] dll_fun.dll loaded successfully.
[main.exe] Function 'dll_print' found at 00007FFxxxxxxxx.
[main.exe] Calling dll_print(42)...
[dll_fun.dll] dll_print() called, value = 42
[main.exe] dll_fun.dll unloaded. Done.
```

---

## 什么是 DLL

### 类比理解

想象你在开发一个大型软件。有些功能是多个程序都要用到的——比如打印日志、加密解密、图像处理。你有两种选择：

| 方式 | 做法 | 缺点 |
|------|------|------|
| **静态库 (.a/.lib)** | 把代码复制到每个 .exe 里 | 每个 .exe 都变大；库更新后所有程序都要重新编译 |
| **动态库 (.dll/.so)** | 代码单独存放，运行时共享 | 需要确保 .dll 文件存在 |

**DLL 就是"一份代码，多处使用"。**

### 生活中的类比

```
静态库 = 每家自己买一本字典，用的时候翻自己的
动态库 = 小区有一个公共图书馆，所有人都去那里查
```

- 静态库：每个 .exe 都包含库代码的副本 → 磁盘占用大，但独立运行
- 动态库：.exe 和 .dll 分离 → 更新 .dll 不需要重新编译 .exe；多个程序共享同一个 .dll

### Windows 系统中的 DLL

打开 `C:\Windows\System32`，你会看到成百上千个 .dll 文件：
- `kernel32.dll` — 操作系统核心功能
- `user32.dll` — 窗口、按钮等 UI 组件
- `gdi32.dll` — 图形绘制

> 你写的每一个 Windows 程序都在默默使用这些系统 DLL。

---

## 两种使用 DLL 的方式

### 方式一：加载时动态链接（Load-Time Dynamic Linking）

```
编译时需要 │  .h 头文件 + .lib 导入库
链接时需要 │  .lib 导入库
运行时需要 │  .dll 文件
```

程序启动时，操作系统自动加载所需的 DLL。如果 DLL 不存在，程序直接报错无法启动。

```c
// 需要头文件和导入库
#include "dll_fun.h"
int main() {
    dll_print(42);  // 直接调用，和普通函数一样
    return 0;
}
```

### 方式二：运行时动态链接（Run-Time Dynamic Linking）⭐ 本项目采用

```
编译时需要 │  无（不需要 .h 也不需要 .lib）
链接时需要 │  无
运行时需要 │  .dll 文件
```

程序运行时，由程序员手动加载 DLL、查找函数、调用、卸载。DLL 缺失时程序可以选择降级运行或给出友好提示。

```c
// 不需要头文件，不需要导入库
#include <windows.h>
int main() {
    HINSTANCE h = LoadLibrary("dll_fun.dll");       // 加载
    typedef void (*fn)(int);
    fn f = (fn)GetProcAddress(h, "dll_print");       // 查找
    f(42);                                            // 调用
    FreeLibrary(h);                                   // 卸载
    return 0;
}
```

### 对比总结

| | 加载时链接 | 运行时链接（本项目） |
|---|---|---|
| 需要 .h 头文件 | ✅ 需要 | ❌ 不需要 |
| 需要 .lib 导入库 | ✅ 需要 | ❌ 不需要 |
| DLL 缺失时 | 程序无法启动 | 可以捕获错误、降级运行 |
| 调用方式 | 直接函数调用 | 通过函数指针 |
| 灵活性 | 低 | 高（可动态选择加载哪个 DLL） |
| 典型场景 | 固定依赖 | 插件系统、热更新 |

---

## 设计思路

### 1. 整体架构

```
┌──────────────┐      LoadLibrary()       ┌──────────────────┐
│              │ ──────────────────────▶  │                  │
│   main.exe   │                          │   dll_fun.dll    │
│              │ ◀──────────────────────  │                  │
│  (调用方)    │      GetProcAddress()     │  (服务提供方)     │
│              │                          │                  │
│  dll_print() │ ───── 函数指针调用 ─────▶ │   dll_print()    │
│              │                          │   真正的实现      │
│              │      FreeLibrary()       │                  │
│              │ ──────────────────────▶  │   (被卸载)        │
└──────────────┘                          └──────────────────┘
```

### 2. 为什么选择"运行时动态链接"

本项目选择运行时加载方式，因为它：

- **不依赖导入库**：初学者不需要理解 .lib 文件的作用
- **错误可控**：DLL 加载失败时可以打印友好提示，而不是直接崩溃
- **概念清晰**：`LoadLibrary → GetProcAddress → 调用 → FreeLibrary` 四个步骤直观展示了 DLL 的工作原理
- **实际应用广**：插件系统（如 VS Code 扩展、Photoshop 滤镜）都基于这种模式

### 3. `__declspec(dllexport)` 的作用

```c
#ifdef _WIN32
    #define DLL_EXPORT __declspec(dllexport)
#else
    #define DLL_EXPORT
#endif

DLL_EXPORT void dll_print(int a);
```

- **Windows**：DLL 默认不导出任何符号。`__declspec(dllexport)` 显式告诉编译器"这个函数要对外的"。没有它，`GetProcAddress` 就找不到函数。
- **Linux/macOS**：所有符号默认可见，不需要特殊标记（所以宏展开为空）。
- **使用宏**：`DLL_EXPORT` 宏让同一份代码可以跨平台编译。

### 4. 头文件的角色

```
dll_fun.h 只被 dll_fun.c 包含（编译 DLL 时用）
main.c 不包含 dll_fun.h（运行时加载不需要头文件）
```

这是一种"生产者声明，消费者自省"的模式：
- **生产者（DLL）**：用头文件声明"我能提供什么"
- **消费者（main.exe）**：通过 `GetProcAddress` 在运行时自省"你有没有我要的函数"

---

## 核心 API 详解

### `LoadLibrary` — 加载 DLL

```c
HINSTANCE LoadLibrary(LPCTSTR lpLibFileName);
```

| 参数 | 说明 |
|------|------|
| `lpLibFileName` | DLL 文件名（同目录下只写文件名即可） |
| **返回值** | 成功：DLL 模块句柄；失败：`NULL` |

> Windows 搜索 DLL 的顺序：① 程序所在目录 → ② 系统目录 → ③ PATH 环境变量。放在 .exe 旁边是最稳妥的做法。

### `GetProcAddress` — 获取函数地址

```c
FARPROC GetProcAddress(HMODULE hModule, LPCSTR lpProcName);
```

| 参数 | 说明 |
|------|------|
| `hModule` | `LoadLibrary` 返回的句柄 |
| `lpProcName` | 函数名（**注意区分大小写**，C 语言函数名在 DLL 中就是源码中的名字） |
| **返回值** | 成功：函数指针；失败：`NULL` |

> **关键技巧**：返回值是通用类型 `FARPROC`，必须用 `typedef` 定义的函数指针类型做强制转换。

```c
typedef void (*dll_print_func)(int);                     // 定义函数指针类型
dll_print_func dll_print = (dll_print_func)GetProcAddress(hDll, "dll_print");
```

### `FreeLibrary` — 卸载 DLL

```c
BOOL FreeLibrary(HMODULE hModule);
```

释放 DLL 占用的内存。操作系统会维护引用计数，只有当引用计数归零时 DLL 才真正从内存中移除。

---

## 执行流程图

```
程序启动
   │
   ▼
LoadLibrary("dll_fun.dll")
   │
   ├── 成功 ────────────────────────────────────┐
   │                                              │
   │  GetProcAddress(hDll, "dll_print")           │
   │     │                                        │
   │     ├── 成功 ──────────────────────┐         │
   │     │                              │         │
   │     │  dll_print(42)  ──▶ 调用 DLL │         │
   │     │     │                        │         │
   │     │     ▼                        │         │
   │     │  [dll_fun.dll] 执行函数体     │         │
   │     │     │                        │         │
   │     │     ▼                        │         │
   │     │  FreeLibrary(hDll)           │         │
   │     │     │                        │         │
   │     │     ▼                        │         │
   │     │  程序正常退出 (return 0)      │         │
   │     │                              │         │
   │     └── 失败 ──▶ 打印错误, 卸载, 退出 (return 1)
   │                                              │
   └── 失败 ──▶ 打印错误, 退出 (return 1)
```

---

## 常见问题

### Q1: 运行 main.exe 提示"找不到 dll_fun.dll"

**原因**：DLL 不在 .exe 所在目录，也不在系统搜索路径中。

**解决**：确保 `dll_fun.dll` 和 `main.exe` 在同一目录下。

### Q2: 运行时提示 "Cannot find 'dll_print'"

**可能原因**：
1. 编译 DLL 时忘记加 `__declspec(dllexport)`
2. C++ 编译导致函数名被 Name Mangling 篡改（本项目用 C 语言，不存在此问题）

**验证方法**：用 `dumpbin /exports dll_fun.dll`（VS 开发者工具）或 `objdump -p dll_fun.dll`（MinGW）查看 DLL 导出了哪些函数。

### Q3: Load-Time 和 Run-Time 链接该怎么选？

| 场景 | 推荐方式 |
|------|----------|
| 功能固定、DLL 一定存在 | 加载时链接（简单、方便） |
| 插件系统、可选功能 | 运行时链接（灵活、容错） |
| 需要热更新/热重载 | 运行时链接 |
| 调用 Windows 系统 API | 加载时链接（系统 DLL 一定存在） |

### Q4: 为什么 main.c 用了 `TEXT()` 宏？

```c
LoadLibrary(TEXT("dll_fun.dll"));
```

`TEXT()` 宏让字符串在 Unicode 和 ANSI 编译模式下都能正确工作。如果确定只使用 ANSI 模式，写 `LoadLibrary("dll_fun.dll")` 也可以。

---

## 扩展阅读

- [Dynamic-Link Library Best Practices (Microsoft Learn)](https://learn.microsoft.com/en-us/windows/win32/dlls/dynamic-link-library-best-practices)
- [LoadLibrary 官方文档](https://learn.microsoft.com/en-us/windows/win32/api/libloaderapi/nf-libloaderapi-loadlibraryw)
- [GetProcAddress 官方文档](https://learn.microsoft.com/en-us/windows/win32/api/libloaderapi/nf-libloaderapi-getprocaddress)
- [dllexport, dllimport (Microsoft Learn)](https://learn.microsoft.com/en-us/cpp/cpp/dllexport-dllimport)

---

## 许可证

本项目仅用于学习目的，可自由使用和修改。
