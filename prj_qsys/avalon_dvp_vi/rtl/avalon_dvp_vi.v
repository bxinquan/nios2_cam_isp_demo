
module avalon_dvp_vi
#(
	parameter BITS = 8,
	parameter COLORBAR_H_FRONT = 16'd200,
	parameter COLORBAR_H_PULSE = 16'd536,
	parameter COLORBAR_H_BACK = 16'd200,
	parameter COLORBAR_H_DISP = 16'd960,
	parameter COLORBAR_V_FRONT = 16'd100,
	parameter COLORBAR_V_PULSE = 16'd240,
	parameter COLORBAR_V_BACK = 16'd100,
	parameter COLORBAR_V_DISP = 16'd544,
	parameter COLORBAR_BAYER = 0 //0:BGGR 1:GBRG 2:GRBG 3:RGGB
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
	output            as_irq,

	input cmos_xclk,
	input cmos_pclk,
	input cmos_href,
	input cmos_vsync,
	input [BITS-1:0] cmos_db,

	output out_pclk,
	output reg out_href,
	output reg out_vsync,
	output reg [BITS-1:0] out_raw
);

	localparam REG_RESET = 0;
	localparam REG_WIDTH = 1;
	localparam REG_HEIGHT = 2;
	localparam REG_FRAME_CNT = 3;
	localparam REG_COLORBAR_EN = 4;
	localparam REG_INT_STATUS = 5;
	localparam REG_INT_MASK = 6;
	
	reg module_reset;
	reg [15:0] dvp_width;
	reg [15:0] dvp_height;
	reg [31:0] dvp_frame_cnt;
	reg colorbar_en;

	reg int_frame_done;
	reg int_mask_frame_done;
	
	assign as_irq = int_frame_done&(~int_mask_frame_done);

	reg prev_vsync_onclk;
	always @ (posedge clk) prev_vsync_onclk <= out_vsync;

	always @ (posedge clk or posedge reset) begin
		if (reset) begin
			module_reset <= 1;
			colorbar_en <= 0;
			int_frame_done <= 0;
			int_mask_frame_done <= 1;
		end
		else begin
			if (as_read) begin
				case (as_address)
					REG_RESET: as_readdata <= {31'd0, module_reset};
					REG_WIDTH: as_readdata <= {16'd0, dvp_width};
					REG_HEIGHT: as_readdata <= {16'd0, dvp_height};
					REG_FRAME_CNT: as_readdata <= dvp_frame_cnt;
					REG_COLORBAR_EN: as_readdata <= {31'd0, colorbar_en};
					REG_INT_STATUS: as_readdata <= {31'd0, int_frame_done};
					REG_INT_MASK: as_readdata <= {31'd0, int_mask_frame_done};
					default: as_readdata <= 0;
				endcase
			end
			else if (as_write) begin
				case (as_address)
					REG_RESET: module_reset <= as_writedata[0];
					REG_WIDTH: ;
					REG_HEIGHT: ;
					REG_FRAME_CNT: ;
					REG_COLORBAR_EN: colorbar_en <= as_writedata[0];
					REG_INT_STATUS: int_frame_done <= 1'd0;
					REG_INT_MASK: int_mask_frame_done <= as_writedata[0];
					default:;
				endcase
			end
			else begin
				if (out_vsync & (~prev_vsync_onclk)) int_frame_done <= 1'b1;
			end
		end
	end
	
	wire gen_pclk, gen_href, gen_vsync;
	wire [BITS-1:0] gen_db;

	dvp_raw_timing_colorbar
		#(
			.BITS(BITS),
			.BAYER(COLORBAR_BAYER),
			.H_FRONT(COLORBAR_H_FRONT),
			.H_PULSE(COLORBAR_H_PULSE),
			.H_BACK(COLORBAR_H_BACK),
			.H_DISP(COLORBAR_H_DISP),
			.V_FRONT(COLORBAR_V_FRONT),
			.V_PULSE(COLORBAR_V_PULSE),
			.V_BACK(COLORBAR_V_BACK),
			.V_DISP(COLORBAR_V_DISP),
			.H_POL(1'b0),
			.V_POL(1'b1)
		)
		dvp_colorbar_timing_generator
		(
			.xclk(cmos_xclk),
			.reset_n(~module_reset),
			
			.dvp_pclk(gen_pclk),
			.dvp_href(gen_href),
			.dvp_hsync(),
			.dvp_vsync(gen_vsync),
			.dvp_raw(gen_db)
		);

	assign out_pclk = module_reset ? 1'b0 : (colorbar_en ? gen_pclk : cmos_pclk);
	always @ (posedge out_pclk or posedge module_reset) begin
		if (module_reset) begin
			out_href <= 0;
			out_vsync <= 0;
			out_raw <= 0;
		end
		else if (colorbar_en) begin
			out_href <= gen_href;
			out_vsync <= gen_vsync;
			out_raw <= gen_db;
		end
		else begin
			out_href <= cmos_href;
			out_vsync <= cmos_vsync;
			out_raw <= cmos_db;
		end
	end

	reg prev_href, prev_vsync;
	always @ (posedge out_pclk) begin
		prev_href <= out_href;
		prev_vsync <= out_vsync;
	end

	reg [15:0] pix_cnt;
	always @ (posedge out_pclk or posedge module_reset) begin
		if (module_reset)
			pix_cnt <= 0;
		else if (~prev_href & out_href)
			pix_cnt <= 1'b1;
		else if (out_href)
			pix_cnt <= pix_cnt + 1'b1;
		else
			pix_cnt <= pix_cnt;
	end

	reg [15:0] line_cnt;
	always @ (posedge out_pclk or posedge module_reset) begin
		if (module_reset)
			line_cnt <= 0;
		else if (~out_vsync & prev_vsync)
			line_cnt <= 0;
		else if (~out_href & prev_href)
			line_cnt <= line_cnt + 1'b1;
		else
			line_cnt <= line_cnt;
	end

	always @ (posedge out_pclk or posedge module_reset) begin
		if (module_reset) begin
			dvp_width <= 0;
			dvp_height <= 0;
			dvp_frame_cnt <= 0;
		end
		else if (~prev_vsync & out_vsync) begin
			dvp_width <= pix_cnt;
			dvp_height <= line_cnt;
			dvp_frame_cnt <= dvp_frame_cnt + 1'b1;
		end
		else begin
			dvp_width <= dvp_width;
			dvp_height <= dvp_height;
			dvp_frame_cnt <= dvp_frame_cnt;
		end
	end
endmodule
