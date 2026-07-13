#ifndef PIPE_PY_H
#define PIPE_PY_H

#include "read_json.h"

/**
 * 通过管道启动Python进程并执行握手通信
 * @param config 配置结构体
 * @return 0成功，-1失败
 */
int run_python_with_pipes(const Config *config);

#endif // PIPE_PY_H