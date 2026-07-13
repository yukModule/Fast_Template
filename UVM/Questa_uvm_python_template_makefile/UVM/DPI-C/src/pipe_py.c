#include "pipe_py.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <windows.h>

#define BUFFER_SIZE 4096

/**
 * 检查文件是否存在
 */
static int file_exists(const char *path)
{
    DWORD attr = GetFileAttributesA(path);
    return attr != INVALID_FILE_ATTRIBUTES && !(attr & FILE_ATTRIBUTE_DIRECTORY);
}

/**
 * 检查目录是否存在
 */
static int dir_exists(const char *path)
{
    DWORD attr = GetFileAttributesA(path);
    return attr != INVALID_FILE_ATTRIBUTES && (attr & FILE_ATTRIBUTE_DIRECTORY);
}

/**
 * 从路径中提取目录名
 */
static void dirname_from_path(const char *path, char *dir, size_t dir_size)
{
    strncpy(dir, path, dir_size - 1);
    dir[dir_size - 1] = '\0';

    char *slash = strrchr(dir, '\\');
    if (!slash) {
        slash = strrchr(dir, '/');
    }
    if (slash) {
        *slash = '\0';
    } else {
        strcpy(dir, ".");
    }
}

/**
 * 解析Python解释器路径
 */
static int resolve_python_exe(const char *venv_path, char *python_exe, size_t size)
{
    // 处理相对路径
    char abs_venv_path[MAX_PATH];
    if (!(venv_path[0] == 'C' && venv_path[1] == ':') &&
        !(venv_path[0] == 'c' && venv_path[1] == ':') &&
        !(venv_path[0] == '\\' && venv_path[1] == '\\')) {
        GetFullPathNameA(venv_path, MAX_PATH, abs_venv_path, NULL);
    } else {
        strncpy(abs_venv_path, venv_path, sizeof(abs_venv_path) - 1);
        abs_venv_path[sizeof(abs_venv_path) - 1] = '\0';
    }
    
    // 直接检查是否是python.exe路径
    snprintf(python_exe, size, "%s", abs_venv_path);
    if (file_exists(python_exe)) {
        return 0;
    }
    
    // 尝试添加python.exe
    snprintf(python_exe, size, "%s\\python.exe", abs_venv_path);
    if (file_exists(python_exe)) {
        return 0;
    }
    
    // 尝试Scripts目录
    snprintf(python_exe, size, "%s\\Scripts\\python.exe", abs_venv_path);
    if (file_exists(python_exe)) {
        return 0;
    }
    
    printf("Cannot find python.exe in: %s\n", abs_venv_path);
    return -1;
}

/**
 * 解析Python脚本路径
 */
static int resolve_script_path(const char *script_name, const char *work_path, char *script_path, size_t size)
{
    // 如果提供了工作路径，优先在工作路径下查找
    if (work_path && work_path[0] != '\0') {
        char full_path[MAX_PATH];
        snprintf(full_path, sizeof(full_path), "%s\\%s", work_path, script_name);
        
        if (file_exists(full_path)) {
            GetFullPathNameA(full_path, (DWORD)size, script_path, NULL);
            return 0;
        }
    }
    
    // 检查是否是绝对路径或当前目录下的文件
    if (file_exists(script_name)) {
        GetFullPathNameA(script_name, (DWORD)size, script_path, NULL);
        return 0;
    }
    
    // 检查exe同目录
    char exe_path[MAX_PATH];
    char exe_dir[MAX_PATH];
    GetModuleFileNameA(NULL, exe_path, sizeof(exe_path));
    dirname_from_path(exe_path, exe_dir, sizeof(exe_dir));
    
    snprintf(script_path, size, "%s\\%s", exe_dir, script_name);
    if (file_exists(script_path)) {
        return 0;
    }
    
    printf("Cannot find script: %s\n", script_name);
    return -1;
}

/**
 * 创建命名管道
 */
static HANDLE create_pipe(const char *pipe_name)
{
    HANDLE pipe = CreateNamedPipeA(
        pipe_name,
        PIPE_ACCESS_DUPLEX,
        PIPE_TYPE_BYTE | PIPE_READMODE_BYTE | PIPE_WAIT,
        1,
        BUFFER_SIZE,
        BUFFER_SIZE,
        0,
        NULL);

    if (pipe == INVALID_HANDLE_VALUE) {
        printf("CreateNamedPipe failed for %s, error=%lu\n", pipe_name, GetLastError());
        return NULL;
    }
    return pipe;
}

