#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <stdint.h>

#define PHYS_ADDR       0x60000000
#define MAP_SIZE        0x1000      // 映射 4KB 空间

int main() {
    int fd;
    void *virt_addr;
    uint32_t *base_ptr;
    int t;

    // 1. 打开 /dev/mem 设备
    fd = open("/dev/mem", O_RDWR | O_SYNC); // O_SYNC 保证不经过缓存，直接读写内存
    if (fd < 0) {
        perror("无法打开 /dev/mem");
        return -1;
    }

    // 2. 将物理地址映射到进程的虚拟地址空间
    virt_addr = mmap(NULL, MAP_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, PHYS_ADDR);
    if (virt_addr == MAP_FAILED) {
        perror("mmap 映射失败");
        close(fd);
        return -1;
    }

    base_ptr = (uint32_t *)virt_addr;

    printf("PetaLinux 内存读取测试程序已启动\n");

    while (1) {
        printf("输入 0 开始读取，输入其他退出: ");
        if (scanf("%d", &t) != 1 || t != 0) break;

        // 在 Linux 下，通过 O_SYNC 映射的地址不需要手动进行 Cache Invalidate
        for (int i = 0; i < 32*32; i++) {
            printf("地址 0x%08X: 0x%08X\n", PHYS_ADDR + i * 4, base_ptr[i]);
        }
        printf("========================== \n");
    }

    // 3. 释放映射并关闭文件
    munmap(virt_addr, MAP_SIZE);
    close(fd);

    return 0;
}
