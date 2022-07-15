#include <stdio.h>
#include <io.h>
#include "system.h"
#include "avalon_isp_lite_regs.h"
#include "avalon_isp_algo_2a.h"

extern int cmos_set_exposure(unsigned exposure);
extern int cmos_set_gain(unsigned gain);

void isp_ae_handler(void* base)
{
	static unsigned cmos_exposure = 0x080;
	static unsigned cmos_gain = 0x010;
	const unsigned target_val = 65;
	unsigned pix_cnt = IORD(base, ISP_REG_STAT_AE_PIX_CNT);
	unsigned sum = IORD(base, ISP_REG_STAT_AE_SUM);
	unsigned gain0 = pix_cnt * target_val / (sum >> 4);

	unsigned expo_diff, gain_diff;
	if (gain0 > 20) {
		expo_diff = (((cmos_exposure * gain0) >> 4) - cmos_exposure) >> 1;
		expo_diff = expo_diff > 0 ? expo_diff : 1;
		gain_diff = (((cmos_gain * gain0) >> 4) - cmos_gain) >> 1;
		gain_diff = gain_diff > 0 ? gain_diff : 1;
		if (cmos_exposure < 0x3ff) {
			if (cmos_exposure + expo_diff > 0x3ff)
				cmos_exposure = 0x3ff;
			else
				cmos_exposure = cmos_exposure + expo_diff;
		}
		else if (cmos_gain < 0x3ff) {
			if (cmos_gain + gain_diff > 0x3ff)
				cmos_gain = 0x3ff;
			else
				cmos_gain = cmos_gain + gain_diff;
		}
		cmos_set_exposure(cmos_exposure);
		cmos_set_gain(cmos_gain);
	}
	else if (gain0 < 12) {
		expo_diff = (cmos_exposure - ((cmos_exposure * gain0) >> 4)) >> 1;
		expo_diff = expo_diff > 0 ? expo_diff : 1;
		gain_diff = (cmos_gain - ((cmos_gain * gain0) >> 4)) >> 1;
		gain_diff = gain_diff > 0 ? gain_diff : 1;
		if (cmos_gain > 16) {
			if (cmos_gain < 16 + gain_diff)
				cmos_gain = 16;
			else
				cmos_gain = cmos_gain - gain_diff;
		}
		else if (cmos_exposure > 1) {
			if (cmos_exposure < 1 + expo_diff)
				cmos_exposure = 1;
			else
				cmos_exposure = cmos_exposure - expo_diff;
		}
		cmos_set_exposure(cmos_exposure);
		cmos_set_gain(cmos_gain);
	}
}


void isp_awb_handler(void* base)
{
	unsigned pix_cnt = IORD(base, ISP_REG_STAT_AWB_PIX_CNT);
	unsigned sum_r = IORD(base, ISP_REG_STAT_AWB_SUM_R);
	unsigned sum_g = IORD(base, ISP_REG_STAT_AWB_SUM_G);
	unsigned sum_b = IORD(base, ISP_REG_STAT_AWB_SUM_B);

	unsigned r_gain0 = (sum_g << 4) / sum_r;
	unsigned b_gain0 = (sum_g << 4) / sum_b;

	IOWR(base, ISP_REG_WB_GGAIN, 0x10);
	IOWR(base, ISP_REG_WB_RGAIN, r_gain0);
	IOWR(base, ISP_REG_WB_BGAIN, b_gain0);
}
