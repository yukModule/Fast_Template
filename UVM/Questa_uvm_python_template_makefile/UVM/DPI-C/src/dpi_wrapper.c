/**
 * DPI-C wrapper for QuestaSim UVM verification.
 * Bridges SystemVerilog to Python reference model via Windows named pipes.
 *
 * Exported DPI functions:
 *   - dpi_init()              : Initialize Python process and pipe communication
 *   - dpi_compute(a,b,&s,&c)  : Send operands to Python, get 8-bit adder result
 *   - dpi_close()             : Shutdown Python process and cleanup
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <windows.h>

/* Ensure Windows API constants are defined (older MinGW may lack these) */
#ifndef GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS
#define GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS    0x00000004
#endif
#ifndef GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT
#define GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT 0x00000002
#endif

/* ===== Configuration (from config.json) ===== */
#define MAX_PATH_LEN    512
#define BUFFER_SIZE     4096

typedef struct {
    char venv_path[MAX_PATH_LEN];
    char script_name[MAX_PATH_LEN];
    char work_path[MAX_PATH_LEN];
} Config;

/* ===== Global state for persistent Python connection ===== */
static HANDLE g_cmd_pipe    = NULL;
static HANDLE g_rsp_pipe    = NULL;
static HANDLE g_proc_handle = NULL;
static HANDLE g_thread_handle = NULL;
static int    g_initialized = 0;

/* ===== Forward declarations ===== */
static int  file_exists(const char *path);
static int  dir_exists(const char *path);
static void dirname_from_path(const char *path, char *dir, size_t dir_size);
static int  resolve_python_exe(const char *venv_path, char *python_exe, size_t size);
static int  load_config_json(const char *filename, Config *config);
static HANDLE create_pipe(const char *pipe_name);
static int  connect_pipe(HANDLE pipe, const char *name);
static int  send_line(HANDLE pipe, const char *line);
static int  recv_line(HANDLE pipe, char *line, size_t size);

/* ===== DPI-C Exported Functions ===== */

/**
 * Initialize the Python reference model process.
 * Called once at the start of simulation.
 */
