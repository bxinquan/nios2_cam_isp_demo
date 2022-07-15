/*
 * ov5640_drv.c
 *
 *  Created on: 2021-4-18
 *      Author: PC-1703
 */



#include <stdio.h>
#include <io.h>
#include "system.h"
#include "altera_avalon_pio_regs.h"

#define CMOS_SCL_PIO	0
#define CMOS_SDA_PIO	1
#define CMOS_PWDN_PIO	2
#define CMOS_RSTN_PIO	3


#define CMOS_PWDN_OUT() (IOWR_ALTERA_AVALON_PIO_DIRECTION(PIO_BASE, IORD_ALTERA_AVALON_PIO_DIRECTION(PIO_BASE)|(1u<<CMOS_PWDN_PIO)))
#define CMOS_PWDN_SET(x) (IOWR_ALTERA_AVALON_PIO_DATA(PIO_BASE, IORD_ALTERA_AVALON_PIO_DATA(PIO_BASE)&~(1u<<CMOS_PWDN_PIO)|(!!(x)<<CMOS_PWDN_PIO)))
#define CMOS_RSTN_OUT() (IOWR_ALTERA_AVALON_PIO_DIRECTION(PIO_BASE, IORD_ALTERA_AVALON_PIO_DIRECTION(PIO_BASE)|(1u<<CMOS_RSTN_PIO)))
#define CMOS_RSTN_SET(x) (IOWR_ALTERA_AVALON_PIO_DATA(PIO_BASE, IORD_ALTERA_AVALON_PIO_DATA(PIO_BASE)&~(1u<<CMOS_RSTN_PIO)|(!!(x)<<CMOS_RSTN_PIO)))
#define MDELAY(x) usleep(x*1000)

static void cmos_poweron()
{
	CMOS_PWDN_SET(1);
	CMOS_RSTN_SET(0);
	CMOS_PWDN_OUT();
	CMOS_RSTN_OUT();
	MDELAY(5);
	
	CMOS_PWDN_SET(0);
	MDELAY(2);

	CMOS_RSTN_SET(1);
	MDELAY(21);
}

static void cmos_poweroff()
{
	CMOS_PWDN_SET(1);
	CMOS_RSTN_SET(0);
	CMOS_PWDN_OUT();
	CMOS_RSTN_OUT();
	MDELAY(5);
}

#define I2C_SCL_OUT() (IOWR_ALTERA_AVALON_PIO_DIRECTION(PIO_BASE, IORD_ALTERA_AVALON_PIO_DIRECTION(PIO_BASE)|(1u<<CMOS_SCL_PIO)))
#define I2C_SCL_SET(x) (IOWR_ALTERA_AVALON_PIO_DATA(PIO_BASE, IORD_ALTERA_AVALON_PIO_DATA(PIO_BASE)&~(1u<<CMOS_SCL_PIO)|(!!(x)<<CMOS_SCL_PIO)))
#define I2C_SDA_IN() (IOWR_ALTERA_AVALON_PIO_DIRECTION(PIO_BASE, IORD_ALTERA_AVALON_PIO_DIRECTION(PIO_BASE)&~(1u<<CMOS_SDA_PIO)))
#define I2C_SDA_OUT() (IOWR_ALTERA_AVALON_PIO_DIRECTION(PIO_BASE, IORD_ALTERA_AVALON_PIO_DIRECTION(PIO_BASE)|(1u<<CMOS_SDA_PIO)))
#define I2C_SDA_SET(x) (IOWR_ALTERA_AVALON_PIO_DATA(PIO_BASE, IORD_ALTERA_AVALON_PIO_DATA(PIO_BASE)&~(1u<<CMOS_SDA_PIO)|(!!(x)<<CMOS_SDA_PIO)))
#define I2C_SDA_GET() ((IORD_ALTERA_AVALON_PIO_DATA(PIO_BASE)>>CMOS_SDA_PIO)&1)
#define I2C_DELAY() usleep(5)

static void i2c_init()
{
	I2C_SCL_SET(1);
	I2C_SDA_SET(1);
	I2C_SCL_OUT();
	I2C_SDA_OUT();
	I2C_DELAY();
}

