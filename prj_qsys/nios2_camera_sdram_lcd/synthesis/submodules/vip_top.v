/*************************************************************************
    > File Name: vip_top.v
    > Author: bxq
    > Mail: 544177215@qq.com
    > Created Time: Thu 21 Jan 2021 21:50:04 GMT
 ************************************************************************/


module vip_top
#(
	parameter BITS = 8,
	parameter WIDTH = 1280,
	parameter HEIGHT = 960
)
(
	input pclk,
	input rst_n,
	
	input in_href,
	input in_vsync,
	input [BITS-1:0] in_y,
	input [BITS-1:0] in_u,
	input [BITS-1:0] in_v,
	
	output out_pclk,
	output out_href,
	output out_vsync,
	output [BITS-1:0] out_r,
	output [BITS-1:0] out_g,
	output [BITS-1:0] out_b,
	
	input hist_equ_en, sobel_en, yuv2rgb_en, dscale_en,
	input [3:0] dscale_scale
);

//`define USE_HIST_EQU 1
//`define USE_SOBEL   1
`define USE_YUV2RGB 1
`define USE_DSCALE  1

	wire hist_equ_href, hist_equ_vsync;
	wire [BITS-1:0] hist_equ_y, hist_equ_u, hist_equ_v;
	wire hist_equ_href_o = hist_equ_en ? hist_equ_href : in_href;
	wire hist_equ_vsync_o = hist_equ_en ? hist_equ_vsync : in_vsync;
	wire [BITS-1:0] hist_equ_y_o = hist_equ_en ? hist_equ_y : in_y;
	wire [BITS-1:0] hist_equ_u_o = hist_equ_en ? hist_equ_u : in_u;
	wire [BITS-1:0] hist_equ_v_o = hist_equ_en ? hist_equ_v : in_v;
`ifdef USE_HIST_EQU
	vip_hist_equ #(BITS, WIDTH, HEIGHT) hist_equ_i0(pclk, rst_n, in_href, in_vsync, in_y, hist_equ_href, hist_equ_vsync, hist_equ_y);
	reg [BITS-1:0] hist_equ_u_r, hist_equ_v_r;
	always @ (posedge pclk) {hist_equ_u_r,hist_equ_v_r} <= {in_u, in_v};
	assign {hist_equ_u, hist_equ_v} = {hist_equ_u_r, hist_equ_v_r};
`else
	assign hist_equ_href = in_href;
	assign hist_equ_vsync = in_vsync;
	assign hist_equ_y = in_y;
	assign hist_equ_u = in_u;
	assign hist_equ_v = in_v;
`endif

	wire sobel_href, sobel_vsync;
	wire [BITS-1:0] sobel_y, sobel_u, sobel_v;
	wire sobel_href_o = sobel_en ? sobel_href : hist_equ_href_o;
	wire sobel_vsync_o = sobel_en ? sobel_vsync : hist_equ_vsync_o;
	wire [BITS-1:0] sobel_y_o = sobel_en ? sobel_y : hist_equ_y_o;
	wire [BITS-1:0] sobel_u_o = sobel_en ? sobel_u : hist_equ_u_o;
	wire [BITS-1:0] sobel_v_o = sobel_en ? sobel_v : hist_equ_v_o;
`ifdef USE_SOBEL
	vip_sobel #(BITS, WIDTH, HEIGHT) sobel_i0(pclk, rst_n, hist_equ_href_o, hist_equ_vsync_o, hist_equ_y_o, sobel_href, sobel_vsync, sobel_y);
	assign sobel_u = 1'b1 << (BITS-1);
	assign sobel_v = 1'b1 << (BITS-1);
`else
	assign sobel_href = hist_equ_href_o;
	assign sobel_vsync = hist_equ_vsync_o;
	assign sobel_y = hist_equ_y_o;
	assign sobel_u = hist_equ_u_o;
	assign sobel_v = hist_equ_v_o;
`endif

	wire yuv2rgb_href, yuv2rgb_vsync;
	wire [BITS-1:0] yuv2rgb_r, yuv2rgb_g, yuv2rgb_b;
	wire yuv2rgb_href_o = yuv2rgb_en ? yuv2rgb_href : sobel_href_o;
	wire yuv2rgb_vsync_o = yuv2rgb_en ? yuv2rgb_vsync : sobel_vsync_o;
	wire [BITS-1:0] yuv2rgb_r_o = yuv2rgb_en ? yuv2rgb_r : sobel_y_o;
	wire [BITS-1:0] yuv2rgb_g_o = yuv2rgb_en ? yuv2rgb_g : sobel_u_o;
	wire [BITS-1:0] yuv2rgb_b_o = yuv2rgb_en ? yuv2rgb_b : sobel_v_o;
`ifdef USE_YUV2RGB
	vip_yuv2rgb #(BITS, WIDTH, HEIGHT) yuv2rgb_i0(pclk, rst_n, sobel_href_o, sobel_vsync_o, sobel_y_o, sobel_u_o, sobel_v_o, yuv2rgb_href, yuv2rgb_vsync, yuv2rgb_r, yuv2rgb_g, yuv2rgb_b);
`else
	assign yuv2rgb_href = sobel_href_o;
	assign yuv2rgb_vsync = sobel_vsync_o;
	assign yuv2rgb_r = sobel_y_o;
	assign yuv2rgb_g = sobel_u_o;
	assign yuv2rgb_b = sobel_v_o;
`endif

	wire dscale_pclk, dscale_href, dscale_vsync;
	wire [BITS-1:0] dscale_r, dscale_g, dscale_b;
	wire dscale_pclk_o = dscale_en ? dscale_pclk : pclk;
	wire dscale_href_o = dscale_en ? dscale_href : yuv2rgb_href_o;
	wire dscale_vsync_o = dscale_en ? dscale_vsync : yuv2rgb_vsync_o;
	wire [BITS-1:0] dscale_r_o = dscale_en ? dscale_r : yuv2rgb_r_o;
	wire [BITS-1:0] dscale_g_o = dscale_en ? dscale_g : yuv2rgb_g_o;
	wire [BITS-1:0] dscale_b_o = dscale_en ? dscale_b : yuv2rgb_b_o;
`ifdef USE_DSCALE
	vip_dscale #(BITS*3, WIDTH, HEIGHT) dscale_i0(pclk, rst_n, dscale_scale, yuv2rgb_href_o, yuv2rgb_vsync_o, {yuv2rgb_r_o, yuv2rgb_g_o, yuv2rgb_b_o}, dscale_pclk, dscale_href, dscale_vsync, {dscale_r, dscale_g, dscale_b});
`else
	assign dscale_pclk = pclk;
	assign dscale_href = yuv2rgb_href_o;
	assign dscale_vsync = yuv2rgb_vsync_o;
	assign dscale_r = yuv2rgb_r_o;
	assign dscale_g = yuv2rgb_g_o;
	assign dscale_b = yuv2rgb_b_o;
`endif

	assign out_pclk = dscale_pclk_o;
	assign out_href = dscale_href_o;
	assign out_vsync = dscale_vsync_o;
	assign out_r = dscale_r_o;
	assign out_g = dscale_g_o;
	assign out_b = dscale_b_o;
endmodule