__declspec(dllexport) void dpi_init(void)
{
    Config config;
    char python_exe[MAX_PATH_LEN];
    char script_path[MAX_PATH_LEN];
    char work_dir[MAX_PATH_LEN];
    char dll_dir[MAX_PATH_LEN];
    char config_path[MAX_PATH_LEN];
    char cmd_pipe_name[128];
    char rsp_pipe_name[128];
    char command_line[2048];
    char pythonpath_env[2048];
    char line[BUFFER_SIZE];

    if (g_initialized) {
        printf("[DPI] Already initialized, skipping\n");
        return;
    }

    printf("\n========================================\n");
    printf("[DPI] dpi_init() - Starting Python Reference Model\n");
    printf("========================================\n\n");

    /* Determine directory containing this DLL */
    char dll_path[MAX_PATH_LEN];
    HMODULE hmod;
    /* Get the module handle for this DLL. We use a trick: pass a function
       pointer from this DLL to GetModuleHandleEx. */
    GetModuleHandleExA(
        GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
        (LPCSTR)&dpi_init,
        &hmod);
    GetModuleFileNameA(hmod, dll_path, sizeof(dll_path));
    dirname_from_path(dll_path, dll_dir, sizeof(dll_dir));
    printf("[DPI] DLL directory: %s\n", dll_dir);

    /* Load config.json relative to DLL */
    {
        int n = snprintf(config_path, sizeof(config_path), "%s\\config.json", dll_dir);
        if (n < 0 || (size_t)n >= sizeof(config_path)) {
            printf("[DPI] ERROR: config path too long\n");
            return;
        }
    }
    printf("[DPI] Loading config: %s\n", config_path);

    if (load_config_json(config_path, &config) != 0) {
        printf("[DPI] ERROR: Failed to load config.json\n");
        return;
    }

    /* Resolve paths relative to DLL directory.
     * Use 2*MAX_PATH_LEN for concatenated paths to avoid truncation warnings. */
    char abs_venv[MAX_PATH_LEN];
    char abs_script[MAX_PATH_LEN];
    char abs_work[MAX_PATH_LEN];
    char combined[2 * MAX_PATH_LEN + 4];

    /* Resolve venv_path */
    {
        int n = snprintf(combined, sizeof(combined), "%s\\%s", dll_dir, config.venv_path);
        if (n < 0 || (size_t)n >= sizeof(combined)) {
            printf("[DPI] ERROR: venv path too long\n");
            return;
        }
        GetFullPathNameA(combined, MAX_PATH_LEN, abs_venv, NULL);
    }

    /* Resolve script_name */
    {
        int n = snprintf(combined, sizeof(combined), "%s\\%s", dll_dir, config.script_name);
        if (n < 0 || (size_t)n >= sizeof(combined)) {
            printf("[DPI] ERROR: script path too long\n");
            return;
        }
        GetFullPathNameA(combined, MAX_PATH_LEN, abs_script, NULL);
    }

    /* Resolve work_path */
    if (config.work_path[0] != '\0') {
        int n = snprintf(combined, sizeof(combined), "%s\\%s", dll_dir, config.work_path);
        if (n < 0 || (size_t)n >= sizeof(combined)) {
            printf("[DPI] ERROR: work path too long\n");
            return;
        }
        GetFullPathNameA(combined, MAX_PATH_LEN, abs_work, NULL);
    } else {
        dirname_from_path(abs_script, abs_work, sizeof(abs_work));
    }

    printf("[DPI] Resolved venv: %s\n", abs_venv);
    printf("[DPI] Resolved script: %s\n", abs_script);
    printf("[DPI] Resolved work dir: %s\n", abs_work);

    /* Resolve Python executable */
    if (resolve_python_exe(abs_venv, python_exe, sizeof(python_exe)) != 0) {
        printf("[DPI] ERROR: Cannot find python.exe\n");
        return;
    }
    printf("[DPI] Python exe: %s\n", python_exe);

    /* Verify script exists */
    if (!file_exists(abs_script)) {
        printf("[DPI] ERROR: Script not found: %s\n", abs_script);
        return;
    }
    strncpy(script_path, abs_script, sizeof(script_path) - 1);

    /* Determine working directory */
    if (dir_exists(abs_work)) {
        strncpy(work_dir, abs_work, sizeof(work_dir) - 1);
        work_dir[sizeof(work_dir) - 1] = '\0';
    } else {
        dirname_from_path(script_path, work_dir, sizeof(work_dir));
    }

    /* Create unique pipe names */
    snprintf(cmd_pipe_name, sizeof(cmd_pipe_name),
             "\\\\.\\pipe\\c_to_python_dpi_%lu", GetCurrentProcessId());
    snprintf(rsp_pipe_name, sizeof(rsp_pipe_name),
             "\\\\.\\pipe\\python_to_c_dpi_%lu", GetCurrentProcessId());

    /* Create pipes */
    g_cmd_pipe = create_pipe(cmd_pipe_name);
    g_rsp_pipe = create_pipe(rsp_pipe_name);
    if (!g_cmd_pipe || !g_rsp_pipe) {
        printf("[DPI] ERROR: Failed to create pipes\n");
        if (g_cmd_pipe) { CloseHandle(g_cmd_pipe); g_cmd_pipe = NULL; }
        if (g_rsp_pipe) { CloseHandle(g_rsp_pipe); g_rsp_pipe = NULL; }
        return;
    }

    /* Build command line: "python.exe" "script.py" "cmd_pipe" "rsp_pipe"
     * Python sys.argv will be: [script_path, cmd_pipe, rsp_pipe] (len=3) */
    snprintf(command_line, sizeof(command_line),
             "\"%s\" \"%s\" \"%s\" \"%s\"",
             python_exe, script_path, cmd_pipe_name, rsp_pipe_name);

    printf("[DPI] Command: %s\n", command_line);

    /* Set PYTHONPATH */
    snprintf(pythonpath_env, sizeof(pythonpath_env),
             "PYTHONPATH=%s;%s\\Python",
             work_dir, work_dir);
    putenv(pythonpath_env);

    /* Start Python process */
    STARTUPINFOA si;
    PROCESS_INFORMATION pi;
    ZeroMemory(&si, sizeof(si));
    ZeroMemory(&pi, sizeof(pi));
    si.cb = sizeof(si);

    if (!CreateProcessA(NULL, command_line, NULL, NULL, FALSE,
                        0, NULL, work_dir, &si, &pi)) {
        printf("[DPI] ERROR: CreateProcess failed, error=%lu\n", GetLastError());
        CloseHandle(g_cmd_pipe); g_cmd_pipe = NULL;
        CloseHandle(g_rsp_pipe); g_rsp_pipe = NULL;
        return;
    }

    g_proc_handle = pi.hProcess;
    g_thread_handle = pi.hThread;
    printf("[DPI] Python process started, PID=%lu\n", pi.dwProcessId);

    /* Connect pipes (Python will connect as client) */
    if (connect_pipe(g_cmd_pipe, cmd_pipe_name) != 0 ||
        connect_pipe(g_rsp_pipe, rsp_pipe_name) != 0) {
        printf("[DPI] ERROR: Pipe connection failed\n");
        TerminateProcess(g_proc_handle, 1);
        CloseHandle(g_thread_handle); g_thread_handle = NULL;
        CloseHandle(g_proc_handle); g_proc_handle = NULL;
        CloseHandle(g_cmd_pipe); g_cmd_pipe = NULL;
        CloseHandle(g_rsp_pipe); g_rsp_pipe = NULL;
        return;
    }

    /* Wait for READY signal from Python */
    if (recv_line(g_rsp_pipe, line, sizeof(line)) != 0 ||
        strcmp(line, "READY") != 0) {
        printf("[DPI] ERROR: Python did not send READY (got: '%s')\n", line);
        send_line(g_cmd_pipe, "EXIT");
        WaitForSingleObject(g_proc_handle, 3000);
        CloseHandle(g_thread_handle); g_thread_handle = NULL;
        CloseHandle(g_proc_handle); g_proc_handle = NULL;
        CloseHandle(g_cmd_pipe); g_cmd_pipe = NULL;
        CloseHandle(g_rsp_pipe); g_rsp_pipe = NULL;
        return;
    }

    g_initialized = 1;
    printf("[DPI] Handshake OK - Python is READY\n");
    printf("========================================\n\n");
}

