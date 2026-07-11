#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <stdint.h>
#include <errno.h>

// ./read 0x70000000 32


int main(int argc, char *argv[]) {
    int fd;
    void *virt_addr;
    uint32_t *base_ptr;
    uint32_t phys_addr;
    size_t map_size;
    uint32_t read_words;

    // 检查参数数量
    if (argc != 3) {
        fprintf(stderr, "错误: 需要 2 个参数\n\n");
        return -1;
    }

    // 检查帮助选项
    if (strcmp(argv[1], "-h") == 0 || strcmp(argv[1], "--help") == 0) {
        return 0;
    }

    // 解析地址
    phys_addr = strtoul(argv[1], NULL, 16);
    if (phys_addr == 0 && errno == EINVAL) {
        fprintf(stderr, "错误: 无效的地址格式 '%s'\n", argv[1]);
        return -1;
    }

    // 解析大小
    map_size = strtoul(argv[2], NULL, 16);
    if (map_size == 0 && errno == EINVAL) {
        fprintf(stderr, "错误: 无效的大小格式 '%s'\n", argv[2]);
        return -1;
    }

    // 对齐到页大小（4KB）
    map_size = (map_size + 0xFFF) & ~0xFFF;
    read_words = map_size / sizeof(uint32_t);

    printf("========================================\n");
    printf("  PL AXI 内存读取工具\n");
    printf("========================================\n");
    printf("物理地址: 0x%08X\n", phys_addr);
    printf("映射大小: 0x%zX (%zu 字节)\n", map_size, map_size);
    printf("读取字数: %u (32位)\n", read_words);
    printf("========================================\n\n");

    // 打开 /dev/mem 设备
    fd = open("/dev/mem", O_RDWR | O_SYNC);
    if (fd < 0) {
        perror("无法打开 /dev/mem");
        fprintf(stderr, "提示: 请以 root 权限运行\n");
        return -1;
    }

    // 映射物理地址到虚拟地址空间
    virt_addr = mmap(NULL, map_size, PROT_READ | PROT_WRITE, 
                     MAP_SHARED, fd, phys_addr);
    if (virt_addr == MAP_FAILED) {
        perror("mmap 映射失败");
        close(fd);
        return -1;
    }

    base_ptr = (uint32_t *)virt_addr;

    printf("内存映射成功！虚拟地址: %p\n\n", virt_addr);
    printf("开始读取...\n");
    printf("========================================\n");

    // 读取并打印数据
    for (int i = 0; i < read_words; i++) {
        uint32_t data = base_ptr[i];
        printf("0x%08X: 0x%08X\n", phys_addr + i * 4, data);
    }

    printf("========================================\n");
    printf("读取完成！共读取 %u 个 32位数据\n", read_words);

    // 释放映射并关闭文件
    munmap(virt_addr, map_size);
    close(fd);

    return 0;
}
