/*
 * "Hello World" example.
 *
 * This example prints 'Hello from Nios II' to the STDOUT stream. It runs on
 * the Nios II 'standard', 'full_featured', 'fast', and 'low_cost' example
 * designs. It runs with or without the MicroC/OS-II RTOS and requires a STDOUT
 * device in your system's hardware.
 * The memory footprint of this hosted application is ~69 kbytes by default
 * using the standard reference design.
 *
 * For a reduced footprint version of this template, and an explanation of how
 * to reduce the memory footprint for a given application, see the
 * "small_hello_world" template.
 *
 */

#include <stdio.h>
#include <io.h>
#include "system.h"
#include "avalon_lcd_rgb_controller_regs.h"
#include "avalon_dvp_vi_regs.h"
#include "avalon_isp_lite_regs.h"
#include "avalon_isp_algo_2a.h"
#include "avalon_vip_regs.h"
#include "avalon_dvp_wch_regs.h"
#include "sys/alt_irq.h"

static unsigned char lcd_fb[480*272*2];
static unsigned char cap_fb[480*272*2];

static unsigned vi_frame_int = 0;
static void dvp_vi_isr(void* isr_context)
{
	IOWR(isr_context, VI_REG_INT_STATUS, 0);
	vi_frame_int ++;
}
extern void isp_ae_handler(void* base);

extern void isp_awb_handler(void* base);
static unsigned isp_frame_int = 0;
static void isp_isr(void* isr_context)
{
	IOWR(isr_context, ISP_REG_INT_STATUS, 0);
	isp_frame_int ++;
	if (0 == (isp_frame_int&1)) {
		isp_ae_handler(isr_context);
		isp_awb_handler(isr_context);
	}
}

static unsigned vip_frame_int = 0;
static void vip_isr(void* isr_context)
{
	IOWR(isr_context, VIP_REG_INT_STATUS, 0);
	vip_frame_int ++;
}

static void init_vi_isp_vip_wch()
{
	IOWR(DVP_VI_BASE, VI_REG_RESET, 1);
	IOWR(ISP_BASE, ISP_REG_RESET, 1);
	IOWR(VIP_BASE, VIP_REG_RESET, 1);
	IOWR(DVP_WCH_BASE, WCH_REG_RESET, 1);

	IOWR(DVP_VI_BASE, VI_REG_INT_MASK, 0xffff);
	IOWR(ISP_BASE, ISP_REG_INT_MASK, 0xffff);
	IOWR(VIP_BASE, VIP_REG_INT_MASK, 0xffff);
	usleep(100000);

	IOWR(DVP_VI_BASE, VI_REG_COLORBAR_EN, 0);

	IOWR(DVP_WCH_BASE, WCH_REG_BUFF_ADDR, cap_fb);
	IOWR(DVP_WCH_BASE, WCH_REG_BUFF_SIZE, sizeof(cap_fb));
	printf("cap_buf = %08X, dvp_reg1 = %08X\n", cap_fb, IORD(DVP_WCH_BASE, WCH_REG_BUFF_ADDR));
	printf("cap_siz = %08X, dvp_reg2 = %08X\n", sizeof(cap_fb), IORD(DVP_WCH_BASE, WCH_REG_BUFF_SIZE));

	unsigned int isp_top_en = 0;
	isp_top_en |= ISP_REG_TOP_EN_BIT_BLC_EN;
	isp_top_en |= ISP_REG_TOP_EN_BIT_BNR_EN;
	//isp_top_en |= ISP_REG_TOP_EN_BIT_DGAIN_EN;
	isp_top_en |= ISP_REG_TOP_EN_BIT_DEMOSIC_EN;
	isp_top_en |= ISP_REG_TOP_EN_BIT_WB_EN;
	isp_top_en |= ISP_REG_TOP_EN_BIT_CCM_EN;
	isp_top_en |= ISP_REG_TOP_EN_BIT_CSC_EN;
	isp_top_en |= ISP_REG_TOP_EN_BIT_GAMMA_EN;
	isp_top_en |= ISP_REG_TOP_EN_BIT_EE_EN;
	isp_top_en |= ISP_REG_TOP_EN_BIT_STAT_AE_EN;
	isp_top_en |= ISP_REG_TOP_EN_BIT_STAT_AWB_EN;
	IOWR(ISP_BASE, ISP_REG_TOP_EN, isp_top_en);

	unsigned int vip_top_en = 0;
	vip_top_en |= VIP_REG_TOP_EN_BIT_HIST_EQU_EN;
	//vip_top_en |= VIP_REG_TOP_EN_BIT_SOBEL_EN;
	vip_top_en |= VIP_REG_TOP_EN_BIT_YUV2RGB_EN;
	vip_top_en |= VIP_REG_TOP_EN_BIT_DSCALE_EN;
	IOWR(VIP_BASE, VIP_REG_TOP_EN, vip_top_en);

	IOWR(DVP_VI_BASE, VI_REG_RESET, 0);
	IOWR(ISP_BASE, ISP_REG_RESET, 0);
	IOWR(VIP_BASE, VIP_REG_RESET, 0);
	IOWR(DVP_WCH_BASE, WCH_REG_RESET, 0);
	printf("vi_reset  = %08X\n", IORD(DVP_VI_BASE, VI_REG_RESET));
	printf("isp_reset = %08X\n", IORD(ISP_BASE, ISP_REG_RESET));
	printf("vip_reset = %08X\n", IORD(VIP_BASE, VIP_REG_RESET));
	printf("wch_reset = %08X\n", IORD(DVP_WCH_BASE, WCH_REG_RESET));

	alt_ic_isr_register(DVP_VI_IRQ_INTERRUPT_CONTROLLER_ID, DVP_VI_IRQ, dvp_vi_isr, DVP_VI_BASE, 0x0);
	alt_ic_isr_register(ISP_IRQ_INTERRUPT_CONTROLLER_ID, ISP_IRQ, isp_isr, ISP_BASE, 0x0);
	alt_ic_isr_register(VIP_IRQ_INTERRUPT_CONTROLLER_ID, VIP_IRQ, vip_isr, VIP_BASE, 0x0);
	IOWR(DVP_VI_BASE, VI_REG_INT_MASK, 0x0);
	IOWR(ISP_BASE, ISP_REG_INT_MASK, 0x0);
	IOWR(VIP_BASE, VIP_REG_INT_MASK, 0x0);
}

