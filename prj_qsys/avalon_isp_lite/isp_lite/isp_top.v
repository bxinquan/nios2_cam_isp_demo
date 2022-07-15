/*************************************************************************
    > File Name: isp_top.v
    > Author: bxq
    > Mail: 544177215@qq.com
    > Created Time: Thu 21 Jan 2021 21:50:04 GMT
 ************************************************************************/


module isp_top
#(
	parameter BITS = 8,
	parameter WIDTH = 1280,
	parameter HEIGHT = 960,
	parameter BAYER = 0, //0:BGGR 1:GBRG 2:GRBG 3:RGGB
	parameter STAT_BITS = 32
)
(
	input pclk,
	input rst_n,
	
	input in_href,
	input in_vsync,
	input [BITS-1:0] in_raw,
	
	output out_href,
	output out_vsync,
	output [BITS-1:0] out_y,
	output [BITS-1:0] out_u,
	output [BITS-1:0] out_v,
	
	input blc_en, bnr_en, dgain_en, demosic_en, wb_en, ccm_en, csc_en, gamma_en, ee_en, stat_ae_en, stat_awb_en,

	input [7:0] blc_b, blc_gb, blc_gr, blc_r,
	input [7:0] dgain,
	input [7:0] wb_rgain, wb_ggain, wb_bgain,
	input [7:0] ccm_rr, ccm_rg, ccm_rb,
	input [7:0] ccm_gr, ccm_gg, ccm_gb,
	input [7:0] ccm_br, ccm_bg, ccm_bb,
	
	output stat_ae_done,
	output [STAT_BITS-1:0] stat_ae_pix_cnt, stat_ae_sum,

	input stat_ae_hist_clk,
	input stat_ae_hist_out,
	input [BITS+1:0] stat_ae_hist_addr, //B,Gb,Gr,R
	output [STAT_BITS-1:0] stat_ae_hist_data,

	input [7:0] stat_awb_min, stat_awb_max,
	output stat_awb_done,
	output [STAT_BITS-1:0] stat_awb_pix_cnt, stat_awb_sum_r, stat_awb_sum_g, stat_awb_sum_b,

	input stat_awb_hist_clk,
	input stat_awb_hist_out,
	input [BITS+1:0] stat_awb_hist_addr, //R,G,B
	output [STAT_BITS-1:0] stat_awb_hist_data
);

`define USE_BLC 1
`define USE_BNR 1
//`define USE_DGAIN 1
`define USE_DEMOSIC 1
`define USE_WB 1
`define USE_CCM 1
`define USE_CSC 1
`define USE_GAMMA 1
`define USE_EE 1
`define USE_STAT_AE 1
`define USE_STAT_AWB 1

	wire blc_href, blc_vsync;
	wire [BITS-1:0] blc_raw;
	wire blc_href_o = blc_en ? blc_href : in_href;
	wire blc_vsync_o =  blc_en ? blc_vsync : in_vsync;
	wire [BITS-1:0] blc_raw_o = blc_en ? blc_raw : in_raw;
`ifdef USE_BLC
	isp_blc #(BITS, WIDTH, HEIGHT, BAYER) blc_i0(pclk, rst_n, blc_b, blc_gb, blc_gr, blc_r, in_href, in_vsync, in_raw, blc_href, blc_vsync, blc_raw);
`else
	assign blc_href = in_href;
	assign blc_vsync = in_vsync;
	assign blc_raw = in_raw;
`endif

	wire bnr_href, bnr_vsync;
	wire [BITS-1:0] bnr_raw;
	wire bnr_href_o = bnr_en ? bnr_href : blc_href_o;
	wire bnr_vsync_o = bnr_en ? bnr_vsync: blc_vsync_o;
	wire [BITS-1:0] bnr_raw_o = bnr_en ? bnr_raw: blc_raw_o;
`ifdef USE_BNR
	isp_bnr #(BITS, WIDTH, HEIGHT, BAYER) bnr_i0(pclk, rst_n, blc_href_o, blc_vsync_o, blc_raw_o, bnr_href, bnr_vsync, bnr_raw);
`else
	assign bnr_href = blc_href_o;
	assign bnr_vsync = blc_vsync_o;
	assign bnr_raw = blc_raw_o;
`endif

