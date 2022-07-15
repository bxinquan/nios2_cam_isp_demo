//Legal Notice: (C)2021 Altera Corporation. All rights reserved.  Your
//use of Altera Corporation's design tools, logic functions and other
//software and tools, and its AMPP partner logic functions, and any
//output files any of the foregoing (including device programming or
//simulation files), and any associated documentation or information are
//expressly subject to the terms and conditions of the Altera Program
//License Subscription Agreement or other applicable license agreement,
//including, without limitation, that your use is for the sole purpose
//of programming logic devices manufactured by Altera and sold by Altera
//or its authorized distributors.  Please refer to the applicable
//agreement for further details.

// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

// turn off superfluous verilog processor warnings 
// altera message_level Level1 
// altera message_off 10034 10035 10036 10037 10230 10240 10030 

module nios2_camera_sdram_lcd_jtag_uart_log_module (
                                                     // inputs:
                                                      clk,
                                                      data,
                                                      strobe,
                                                      valid
                                                   )
;

  input            clk;
  input   [  7: 0] data;
  input            strobe;
  input            valid;


//synthesis translate_off
//////////////// SIMULATION-ONLY CONTENTS
   reg [31:0] text_handle; // for $fopen
   initial text_handle = $fopen ("nios2_camera_sdram_lcd_jtag_uart_output_stream.dat");

   always @(posedge clk) begin
      if (valid && strobe) begin
	 $fwrite (text_handle, "%b\n", data);
          // echo raw binary strings to file as ascii to screen
         $write("%s", ((data == 8'hd) ? 8'ha : data));
                     
	 // non-standard; poorly documented; required to get real data stream.
	 $fflush (text_handle);
      end
   end // clk


//////////////// END SIMULATION-ONLY CONTENTS

//synthesis translate_on

endmodule


// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

// turn off superfluous verilog processor warnings 
// altera message_level Level1 
// altera message_off 10034 10035 10036 10037 10230 10240 10030 

module nios2_camera_sdram_lcd_jtag_uart_sim_scfifo_w (
                                                       // inputs:
                                                        clk,
                                                        fifo_wdata,
                                                        fifo_wr,

                                                       // outputs:
                                                        fifo_FF,
                                                        r_dat,
                                                        wfifo_empty,
                                                        wfifo_used
                                                     )
;

  output           fifo_FF;
  output  [  7: 0] r_dat;
  output           wfifo_empty;
  output  [  5: 0] wfifo_used;
  input            clk;
  input   [  7: 0] fifo_wdata;
  input            fifo_wr;

  wire             fifo_FF;
  wire    [  7: 0] r_dat;
  wire             wfifo_empty;
  wire    [  5: 0] wfifo_used;

//synthesis translate_off
//////////////// SIMULATION-ONLY CONTENTS
  //nios2_camera_sdram_lcd_jtag_uart_log, which is an e_log
  nios2_camera_sdram_lcd_jtag_uart_log_module nios2_camera_sdram_lcd_jtag_uart_log
    (
      .clk    (clk),
      .data   (fifo_wdata),
      .strobe (fifo_wr),
      .valid  (fifo_wr)
    );

  assign wfifo_used = {6{1'b0}};
  assign r_dat = {8{1'b0}};
  assign fifo_FF = 1'b0;
  assign wfifo_empty = 1'b1;

//////////////// END SIMULATION-ONLY CONTENTS

//synthesis translate_on

endmodule


// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

// turn off superfluous verilog processor warnings 
// altera message_level Level1 
// altera message_off 10034 10035 10036 10037 10230 10240 10030 

module nios2_camera_sdram_lcd_jtag_uart_scfifo_w (
                                                   // inputs:
                                                    clk,
                                                    fifo_clear,
                                                    fifo_wdata,
                                                    fifo_wr,
                                                    rd_wfifo,

                                                   // outputs:
                                                    fifo_FF,
                                                    r_dat,
                                                    wfifo_empty,
                                                    wfifo_used
                                                 )
;

  output           fifo_FF;
  output  [  7: 0] r_dat;
  output           wfifo_empty;
  output  [  5: 0] wfifo_used;
  input            clk;
  input            fifo_clear;
  input   [  7: 0] fifo_wdata;
  input            fifo_wr;
  input            rd_wfifo;

  wire             fifo_FF;
  wire    [  7: 0] r_dat;
  wire             wfifo_empty;
  wire    [  5: 0] wfifo_used;

//synthesis translate_off
//////////////// SIMULATION-ONLY CONTENTS
  nios2_camera_sdram_lcd_jtag_uart_sim_scfifo_w the_nios2_camera_sdram_lcd_jtag_uart_sim_scfifo_w
    (
      .clk         (clk),
      .fifo_FF     (fifo_FF),
      .fifo_wdata  (fifo_wdata),
      .fifo_wr     (fifo_wr),
      .r_dat       (r_dat),
      .wfifo_empty (wfifo_empty),
      .wfifo_used  (wfifo_used)
    );


//////////////// END SIMULATION-ONLY CONTENTS

//synthesis translate_on
//synthesis read_comments_as_HDL on
//  scfifo wfifo
//    (
//      .aclr (fifo_clear),
//      .clock (clk),
//      .data (fifo_wdata),
//      .empty (wfifo_empty),
//      .full (fifo_FF),
//      .q (r_dat),
//      .rdreq (rd_wfifo),
//      .usedw (wfifo_used),
//      .wrreq (fifo_wr)
//    );
//
//  defparam wfifo.lpm_hint = "RAM_BLOCK_TYPE=AUTO",
//           wfifo.lpm_numwords = 64,
//           wfifo.lpm_showahead = "OFF",
//           wfifo.lpm_type = "scfifo",
//           wfifo.lpm_width = 8,
//           wfifo.lpm_widthu = 6,
//           wfifo.overflow_checking = "OFF",
//           wfifo.underflow_checking = "OFF",
//           wfifo.use_eab = "ON";
//
//synthesis read_comments_as_HDL off

endmodule


// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

// turn off superfluous verilog processor warnings 
// altera message_level Level1 
// altera message_off 10034 10035 10036 10037 10230 10240 10030 

module nios2_camera_sdram_lcd_jtag_uart_drom_module (
                                                      // inputs:
                                                       clk,
                                                       incr_addr,
                                                       reset_n,

                                                      // outputs:
                                                       new_rom,
                                                       num_bytes,
                                                       q,
                                                       safe
                                                    )
;

  parameter POLL_RATE = 100;


  output           new_rom;
  output  [ 31: 0] num_bytes;
  output  [  7: 0] q;
  output           safe;
  input            clk;
  input            incr_addr;
  input            reset_n;

  reg     [ 11: 0] address;
  reg              d1_pre;
  reg              d2_pre;
  reg              d3_pre;
  reg              d4_pre;
  reg              d5_pre;
  reg              d6_pre;
  reg              d7_pre;
  reg              d8_pre;
  reg              d9_pre;
  reg     [  7: 0] mem_array [2047: 0];
  reg     [ 31: 0] mutex [  1: 0];
  reg              new_rom;
  wire    [ 31: 0] num_bytes;
  reg              pre;
  wire    [  7: 0] q;
  wire             safe;

//synthesis translate_off
//////////////// SIMULATION-ONLY CONTENTS
  assign q = mem_array[address];
  always @(posedge clk or negedge reset_n)
    begin
      if (reset_n == 0)
        begin
          d1_pre <= 0;
          d2_pre <= 0;
          d3_pre <= 0;
          d4_pre <= 0;
          d5_pre <= 0;
          d6_pre <= 0;
          d7_pre <= 0;
          d8_pre <= 0;
          d9_pre <= 0;
          new_rom <= 0;
        end
      else 
        begin
          d1_pre <= pre;
          d2_pre <= d1_pre;
          d3_pre <= d2_pre;
          d4_pre <= d3_pre;
          d5_pre <= d4_pre;
          d6_pre <= d5_pre;
          d7_pre <= d6_pre;
          d8_pre <= d7_pre;
          d9_pre <= d8_pre;
          new_rom <= d9_pre;
        end
    end



   assign     num_bytes = mutex[1];
                   reg        safe_delay;
   reg [31:0] poll_count;
   reg [31:0] mutex_handle;
   wire       interactive = 1'b0 ; // '
   assign     safe = (address < mutex[1]);

   initial poll_count = POLL_RATE;

   always @(posedge clk or negedge reset_n) begin
      if (reset_n !== 1) begin
         safe_delay <= 0;
      end else begin
         safe_delay <= safe;
      end
   end // safe_delay

   always @(posedge clk or negedge reset_n) begin
      if (reset_n !== 1) begin  // dont worry about null _stream.dat file
         address <= 0;
         mem_array[0] <= 0;
         mutex[0] <= 0;
         mutex[1] <= 0;
         pre <= 0;
      end else begin            // deal with the non-reset case
         pre <= 0;
         if (incr_addr && safe) address <= address + 1;
         if (mutex[0] && !safe && safe_delay) begin
            // and blast the mutex after falling edge of safe if interactive
            if (interactive) begin
               mutex_handle = $fopen ("nios2_camera_sdram_lcd_jtag_uart_input_mutex.dat");
               $fdisplay (mutex_handle, "0");
               $fclose (mutex_handle);
               // $display ($stime, "\t%m:\n\t\tMutex cleared!");
            end else begin
               // sleep until next reset, do not bash mutex.
               wait (!reset_n);
            end
         end // OK to bash mutex.
         if (poll_count < POLL_RATE) begin // wait
            poll_count = poll_count + 1;
         end else begin         // do the interesting stuff.
            poll_count = 0;
            if (mutex_handle) begin
            $readmemh ("nios2_camera_sdram_lcd_jtag_uart_input_mutex.dat", mutex);
            end
            if (mutex[0] && !safe) begin
            // read stream into mem_array after current characters are gone!
               // save mutex[0] value to compare to address (generates 'safe')
               mutex[1] <= mutex[0];
               // $display ($stime, "\t%m:\n\t\tMutex hit: Trying to read %d bytes...", mutex[0]);
               $readmemb("nios2_camera_sdram_lcd_jtag_uart_input_stream.dat", mem_array);
               // bash address and send pulse outside to send the char:
               address <= 0;
               pre <= -1;
            end // else mutex miss...
         end // poll_count
      end // reset
   end // posedge clk


//////////////// END SIMULATION-ONLY CONTENTS

//synthesis translate_on

endmodule


// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

// turn off superfluous verilog processor warnings 
// altera message_level Level1 
// altera message_off 10034 10035 10036 10037 10230 10240 10030 

module nios2_camera_sdram_lcd_jtag_uart_sim_scfifo_r (
                                                       // inputs:
                                                        clk,
                                                        fifo_rd,
                                                        rst_n,

                                                       // outputs:
                                                        fifo_EF,
                                                        fifo_rdata,
                                                        rfifo_full,
                                                        rfifo_used
                                                     )
;

  output           fifo_EF;
  output  [  7: 0] fifo_rdata;
  output           rfifo_full;
  output  [  5: 0] rfifo_used;
  input            clk;
  input            fifo_rd;
  input            rst_n;

  reg     [ 31: 0] bytes_left;
  wire             fifo_EF;
  reg              fifo_rd_d;
  wire    [  7: 0] fifo_rdata;
  wire             new_rom;
  wire    [ 31: 0] num_bytes;
  wire    [  6: 0] rfifo_entries;
  wire             rfifo_full;
  wire    [  5: 0] rfifo_used;
  wire             safe;

//synthesis translate_off
//////////////// SIMULATION-ONLY CONTENTS
  //nios2_camera_sdram_lcd_jtag_uart_drom, which is an e_drom
  nios2_camera_sdram_lcd_jtag_uart_drom_module nios2_camera_sdram_lcd_jtag_uart_drom
    (
      .clk       (clk),
      .incr_addr (fifo_rd_d),
      .new_rom   (new_rom),
      .num_bytes (num_bytes),
      .q         (fifo_rdata),
      .reset_n   (rst_n),
      .safe      (safe)
    );

  // Generate rfifo_entries for simulation
  always @(posedge clk or negedge rst_n)
    begin
      if (rst_n == 0)
        begin
          bytes_left <= 32'h0;
          fifo_rd_d <= 1'b0;
        end
      else 
        begin
          fifo_rd_d <= fifo_rd;
          // decrement on read
          if (fifo_rd_d)
              bytes_left <= bytes_left - 1'b1;
          // catch new contents
          if (new_rom)
              bytes_left <= num_bytes;
        end
    end


  assign fifo_EF = bytes_left == 32'b0;
  assign rfifo_full = bytes_left > 7'h40;
  assign rfifo_entries = (rfifo_full) ? 7'h40 : bytes_left;
  assign rfifo_used = rfifo_entries[5 : 0];

//////////////// END SIMULATION-ONLY CONTENTS

//synthesis translate_on

endmodule


// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

// turn off superfluous verilog processor warnings 
// altera message_level Level1 
// altera message_off 10034 10035 10036 10037 10230 10240 10030 

module nios2_camera_sdram_lcd_jtag_uart_scfifo_r (
                                                   // inputs:
                                                    clk,
                                                    fifo_clear,
                                                    fifo_rd,
                                                    rst_n,
                                                    t_dat,
                                                    wr_rfifo,

                                                   // outputs:
                                                    fifo_EF,
                                                    fifo_rdata,
                                                    rfifo_full,
                                                    rfifo_used
                                                 )
;

  output           fifo_EF;
  output  [  7: 0] fifo_rdata;
  output           rfifo_full;
  output  [  5: 0] rfifo_used;
  input            clk;
  input            fifo_clear;
  input            fifo_rd;
  input            rst_n;
  input   [  7: 0] t_dat;
  input            wr_rfifo;

  wire             fifo_EF;
  wire    [  7: 0] fifo_rdata;
  wire             rfifo_full;
  wire    [  5: 0] rfifo_used;

//synthesis translate_off
//////////////// SIMULATION-ONLY CONTENTS
  nios2_camera_sdram_lcd_jtag_uart_sim_scfifo_r the_nios2_camera_sdram_lcd_jtag_uart_sim_scfifo_r
    (
      .clk        (clk),
      .fifo_EF    (fifo_EF),
      .fifo_rd    (fifo_rd),
      .fifo_rdata (fifo_rdata),
      .rfifo_full (rfifo_full),
      .rfifo_used (rfifo_used),
      .rst_n      (rst_n)
    );


//////////////// END SIMULATION-ONLY CONTENTS

//synthesis translate_on
//synthesis read_comments_as_HDL on
//  scfifo rfifo
//    (
//      .aclr (fifo_clear),
//      .clock (clk),
//      .data (t_dat),
//      .empty (fifo_EF),
//      .full (rfifo_full),
//      .q (fifo_rdata),
//      .rdreq (fifo_rd),
//      .usedw (rfifo_used),
//      .wrreq (wr_rfifo)
//    );
//
//  defparam rfifo.lpm_hint = "RAM_BLOCK_TYPE=AUTO",
//           rfifo.lpm_numwords = 64,
//           rfifo.lpm_showahead = "OFF",
//           rfifo.lpm_type = "scfifo",
//           rfifo.lpm_width = 8,
//           rfifo.lpm_widthu = 6,
//           rfifo.overflow_checking = "OFF",
//           rfifo.underflow_checking = "OFF",
//           rfifo.use_eab = "ON";
//
//synthesis read_comments_as_HDL off

endmodule


// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

// turn off superfluous verilog processor warnings 
// altera message_level Level1 
// altera message_off 10034 10035 10036 10037 10230 10240 10030 

module nios2_camera_sdram_lcd_jtag_uart (
                                          // inputs:
                                           av_address,
                                           av_chipselect,
                                           av_read_n,
                                           av_write_n,
                                           av_writedata,
                                           clk,
                                           rst_n,

                                          // outputs:
                                           av_irq,
                                           av_readdata,
                                           av_waitrequest,
                                           dataavailable,
                                           readyfordata
                                        )
  /* synthesis ALTERA_ATTRIBUTE = "SUPPRESS_DA_RULE_INTERNAL=\"R101,C106,D101,D103\"" */ ;

  output           av_irq;
  output  [ 31: 0] av_readdata;
  output           av_waitrequest;
  output           dataavailable;
  output           readyfordata;
  input            av_address;
  input            av_chipselect;
  input            av_read_n;
  input            av_write_n;
  input   [ 31: 0] av_writedata;
  input            clk;
  input            rst_n;

  reg              ac;
  wire             activity;
  wire             av_irq;
  wire    [ 31: 0] av_readdata;
  reg              av_waitrequest;
  reg              dataavailable;
  reg              fifo_AE;
  reg              fifo_AF;
  wire             fifo_EF;
  wire             fifo_FF;
  wire             fifo_clear;
  wire             fifo_rd;
  wire    [  7: 0] fifo_rdata;
  wire    [  7: 0] fifo_wdata;
  reg              fifo_wr;
  reg              ien_AE;
  reg              ien_AF;
  wire             ipen_AE;
  wire             ipen_AF;
  reg              pause_irq;
  wire    [  7: 0] r_dat;
  wire             r_ena;
  reg              r_val;
  wire             rd_wfifo;
  reg              read_0;
  reg              readyfordata;
  wire             rfifo_full;
  wire    [  5: 0] rfifo_used;
  reg              rvalid;
  reg              sim_r_ena;
  reg              sim_t_dat;
  reg              sim_t_ena;
  reg              sim_t_pause;
  wire    [  7: 0] t_dat;
  reg              t_dav;
  wire             t_ena;
  wire             t_pause;
  wire             wfifo_empty;
  wire    [  5: 0] wfifo_used;
  reg              woverflow;
  wire             wr_rfifo;
  //avalon_jtag_slave, which is an e_avalon_slave
  assign rd_wfifo = r_ena & ~wfifo_empty;
  assign wr_rfifo = t_ena & ~rfifo_full;
  assign fifo_clear = ~rst_n;
  nios2_camera_sdram_lcd_jtag_uart_scfifo_w the_nios2_camera_sdram_lcd_jtag_uart_scfifo_w
    (
      .clk         (clk),
      .fifo_FF     (fifo_FF),
      .fifo_clear  (fifo_clear),
      .fifo_wdata  (fifo_wdata),
      .fifo_wr     (fifo_wr),
      .r_dat       (r_dat),
      .rd_wfifo    (rd_wfifo),
      .wfifo_empty (wfifo_empty),
      .wfifo_used  (wfifo_used)
    );

  nios2_camera_sdram_lcd_jtag_uart_scfifo_r the_nios2_camera_sdram_lcd_jtag_uart_scfifo_r
    (
      .clk        (clk),
      .fifo_EF    (fifo_EF),
      .fifo_clear (fifo_clear),
      .fifo_rd    (fifo_rd),
      .fifo_rdata (fifo_rdata),
      .rfifo_full (rfifo_full),
      .rfifo_used (rfifo_used),
      .rst_n      (rst_n),
      .t_dat      (t_dat),
      .wr_rfifo   (wr_rfifo)
    );

  assign ipen_AE = ien_AE & fifo_AE;
  assign ipen_AF = ien_AF & (pause_irq | fifo_AF);
  assign av_irq = ipen_AE | ipen_AF;
  assign activity = t_pause | t_ena;
  always @(posedge clk or negedge rst_n)
    begin
      if (rst_n == 0)
          pause_irq <= 1'b0;
      else // only if fifo is not empty...
      if (t_pause & ~fifo_EF)
          pause_irq <= 1'b1;
      else if (read_0)
          pause_irq <= 1'b0;
    end


  always @(posedge clk or negedge rst_n)
    begin
      if (rst_n == 0)
        begin
          r_val <= 1'b0;
          t_dav <= 1'b1;
        end
      else 
        begin
          r_val <= r_ena & ~wfifo_empty;
          t_dav <= ~rfifo_full;
        end
    end


  always @(posedge clk or negedge rst_n)
    begin
      if (rst_n == 0)
        begin
          fifo_AE <= 1'b0;
          fifo_AF <= 1'b0;
          fifo_wr <= 1'b0;
          rvalid <= 1'b0;
          read_0 <= 1'b0;
          ien_AE <= 1'b0;
          ien_AF <= 1'b0;
          ac <= 1'b0;
          woverflow <= 1'b0;
          av_waitrequest <= 1'b1;
        end
      else 
        begin
          fifo_AE <= {fifo_FF,wfifo_used} <= 8;
          fifo_AF <= (7'h40 - {rfifo_full,rfifo_used}) <= 8;
          fifo_wr <= 1'b0;
          read_0 <= 1'b0;
          av_waitrequest <= ~(av_chipselect & (~av_write_n | ~av_read_n) & av_waitrequest);
          if (activity)
              ac <= 1'b1;
          // write
          if (av_chipselect & ~av_write_n & av_waitrequest)
              // addr 1 is control; addr 0 is data
              if (av_address)
                begin
                  ien_AF <= av_writedata[0];
                  ien_AE <= av_writedata[1];
                  if (av_writedata[10] & ~activity)
                      ac <= 1'b0;
                end
              else 
                begin
                  fifo_wr <= ~fifo_FF;
                  woverflow <= fifo_FF;
                end
          // read
          if (av_chipselect & ~av_read_n & av_waitrequest)
            begin
              // addr 1 is interrupt; addr 0 is data
              if (~av_address)
                  rvalid <= ~fifo_EF;
              read_0 <= ~av_address;
            end
        end
    end


  assign fifo_wdata = av_writedata[7 : 0];
  assign fifo_rd = (av_chipselect & ~av_read_n & av_waitrequest & ~av_address) ? ~fifo_EF : 1'b0;
  assign av_readdata = read_0 ? { {9{1'b0}},rfifo_full,rfifo_used,rvalid,woverflow,~fifo_FF,~fifo_EF,1'b0,ac,ipen_AE,ipen_AF,fifo_rdata } : { {9{1'b0}},(7'h40 - {fifo_FF,wfifo_used}),rvalid,woverflow,~fifo_FF,~fifo_EF,1'b0,ac,ipen_AE,ipen_AF,{6{1'b0}},ien_AE,ien_AF };
  always @(posedge clk or negedge rst_n)
    begin
      if (rst_n == 0)
          readyfordata <= 0;
      else 
        readyfordata <= ~fifo_FF;
    end



//synthesis translate_off
//////////////// SIMULATION-ONLY CONTENTS
  // Tie off Atlantic Interface signals not used for simulation
  always @(posedge clk)
    begin
      sim_t_pause <= 1'b0;
      sim_t_ena <= 1'b0;
      sim_t_dat <= t_dav ? r_dat : {8{r_val}};
      sim_r_ena <= 1'b0;
    end


  assign r_ena = sim_r_ena;
  assign t_ena = sim_t_ena;
  assign t_dat = sim_t_dat;
  assign t_pause = sim_t_pause;
  always @(fifo_EF)
    begin
      dataavailable = ~fifo_EF;
    end



//////////////// END SIMULATION-ONLY CONTENTS

//synthesis translate_on
//synthesis read_comments_as_HDL on
//  alt_jtag_atlantic nios2_camera_sdram_lcd_jtag_uart_alt_jtag_atlantic
//    (
//      .clk (clk),
//      .r_dat (r_dat),
//      .r_ena (r_ena),
//      .r_val (r_val),
//      .rst_n (rst_n),
//      .t_dat (t_dat),
//      .t_dav (t_dav),
//      .t_ena (t_ena),
//      .t_pause (t_pause)
//    );
//
//  defparam nios2_camera_sdram_lcd_jtag_uart_alt_jtag_atlantic.INSTANCE_ID = 0,
//           nios2_camera_sdram_lcd_jtag_uart_alt_jtag_atlantic.LOG2_RXFIFO_DEPTH = 6,
//           nios2_camera_sdram_lcd_jtag_uart_alt_jtag_atlantic.LOG2_TXFIFO_DEPTH = 6,
//           nios2_camera_sdram_lcd_jtag_uart_alt_jtag_atlantic.SLD_AUTO_INSTANCE_INDEX = "YES";
//
//  always @(posedge clk or negedge rst_n)
//    begin
//      if (rst_n == 0)
//          dataavailable <= 0;
//      else 
//        dataavailable <= ~fifo_EF;
//    end
//
//
//synthesis read_comments_as_HDL off

endmodule

