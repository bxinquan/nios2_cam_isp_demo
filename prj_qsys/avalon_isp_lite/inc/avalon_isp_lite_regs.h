#ifndef __AVALON_ISP_LITE_REGS__
#define __AVALON_ISP_LITE_REGS__

#define ISP_REG_RESET    0
#define ISP_REG_TOP_EN    1
#define ISP_REG_BLC_B    2
#define ISP_REG_BLC_GB    3
#define ISP_REG_BLC_GR    4
#define ISP_REG_BLC_R    5
#define ISP_REG_DGAIN    6
#define ISP_REG_WB_RGAIN    7
#define ISP_REG_WB_GGAIN    8
#define ISP_REG_WB_BGAIN    9
#define ISP_REG_CCM_RR    10
#define ISP_REG_CCM_RG    11
#define ISP_REG_CCM_RB    12
#define ISP_REG_CCM_GR    13
#define ISP_REG_CCM_GG    14
#define ISP_REG_CCM_GB    15
#define ISP_REG_CCM_BR    16
#define ISP_REG_CCM_BG    17
#define ISP_REG_CCM_BB    18
#define ISP_REG_STAT_AWB_MIN    19
#define ISP_REG_STAT_AWB_MAX    20
#define ISP_REG_STAT_AE_PIX_CNT    21
#define ISP_REG_STAT_AE_SUM    22
#define ISP_REG_STAT_AWB_PIX_CNT    23
#define ISP_REG_STAT_AWB_SUM_R    24
#define ISP_REG_STAT_AWB_SUM_G    25
#define ISP_REG_STAT_AWB_SUM_B    26
#define ISP_REG_INT_STATUS    27
#define ISP_REG_INT_MASK    28

#define ISP_REG_STAT_AE_HIST_ADDR     1024
#define ISP_REG_STAT_AE_HIST_SIZE     256*4
#define ISP_REG_STAT_AWB_HIST_ADDR    2048
#define ISP_REG_STAT_AWB_HIST_SIZE    256*3


#define ISP_REG_TOP_EN_BIT_BLC_EN           (1<<0)
#define ISP_REG_TOP_EN_BIT_BNR_EN           (1<<1)
#define ISP_REG_TOP_EN_BIT_DGAIN_EN         (1<<2)
#define ISP_REG_TOP_EN_BIT_DEMOSIC_EN       (1<<3)
#define ISP_REG_TOP_EN_BIT_WB_EN            (1<<4)
#define ISP_REG_TOP_EN_BIT_CCM_EN           (1<<5)
#define ISP_REG_TOP_EN_BIT_CSC_EN           (1<<6)
#define ISP_REG_TOP_EN_BIT_GAMMA_EN         (1<<7)
#define ISP_REG_TOP_EN_BIT_EE_EN            (1<<8)
#define ISP_REG_TOP_EN_BIT_STAT_AE_EN       (1<<9)
#define ISP_REG_TOP_EN_BIT_STAT_AWB_EN      (1<<10)

#define ISP_REG_INT_STATUS_BIT_FRAME_DONE   (1<<0)
#define ISP_REG_INT_STATUS_BIT_AE_DONE      (1<<1)
#define ISP_REG_INT_STATUS_BIT_AWB_DONE     (1<<2)

#define ISP_REG_INT_MASK_BIT_FRAME_DONE     (1<<0)
#define ISP_REG_INT_MASK_BIT_AE_DONE        (1<<1)
#define ISP_REG_INT_MASK_BIT_AWB_DONE       (1<<2)

#endif
