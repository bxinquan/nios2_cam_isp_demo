/*
  Legal Notice: (C)2007 Altera Corporation. All rights reserved.  Your
  use of Altera Corporation's design tools, logic functions and other
  software and tools, and its AMPP partner logic functions, and any
  output files any of the foregoing (including device programming or
  simulation files), and any associated documentation or information are
  expressly subject to the terms and conditions of the Altera Program
  License Subscription Agreement or other applicable license agreement,
  including, without limitation, that your use is for the sole purpose
  of programming logic devices manufactured by Altera and sold by Altera
  or its authorized distributors.  Please refer to the applicable
  agreement for further details.
*/

/*

	Author:  JCJB
	Date:  11/04/2007
	
	This simple write master is passed a word aligned address, length in bytes,
	and a 'go' bit.  The master will continue to post writes until the length register
	reaches zero.  When the length register reaches zero the 'done' bit is asserted. 

	To use this master you must simply drive the control signals into this block,
	and also write the data to the exposed write FIFO.  To read from the exposed FIFO
	use the 'user_write_buffer' signal to push data into the FIFO 'user_buffer_data'.
	The signal 'user_buffer_full' is asserted whenever the exposed buffer is full.
	You should not attempt to write data to the exposed FIFO if it is full.
	
*/


// altera message_off 10230

module write_master (
	clk,
	reset,
	
	// control inputs and outputs
	control_fixed_location,
	control_write_base,
	control_write_length,
	control_go,
	control_done,
	
	// user logic inputs and outputs
	user_write_clk,
	user_write_buffer,
	user_buffer_data,
	user_buffer_full,
	
	// master inputs and outputs
	master_address,
	master_write,
	master_byteenable,
	master_writedata,
	master_waitrequest
);


	parameter DATAWIDTH = 32;
	parameter BYTEENABLEWIDTH = 4;
	parameter ADDRESSWIDTH = 32;
	parameter FIFODEPTH = 32;
	parameter FIFODEPTH_LOG2 = 5;
	parameter FIFOUSEMEMORY = 1;  // set to 0 to use LEs instead
	
	
	
	input clk;
	input reset;
	
	// control inputs and outputs
	input control_fixed_location;  // this only makes sense to enable when MAXBURSTCOUNT = 1
	input [ADDRESSWIDTH-1:0] control_write_base;
	input [ADDRESSWIDTH-1:0] control_write_length;
	input control_go;
	output wire control_done;
	
	// user logic inputs and outputs
	input user_write_buffer;
	input user_write_clk;
	input [DATAWIDTH-1:0] user_buffer_data;
	output wire user_buffer_full;
	
	// master inputs and outputs
	input master_waitrequest;
	output wire [ADDRESSWIDTH-1:0] master_address;
	output wire master_write;
	output wire [BYTEENABLEWIDTH-1:0] master_byteenable;
	output wire [DATAWIDTH-1:0] master_writedata;

	
	// internal control signals
	reg control_fixed_location_d1;
	reg [ADDRESSWIDTH-1:0] address;  // this increments for each word
	reg [ADDRESSWIDTH-1:0] length;
	wire increment_address;  // this increments the 'address' register when write is asserted and waitrequest is de-asserted
	wire read_fifo;
    wire user_buffer_empty;



	// registering the control_fixed_location bit
	always @ (posedge clk or posedge reset)
	begin
		if (reset == 1)
		begin
			control_fixed_location_d1 <= 0;
		end
		else
		begin
			if (control_go == 1)
			begin
				control_fixed_location_d1 <= control_fixed_location;
			end
		end
	end



	// master word increment counter
	always @ (posedge clk or posedge reset)
	begin
		if (reset == 1)
		begin
			address <= 0;
		end
		else
		begin
			if (control_go == 1)
			begin
				address <= control_write_base;
			end
			else if ((increment_address == 1) & (control_fixed_location_d1 == 0))
			begin
				address <= address + BYTEENABLEWIDTH;  // always performing word size accesses
			end
		end
	end


	// master length logic
	always @ (posedge clk or posedge reset)
	begin
		if (reset == 1)
		begin
			length <= 0;
		end
		else
		begin
			if (control_go == 1)
			begin
				length <= control_write_length;
			end
			else if (increment_address == 1)
			begin
				length <= length - BYTEENABLEWIDTH;  // always performing word size accesses
			end
		end
	end

	// controlled signals going to the master/control ports
	assign master_address = address;
	assign master_byteenable = -1;  // all ones, always performing word size accesses
	assign control_done = (length == 0);
	assign master_write = (user_buffer_empty == 0) & (control_done == 0);

	assign increment_address = (user_buffer_empty == 0) & (master_waitrequest == 0) & (control_done == 0);
	assign read_fifo = increment_address;
	
	dcfifo the_user_to_master_fifo (
		.rdclk (clk),
		.wrclk (user_write_clk),
		.wrreq (user_write_buffer),
		.aclr (reset),
		.data (user_buffer_data),
		.rdreq (read_fifo),
		.q (master_writedata),
		.rdempty (user_buffer_empty),
		.wrusedw (),
		.rdfull (),
		.rdusedw (),
		.wrempty (),
		.wrfull (user_buffer_full)
	);

	defparam
		the_user_to_master_fifo.intended_device_family = "Cyclone IV E",
		the_user_to_master_fifo.lpm_numwords = FIFODEPTH,
		the_user_to_master_fifo.lpm_showahead = "ON",
		the_user_to_master_fifo.lpm_type = "dcfifo",
		the_user_to_master_fifo.lpm_width = DATAWIDTH,
		the_user_to_master_fifo.lpm_widthu = FIFODEPTH_LOG2,
		the_user_to_master_fifo.overflow_checking = "OFF",
		the_user_to_master_fifo.rdsync_delaypipe = 4,
		the_user_to_master_fifo.read_aclr_synch = "ON",
		the_user_to_master_fifo.underflow_checking = "OFF",
		the_user_to_master_fifo.use_eab = (FIFOUSEMEMORY == 1)? "ON" : "OFF",
		the_user_to_master_fifo.write_aclr_synch = "ON",
		the_user_to_master_fifo.wrsync_delaypipe = 4;
endmodule