`ifdef USE_STAT_AE
	isp_stat_ae #(BITS, WIDTH, HEIGHT, BAYER, STAT_BITS) isp_stat_ae_i0(pclk, rst_n, bnr_href_o&stat_ae_en, bnr_vsync_o&stat_ae_en, bnr_raw_o,
			stat_ae_done, stat_ae_pix_cnt, stat_ae_sum,
			stat_ae_hist_clk, stat_ae_hist_out, stat_ae_hist_addr, stat_ae_hist_data);
`endif

	wire dgain_href, dgain_vsync;
	wire [BITS-1:0] dgain_raw;
	wire dgain_href_o = dgain ? dgain_href : bnr_href_o;
	wire dgain_vsync_o = dgain ? dgain_vsync : bnr_vsync_o;
	wire [BITS-1:0] dgain_raw_o = dgain ? dgain_raw : bnr_raw_o;
`ifdef USE_DGAIN
	isp_dgain #(BITS, WIDTH, HEIGHT) dgain_i0(pclk, rst_n, dgain, bnr_href_o, bnr_vsync_o, bnr_raw_o, dgain_href, dgain_vsync, dgain_raw);
`else
	assign dgain_href = bnr_href_o;
	assign dgain_vsync = bnr_vsync_o;
	assign dgain_raw = bnr_raw_o;
`endif

	wire dm_href, dm_vsync;
	wire [BITS-1:0] dm_r, dm_g, dm_b;
	wire dm_href_o = demosic_en ? dm_href : dgain_href_o;
	wire dm_vsync_o = demosic_en ? dm_vsync : dgain_vsync_o;
	wire [BITS-1:0] dm_r_o = demosic_en ? dm_r : dgain_raw_o;
	wire [BITS-1:0] dm_g_o = demosic_en ? dm_g : dgain_raw_o;
	wire [BITS-1:0] dm_b_o = demosic_en ? dm_b : dgain_raw_o;
`ifdef USE_DEMOSIC
	isp_demosaic #(BITS, WIDTH, HEIGHT, BAYER) demosaic_i0(pclk, rst_n, dgain_href_o, dgain_vsync_o, dgain_raw_o, dm_href, dm_vsync, dm_r, dm_g, dm_b);
`else
	assign dm_href = dgain_href_o;
	assign dm_vsync = dgain_vsync_o;
	assign dm_r = dgain_raw_o;
	assign dm_g = dgain_raw_o;
	assign dm_b = dgain_raw_o;
`endif

`ifdef USE_STAT_AWB
	isp_stat_awb #(BITS, WIDTH, HEIGHT, STAT_BITS) isp_stat_awb_i0(pclk, rst_n, stat_awb_min, stat_awb_max, dm_href_o&stat_awb_en, dm_vsync_o&stat_awb_en, dm_r_o, dm_g_o, dm_b_o,
			stat_awb_done, stat_awb_pix_cnt, stat_awb_sum_r, stat_awb_sum_g, stat_awb_sum_b,
			stat_awb_hist_clk, stat_awb_hist_out, stat_awb_hist_addr, stat_awb_hist_data );
`endif

	wire wb_href, wb_vsync;
	wire [BITS-1:0] wb_r, wb_g, wb_b;
	wire wb_href_o = wb_en ? wb_href : dm_href_o;
	wire wb_vsync_o = wb_en ? wb_vsync : dm_vsync_o;
	wire [BITS-1:0] wb_r_o = wb_en ? wb_r : dm_r_o;
	wire [BITS-1:0] wb_g_o = wb_en ? wb_g : dm_g_o;
	wire [BITS-1:0] wb_b_o = wb_en ? wb_b : dm_b_o;
`ifdef USE_WB
	isp_wb #(BITS, WIDTH, HEIGHT) wb_i0(pclk, rst_n, wb_rgain, wb_ggain, wb_bgain, dm_href_o, dm_vsync_o, dm_r_o, dm_g_o, dm_b_o, wb_href, wb_vsync, wb_r, wb_g, wb_b);
`else
	assign wb_href = dm_href_o;
	assign wb_vsync = dm_vsync_o;
	assign wb_r = dm_r_o;
	assign wb_g = dm_g_o;
	assign wb_b = dm_b_o;
