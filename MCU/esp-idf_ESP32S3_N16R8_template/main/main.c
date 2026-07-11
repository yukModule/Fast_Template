#include <stdio.h>
#include <driver/gpio.h>

#include "esp_task_wdt.h"
#include "mat.h"


#define GPIO_LED_IO 18  //LED灯对应GPIO18

void app_main(void)
{
    printf("hello RYMCU.rn \r\n");

	// step 1 初始化GPIO
    gpio_config_t my_io_config =
    {
        .pin_bit_mask = 1 << GPIO_LED_IO, //
        .mode = GPIO_MODE_OUTPUT, //设置为输出模式
    };
    gpio_config(&my_io_config);

    // step 2 点亮LED
    gpio_set_level(GPIO_LED_IO,0);
    printf("1 \r\n");
    printf("%d \r\n", global_mat);
    
    while (1){
        vTaskDelay(pdMS_TO_TICKS(1000)); //手动喂狗
    }
    
}