static int i2c_write_byte(unsigned char slave_addr, const unsigned char* data, unsigned len)
{
	int i, j;
	int ret = 0;
	//start
	I2C_SCL_SET(1);
	I2C_SDA_SET(1);
	I2C_SDA_OUT();
	I2C_DELAY();
	I2C_SDA_SET(0);
	I2C_DELAY();
	I2C_SCL_SET(0);
	I2C_DELAY();

	//addr
	unsigned char addr = (slave_addr << 1) | 0; //W
	for (i = 0; i < 8; i++) {
		I2C_SDA_SET(addr&0x80);
		I2C_SCL_SET(1);
		I2C_DELAY();
		I2C_SCL_SET(0);
		I2C_DELAY();
		addr <<= 1;
	}
	I2C_SDA_IN();
	I2C_SCL_SET(1);
	I2C_DELAY();
	ret += I2C_SDA_GET();
	I2C_SCL_SET(0);
	I2C_SDA_OUT();
	I2C_DELAY();

	for (i = 0; i < len; i++) {
		unsigned char d = data[i];
		for (j = 0; j < 8; j++) {
			I2C_SDA_SET(d&0x80);
			I2C_SCL_SET(1);
			I2C_DELAY();
			I2C_SCL_SET(0);
			I2C_DELAY();
			d <<= 1;
		}
		I2C_SDA_IN();
		I2C_SCL_SET(1);
		I2C_DELAY();
		ret += I2C_SDA_GET();
		I2C_SCL_SET(0);
		I2C_SDA_OUT();
		I2C_DELAY();
	}

	//stop
	I2C_SDA_SET(0);
	I2C_SCL_SET(1);
	I2C_DELAY();
	I2C_SDA_SET(1);
	I2C_DELAY();

	return ret;
}


static int ov_wr_reg(unsigned short reg, unsigned char data)
{
	unsigned char slave = 0x78>>1;
	unsigned char buff[3];
	buff[0] = (reg >> 8) & 0xff;
	buff[1] = (reg >> 0) & 0xff;
	buff[2] = data;
	return i2c_write_byte(slave, buff, 3);
}