/**
 * Compute one 8-bit adder reference result.
 * Called each cycle with DUT inputs a and b.
 * Returns the expected sum and carry-out via pointers.
 */
__declspec(dllexport) void dpi_compute(int a, int b, int *sum, int *cout)
{
    char cmd[256];
    char line[BUFFER_SIZE];

    if (!g_initialized) {
        printf("[DPI] ERROR: Not initialized, cannot compute\n");
        *sum = 0;
        *cout = 0;
        return;
    }

    /* Send COMPUTE command */
    snprintf(cmd, sizeof(cmd), "COMPUTE %d %d", a, b);
    if (send_line(g_cmd_pipe, cmd) != 0) {
        printf("[DPI] ERROR: Failed to send COMPUTE command\n");
        *sum = 0;
        *cout = 0;
        return;
    }

    /* Receive result: "<sum> <cout>" */
    if (recv_line(g_rsp_pipe, line, sizeof(line)) != 0) {
        printf("[DPI] ERROR: Failed to receive result\n");
        *sum = 0;
        *cout = 0;
        return;
    }

    /* Parse result */
    if (sscanf(line, "%d %d", sum, cout) != 2) {
        printf("[DPI] ERROR: Invalid result format: '%s'\n", line);
        *sum = 0;
        *cout = 0;
    }

    /* Receive COMPLETE flag */
    if (recv_line(g_rsp_pipe, line, sizeof(line)) != 0) {
        printf("[DPI] ERROR: Failed to receive COMPLETE flag\n");
        *sum = 0;
        *cout = 0;
        return;
    }

    if (strcmp(line, "COMPLETE") != 0) {
        printf("[DPI] WARNING: Unexpected completion flag: '%s'\n", line);
    }
}

/**
 * Shutdown the Python process and cleanup resources.
 * Called at the end of simulation.
 */
__declspec(dllexport) void dpi_close(void)
{
    if (!g_initialized) {
        printf("[DPI] Not initialized, nothing to close\n");
        return;
    }

    printf("\n[DPI] dpi_close() - Shutting down Python\n");

    /* Send EXIT command */
    send_line(g_cmd_pipe, "EXIT");

    /* Wait for Python to exit */
    if (g_proc_handle) {
        WaitForSingleObject(g_proc_handle, 5000);
    }

    /* Cleanup handles */
    if (g_thread_handle) { CloseHandle(g_thread_handle); g_thread_handle = NULL; }
    if (g_proc_handle)   { CloseHandle(g_proc_handle);   g_proc_handle   = NULL; }
    if (g_cmd_pipe)       { CloseHandle(g_cmd_pipe);      g_cmd_pipe       = NULL; }
    if (g_rsp_pipe)       { CloseHandle(g_rsp_pipe);      g_rsp_pipe       = NULL; }

    g_initialized = 0;
    printf("[DPI] Cleanup complete\n");
}

/* ===== Utility Functions ===== */

static int file_exists(const char *path)
{
    DWORD attr = GetFileAttributesA(path);
    return (attr != INVALID_FILE_ATTRIBUTES) && !(attr & FILE_ATTRIBUTE_DIRECTORY);
}

static int dir_exists(const char *path)
{
    DWORD attr = GetFileAttributesA(path);
    return (attr != INVALID_FILE_ATTRIBUTES) && (attr & FILE_ATTRIBUTE_DIRECTORY);
}

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

static int resolve_python_exe(const char *venv_path, char *python_exe, size_t size)
{
    /* Try as direct path to python.exe */
    snprintf(python_exe, size, "%s\\python.exe", venv_path);
    if (file_exists(python_exe)) return 0;

    /* Try Scripts directory (virtual env) */
    snprintf(python_exe, size, "%s\\Scripts\\python.exe", venv_path);
    if (file_exists(python_exe)) return 0;

    /* Try the path itself */
    snprintf(python_exe, size, "%s", venv_path);
    if (file_exists(python_exe)) return 0;

    printf("[DPI] ERROR: Cannot find python.exe in '%s'\n", venv_path);
    return -1;
}

