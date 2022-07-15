
module avalon_vip
#(
	parameter BITS = 8,
	parameter WIDTH = 1280,
	parameter HEIGHT = 960
)
(
	input clk,
	input reset,
	
	// slave control register
	input [5:0]       as_address,
	input             as_read,
	output reg [31:0] as_readdata,
	input             as_write,
	input [31:0]      as_writedata,
	
	output irq,

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
	output [BITS-1:0] out_b
);

	localparam REG_RESET = 0;
	localparam REG_TOP_EN = 1;
	localparam REG_DSCALE_SCALE = 2;
	localparam REG_INT_STATUS = 3;
	localparam REG_INT_MASK = 4;
	
	reg module_reset;
	reg hist_equ_en, sobel_en, yuv2rgb_en, dscale_en;

	reg [3:0] dscale_scale;

	reg int_frame_done;
	reg int_mask_frame_done;
	
	assign irq = int_frame_done&(~int_mask_frame_done);

	reg prev_vsync;
	always @ (posedge clk) prev_vsync <= out_vsync;

	always @ (posedge clk or posedge reset) begin
		if (reset) begin
			module_reset <= 1;
			sobel_en <= 0;
			yuv2rgb_en <= 1;
			dscale_en <= 1;
			dscale_scale <= 4'd1;//1/2
			int_frame_done <= 0;
			int_mask_frame_done <= 1;
		end
		else begin
			if (as_read) begin
				case (as_address)
					REG_RESET: as_readdata <= {31'd0, module_reset};
					REG_TOP_EN: as_readdata <= {28'd0, dscale_en, yuv2rgb_en, sobel_en, hist_equ_en};
					REG_DSCALE_SCALE: as_readdata <= {28'd0, dscale_scale};
					REG_INT_STATUS: as_readdata <= {31'd0, int_frame_done};
					REG_INT_MASK: as_readdata <= {31'd0, int_mask_frame_done};
					default: as_readdata <= 0;
				endcase
			end
			else if (as_write) begin
				case (as_address)
					REG_RESET: module_reset <= as_writedata[0];
					REG_TOP_EN: {dscale_en, yuv2rgb_en, sobel_en, hist_equ_en} <= as_writedata[3:0];
					REG_DSCALE_SCALE: dscale_scale <= as_writedata[3:0];
					REG_INT_STATUS: int_frame_done <= 1'd0;
					REG_INT_MASK: int_mask_frame_done <= as_writedata[0];
					default:;
				endcase
			end
			else begin
				if (out_vsync & (~prev_vsync)) int_frame_done <= 1'b1;
			end
		end
	end
	
	vip_top #(BITS, WIDTH, HEIGHT) vip_top_i0 (
			.pclk(pclk),
			.rst_n(rst_n & ~module_reset),
			
			.in_href(in_href),
			.in_vsync(in_vsync),
			.in_y(in_y),
			.in_u(in_u),
			.in_v(in_v),
			
			.out_pclk(out_pclk),
			.out_href(out_href),
			.out_vsync(out_vsync),
			.out_r(out_r),
			.out_g(out_g),
			.out_b(out_b),
			
			.hist_equ_en(hist_equ_en),
			.sobel_en(sobel_en),
			.yuv2rgb_en(yuv2rgb_en),
			.dscale_en(dscale_en),
			.dscale_scale(dscale_scale)
		);
endmodule
