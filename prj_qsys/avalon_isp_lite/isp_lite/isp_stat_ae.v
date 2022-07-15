/*************************************************************************
    > File Name: isp_stat_ae.v
    > Author: bxq
    > Mail: 544177215@qq.com
    > Created Time: Thu 21 Jan 2021 21:50:04 GMT
 ************************************************************************/

/*
 * ISP - Statistics for Auto Exposure
 */

module isp_stat_ae
#(
	parameter BITS = 8,
	parameter WIDTH = 1280,
	parameter HEIGHT = 960,
	parameter BAYER = 0, //0:BGGR 1:GBRG 2:GRBG 3:RGGB
	parameter OUT_BITS = 32
)
(
	input pclk,
	input rst_n,

	input in_href,
	input in_vsync,
	input [BITS-1:0] in_raw,

	output out_done,
	output [OUT_BITS-1:0] out_cnt,
	output [OUT_BITS-1:0] out_sum,
	
	input hist_clk,
	input hist_out,
	input [BITS+1:0] hist_addr, //[BITS+1:BITS] 2'b00:B,2'b01:Gb,2'b10:Gr,2'b11:R
	output [OUT_BITS-1:0] hist_data
	
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
	reg [OUT_BITS-1:0] tmp_sum;
	always @ (posedge pclk or negedge rst_n) begin
		if (!rst_n) begin
			tmp_cnt <= 0;
			tmp_sum <= 0;
		end
		else if (frame_start) begin
			tmp_cnt <= 0;
			tmp_sum <= 0;
		end
		else if (in_href) begin
			tmp_cnt <= tmp_cnt + 1'b1;
			tmp_sum <= tmp_sum + in_raw;
		end
		else begin
			tmp_cnt <= tmp_cnt;
			tmp_sum <= tmp_sum;
		end
	end

	reg done;
	reg [OUT_BITS-1:0] pix_cnt;
	reg [OUT_BITS-1:0] pix_sum;
	always @ (posedge pclk or negedge rst_n) begin
		if (!rst_n) begin
			done <= 0;
			pix_cnt <= 0;
			pix_sum <= 0;
		end
		else if (frame_end) begin
			done <= 1;
			pix_cnt <= tmp_cnt;
			pix_sum <= tmp_sum;
		end
		else begin
			done <= 0;
			pix_cnt <= pix_cnt;
			pix_sum <= pix_sum;
		end
	end

	assign out_done = done;
	assign out_cnt = pix_cnt;
	assign out_sum = pix_sum;

	reg odd_pix;
	always @ (posedge pclk or negedge rst_n) begin
		if (!rst_n)
			odd_pix <= 0;
		else if (!in_href)
			odd_pix <= 0;
		else
			odd_pix <= ~odd_pix;
	end
	
	reg prev_href;
	always @ (posedge pclk or negedge rst_n) begin
		if (!rst_n) 
			prev_href <= 0;
		else
			prev_href <= in_href;
	end	
	
	reg odd_line;
	always @ (posedge pclk or negedge rst_n) begin
		if (!rst_n) 
			odd_line <= 0;
		else if (in_vsync)
			odd_line <= 0;
		else if (prev_href & (~in_href))
			odd_line <= ~odd_line;
		else
			odd_line <= odd_line;
	end

	reg [1:0] addr_h2;
	always @ (*) begin
		case (BAYER)
			0: addr_h2 = {odd_line, odd_pix};
			1: addr_h2 = {odd_line, ~odd_pix};
			2: addr_h2 = {~odd_line, odd_pix};
			3: addr_h2 = {~odd_line, ~odd_pix};
			default: addr_h2 = 2'd0;
		endcase
	end

	hist_ram #(BITS+2, OUT_BITS) hist_ram_raw (pclk, rst_n, in_href, in_vsync, {addr_h2,in_raw}, hist_clk, hist_out, hist_addr, hist_data);
endmodule
