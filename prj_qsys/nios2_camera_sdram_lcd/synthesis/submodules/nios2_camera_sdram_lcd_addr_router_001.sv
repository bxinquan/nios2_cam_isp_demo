// (C) 2001-2012 Altera Corporation. All rights reserved.
// Your use of Altera Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Altera Program License Subscription 
// Agreement, Altera MegaCore Function License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Altera and sold by 
// Altera or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


// $Id: //acds/rel/12.1/ip/merlin/altera_merlin_router/altera_merlin_router.sv.terp#1 $
// $Revision: #1 $
// $Date: 2012/08/12 $
// $Author: swbranch $

// -------------------------------------------------------
// Merlin Router
//
// Asserts the appropriate one-hot encoded channel based on 
// either (a) the address or (b) the dest id. The DECODER_TYPE
// parameter controls this behaviour. 0 means address decoder,
// 1 means dest id decoder.
//
// In the case of (a), it also sets the destination id.
// -------------------------------------------------------

`timescale 1 ns / 1 ns

module nios2_camera_sdram_lcd_addr_router_001_default_decode
  #(
     parameter DEFAULT_CHANNEL = 1,
               DEFAULT_DESTID = 1 
   )
  (output [98 - 95 : 0] default_destination_id,
   output [11-1 : 0] default_src_channel
  );

  assign default_destination_id = 
    DEFAULT_DESTID[98 - 95 : 0];
  generate begin : default_decode
    if (DEFAULT_CHANNEL == -1)
      assign default_src_channel = '0;
    else
      assign default_src_channel = 11'b1 << DEFAULT_CHANNEL;
  end
  endgenerate

endmodule


module nios2_camera_sdram_lcd_addr_router_001
(
    // -------------------
    // Clock & Reset
    // -------------------
    input clk,
    input reset,

    // -------------------
    // Command Sink (Input)
    // -------------------
    input                       sink_valid,
    input  [109-1 : 0]    sink_data,
    input                       sink_startofpacket,
    input                       sink_endofpacket,
    output                      sink_ready,

    // -------------------
    // Command Source (Output)
    // -------------------
    output                          src_valid,
    output reg [109-1    : 0] src_data,
    output reg [11-1 : 0] src_channel,
    output                          src_startofpacket,
    output                          src_endofpacket,
    input                           src_ready
);

    // -------------------------------------------------------
    // Local parameters and variables
    // -------------------------------------------------------
    localparam PKT_ADDR_H = 67;
    localparam PKT_ADDR_L = 36;
    localparam PKT_DEST_ID_H = 98;
    localparam PKT_DEST_ID_L = 95;
    localparam ST_DATA_W = 109;
    localparam ST_CHANNEL_W = 11;
    localparam DECODER_TYPE = 0;

    localparam PKT_TRANS_WRITE = 70;
    localparam PKT_TRANS_READ  = 71;

    localparam PKT_ADDR_W = PKT_ADDR_H-PKT_ADDR_L + 1;
    localparam PKT_DEST_ID_W = PKT_DEST_ID_H-PKT_DEST_ID_L + 1;




    // -------------------------------------------------------
    // Figure out the number of bits to mask off for each slave span
    // during address decoding
    // -------------------------------------------------------
    localparam PAD0 = log2ceil(64'h2000000 - 64'h0);
    localparam PAD1 = log2ceil(64'h2004000 - 64'h2000000);
    localparam PAD2 = log2ceil(64'h2005000 - 64'h2004800);
    localparam PAD3 = log2ceil(64'h2005100 - 64'h2005000);
    localparam PAD4 = log2ceil(64'h2005200 - 64'h2005100);
    localparam PAD5 = log2ceil(64'h2005210 - 64'h2005200);
    localparam PAD6 = log2ceil(64'h2005220 - 64'h2005210);
    localparam PAD7 = log2ceil(64'h2005230 - 64'h2005220);
    localparam PAD8 = log2ceil(64'h2005240 - 64'h2005230);
    localparam PAD9 = log2ceil(64'h2005248 - 64'h2005240);
    localparam PAD10 = log2ceil(64'h2005250 - 64'h2005248);
    // -------------------------------------------------------
    // Work out which address bits are significant based on the
    // address range of the slaves. If the required width is too
    // large or too small, we use the address field width instead.
    // -------------------------------------------------------
    localparam ADDR_RANGE = 64'h2005250;
    localparam RANGE_ADDR_WIDTH = log2ceil(ADDR_RANGE);
    localparam OPTIMIZED_ADDR_H = (RANGE_ADDR_WIDTH > PKT_ADDR_W) ||
                                  (RANGE_ADDR_WIDTH == 0) ?
                                        PKT_ADDR_H :
                                        PKT_ADDR_L + RANGE_ADDR_WIDTH - 1;
    localparam RG = RANGE_ADDR_WIDTH-1;

      wire [PKT_ADDR_W-1 : 0] address = sink_data[OPTIMIZED_ADDR_H : PKT_ADDR_L];

    // -------------------------------------------------------
    // Pass almost everything through, untouched
    // -------------------------------------------------------
    assign sink_ready        = src_ready;
    assign src_valid         = sink_valid;
    assign src_startofpacket = sink_startofpacket;
    assign src_endofpacket   = sink_endofpacket;

    wire [PKT_DEST_ID_W-1:0] default_destid;
    wire [11-1 : 0] default_src_channel;




    nios2_camera_sdram_lcd_addr_router_001_default_decode the_default_decode(
      .default_destination_id (default_destid),
      .default_src_channel (default_src_channel)
    );

    always @* begin
        src_data    = sink_data;
        src_channel = default_src_channel;

        src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = default_destid;
        // --------------------------------------------------
        // Address Decoder
        // Sets the channel and destination ID based on the address
        // --------------------------------------------------

        // ( 0x0 .. 0x2000000 )
        if ( {address[RG:PAD0],{PAD0{1'b0}}} == 26'h0 ) begin
            src_channel = 11'b00000000010;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 1;
        end

        // ( 0x2000000 .. 0x2004000 )
        if ( {address[RG:PAD1],{PAD1{1'b0}}} == 26'h2000000 ) begin
            src_channel = 11'b00001000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 6;
        end

        // ( 0x2004800 .. 0x2005000 )
        if ( {address[RG:PAD2],{PAD2{1'b0}}} == 26'h2004800 ) begin
            src_channel = 11'b00000000001;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 0;
        end

        // ( 0x2005000 .. 0x2005100 )
        if ( {address[RG:PAD3],{PAD3{1'b0}}} == 26'h2005000 ) begin
            src_channel = 11'b10000000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 10;
        end

        // ( 0x2005100 .. 0x2005200 )
        if ( {address[RG:PAD4],{PAD4{1'b0}}} == 26'h2005100 ) begin
            src_channel = 11'b00010000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 7;
        end

        // ( 0x2005200 .. 0x2005210 )
        if ( {address[RG:PAD5],{PAD5{1'b0}}} == 26'h2005200 ) begin
            src_channel = 11'b01000000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 9;
        end

        // ( 0x2005210 .. 0x2005220 )
        if ( {address[RG:PAD6],{PAD6{1'b0}}} == 26'h2005210 ) begin
            src_channel = 11'b00100000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 8;
        end

        // ( 0x2005220 .. 0x2005230 )
        if ( {address[RG:PAD7],{PAD7{1'b0}}} == 26'h2005220 ) begin
            src_channel = 11'b00000100000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 5;
        end

        // ( 0x2005230 .. 0x2005240 )
        if ( {address[RG:PAD8],{PAD8{1'b0}}} == 26'h2005230 ) begin
            src_channel = 11'b00000010000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 4;
        end

        // ( 0x2005240 .. 0x2005248 )
        if ( {address[RG:PAD9],{PAD9{1'b0}}} == 26'h2005240 ) begin
            src_channel = 11'b00000001000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 3;
        end

        // ( 0x2005248 .. 0x2005250 )
        if ( {address[RG:PAD10],{PAD10{1'b0}}} == 26'h2005248 ) begin
            src_channel = 11'b00000000100;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 2;
        end

end


    // --------------------------------------------------
    // Ceil(log2()) function
    // --------------------------------------------------
    function integer log2ceil;
        input reg[65:0] val;
        reg [65:0] i;

        begin
            i = 1;
            log2ceil = 0;

            while (i < val) begin
                log2ceil = log2ceil + 1;
                i = i << 1;
            end
        end
    endfunction

endmodule


