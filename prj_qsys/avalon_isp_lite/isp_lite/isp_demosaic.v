/*************************************************************************
    > File Name: isp_demosaic.v
    > Author: bxq
    > Mail: 544177215@qq.com
    > Created Time: Thu 21 Jan 2021 21:50:04 GMT
 ************************************************************************/

/*
 * ISP - Demosaic (RAW -> RGB)
 */

module isp_demosaic
#(
	parameter BITS = 8,
	parameter WIDTH = 1280,
	parameter HEIGHT = 960,
	parameter BAYER = 0 //0:BGGR 1:GBRG 2:GRBG 3:RGGB
)
(
	input pclk,
	input rst_n,

	input in_href,
	input in_vsync,
	input [BITS-1:0] in_raw,

	output out_href,
	output out_vsync,
	output [BITS-1:0] out_r,
	output [BITS-1:0] out_g,
	output [BITS-1:0] out_b
);

	wire [BITS-1:0] shiftout;
	wire [BITS-1:0] tap1x, tap0x;
	shift_register #(BITS, WIDTH, 2) linebuffer(pclk, in_href, in_raw, shiftout, {tap1x, tap0x});
	
	reg [BITS-1:0] in_raw_r;
	reg [BITS-1:0] p11,p12,p13;
	reg [BITS-1:0] p21,p22,p23;
	reg [BITS-1:0] p31,p32,p33;
	always @ (posedge pclk or negedge rst_n) begin
		if (!rst_n) begin
			in_raw_r <= 0;
			p13 <= 0;
			p23 <= 0;
			p33 <= 0;
			p12 <= 0;
			p22 <= 0;
			p32 <= 0;
			p11 <= 0;
			p21 <= 0;
			p31 <= 0;
		end
		else begin
			in_raw_r <= in_raw;
			p11 <= p12;
			p21 <= p22;
			p31 <= p32;
			p12 <= p13;
			p22 <= p23;
			p32 <= p33;
			p13 <= tap1x;
			p23 <= tap0x;
			p33 <= in_raw_r;
		end
	end

	reg odd_pix;
	always @ (posedge pclk or negedge rst_n) begin
		if (!rst_n)
			odd_pix <= 0;
		else if (!in_href)
			odd_pix <= 0;
		else
			odd_pix <= ~odd_pix;
	end
	wire odd_pix_dly = ~odd_pix;
	
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
	wire odd_line_dly = ~odd_line;

	reg [BITS-1:0] r_now, g_now, b_now;
	always @ (posedge pclk or negedge rst_n) begin
		if (!rst_n) begin
			r_now <=  0;
			g_now <=  0;
			b_now <=  0;
		end
		else begin
			case (BAYER)
				0: begin
					r_now <= raw2r({odd_line_dly, odd_pix_dly},
										p11,p12,p13,
										p21,p22,p23,
										p31,p32,p33);
					g_now <= raw2g({odd_line_dly, odd_pix_dly},
										p11,p12,p13,
										p21,p22,p23,
										p31,p32,p33);
					b_now <= raw2b({odd_line_dly, odd_pix_dly},
										p11,p12,p13,
										p21,p22,p23,
										p31,p32,p33);
				end
				1: begin
					r_now <= raw2r({odd_line_dly, ~odd_pix_dly},
										p11,p12,p13,
										p21,p22,p23,
										p31,p32,p33);
					g_now <= raw2g({odd_line_dly, ~odd_pix_dly},
										p11,p12,p13,
										p21,p22,p23,
										p31,p32,p33);
					b_now <= raw2b({odd_line_dly, ~odd_pix_dly},
										p11,p12,p13,
										p21,p22,p23,
										p31,p32,p33);
				end
				2: begin
					r_now <= raw2r({~odd_line_dly, odd_pix_dly},
										p11,p12,p13,
										p21,p22,p23,
										p31,p32,p33);
					g_now <= raw2g({~odd_line_dly, odd_pix_dly},
										p11,p12,p13,
										p21,p22,p23,
										p31,p32,p33);
					b_now <= raw2b({~odd_line_dly, odd_pix_dly},
										p11,p12,p13,
										p21,p22,p23,
										p31,p32,p33);
				end
				3: begin
					r_now <= raw2r({~odd_line_dly, ~odd_pix_dly},
										p11,p12,p13,
										p21,p22,p23,
										p31,p32,p33);
					g_now <= raw2g({~odd_line_dly, ~odd_pix_dly},
										p11,p12,p13,
										p21,p22,p23,
										p31,p32,p33);
					b_now <= raw2b({~odd_line_dly, ~odd_pix_dly},
										p11,p12,p13,
										p21,p22,p23,
										p31,p32,p33);
				end
				default: begin
					r_now <=  0;
					g_now <=  0;
					b_now <=  0;
				end
			endcase
		end
	end

	localparam DLY_CLK = 4;
	reg [DLY_CLK-1:0] href_dly;
	reg [DLY_CLK-1:0] vsync_dly;
	always @ (posedge pclk or negedge rst_n) begin
		if (!rst_n) begin
			href_dly <= 0;
			vsync_dly <= 0;
		end
		else begin
			href_dly <= {href_dly[DLY_CLK-2:0], in_href};
			vsync_dly <= {vsync_dly[DLY_CLK-2:0], in_vsync};
		end
	end
	
	assign out_href = href_dly[DLY_CLK-1];
	assign out_vsync = vsync_dly[DLY_CLK-1];
	assign out_r = out_href ? r_now : {BITS{1'b0}};
	assign out_g = out_href ? g_now : {BITS{1'b0}};
	assign out_b = out_href ? b_now : {BITS{1'b0}};

	function [BITS-1:0] raw2r;
		input [1:0] format;//0:B 1:Gb 2:Gr 3:R
		input [BITS-1:0] p11,p12,p13;
		input [BITS-1:0] p21,p22,p23;
		input [BITS-1:0] p31,p32,p33;
		reg [BITS+1:0] r;
		begin
			case (format)
				2'b00: r = (p11 + p13 + p31 + p33) >> 2;
				2'b01: r = (p12 + p32) >> 1;
				2'b10: r = (p21 + p23) >> 1;
				2'b11: r = p22;
				default: r = {BITS{1'b0}};
			endcase
			raw2r = r > {BITS{1'b1}} ? {BITS{1'b1}} : r[BITS-1:0];
		end
	endfunction

	function [BITS-1:0] raw2g;
		input [1:0] format;//0:B 1:Gb 2:Gr 3:R
		input [BITS-1:0] p11,p12,p13;
		input [BITS-1:0] p21,p22,p23;
		input [BITS-1:0] p31,p32,p33;
		reg [BITS+1:0] g;
		begin
			case (format)
				2'b00: g = (p12 + p32 + p21 + p23) >> 2;
				2'b01: g = p22;
				2'b10: g = p22;
				2'b11: g = (p12 + p32 + p21 + p23) >> 2;
				default: g = {BITS{1'b0}};
			endcase
			raw2g = g > {BITS{1'b1}} ? {BITS{1'b1}} : g[BITS-1:0];
		end
	endfunction

	function [BITS-1:0] raw2b;
		input [1:0] format;//0:B 1:Gb 2:Gr 3:R
		input [BITS-1:0] p11,p12,p13;
		input [BITS-1:0] p21,p22,p23;
		input [BITS-1:0] p31,p32,p33;
		reg [BITS+1:0] b;
		begin
			case (format)
				2'b00: b = p22;
				2'b01: b = (p21 + p23) >> 1;
				2'b10: b = (p12 + p32) >> 1;
				2'b11: b = (p11 + p13 + p31 + p33) >> 2;
				default: b = {BITS{1'b0}};
			endcase
			raw2b = b > {BITS{1'b1}} ? {BITS{1'b1}} : b[BITS-1:0];
		end
	endfunction
endmodule
