

//LCD_RGB_480x720_9MHz RGB565
module avalon_lcd_rgb_controller
#(
	parameter H_FRONT = 16'd2,
	parameter H_PULSE = 16'd41,
	parameter H_BACK = 16'd2,
	parameter H_DISP = 16'd480,
	parameter V_FRONT = 16'd2,
	parameter V_PULSE = 16'd10,
	parameter V_BACK = 16'd2,
	parameter V_DISP = 16'd272,
	parameter H_POL = 1'b0,
	parameter V_POL = 1'b0,
	parameter AM_DATA_WIDTH = 16,
	parameter AM_MAXIMUM_BURST_COUNT = 4,
	parameter AM_BURST_COUNT_WIDTH = 3,
	parameter AM_ADDRESS_WIDTH = 32,
	parameter AM_FIFO_DEPTH = 32,
	parameter AM_FIFO_DEPTH_LOG2 = 5,
	parameter AM_MEMORY_BASED_FIFO = 1  // set to 0 to use LEs instead
)
(
	// avalon clock&reset
	input clk,
	input reset,
	
	// slave control register
	input [1:0]       as_address,//0x0-lcd_reset, 0x0-stream_address
	input             as_read,
	output reg [31:0] as_readdata,
	input             as_write,
	input [31:0]      as_writedata,
	
	// master burst read
	input am_waitrequest,
	input am_readdatavalid,
	input [AM_DATA_WIDTH-1:0] am_readdata,
	output [AM_ADDRESS_WIDTH-1:0] am_address,
	output am_read,
	output [(AM_DATA_WIDTH/8)-1:0] am_byteenable,
	output [AM_BURST_COUNT_WIDTH-1:0] am_burstcount,

	//pixel clock 
	input pclk,	 //9MHz

	//LCD pin
	output lcd_dclk,
	output lcd_de,
	output lcd_hs,
	output lcd_vs,
	output [7:0] lcd_r,
	output [7:0] lcd_g,
	output [7:0] lcd_b
);

	//mm control register
	reg timing_reset;
	reg [AM_ADDRESS_WIDTH-1:0] fb_addr;
	always @ (posedge clk or posedge reset) begin
		if (reset) begin
			timing_reset <= 1;
			fb_addr <= 0;
		end
		else begin
			if (as_read) begin
				case (as_address)
					2'd0: as_readdata <= {31'd0, timing_reset};
					2'd1: as_readdata <= fb_addr;
					default: as_readdata <= 0;
				endcase
			end
			if (as_write) begin
				case (as_address)
					2'd0: timing_reset <= as_writedata[0];
					2'd1: fb_addr <= as_writedata;
					default:;
				endcase
			end
		end
	end

	// control inputs and outputs
	reg prev_vs;
	always @ (posedge clk) prev_vs <= lcd_vs;

	reg control_go;
	always @ (posedge clk or posedge timing_reset) begin
		if (timing_reset)
			control_go <= 1'b0;
		else if (prev_vs != V_POL && lcd_vs == V_POL)
			control_go <= 1'b1;
		else
			control_go <= 1'b0;
	end

	lcd_rgb_timing_colorbar a_lcd_rgb_timing(
		.pclk(pclk),
		.reset_n(!timing_reset),
		.lcd_dclk(lcd_dclk),
		.lcd_de(lcd_de),
		.lcd_hs(lcd_hs),
		.lcd_vs(lcd_vs),
		.lcd_r(),
		.lcd_g(),
		.lcd_b()
	);
	defparam a_lcd_rgb_timing.H_FRONT = H_FRONT;
	defparam a_lcd_rgb_timing.H_PULSE = H_PULSE;
	defparam a_lcd_rgb_timing.H_BACK = H_BACK;
	defparam a_lcd_rgb_timing.H_DISP = H_DISP;
	defparam a_lcd_rgb_timing.V_FRONT = V_FRONT;
	defparam a_lcd_rgb_timing.V_PULSE = V_PULSE;
	defparam a_lcd_rgb_timing.V_BACK = V_BACK;
	defparam a_lcd_rgb_timing.V_DISP = V_DISP;
	defparam a_lcd_rgb_timing.H_POL = H_POL;
	defparam a_lcd_rgb_timing.V_POL = V_POL;

	wire [AM_DATA_WIDTH-1:0] user_buffer_data;
	assign lcd_r = lcd_de ? {user_buffer_data[15:11],3'd0} : 8'd0;
	assign lcd_g = lcd_de ? {user_buffer_data[10:5],2'd0} : 8'd0;
	assign lcd_b = lcd_de ? {user_buffer_data[4:0],3'd0} : 8'd0;

	burst_read_master a_burst_read_master(
		.clk (clk),
		.reset (timing_reset),
		.control_fixed_location (1'b0),
		.control_read_base (fb_addr),
		.control_read_length (H_DISP * V_DISP * 2),
		.control_go (control_go),
		.control_done (),
		.control_early_done (),
		.user_read_clock (pclk),
		.user_read_buffer (lcd_de),
		.user_buffer_data (user_buffer_data),
		.user_data_available (),
		.master_address (am_address),
		.master_read (am_read),
		.master_byteenable (am_byteenable),
		.master_readdata (am_readdata),
		.master_readdatavalid (am_readdatavalid),
		.master_burstcount (am_burstcount),
		.master_waitrequest (am_waitrequest)
	);
	defparam a_burst_read_master.DATAWIDTH = AM_DATA_WIDTH;
	defparam a_burst_read_master.MAXBURSTCOUNT = AM_MAXIMUM_BURST_COUNT;
	defparam a_burst_read_master.BURSTCOUNTWIDTH = AM_BURST_COUNT_WIDTH;
	defparam a_burst_read_master.BYTEENABLEWIDTH = AM_DATA_WIDTH/8;
	defparam a_burst_read_master.ADDRESSWIDTH = AM_ADDRESS_WIDTH;
	defparam a_burst_read_master.FIFODEPTH = AM_FIFO_DEPTH;
	defparam a_burst_read_master.FIFODEPTH_LOG2 = AM_FIFO_DEPTH_LOG2;
	defparam a_burst_read_master.FIFOUSEMEMORY = AM_MEMORY_BASED_FIFO;
	
	/*
	latency_aware_read_master a_latency_aware_read_master(
		.clk (clk),
		.reset (timing_reset),
		.control_fixed_location (1'b0),
		.control_read_base (fb_addr),
		.control_read_length (H_DISP * V_DISP * 2),
		.control_go (control_go),
		.control_done (),
		.control_early_done (),
		.user_read_clock (pclk),
		.user_read_buffer (lcd_de),
		.user_buffer_data (user_buffer_data),
		.user_data_available (),
		.master_address (am_address),
		.master_read (am_read),
		.master_byteenable (am_byteenable),
		.master_readdata (am_readdata),
		.master_readdatavalid (am_readdatavalid),
		.master_waitrequest (am_waitrequest)
	);
	defparam a_latency_aware_read_master.DATAWIDTH = AM_DATA_WIDTH;
	defparam a_latency_aware_read_master.BYTEENABLEWIDTH = AM_DATA_WIDTH/8;
	defparam a_latency_aware_read_master.ADDRESSWIDTH = AM_ADDRESS_WIDTH;
	defparam a_latency_aware_read_master.FIFODEPTH = AM_FIFO_DEPTH;
	defparam a_latency_aware_read_master.FIFODEPTH_LOG2 = AM_FIFO_DEPTH_LOG2;
	defparam a_latency_aware_read_master.FIFOUSEMEMORY = AM_MEMORY_BASED_FIFO;*/

endmodule
