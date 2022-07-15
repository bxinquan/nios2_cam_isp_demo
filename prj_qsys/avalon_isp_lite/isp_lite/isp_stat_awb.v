/*************************************************************************
    > File Name: isp_stat_awb.v
    > Author: bxq
    > Mail: 544177215@qq.com
    > Created Time: Thu 21 Jan 2021 21:50:04 GMT
 ************************************************************************/

/*
 * ISP - Statistics for Auto White Balance
 */

module isp_stat_awb
#(
	parameter BITS = 8,
	parameter WIDTH = 1280,
	parameter HEIGHT = 960,
	parameter OUT_BITS = 32
)
(
	input pclk,
	input rst_n,

	input [BITS-1:0] min,
	input [BITS-1:0] max,

	input in_href,
	input in_vsync,
	input [BITS-1:0] in_r,
	input [BITS-1:0] in_g,
	input [BITS-1:0] in_b,

	output out_done,
	output [OUT_BITS-1:0] out_cnt,
	output [OUT_BITS-1:0] out_sum_r,
	output [OUT_BITS-1:0] out_sum_g,
	output [OUT_BITS-1:0] out_sum_b,

	input hist_clk,
	input hist_out,
	input [BITS+1:0] hist_addr, //[BITS+1:BITS] 2'b00:R,2'b01:G,2'b10:B
	output reg [OUT_BITS-1:0] hist_data
);

	reg prev_vsync;
	wire frame_start = prev_vsync & (~in_vsync);
	wire frame_end = (~prev_vsync) & in_vsync;
	always @ (posedge pclk or negedge rst_n) begin
		if (!rst_n) begin
			prev_vsync <= 0;
		end
		else begin
			prev_vsync <= in_vsync;
		end
	end

	reg [OUT_BITS-1:0] tmp_cnt;
	reg [OUT_BITS-1:0] tmp_sum_r, tmp_sum_g, tmp_sum_b;
	always @ (posedge pclk or negedge rst_n) begin
		if (!rst_n) begin
			tmp_cnt <= 0;
			tmp_sum_r <= 0;
			tmp_sum_g <= 0;
			tmp_sum_b <= 0;
		end
		else if (frame_start) begin
			tmp_cnt <= 0;
			tmp_sum_r <= 0;
			tmp_sum_g <= 0;
			tmp_sum_b <= 0;
		end
		else if (in_href && (in_r >= min && in_r <= max) && (in_g >= min && in_g <= max) && (in_b >= min && in_b <= max)) begin
			tmp_cnt <= tmp_cnt + 1'b1;
			tmp_sum_r <= tmp_sum_r + in_r;
			tmp_sum_g <= tmp_sum_g + in_g;
			tmp_sum_b <= tmp_sum_b + in_b;
		end
		else begin
			tmp_cnt <= tmp_cnt;
			tmp_sum_r <= tmp_sum_r;
			tmp_sum_g <= tmp_sum_g;
			tmp_sum_b <= tmp_sum_b;
		end
	end

	reg done;
	reg [OUT_BITS-1:0] pix_cnt;
	reg [OUT_BITS-1:0] pix_sum_r;
	reg [OUT_BITS-1:0] pix_sum_g;
	reg [OUT_BITS-1:0] pix_sum_b;
	always @ (posedge pclk or negedge rst_n) begin
		if (!rst_n) begin
			done <= 0;
			pix_cnt <= 0;
			pix_sum_r <= 0;
			pix_sum_g <= 0;
			pix_sum_b <= 0;
		end
		else if (frame_end) begin
			done <= 1;
			pix_cnt <= tmp_cnt;
			pix_sum_r <= tmp_sum_r;
			pix_sum_g <= tmp_sum_g;
			pix_sum_b <= tmp_sum_b;
		end
		else begin
			done <= 0;
			pix_cnt <= pix_cnt;
			pix_sum_r <= pix_sum_r;
			pix_sum_g <= pix_sum_g;
			pix_sum_b <= pix_sum_b;
		end
	end

	assign out_done = done;
	assign out_cnt = pix_cnt;
	assign out_sum_r = pix_sum_r;
	assign out_sum_g = pix_sum_g;
	assign out_sum_b = pix_sum_b;

	wire [OUT_BITS-1:0] hist_data_r, hist_data_g, hist_data_b;
	reg hist_out_r, hist_out_g, hist_out_b;
	always @ (*) begin
		case (hist_addr[BITS+1:BITS])
			2'b00: {hist_out_r, hist_out_g, hist_out_b, hist_data} = {3'b100, hist_data_r};
			2'b01: {hist_out_r, hist_out_g, hist_out_b, hist_data} = {3'b010, hist_data_g};
			2'b10: {hist_out_r, hist_out_g, hist_out_b, hist_data} = {3'b001, hist_data_b};
			default: {hist_out_r, hist_out_g, hist_out_b, hist_data} = {3'b000, {OUT_BITS{1'b0}}};
		endcase
	end
	hist_ram #(BITS, OUT_BITS) hist_ram_r (pclk, rst_n, in_href, in_vsync, in_r, hist_clk, hist_out_r, hist_addr[BITS-1:0], hist_data_r);
	hist_ram #(BITS, OUT_BITS) hist_ram_g (pclk, rst_n, in_href, in_vsync, in_g, hist_clk, hist_out_g, hist_addr[BITS-1:0], hist_data_g);
	hist_ram #(BITS, OUT_BITS) hist_ram_b (pclk, rst_n, in_href, in_vsync, in_b, hist_clk, hist_out_b, hist_addr[BITS-1:0], hist_data_b);
endmodule
