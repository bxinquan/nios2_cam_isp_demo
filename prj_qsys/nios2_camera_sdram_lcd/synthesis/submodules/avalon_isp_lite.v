
module avalon_isp_lite
#(
	parameter BITS = 8,
	parameter WIDTH = 1280,
	parameter HEIGHT = 960,
	parameter BAYER = 0, //0:BGGR 1:GBRG 2:GRBG 3:RGGB
	parameter STAT_BITS = 28
)
(
	input clk,
	input reset,
	
	// slave control register
	input [BITS+3:0]  as_address,
	input             as_read,
	output reg [31:0] as_readdata,
	input             as_write,
	input [31:0]      as_writedata,
	
	output irq,

	input pclk,
	input rst_n,

	input in_href,
	input in_vsync,
	input [BITS-1:0] in_raw,
	
	output out_href,
	output out_vsync,
	output [BITS-1:0] out_y,
	output [BITS-1:0] out_u,
	output [BITS-1:0] out_v
);

	localparam REG_RESET = 0;
	localparam REG_TOP_EN = 1;
	localparam REG_BLC_B = 2;
	localparam REG_BLC_GB = 3;
	localparam REG_BLC_GR = 4;
	localparam REG_BLC_R = 5;
	localparam REG_DGAIN = 6;
	localparam REG_WB_RGAIN = 7;
	localparam REG_WB_GGAIN = 8;
	localparam REG_WB_BGAIN = 9;
	localparam REG_CCM_RR = 10;
	localparam REG_CCM_RG = 11;
	localparam REG_CCM_RB = 12;
	localparam REG_CCM_GR = 13;
	localparam REG_CCM_GG = 14;
	localparam REG_CCM_GB = 15;
	localparam REG_CCM_BR = 16;
	localparam REG_CCM_BG = 17;
	localparam REG_CCM_BB = 18;
	localparam REG_STAT_AWB_MIN = 19;
	localparam REG_STAT_AWB_MAX = 20;
	localparam REG_STAT_AE_PIX_CNT = 21;
	localparam REG_STAT_AE_SUM = 22;
	localparam REG_STAT_AWB_PIX_CNT = 23;
	localparam REG_STAT_AWB_SUM_R = 24;
	localparam REG_STAT_AWB_SUM_G = 25;
	localparam REG_STAT_AWB_SUM_B = 26;
	localparam REG_INT_STATUS = 27;
	localparam REG_INT_MASK = 28;
	
	reg module_reset;
	reg blc_en, bnr_en, dgain_en, demosic_en, wb_en, ccm_en, csc_en, gamma_en, ee_en, stat_ae_en, stat_awb_en;

	reg [7:0] blc_b, blc_gb, blc_gr, blc_r;
	reg [7:0] dgain;
	reg [7:0] wb_rgain, wb_ggain, wb_bgain;
	reg [7:0] ccm_rr, ccm_rg, ccm_rb;
	reg [7:0] ccm_gr, ccm_gg, ccm_gb;
	reg [7:0] ccm_br, ccm_bg, ccm_bb;
	reg [7:0] stat_awb_min, stat_awb_max;
	
	wire stat_ae_done;
	wire [STAT_BITS-1:0] stat_ae_pix_cnt, stat_ae_sum;

	wire stat_awb_done;
	wire [STAT_BITS-1:0] stat_awb_pix_cnt, stat_awb_sum_r, stat_awb_sum_g, stat_awb_sum_b;
	
	reg int_frame_done, int_ae_done, int_awb_done;
	reg int_mask_frame_done, int_mask_ae_done, int_mask_awb_done;
	
	assign irq = int_frame_done&(~int_mask_frame_done) | int_ae_done&(~int_mask_ae_done) | int_awb_done&(~int_mask_awb_done);

	reg prev_vsync;
	always @ (posedge clk) prev_vsync <= out_vsync;

	reg reg_addr_range, stat_ae_hist_out, stat_awb_hist_out;
	reg [31:0] as_readdata_r;
	wire [STAT_BITS-1:0] stat_ae_hist_data, stat_awb_hist_data;
	always @ (*) begin
		case (as_address[BITS+3:BITS+2])
			2'b00: {reg_addr_range, stat_ae_hist_out, stat_awb_hist_out, as_readdata} = {3'b100, as_readdata_r}; 
			2'b01: {reg_addr_range, stat_ae_hist_out, stat_awb_hist_out, as_readdata} = {3'b010, {32-STAT_BITS{1'b0}}, stat_ae_hist_data}; 
			2'b10: {reg_addr_range, stat_ae_hist_out, stat_awb_hist_out, as_readdata} = {3'b001, {32-STAT_BITS{1'b0}}, stat_awb_hist_data}; 
			default: {reg_addr_range, stat_ae_hist_out, stat_awb_hist_out, as_readdata} = {3'b000, {32{1'b0}}}; 
		endcase
	end

	always @ (posedge clk or posedge reset) begin
		if (reset) begin
			module_reset <= 1;
			blc_en <= 1;
			bnr_en <= 1;
			dgain_en <= 0;
			demosic_en <= 1;
			wb_en <= 1;
			ccm_en <= 1;
			csc_en <= 1;
			gamma_en <= 1;
			ee_en <= 1;
			stat_ae_en <= 1;
			stat_awb_en <= 1;
			blc_b <= 8'd40;
			blc_gb <= 8'd40;
			blc_gr <= 8'd40;
			blc_r <= 8'd40;
			dgain <= 8'h10;
			wb_rgain <= 8'h10;
			wb_ggain <= 8'h10;
			wb_bgain <= 8'h10;
			ccm_rr <=  8'sh1a;
			ccm_rg <= -8'sh05;
			ccm_rb <= -8'sh05;
			ccm_gr <= -8'sh05;
			ccm_gg <=  8'sh1a;
			ccm_gb <= -8'sh05;
			ccm_br <= -8'sh05;
			ccm_bg <= -8'sh05;
			ccm_bb <=  8'sh1a;
			stat_awb_min <=  8'd10;
			stat_awb_max <=  8'd220;
			int_frame_done <= 0;
			int_ae_done <= 0;
			int_awb_done <= 0;
			int_mask_frame_done <= 1;
			int_mask_ae_done <= 1;
			int_mask_awb_done <= 1;
		end
		else begin
			if (reg_addr_range & as_read) begin
				case (as_address)
					REG_RESET: as_readdata_r <= {31'd0, module_reset};
					REG_TOP_EN: as_readdata_r <= {21'd0, stat_awb_en, stat_ae_en, ee_en, gamma_en, csc_en, ccm_en, wb_en, demosic_en, dgain_en, bnr_en, blc_en};
					REG_BLC_B: as_readdata_r <= {24'd0, blc_b};
					REG_BLC_GB: as_readdata_r <= {24'd0, blc_gb};
					REG_BLC_GR: as_readdata_r <= {24'd0, blc_gr};
					REG_BLC_R: as_readdata_r <= {24'd0, blc_r};
					REG_DGAIN: as_readdata_r <= {24'd0, dgain};
					REG_WB_RGAIN: as_readdata_r <= {24'd0, wb_rgain};
					REG_WB_GGAIN: as_readdata_r <= {24'd0, wb_ggain};
					REG_WB_BGAIN: as_readdata_r <= {24'd0, wb_bgain};
					REG_CCM_RR: as_readdata_r <= {24'd0, ccm_rr};
					REG_CCM_RG: as_readdata_r <= {24'd0, ccm_rg};
					REG_CCM_RB: as_readdata_r <= {24'd0, ccm_rb};
					REG_CCM_GR: as_readdata_r <= {24'd0, ccm_gr};
					REG_CCM_GG: as_readdata_r <= {24'd0, ccm_gg};
					REG_CCM_GB: as_readdata_r <= {24'd0, ccm_gb};
					REG_CCM_BR: as_readdata_r <= {24'd0, ccm_br};
					REG_CCM_BG: as_readdata_r <= {24'd0, ccm_bg};
					REG_CCM_BB: as_readdata_r <= {24'd0, ccm_bb};
					REG_STAT_AWB_MIN: as_readdata_r <= {24'd0, stat_awb_min};
					REG_STAT_AWB_MAX: as_readdata_r <= {24'd0, stat_awb_max};
					REG_STAT_AE_PIX_CNT: as_readdata_r <= stat_ae_pix_cnt;
					REG_STAT_AE_SUM: as_readdata_r <= stat_ae_sum;
					REG_STAT_AWB_PIX_CNT: as_readdata_r <= stat_awb_pix_cnt;
					REG_STAT_AWB_SUM_R: as_readdata_r <= stat_awb_sum_r;
					REG_STAT_AWB_SUM_G: as_readdata_r <= stat_awb_sum_g;
					REG_STAT_AWB_SUM_B: as_readdata_r <= stat_awb_sum_b;
					REG_INT_STATUS: as_readdata_r <= {29'd0, int_awb_done, int_ae_done, int_frame_done};
					REG_INT_MASK: as_readdata_r <= {29'd0, int_mask_awb_done, int_mask_ae_done, int_mask_frame_done};
					default: as_readdata_r <= 0;
				endcase
			end
			else if (reg_addr_range & as_write) begin
				case (as_address)
					REG_RESET: module_reset <= as_writedata[0];
					REG_TOP_EN: {stat_awb_en, stat_ae_en, ee_en, gamma_en, csc_en, ccm_en, wb_en, demosic_en, dgain_en, bnr_en, blc_en} <= as_writedata[10:0];
					REG_BLC_B: blc_b <= as_writedata[7:0];
					REG_BLC_GB: blc_gb <= as_writedata[7:0];
					REG_BLC_GR: blc_gr <= as_writedata[7:0];
					REG_BLC_R: blc_r <= as_writedata[7:0];
					REG_DGAIN: dgain <= as_writedata[7:0];
					REG_WB_RGAIN: wb_rgain <= as_writedata[7:0];
					REG_WB_GGAIN: wb_ggain <= as_writedata[7:0];
					REG_WB_BGAIN: wb_bgain <= as_writedata[7:0];
					REG_CCM_RR: ccm_rr <= as_writedata[7:0];
					REG_CCM_RG: ccm_rg <= as_writedata[7:0];
					REG_CCM_RB: ccm_rb <= as_writedata[7:0];
					REG_CCM_GR: ccm_gr <= as_writedata[7:0];
					REG_CCM_GG: ccm_gg <= as_writedata[7:0];
					REG_CCM_GB: ccm_gb <= as_writedata[7:0];
					REG_CCM_BR: ccm_br <= as_writedata[7:0];
					REG_CCM_BG: ccm_bg <= as_writedata[7:0];
					REG_CCM_BB: ccm_bb <= as_writedata[7:0];
					REG_STAT_AWB_MIN: stat_awb_min <= as_writedata[7:0];
					REG_STAT_AWB_MAX: stat_awb_max <= as_writedata[7:0];
					REG_STAT_AE_PIX_CNT:;
					REG_STAT_AE_SUM:;
					REG_STAT_AWB_PIX_CNT:;
					REG_STAT_AWB_SUM_R:;
					REG_STAT_AWB_SUM_G:;
					REG_STAT_AWB_SUM_B:;
					REG_INT_STATUS: {int_awb_done, int_ae_done, int_frame_done} <= 3'd0;
					REG_INT_MASK: {int_mask_awb_done, int_mask_ae_done, int_mask_frame_done} <= 3'd0;
					default:;
				endcase
			end
			else begin
				if (stat_ae_done) int_ae_done <= 1'b1;
				if (stat_awb_done) int_awb_done <= 1'b1;
				if (out_vsync & (~prev_vsync)) int_frame_done <= 1'b1;
			end
		end
	end
	
	isp_top #(BITS, WIDTH, HEIGHT, BAYER, STAT_BITS) isp_top_i0 (
			.pclk(pclk),
			.rst_n(rst_n & ~module_reset),
		
			.in_href(in_href),
			.in_vsync(in_vsync),
			.in_raw(in_raw),
		
			.out_href(out_href),
			.out_vsync(out_vsync),
			.out_y(out_y),
			.out_u(out_u),
			.out_v(out_v),
		
			.blc_en(blc_en), 
			.bnr_en(bnr_en),
			.dgain_en(dgain_en),
			.demosic_en(demosic_en),
			.wb_en(wb_en),
			.ccm_en(ccm_en),
			.csc_en(csc_en),
			.gamma_en(gamma_en),
			.ee_en(ee_en),
			.stat_ae_en(stat_ae_en),
			.stat_awb_en(stat_awb_en),

			.blc_b(blc_b), .blc_gb(blc_gb), .blc_gr(blc_gr), .blc_r(blc_r),
			.dgain(dgain),
			.wb_rgain(wb_rgain), .wb_ggain(wb_ggain), .wb_bgain(wb_bgain),
			.ccm_rr(ccm_rr), .ccm_rg(ccm_rg), .ccm_rb(ccm_rb),
			.ccm_gr(ccm_gr), .ccm_gg(ccm_gg), .ccm_gb(ccm_gb),
			.ccm_br(ccm_br), .ccm_bg(ccm_bg), .ccm_bb(ccm_bb),

			.stat_ae_done(stat_ae_done),
			.stat_ae_pix_cnt(stat_ae_pix_cnt), .stat_ae_sum(stat_ae_sum),
			.stat_ae_hist_clk(clk),
			.stat_ae_hist_out(as_read & stat_ae_hist_out),
			.stat_ae_hist_addr(as_address[BITS+1:0]),
			.stat_ae_hist_data(/*stat_ae_hist_data*/),

			.stat_awb_min(stat_awb_min), .stat_awb_max(stat_awb_max),
			.stat_awb_done(stat_awb_done),
			.stat_awb_pix_cnt(stat_awb_pix_cnt), .stat_awb_sum_r(stat_awb_sum_r), .stat_awb_sum_g(stat_awb_sum_g), .stat_awb_sum_b(stat_awb_sum_b),
			.stat_awb_hist_clk(clk),
			.stat_awb_hist_out(as_read & stat_awb_hist_out),
			.stat_awb_hist_addr(as_address[BITS+1:0]),
			.stat_awb_hist_data(/*stat_awb_hist_data*/)
		);
endmodule
