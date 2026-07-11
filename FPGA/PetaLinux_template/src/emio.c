#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <stdbool.h>
#include <string.h>


#define EMIO_BASE       416
#define EMIO_PIN_INDEX  0       // 第一个EMIO引脚
#define EMIO_PIN_ADDR   (EMIO_BASE + EMIO_PIN_INDEX)


void emio_gpio_init(void)
{
    int gpio_fd;
    char buf[100];

    // 1. 导出GPIO
    gpio_fd = open("/sys/class/gpio/export", O_WRONLY);
    if (gpio_fd < 0) {
        printf("Failed to open /sys/class/gpio/export\n");
        return;
    }
    snprintf(buf, sizeof(buf), "%d", EMIO_PIN_ADDR);
    write(gpio_fd, buf, strlen(buf));
    close(gpio_fd);

    // 等待sysfs创建
    usleep(100000);

    // 2. 设置方向为输出
    snprintf(buf, sizeof(buf), "/sys/class/gpio/gpio%d/direction", EMIO_PIN_ADDR);
    gpio_fd = open(buf, O_RDWR);
    if (gpio_fd < 0) {
        printf("Failed to open direction for GPIO %d\n", EMIO_PIN_ADDR);
        return;
    }
    write(gpio_fd, "out", 4);
    close(gpio_fd);

    printf("EMIO GPIO %d initialized as output\n", EMIO_PIN_ADDR);
}

void emio_gpio_set(bool is_on)
{
    int gpio_fd;
    char buf[100];

    snprintf(buf, sizeof(buf), "/sys/class/gpio/gpio%d/value", EMIO_PIN_ADDR);
    gpio_fd = open(buf, O_RDWR);
    if (gpio_fd < 0) {
        printf("Failed to open value for GPIO %d\n", EMIO_PIN_ADDR);
        return;
    }

    if (is_on) {
        write(gpio_fd, "1", 2);
    } else {
        write(gpio_fd, "0", 2);
    }
    close(gpio_fd);
}

int main()
{
    printf("=== EMIO GPIO Test ===\n");
    printf("EMIO Pin: %d (EMIO Base: %d, Index: %d)\n", 
           EMIO_PIN_ADDR, EMIO_BASE, EMIO_PIN_INDEX);

    // 初始化EMIO GPIO
    emio_gpio_init();


    // 输出高电平
    emio_gpio_set(true);
    printf("EMIO Output: HIGH (1)\n");
    usleep(500000);  // 0.5秒

    // 输出低电平
    emio_gpio_set(false);
    printf("EMIO Output: LOW  (0)\n");


    return 0;
}
