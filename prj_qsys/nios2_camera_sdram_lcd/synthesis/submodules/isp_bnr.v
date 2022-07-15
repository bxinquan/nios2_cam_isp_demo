/*************************************************************************
    > File Name: isp_bnr.v
    > Author: bxq
    > Mail: 544177215@qq.com
    > Created Time: Thu 21 Jan 2021 21:50:04 GMT
 ************************************************************************/

/*
 * ISP - Noise Reduction
 * Gaussian Filter
 */

module isp_bnr
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
	output [BITS-1:0] out_raw
);

	wire [BITS-1:0] shiftout;
	wire [BITS-1:0] tap3x, tap2x, tap1x, tap0x;
	shift_register #(BITS, WIDTH, 4) linebuffer(pclk, in_href, in_raw, shiftout, {tap3x, tap2x, tap1x, tap0x});
	
	reg [BITS-1:0] in_raw_r;
	reg [BITS-1:0] p11,p12,p13,p14,p15;
	reg [BITS-1:0] p21,p22,p23,p24,p25;
	reg [BITS-1:0] p31,p32,p33,p34,p35;
	reg [BITS-1:0] p41,p42,p43,p44,p45;
	reg [BITS-1:0] p51,p52,p53,p54,p55;
	always @ (posedge pclk or negedge rst_n) begin
		if (!rst_n) begin
			in_raw_r <= 0;
			p11 <= 0;
			p21 <= 0;
			p31 <= 0;
			p41 <= 0;
			p51 <= 0;
			p12 <= 0;
			p22 <= 0;
			p32 <= 0;
			p42 <= 0;
			p52 <= 0;
			p13 <= 0;
			p23 <= 0;
			p33 <= 0;
			p43 <= 0;
			p53 <= 0;
			p14 <= 0;
			p24 <= 0;
			p34 <= 0;
			p44 <= 0;
			p54 <= 0;
			p15 <= 0;
			p25 <= 0;
			p35 <= 0;
			p45 <= 0;
			p55 <= 0;
		end
		else begin
			in_raw_r <= in_raw;
			p11 <= p12;
			p21 <= p22;
			p31 <= p32;
			p41 <= p42;
			p51 <= p52;
			p12 <= p13;
			p22 <= p23;
			p32 <= p33;
			p42 <= p43;
			p52 <= p53;
			p13 <= p14;
			p23 <= p24;
			p33 <= p34;
			p43 <= p44;
			p53 <= p54;
			p14 <= p15;
			p24 <= p25;
			p34 <= p35;
			p44 <= p45;
			p54 <= p55;
			p15 <= tap3x;
			p25 <= tap2x;
			p35 <= tap1x;
			p45 <= tap0x;
			p55 <= in_raw_r;
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
	wire odd_pix_dly = odd_pix;
	
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
	wire odd_line_dly = odd_line;

	reg [BITS-1:0] raw_now;
	always @ (posedge pclk or negedge rst_n) begin
		if (!rst_n) begin
			raw_now <=  0;
		end
		else begin
			case (BAYER)
				0: begin
					raw_now <= gauss({odd_line_dly, odd_pix_dly},
										p11,p12,p13,p14,p15,
										p21,p22,p23,p24,p25,
										p31,p32,p33,p34,p35,
										p41,p42,p43,p44,p45,
										p51,p52,p53,p54,p55);
				end
				1: begin
					raw_now <= gauss({odd_line_dly, ~odd_pix_dly},
										p11,p12,p13,p14,p15,
										p21,p22,p23,p24,p25,
										p31,p32,p33,p34,p35,
										p41,p42,p43,p44,p45,
										p51,p52,p53,p54,p55);
				end
				2: begin
					raw_now <= gauss({~odd_line_dly, odd_pix_dly},
										p11,p12,p13,p14,p15,
										p21,p22,p23,p24,p25,
										p31,p32,p33,p34,p35,
										p41,p42,p43,p44,p45,
										p51,p52,p53,p54,p55);
				end
				3: begin
					raw_now <= gauss({~odd_line_dly, ~odd_pix_dly},
										p11,p12,p13,p14,p15,
										p21,p22,p23,p24,p25,
										p31,p32,p33,p34,p35,
										p41,p42,p43,p44,p45,
										p51,p52,p53,p54,p55);
				end
				default: begin
					raw_now <=  0;
				end
			endcase
		end
	end

	localparam DLY_CLK = 5;
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
	assign out_raw = out_href ? raw_now : {BITS{1'b0}};

	// B,R gauss kernel
	// [1, 0, 2, 0, 1]
	// [0, 0, 0, 0, 0]
	// [2, 0, 4, 0, 2]
	// [0, 0, 0, 0, 0]
	// [1, 0, 2, 0, 1]
	//
	// Gb,Gr gauss kernel
	// [0, 0, 1, 0, 0]
	// [0, 2, 0, 2, 0]
	// [1, 0, 4, 0, 1]
	// [0, 2, 0, 2, 0]
	// [0, 0, 1, 0, 0]
	function [BITS-1:0] gauss;
		input [1:0] format;//0:B 1:Gb 2:Gr 3:R
		input [BITS-1:0] p11,p12,p13,p14,p15;
		input [BITS-1:0] p21,p22,p23,p24,p25;
		input [BITS-1:0] p31,p32,p33,p34,p35;
		input [BITS-1:0] p41,p42,p43,p44,p45;
		input [BITS-1:0] p51,p52,p53,p54,p55;
		reg [BITS-1+4:0] raw;
		begin
			case (format)
				2'b00,2'b11: raw = {2'd0,p33,2'd0} + {3'd0,p13,1'd0} + {3'd0,p31,1'd0} + {3'd0,p35,1'd0} + {3'd0,p53,1'd0} + {4'd0,p11} + {4'd0,p15} + {4'd0,p51} + {4'd0,p55};
				2'b01,2'b10: raw = {2'd0,p33,2'd0} + {3'd0,p22,1'd0} + {3'd0,p24,1'd0} + {3'd0,p42,1'd0} + {3'd0,p44,1'd0} + {4'd0,p13} + {4'd0,p31} + {4'd0,p35} + {4'd0,p53};
				default: raw = {4'd0,{BITS{1'b0}}};
			endcase
			gauss = raw[BITS-1+4:4] > {BITS{1'b1}} ? {BITS{1'b1}} : raw[BITS-1+4:4];
		end
	endfunction
endmodule
