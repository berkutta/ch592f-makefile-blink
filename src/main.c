#include "CH59x_common.h"

int main()
{
    SetSysClock(CLK_SOURCE_PLL_60MHz);

    GPIOB_ModeCfg(GPIO_Pin_23, GPIO_ModeOut_PP_5mA);

    while (1) {
        GPIOB_SetBits(GPIO_Pin_23);
        DelayMs(500);
        GPIOB_ResetBits(GPIO_Pin_23);
        DelayMs(500);
    }
}