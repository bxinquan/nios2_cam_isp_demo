
module avalon_dvp_wch
#(
	parameter AM_DATA_WIDTH = 16,
	parameter AM_MAX_BURST_COUNT = 4,
	parameter AM_BURST_COUNT_WIDTH = 3,
	parameter AM_ADDRESS_WIDTH = 32,
	parameter AM_FIFO_DEPTH = 32,
	parameter AM_FIFO_DEPTH_LOG2 = 5,
	parameter AM_MEMORY_BASED_FIFO = 1  // set to 0 to use LEs instead
)
(	input clk,
	input reset,
	
	// slave control register
	input [1:0]       as_address,//0x0-dvp_reset, 0x0-stream_address
	input             as_read,
	output reg [31:0] as_readdata,
	input             as_write,
	input [31:0]      as_writedata,

	// master write
	output                            am_write,
	output [AM_DATA_WIDTH-1:0]        am_writedata,
	output [AM_ADDRESS_WIDTH-1:0]     am_address,
	output [AM_BURST_COUNT_WIDTH-1:0] am_burstcount,	
	input                             am_waitrequest,

	input                     pclk,	
	input                     href,
	input                     vsync,
	input [AM_DATA_WIDTH-1:0] raw
);

	//mm control register
	reg wch_reset;
	reg [31:0] buff_addr;
	reg [31:0] buff_size;

	always @ (posedge clk or posedge reset) begin
		if (reset) begin
			wch_reset <= 1;
			buff_addr <= 0;
			buff_size <= 0;
		end
		else begin
			if (as_read) begin
				case (as_address)
					2'd0: as_readdata <= {31'd0, wch_reset};
					2'd1: as_readdata <= buff_addr;
					2'd2: as_readdata <= buff_size;
					default: as_readdata <= 0;
				endcase
			end
			if (as_write) begin
				case (as_address)
					2'd0: wch_reset <= as_writedata[0];
					2'd1: buff_addr <= as_writedata;
					2'd2: buff_size <= as_writedata;
					default:;
				endcase
			end
		end
	end

	// control inputs and outputs
	reg prev_vsync;
	always @ (posedge clk) prev_vsync <= vsync;

	reg control_go;
	reg vsync_edge;
	always @ (posedge clk or posedge wch_reset) begin
		if (wch_reset) begin
			control_go <= 1'b0;
			vsync_edge <= 1'b0;
		end
		else if (!prev_vsync && vsync) begin
			control_go <= 1'b1;
			vsync_edge <= 1'b1;
		end
		else begin
			control_go <= 1'b0;
			vsync_edge <= vsync_edge;
		end
	end

	burst_write_master burst_write_master
	(
		 .clk(clk),
		 .reset (wch_reset),
		 .control_fixed_location(1'b0),
		 .control_write_base(buff_addr),
		 .control_write_length (buff_size),
		 .control_go(control_go),
		 .control_done(),
		 .user_write_clk(pclk),
		 .user_write_buffer(href&vsync_edge),
		 .user_buffer_data(raw),
		 .user_buffer_full(),
		 .master_address(am_address),
		 .master_write(am_write),
		 .master_byteenable(),
		 .master_writedata(am_writedata),
		 .master_burstcount(am_burstcount),
		 .master_waitrequest(am_waitrequest)
	);
	defparam burst_write_master.DATAWIDTH = AM_DATA_WIDTH;
	defparam burst_write_master.MAXBURSTCOUNT = AM_MAX_BURST_COUNT;
	defparam burst_write_master.BURSTCOUNTWIDTH = AM_BURST_COUNT_WIDTH;
	defparam burst_write_master.BYTEENABLEWIDTH = AM_DATA_WIDTH/8;
	defparam burst_write_master.ADDRESSWIDTH = AM_ADDRESS_WIDTH;
	defparam burst_write_master.FIFODEPTH = AM_FIFO_DEPTH;
	defparam burst_write_master.FIFODEPTH_LOG2 = AM_FIFO_DEPTH_LOG2;
	defparam burst_write_master.FIFOUSEMEMORY = AM_MEMORY_BASED_FIFO;
endmodule