static int read_json_string(const char *json, const char *key, char *out, size_t out_size)
{
    char pattern[256];
    snprintf(pattern, sizeof(pattern), "\"%s\"", key);

    const char *p = strstr(json, pattern);
    if (!p) return -1;

    p = strchr(p + strlen(pattern), ':');
    if (!p) return -1;

    p = strchr(p, '"');
    if (!p) return -1;
    p++;

    size_t i = 0;
    while (*p && *p != '"' && i + 1 < out_size) {
        if (*p == '\\' && p[1]) {
            p++;
            switch (*p) {
            case '\\': case '"': case '/': out[i++] = *p++; break;
            case 'n':  out[i++] = '\n'; p++; break;
            case 'r':  out[i++] = '\r'; p++; break;
            case 't':  out[i++] = '\t'; p++; break;
            default:   out[i++] = *p++; break;
            }
        } else {
            out[i++] = *p++;
        }
    }
    out[i] = '\0';
    return (*p == '"') ? 0 : -1;
}

static int load_config_json(const char *filename, Config *config)
{
    FILE *fp = fopen(filename, "rb");
    if (!fp) {
        printf("[DPI] ERROR: Cannot open config: %s\n", filename);
        return -1;
    }

    fseek(fp, 0, SEEK_END);
    long fsize = ftell(fp);
    fseek(fp, 0, SEEK_SET);

    char *json = (char *)malloc((size_t)fsize + 1);
    if (!json) { fclose(fp); return -1; }
    if (fread(json, 1, (size_t)fsize, fp) != (size_t)fsize) {
        free(json); fclose(fp); return -1;
    }
    json[fsize] = '\0';
    fclose(fp);

    /* Initialize defaults */
    memset(config, 0, sizeof(*config));

    /* Read fields */
    if (read_json_string(json, "venv_path", config->venv_path, sizeof(config->venv_path)) != 0) {
        printf("[DPI] ERROR: venv_path not found in config\n");
        free(json);
        return -1;
    }
    read_json_string(json, "script_name", config->script_name, sizeof(config->script_name));
    read_json_string(json, "work", config->work_path, sizeof(config->work_path));

    free(json);

    if (config->script_name[0] == '\0') {
        printf("[DPI] ERROR: script_name not found in config\n");
        return -1;
    }

    printf("[DPI] Config: venv=%s, script=%s, work=%s\n",
           config->venv_path, config->script_name,
           config->work_path[0] ? config->work_path : "(not set)");

    return 0;
}

/* ===== Pipe Communication Functions ===== */

static HANDLE create_pipe(const char *pipe_name)
{
    HANDLE pipe = CreateNamedPipeA(
        pipe_name,
        PIPE_ACCESS_DUPLEX,
        PIPE_TYPE_BYTE | PIPE_READMODE_BYTE | PIPE_WAIT,
        1,
        BUFFER_SIZE,
        BUFFER_SIZE,
        5000,  /* timeout ms */
        NULL);

    if (pipe == INVALID_HANDLE_VALUE) {
        printf("[DPI] ERROR: CreateNamedPipe failed for %s, error=%lu\n",
               pipe_name, GetLastError());
        return NULL;
    }
    return pipe;
}

static int connect_pipe(HANDLE pipe, const char *name)
{
    BOOL ok = ConnectNamedPipe(pipe, NULL);
    DWORD err = GetLastError();
    if (!ok && err != ERROR_PIPE_CONNECTED) {
        printf("[DPI] ERROR: ConnectNamedPipe failed for %s, error=%lu\n", name, err);
        return -1;
    }
    return 0;
}

static int send_line(HANDLE pipe, const char *line)
{
    DWORD written = 0;
    char buffer[BUFFER_SIZE];
    int len = snprintf(buffer, sizeof(buffer), "%s\n", line);

    if (!WriteFile(pipe, buffer, (DWORD)len, &written, NULL)) {
        printf("[DPI] ERROR: WriteFile failed, error=%lu\n", GetLastError());
        return -1;
    }
    return 0;
}

static int recv_line(HANDLE pipe, char *line, size_t size)
{
    size_t pos = 0;
    while (pos + 1 < size) {
        char ch;
        DWORD read = 0;
        if (!ReadFile(pipe, &ch, 1, &read, NULL) || read == 0) {
            printf("[DPI] ERROR: ReadFile failed (pos=%zu), error=%lu\n", pos, GetLastError());
            return -1;
        }
        if (ch == '\n') break;
        if (ch != '\r') line[pos++] = ch;
    }
    line[pos] = '\0';
    return 0;
}
