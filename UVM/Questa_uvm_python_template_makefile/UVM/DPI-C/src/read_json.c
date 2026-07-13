#include "read_json.h"

/**
 * 检查目录是否存在
 */
static int dir_exists(const char *path)
{
    DWORD attr = GetFileAttributesA(path);
    return attr != INVALID_FILE_ATTRIBUTES && (attr & FILE_ATTRIBUTE_DIRECTORY);
}

/**
 * 获取绝对路径（处理相对路径）
 */
static int get_absolute_path(const char *base_path, const char *relative_path, char *absolute_path, size_t size)
{
    /* Use 2*MAX_PATH for concatenation safety */
    char full_path[MAX_PATH * 2];
    
    // 如果是绝对路径，直接使用
    if ((relative_path[0] == 'C' && relative_path[1] == ':') ||
        (relative_path[0] == 'c' && relative_path[1] == ':') ||
        (relative_path[0] == '\\' && relative_path[1] == '\\')) {
        strncpy(full_path, relative_path, sizeof(full_path) - 1);
        full_path[sizeof(full_path) - 1] = '\0';
    } else {
        // 获取当前工作目录
        char current_dir[MAX_PATH];
        GetCurrentDirectoryA(sizeof(current_dir), current_dir);
        
        // 构建完整路径
        snprintf(full_path, sizeof(full_path), "%s\\%s", current_dir, relative_path);
    }
    
    // 规范化路径（处理 .. 和 .）
    char normalized_path[MAX_PATH];
    if (GetFullPathNameA(full_path, MAX_PATH, normalized_path, NULL) == 0) {
        printf("Failed to resolve path: %s\n", full_path);
        return -1;
    }
    
    strncpy(absolute_path, normalized_path, size - 1);
    absolute_path[size - 1] = '\0';
    return 0;
}

/**
 * 从JSON字符串中读取指定key的字符串值
 */
static int read_json_string(const char *json, const char *key, char *out, size_t out_size)
{
    char pattern[128];
    snprintf(pattern, sizeof(pattern), "\"%s\"", key);

    const char *p = strstr(json, pattern);
    if (!p) {
        return -1;
    }
    p = strchr(p + strlen(pattern), ':');
    if (!p) {
        return -1;
    }
    p = strchr(p, '"');
    if (!p) {
        return -1;
    }
    p++;

    size_t i = 0;
    while (*p && *p != '"' && i + 1 < out_size) {
        if (*p == '\\' && p[1]) {
            p++;
            switch (*p) {
            case '\\':
            case '"':
            case '/':
                out[i++] = *p++;
                break;
            case 'n':
                out[i++] = '\n';
                p++;
                break;
            case 'r':
                out[i++] = '\r';
                p++;
                break;
            case 't':
                out[i++] = '\t';
                p++;
                break;
            default:
                out[i++] = *p++;
                break;
            }
        } else {
            out[i++] = *p++;
        }
    }
    out[i] = '\0';
    return *p == '"' ? 0 : -1;
}

/**
 * 加载配置文件
 */
int load_config(const char *filename, Config *config)
{
    FILE *file = fopen(filename, "rb");
    if (!file) {
        printf("Cannot open %s\n", filename);
        return -1;
    }

    fseek(file, 0, SEEK_END);
    long size = ftell(file);
    fseek(file, 0, SEEK_SET);

    char *json = (char *)malloc((size_t)size + 1);
    if (!json) {
        fclose(file);
        return -1;
    }

    if (fread(json, 1, (size_t)size, file) != (size_t)size) {
        free(json);
        fclose(file);
        return -1;
    }
    json[size] = '\0';
    fclose(file);

    // 初始化默认值
    config->venv_path[0] = '\0';
    config->work_path[0] = '\0';
    strcpy(config->script_name, "python.py");

    // 读取各个字段
    read_json_string(json, "venv_path", config->venv_path, sizeof(config->venv_path));
    read_json_string(json, "script_name", config->script_name, sizeof(config->script_name));
    read_json_string(json, "work", config->work_path, sizeof(config->work_path));
    
    free(json);

    // 检查必需字段
    if (config->venv_path[0] == '\0') {
        printf("config.json must contain venv_path\n");
        return -1;
    }

    // 处理相对路径，转换为绝对路径
    char absolute_work_path[MAX_PATH];
    if (config->work_path[0] != '\0') {
        if (get_absolute_path(NULL, config->work_path, absolute_work_path, sizeof(absolute_work_path)) == 0) {
            strncpy(config->work_path, absolute_work_path, sizeof(config->work_path) - 1);
            config->work_path[sizeof(config->work_path) - 1] = '\0';
            
            // 检查工作目录是否存在
            if (!dir_exists(config->work_path)) {
                printf("Warning: work path does not exist: %s\n", config->work_path);
            }
        } else {
            printf("Warning: Failed to resolve work path: %s\n", config->work_path);
        }
    }

    return 0;
}