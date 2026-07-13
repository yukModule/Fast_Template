#ifndef READ_JSON_H
#define READ_JSON_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <windows.h>

#define MAX_PATH 260

typedef struct {
    char venv_path[MAX_PATH];
    char script_name[MAX_PATH];
    char work_path[MAX_PATH];  // 新增工作路径
} Config;

/**
 * 从JSON文件加载配置
 * @param filename JSON文件名
 * @param config 配置结构体指针
 * @return 0成功，-1失败
 */
int load_config(const char *filename, Config *config);

#endif // READ_JSON_H