int ov5640_init_raw_1280_960_30fps_crop_960_544()
{
	i2c_init();
	cmos_poweron();
	ov_wr_reg(0x3103, 0x11);
	ov_wr_reg(0x3008, 0x82);
	ov_wr_reg(0x3008, 0x42);
	ov_wr_reg(0x3103, 0x03);
	ov_wr_reg(0x3017, 0xff);
	ov_wr_reg(0x3018, 0xff);
	ov_wr_reg(0x3034, 0x1a);
	ov_wr_reg(0x3035, 0x11);
	ov_wr_reg(0x3036, 0x46);
	ov_wr_reg(0x3037, 0x13);
	ov_wr_reg(0x3108, 0x01);
	ov_wr_reg(0x3630, 0x36);
	ov_wr_reg(0x3631, 0x0e);
	ov_wr_reg(0x3632, 0xe2);
	ov_wr_reg(0x3633, 0x12);
	ov_wr_reg(0x3621, 0xe0);
	ov_wr_reg(0x3704, 0xa0);
	ov_wr_reg(0x3703, 0x5a);
	ov_wr_reg(0x3715, 0x78);
	ov_wr_reg(0x3717, 0x01);
	ov_wr_reg(0x370b, 0x60);
	ov_wr_reg(0x3705, 0x1a);
	ov_wr_reg(0x3905, 0x02);
	ov_wr_reg(0x3906, 0x10);
	ov_wr_reg(0x3901, 0x0a);
	ov_wr_reg(0x3731, 0x12);
	ov_wr_reg(0x3600, 0x08);
	ov_wr_reg(0x3601, 0x33);
	ov_wr_reg(0x302d, 0x60);
	ov_wr_reg(0x3620, 0x52);
	ov_wr_reg(0x371b, 0x20);
	ov_wr_reg(0x471c, 0x50);
	ov_wr_reg(0x3a13, 0x43);
	ov_wr_reg(0x3a18, 0x00);
	ov_wr_reg(0x3a19, 0xf8);
	ov_wr_reg(0x3635, 0x13);
	ov_wr_reg(0x3636, 0x03);
	ov_wr_reg(0x3634, 0x40);
	ov_wr_reg(0x3622, 0x01);
	ov_wr_reg(0x3c01, 0x34);
	ov_wr_reg(0x3c04, 0x28);
	ov_wr_reg(0x3c05, 0x98);
	ov_wr_reg(0x3c06, 0x00);
	ov_wr_reg(0x3c07, 0x07);
	ov_wr_reg(0x3c08, 0x00);
	ov_wr_reg(0x3c09, 0x1c);
	ov_wr_reg(0x3c0a, 0x9c);
	ov_wr_reg(0x3c0b, 0x40);
	ov_wr_reg(0x3820, 0x42);
	ov_wr_reg(0x3821, 0x01);
	ov_wr_reg(0x3814, 0x31);
	ov_wr_reg(0x3815, 0x31);
	ov_wr_reg(0x3800, 0x00);
	ov_wr_reg(0x3801, 0x00);
	ov_wr_reg(0x3802, 0x00);
	ov_wr_reg(0x3803, 0x04);
	ov_wr_reg(0x3804, 0x0a);
	ov_wr_reg(0x3805, 0x3f);
	ov_wr_reg(0x3806, 0x07);
	ov_wr_reg(0x3807, 0x9b);
	ov_wr_reg(0x3808, 0x03);
	ov_wr_reg(0x3809, 0xc0);
	ov_wr_reg(0x380a, 0x02);
	ov_wr_reg(0x380b, 0x20);
	ov_wr_reg(0x380c, 0x07);
	ov_wr_reg(0x380d, 0x68);
	ov_wr_reg(0x380e, 0x03);
	ov_wr_reg(0x380f, 0xd8);
	ov_wr_reg(0x3810, 0x00);
	ov_wr_reg(0x3811, 0x10);
	ov_wr_reg(0x3812, 0x00);
	ov_wr_reg(0x3813, 0x07);
	ov_wr_reg(0x3618, 0x00);
	ov_wr_reg(0x3612, 0x29);
	ov_wr_reg(0x3708, 0x64);
	ov_wr_reg(0x3709, 0x52);
	ov_wr_reg(0x370c, 0x03);
	ov_wr_reg(0x3a02, 0x03);
	ov_wr_reg(0x3a03, 0xd8);
	ov_wr_reg(0x3a08, 0x01);
	ov_wr_reg(0x3a09, 0x27);
	ov_wr_reg(0x3a0a, 0x00);
	ov_wr_reg(0x3a0b, 0xf6);
	ov_wr_reg(0x3a0e, 0x03);
	ov_wr_reg(0x3a0d, 0x04);
	ov_wr_reg(0x3a14, 0x03);
	ov_wr_reg(0x3a15, 0xd8);
	ov_wr_reg(0x4001, 0x02);
	ov_wr_reg(0x4004, 0x02);
	ov_wr_reg(0x3000, 0x00);
	ov_wr_reg(0x3002, 0x1c);
	ov_wr_reg(0x3004, 0xff);
	ov_wr_reg(0x3006, 0xc3);
	ov_wr_reg(0x300e, 0x58);
	ov_wr_reg(0x302e, 0x00);
	ov_wr_reg(0x4300, 0xf8);
	ov_wr_reg(0x501f, 0x03);
	ov_wr_reg(0x4713, 0x03);
	ov_wr_reg(0x4407, 0x04);
	ov_wr_reg(0x440e, 0x00);
	ov_wr_reg(0x460b, 0x37);
	ov_wr_reg(0x460c, 0x20);
	ov_wr_reg(0x4837, 0x16);
	ov_wr_reg(0x3824, 0x04);
	ov_wr_reg(0x5000, 0x00);
	ov_wr_reg(0x5001, 0x00);
	ov_wr_reg(0x3a0f, 0x36);
	ov_wr_reg(0x3a10, 0x2e);
	ov_wr_reg(0x3a1b, 0x38);
	ov_wr_reg(0x3a1e, 0x2c);
	ov_wr_reg(0x3a11, 0x70);
	ov_wr_reg(0x3a1f, 0x18);
	ov_wr_reg(0x3008, 0x02);
	ov_wr_reg(0x3035, 0x21);
	ov_wr_reg(0x3400, 0x04);
	ov_wr_reg(0x3401, 0x00);
	ov_wr_reg(0x3402, 0x04);
	ov_wr_reg(0x3403, 0x00);
	ov_wr_reg(0x3404, 0x04);
	ov_wr_reg(0x3405, 0x00);
	ov_wr_reg(0x3406, 0x01);
	ov_wr_reg(0x4000, 0x88);
	ov_wr_reg(0x3503, 0x03);

	unsigned int cmos_exposure = 0x300;
	unsigned int cmos_gain = 0x40;
    ov_wr_reg(0x3500, 0x00);// Exposure [19:16]
	ov_wr_reg(0x3501, (cmos_exposure>>4)&0x3f);// Exposure [15:8]
	ov_wr_reg(0x3502, (cmos_exposure&0x0f)<<4);// Exposure [7:0]
	ov_wr_reg(0x350a, (cmos_gain>>8)&0x3);// Real gain[9:8]
	ov_wr_reg(0x350b, cmos_gain&0x0ff);// Real gain[7:0]

	printf("=== ov5640_init_raw_1280_960_30fps_crop_960_544 initialize OK!\n");
	return 0;
}

int cmos_set_exposure(unsigned exposure)
{
    ov_wr_reg(0x3500, 0x00);// Exposure [19:16]
	ov_wr_reg(0x3501, (exposure>>4)&0x3f);// Exposure [15:8]
	ov_wr_reg(0x3502, (exposure&0x0f)<<4);// Exposure [7:0]
}

int cmos_set_gain(unsigned gain)
{
	ov_wr_reg(0x350a, (gain>>8)&0x3);// Real gain[9:8]
	ov_wr_reg(0x350b, gain&0x0ff);// Real gain[7:0]
}