extern int ov5640_init_raw_1280_960_30fps_crop_960_544();


int main(){

	printf("Hello Nios2\n");
	IOWR(LCD_CONTROLLER_BASE, LCD_REG_RESET, 1);
	ov5640_init_raw_1280_960_30fps_crop_960_544();
	usleep(100000);

	unsigned short* ptr = lcd_fb;
	unsigned x,y;
	for (y = 0; y < 272; y ++)
		for (x = 0; x < 480; x++) {
			if (x < 480 * 1 / 8)
				*ptr = 0xffff;
			else if (x < 480 * 2 / 8)
				*ptr = 0xffe0;
			else if (x < 480 * 3 / 8)
				*ptr = 0xf81f;
			else if (x < 480 * 4 / 8)
				*ptr = 0xf800;
			else if (x < 480 * 5 / 8)
				*ptr = 0x07ff;
			else if (x < 480 * 6 / 8)
				*ptr = 0x07e0;
			else if (x < 480 * 7 / 8)
				*ptr = 0x001f;
			else
				*ptr = 0x0000;
			ptr++;
		}

	IOWR(LCD_CONTROLLER_BASE, LCD_REG_FB_ADDR, cap_fb);
	IOWR(LCD_CONTROLLER_BASE, LCD_REG_RESET, 0);
	printf("lcd_fb = %08X, lcd_reg1 = %08X\n", cap_fb, IORD(LCD_CONTROLLER_BASE, LCD_REG_FB_ADDR));
	printf("lcd_reset = %08X(lcd_reg0)\n", IORD(LCD_CONTROLLER_BASE, LCD_REG_RESET));

	init_vi_isp_vip_wch();

	while(1) {
		usleep(1000000);
		IOWR(LCD_CONTROLLER_BASE, LCD_REG_FB_ADDR, lcd_fb);
		usleep(100000);
		IOWR(LCD_CONTROLLER_BASE, LCD_REG_FB_ADDR, cap_fb);
		printf("%u x %u, frame %u, interrupt vi %u, isp %u, vip %u\n",
				IORD(DVP_VI_BASE, VI_REG_WIDTH),
				IORD(DVP_VI_BASE, VI_REG_HEIGHT),
				IORD(DVP_VI_BASE, VI_REG_FRAME_CNT),
				vi_frame_int, isp_frame_int, vip_frame_int);
		printf("AE HIST [");
		int i;
		unsigned sum = 0;
		for (i = 0; i < ISP_REG_STAT_AE_HIST_SIZE; i++) {
			unsigned data = IORD(ISP_BASE, ISP_REG_STAT_AE_HIST_ADDR+i);
			sum += data;
			if (i >= 48 && i < 48 + 32)
				printf("%u, ", data);
		}
		printf("] total %u\n", sum);//sum may be error, because of reading hist in vsync time
	}
}