`endif

	wire ccm_href, ccm_vsync;
	wire [BITS-1:0] ccm_r, ccm_g, ccm_b;
	wire ccm_href_o =  ccm_en ? ccm_href : wb_href_o;
	wire ccm_vsync_o =  ccm_en ? ccm_vsync : wb_vsync_o;
	wire [BITS-1:0] ccm_r_o = ccm_en ? ccm_r : wb_r_o;
	wire [BITS-1:0] ccm_g_o = ccm_en ? ccm_g : wb_g_o;
	wire [BITS-1:0] ccm_b_o = ccm_en ? ccm_b : wb_b_o;
`ifdef USE_CCM
	isp_ccm #(BITS, WIDTH, HEIGHT) ccm_i0(pclk, rst_n, 
		ccm_rr, ccm_rg, ccm_rg,
		ccm_gr, ccm_gg, ccm_gb,
		ccm_br, ccm_bg, ccm_bb,
		wb_href_o, wb_vsync_o, wb_r_o, wb_g_o, wb_b_o, ccm_href, ccm_vsync, ccm_r, ccm_g, ccm_b);
`else
	assign ccm_href = wb_href_o;
	assign ccm_vsync = wb_vsync;
	assign ccm_r = wb_r_o;
	assign ccm_g = wb_g_o;
	assign ccm_b = wb_b_o;
`endif

	wire csc_href, csc_vsync;
	wire [BITS-1:0] csc_y, csc_u, csc_v;
	wire csc_href_o = csc_en ? csc_href : ccm_href_o;
	wire csc_vsync_o = csc_en ? csc_vsync : ccm_vsync_o;
	wire [BITS-1:0] csc_y_o = csc_en ? csc_y : ccm_r_o;
	wire [BITS-1:0] csc_u_o = csc_en ? csc_u : ccm_g_o;
	wire [BITS-1:0] csc_v_o = csc_en ? csc_v : ccm_b_o;
`ifdef USE_CSC
	isp_csc #(BITS, WIDTH, HEIGHT) csc_i0(pclk, rst_n, ccm_href_o, ccm_vsync_o, ccm_r_o, ccm_g_o, ccm_b_o, csc_href, csc_vsync, csc_y, csc_u, csc_v);
`else
	assign csc_href = ccm_href_o;
	assign csc_vsync = ccm_vsync_o;
	assign csc_y = ccm_r_o;
	assign csc_u = ccm_g_o;
	assign csc_v = ccm_b_o;
`endif

	wire gamma_href, gamma_vsync;
	wire [BITS-1:0] gamma_y, gamma_u, gamma_v;
	wire gamma_href_o = gamma_en ? gamma_href : csc_href_o;
	wire gamma_vsync_o = gamma_en ? gamma_vsync : csc_vsync_o;
	wire [BITS-1:0] gamma_y_o = gamma_en ? gamma_y : csc_y_o;
	wire [BITS-1:0] gamma_u_o = gamma_en ? gamma_u : csc_u_o;
	wire [BITS-1:0] gamma_v_o = gamma_en ? gamma_v : csc_v_o;
`ifdef USE_GAMMA
	isp_gamma #(BITS, WIDTH, HEIGHT) gamma_i0(pclk, rst_n, csc_href_o, csc_vsync_o, csc_y_o, csc_u_o, csc_v_o, gamma_href, gamma_vsync, gamma_y, gamma_u, gamma_v);
`else
	assign gamma_href = csc_href_o;
	assign gamma_vsync = csc_vsync_o;
	assign gamma_y = csc_y_o;
	assign gamma_u = csc_u_o;
	assign gamma_v = csc_v_o;
`endif

	wire ee_href, ee_vsync;
	wire [BITS-1:0] ee_y, ee_u, ee_v;
	wire ee_href_o =  ee_en ? ee_href : gamma_href_o;
	wire ee_vsync_o =  ee_en ? ee_vsync : gamma_vsync_o;
	wire [BITS-1:0] ee_y_o = ee_en ? ee_y : gamma_y_o;
	wire [BITS-1:0] ee_u_o = ee_en ? ee_u : gamma_u_o;
	wire [BITS-1:0] ee_v_o = ee_en ? ee_v : gamma_v_o;
`ifdef USE_EE
	isp_ee #(BITS, WIDTH, HEIGHT) ee_i0(pclk, rst_n, gamma_href_o, gamma_vsync_o, gamma_y_o, gamma_u_o, gamma_v_o, ee_href, ee_vsync, ee_y, ee_u, ee_v);
`else
	assign ee_href = gamma_href_o;
	assign ee_vsync = gamma_vsync_o;
	assign ee_y = gamma_y_o;
	assign ee_u = gamma_u_o;
	assign ee_v = gamma_v_o;
`endif

	assign out_href = ee_href_o;
	assign out_vsync = ee_vsync_o;
	assign out_y = ee_y_o;
	assign out_u = ee_u_o;
	assign out_v = ee_v_o;
endmodule
