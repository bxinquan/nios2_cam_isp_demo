#ifndef __AVALON_VIP_REGS__
#define __AVALON_VIP_REGS__

#define VIP_REG_RESET    0
#define VIP_REG_TOP_EN    1
#define VIP_REG_DSCALE_SCALE    2
#define VIP_REG_INT_STATUS    3
#define VIP_REG_INT_MASK    4

#define VIP_REG_TOP_EN_BIT_HIST_EQU_EN     (1<<0)
#define VIP_REG_TOP_EN_BIT_SOBEL_EN        (1<<1)
#define VIP_REG_TOP_EN_BIT_YUV2RGB_EN      (1<<2)
#define VIP_REG_TOP_EN_BIT_DSCALE_EN       (1<<3)

#define VIP_REG_INT_STATUS_BIT_FRAME_DONE  (1<<0)

#define VIP_REG_INT_MASK_BIT_FRAME_DONE    (1<<0)

#endif