/**
 * 连接管道
 */
static int connect_pipe(HANDLE pipe, const char *name)
{
    BOOL ok = ConnectNamedPipe(pipe, NULL);
    DWORD err = GetLastError();
    if (!ok && err != ERROR_PIPE_CONNECTED) {
        printf("ConnectNamedPipe failed for %s, error=%lu\n", name, err);
        return -1;
    }
    return 0;
}

/**
 * 发送一行数据
 */
static int send_line(HANDLE pipe, const char *line)
{
    DWORD written = 0;
    char buffer[BUFFER_SIZE];
    snprintf(buffer, sizeof(buffer), "%s\n", line);

    if (!WriteFile(pipe, buffer, (DWORD)strlen(buffer), &written, NULL)) {
        printf("WriteFile failed, error=%lu\n", GetLastError());
        return -1;
    }
    return 0;
}

/**
 * 接收一行数据
 */
static int recv_line(HANDLE pipe, char *line, size_t size)
{
    size_t pos = 0;
    while (pos + 1 < size) {
        char ch;
        DWORD read = 0;
        if (!ReadFile(pipe, &ch, 1, &read, NULL) || read == 0) {
            printf("ReadFile failed, error=%lu\n", GetLastError());
            return -1;
        }
        if (ch == '\n') {
            break;
        }
        if (ch != '\r') {
            line[pos++] = ch;
        }
    }
    line[pos] = '\0';
    return 0;
}

/**
 * 等待用户按回车
 */
static int wait_for_enter(const char *message)
{
    printf("%s", message);
    fflush(stdout);

    int ch;
    while ((ch = getchar()) != '\n' && ch != EOF) {
    }
    return 0;
}

/**
 * 请求Python执行do_data函数
 */
static int request_do_data(HANDLE cmd_pipe, HANDLE rsp_pipe, int index)
{
    char line[BUFFER_SIZE];

    printf("\n[%d] C -> Python: DO_DATA\n", index);
    if (send_line(cmd_pipe, "DO_DATA") != 0) {
        return -1;
    }

    if (recv_line(rsp_pipe, line, sizeof(line)) != 0) {
        return -1;
    }
    printf("[%d] Python result: %s\n", index, line);

    if (recv_line(rsp_pipe, line, sizeof(line)) != 0) {
        return -1;
    }
    printf("[%d] Python flag: %s\n", index, line);

    if (strcmp(line, "COMPLETE") != 0) {
        printf("Unexpected completion flag: %s\n", line);
        return -1;
    }
    return 0;
}

/**
 * 运行Python进程并通过管道通信
 */
