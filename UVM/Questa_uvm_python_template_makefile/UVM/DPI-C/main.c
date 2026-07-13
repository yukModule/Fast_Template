#include <stdio.h>
#include "read_json.h"
#include "pipe_py.h"

int main(void)
{
    Config config;

    // 加载配置文件
    if (load_config("config.json", &config) != 0) {
        return 1;
    }

    printf("Config loaded\n");
    printf("venv_path  : %s\n", config.venv_path);
    printf("script_name: %s\n\n", config.script_name);

    // 运行Python进程并通过管道通信
    if (run_python_with_pipes(&config) != 0) {
        printf("\nProgram failed\n");
        return 1;
    }

    printf("\nProgram completed successfully\n");
    return 0;
}