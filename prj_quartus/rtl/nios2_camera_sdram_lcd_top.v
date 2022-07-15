
module nios2_camera_sdram_lcd_top
(
	input clk,
	input rst_n,

	output                      sdram_clk,         //sdram clock
	output                      sdram_cke,         //sdram clock enable
	output                      sdram_cs_n,        //sdram chip select
	output                      sdram_we_n,        //sdram write enable
	output                      sdram_cas_n,       //sdram column address strobe
	output                      sdram_ras_n,       //sdram row address strobe
	output[1:0]                 sdram_dqm,         //sdram data enable
	output[1:0]                 sdram_ba,          //sdram bank address
	output[12:0]                sdram_addr,        //sdram address
	inout[15:0]                 sdram_dq,          //sdram data
	output lcd_dclk,
	output lcd_de,
	output lcd_hs,
	output lcd_vs,
	output [7:0] lcd_r,
	output [7:0] lcd_g,
	output [7:0] lcd_b,
	inout                       cmos_scl,          //cmos i2c clock
	inout                       cmos_sda,          //cmos i2c data
	input                       cmos_vsync,        //cmos vsync
	input                       cmos_href,         //cmos hsync refrence,data valid
	input                       cmos_pclk,         //cmos pxiel clock
	output                      cmos_xclk,         //cmos externl clock
	input   [7:0]               cmos_db,           //cmos data
	output                      cmos_rst_n,        //cmos reset
	output                      cmos_pwdn,         //cmos power down
	output [3:0] led_pin
);

	wire vi_pclk;
	wire vi_out_href, vi_out_vsync;
	wire [7:0] vi_out_raw;
	wire isp_out_href, isp_out_vsync;
	wire [7:0] isp_out_y, isp_out_u, isp_out_v;
	wire vip_out_pclk;
	wire vip_out_href;
	wire vip_out_vsync;
	wire [7:0] vip_out_r, vip_out_g, vip_out_b;
	
	assign led_pin = {vip_out_vsync, isp_out_vsync, vi_out_vsync, cmos_rst_n};

	wire lcd_xclk;
	nios2_camera_sdram_lcd sopc(
		.sdram_addr(sdram_addr),    //     sdram.addr
		.sdram_ba(sdram_ba),      //          .ba
		.sdram_cas_n(sdram_cas_n),   //          .cas_n
		.sdram_cke(sdram_cke),     //          .cke
		.sdram_cs_n(sdram_cs_n),    //          .cs_n
		.sdram_dq(sdram_dq),      //          .dq
		.sdram_dqm(sdram_dqm),     //          .dqm
		.sdram_ras_n(sdram_ras_n),   //          .ras_n
		.sdram_we_n(sdram_we_n),    //          .we_n
		.pio_export({4'hz, cmos_rst_n, cmos_pwdn, cmos_sda, cmos_scl}),    //       pio.export
		.clk_clk(clk),       //       clk.clk
		.sdram_clk_clk(sdram_clk),  // sdram_clk.clk
		  
        .lcd_pclk                     (lcd_xclk),                     //           lcd.pclk
        .lcd_lcd_dclk                 (lcd_dclk),                 //              .lcd_dclk
        .lcd_lcd_de                   (lcd_de),                   //              .lcd_de
        .lcd_lcd_hs                   (lcd_hs),                   //              .lcd_hs
        .lcd_lcd_vs                   (lcd_vs),                   //              .lcd_vs
        .lcd_lcd_r                    (lcd_r),                    //              .lcd_r
        .lcd_lcd_g                    (lcd_g),                    //              .lcd_g
        .lcd_lcd_b                    (lcd_b),                    //              .lcd_b
        .lcd_xclk_clk                 (lcd_xclk),
	
        .cmos_xclk_clk (cmos_xclk),  // cmos_xclk.clk	

        .dvp_vi_cmos_xclk  (cmos_xclk),  //    dvp_vi.cmos_xclk
        .dvp_vi_cmos_pclk  (cmos_pclk),  //          .cmos_pclk
        .dvp_vi_cmos_href  (cmos_href),  //          .cmos_href
        .dvp_vi_cmos_vsync (cmos_vsync), //          .cmos_vsync
        .dvp_vi_cmos_db    (cmos_db),    //          .cmos_db
        .dvp_vi_out_pclk   (vi_pclk),   //          .out_pclk
        .dvp_vi_out_href   (vi_out_href),   //          .out_href
        .dvp_vi_out_vsync  (vi_out_vsync),  //          .out_vsync
        .dvp_vi_out_raw    (vi_out_raw),     //          .out_raw
		  
        .isp_pclk      (vi_pclk),      //       isp.pclk
        .isp_rst_n     (cmos_rst_n),     //          .rst_n
        .isp_in_href   (vi_out_href),   //          .in_href
        .isp_in_vsync  (vi_out_vsync),  //          .in_vsync
        .isp_in_raw    (vi_out_raw),    //          .in_raw
        .isp_out_href  (isp_out_href),  //          .out_href
        .isp_out_vsync (isp_out_vsync), //          .out_vsync
        .isp_out_y     (isp_out_y),     //          .out_y
        .isp_out_u     (isp_out_u),     //          .out_u
        .isp_out_v     (isp_out_v),     //          .out_v

        .vip_pclk      (vi_pclk),      //       vip.pclk
        .vip_rst_n     (cmos_rst_n),     //          .rst_n
        .vip_in_href   (isp_out_href),   //          .in_href
        .vip_in_vsync  (isp_out_vsync),  //          .in_vsync
        .vip_in_y      (isp_out_y),      //          .in_y
        .vip_in_u      (isp_out_u),      //          .in_u
        .vip_in_v      (isp_out_v),      //          .in_v
        .vip_out_pclk  (vip_out_pclk),  //          .out_pclk
        .vip_out_href  (vip_out_href),  //          .out_href
        .vip_out_vsync (vip_out_vsync), //          .out_vsync
        .vip_out_r     (vip_out_r),     //          .out_r
        .vip_out_g     (vip_out_g),     //          .out_g
        .vip_out_b     (vip_out_b),     //          .out_b
 
        .dvp_wch_pclk      (vip_out_pclk),      //       dvp_wch.pclk
        .dvp_wch_href      (vip_out_href),      //          .href
        .dvp_wch_vsync     (vip_out_vsync),     //          .vsync
        .dvp_wch_raw       ({vip_out_r[7:3], vip_out_g[7:2], vip_out_b[7:3]})       //          .raw
 
		 
		 );

endmodule