int run_python_with_pipes(const Config *config)
{
    char python_exe[MAX_PATH];
    char script_path[MAX_PATH];
    char work_dir[MAX_PATH];
    char cmd_pipe_name[128];
    char rsp_pipe_name[128];

    printf("=== Configuration ===\n");
    printf("venv_path  : %s\n", config->venv_path);
    printf("script_name: %s\n", config->script_name);
    printf("work_path  : %s\n", config->work_path[0] != '\0' ? config->work_path : "(not set)");
    printf("====================\n\n");

    // 解析Python解释器路径
    if (resolve_python_exe(config->venv_path, python_exe, sizeof(python_exe)) != 0) {
        return -1;
    }

    // 解析Python脚本路径（使用work_path）
    if (resolve_script_path(config->script_name, config->work_path, script_path, sizeof(script_path)) != 0) {
        return -1;
    }

    // 确定工作目录
    if (config->work_path[0] != '\0' && dir_exists(config->work_path)) {
        // 使用配置的工作目录
        strncpy(work_dir, config->work_path, sizeof(work_dir) - 1);
        work_dir[sizeof(work_dir) - 1] = '\0';
    } else {
        // 使用脚本所在目录
        dirname_from_path(script_path, work_dir, sizeof(work_dir));
    }
    
    if (!dir_exists(work_dir)) {
        printf("Invalid working directory: %s\n", work_dir);
        return -1;
    }

    // 创建管道名称（使用进程ID确保唯一性）
    snprintf(cmd_pipe_name, sizeof(cmd_pipe_name), "\\\\.\\pipe\\c_to_python_%lu", GetCurrentProcessId());
    snprintf(rsp_pipe_name, sizeof(rsp_pipe_name), "\\\\.\\pipe\\python_to_c_%lu", GetCurrentProcessId());

    // 创建管道
    HANDLE cmd_pipe = create_pipe(cmd_pipe_name);
    HANDLE rsp_pipe = create_pipe(rsp_pipe_name);
    if (!cmd_pipe || !rsp_pipe) {
        if (cmd_pipe) CloseHandle(cmd_pipe);
        if (rsp_pipe) CloseHandle(rsp_pipe);
        return -1;
    }

    // 构建命令行
    char command_line[2048];
    snprintf(command_line, sizeof(command_line), "\"%s\" \"%s\" \"%s\" \"%s\"",
             python_exe, script_path, cmd_pipe_name, rsp_pipe_name);

    // 启动Python进程
    STARTUPINFOA si;
    PROCESS_INFORMATION pi;
    ZeroMemory(&si, sizeof(si));
    ZeroMemory(&pi, sizeof(pi));
    si.cb = sizeof(si);

    printf("Python exe   : %s\n", python_exe);
    printf("Script       : %s\n", script_path);
    printf("Work dir     : %s\n", work_dir);
    printf("Command line : %s\n", command_line);
    printf("Starting Python process...\n");

    // 设置环境变量，以便Python可以找到模块
    char pythonpath_env[2048];
    if (config->work_path[0] != '\0') {
        snprintf(pythonpath_env, sizeof(pythonpath_env), 
                 "PYTHONPATH=%s;%s\\src",
                 config->work_path, config->work_path);
        printf("Setting PYTHONPATH: %s\n", pythonpath_env);
        putenv(pythonpath_env);
    }

    if (!CreateProcessA(NULL, command_line, NULL, NULL, FALSE, 0, NULL, work_dir, &si, &pi)) {
        printf("CreateProcess failed, error=%lu\n", GetLastError());
        CloseHandle(cmd_pipe);
        CloseHandle(rsp_pipe);
        return -1;
    }

    // 等待Python连接管道
    if (connect_pipe(cmd_pipe, cmd_pipe_name) != 0 ||
        connect_pipe(rsp_pipe, rsp_pipe_name) != 0) {
        TerminateProcess(pi.hProcess, 1);
        CloseHandle(pi.hThread);
        CloseHandle(pi.hProcess);
        CloseHandle(cmd_pipe);
        CloseHandle(rsp_pipe);
        return -1;
    }

    // 等待Python发送READY信号
    char line[BUFFER_SIZE];
    if (recv_line(rsp_pipe, line, sizeof(line)) != 0 || strcmp(line, "READY") != 0) {
        printf("Python did not send READY\n");
        send_line(cmd_pipe, "EXIT");
        WaitForSingleObject(pi.hProcess, 2000);
        CloseHandle(pi.hThread);
        CloseHandle(pi.hProcess);
        CloseHandle(cmd_pipe);
        CloseHandle(rsp_pipe);
        return -1;
    }

    printf("Handshake OK: Python is READY\n");

    // 第一次执行
    wait_for_enter("\nPress Enter to request Python do_data #1...");
    if (request_do_data(cmd_pipe, rsp_pipe, 1) != 0) {
        send_line(cmd_pipe, "EXIT");
        WaitForSingleObject(pi.hProcess, 2000);
        CloseHandle(pi.hThread);
        CloseHandle(pi.hProcess);
        CloseHandle(cmd_pipe);
        CloseHandle(rsp_pipe);
        return -1;
    }

    // 第二次执行
    wait_for_enter("\nPress Enter to request Python do_data #2...");
    if (request_do_data(cmd_pipe, rsp_pipe, 2) != 0) {
        send_line(cmd_pipe, "EXIT");
        WaitForSingleObject(pi.hProcess, 2000);
        CloseHandle(pi.hThread);
        CloseHandle(pi.hProcess);
        CloseHandle(cmd_pipe);
        CloseHandle(rsp_pipe);
        return -1;
    }

    // 发送退出命令
    printf("\nC -> Python: EXIT\n");
    send_line(cmd_pipe, "EXIT");
    WaitForSingleObject(pi.hProcess, 5000);

    // 清理资源
    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);
    CloseHandle(cmd_pipe);
    CloseHandle(rsp_pipe);
    return 0;
}