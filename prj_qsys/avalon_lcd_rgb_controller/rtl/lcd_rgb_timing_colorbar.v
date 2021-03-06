
`define LCD_RGB_480x720_9MHz

module lcd_rgb_timing_colorbar
(
	input pclk,
	input reset_n,
	
	output lcd_dclk,
	output reg lcd_de,
	output reg lcd_hs,
	output reg lcd_vs,
	output [7:0] lcd_r,
	output [7:0] lcd_g,
	output [7:0] lcd_b
);

`ifdef LCD_RGB_480x720_9MHz
	parameter H_FRONT = 16'd2;
	parameter H_PULSE = 16'd41;
	parameter H_BACK = 16'd2;
	parameter H_DISP = 16'd480;
	parameter V_FRONT = 16'd2;
	parameter V_PULSE = 16'd10;
	parameter V_BACK = 16'd2;
	parameter V_DISP = 16'd272;
	parameter H_POL = 1'b0;
	parameter V_POL = 1'b0;
`endif
`ifdef LCD_RGB_640x480_25_175MHz
	parameter H_FRONT = 16'd16;
	parameter H_PULSE = 16'd96;
	parameter H_BACK = 16'd48;
	parameter H_DISP = 16'd640;
	parameter V_FRONT = 16'd10;
	parameter V_PULSE = 16'd2;
	parameter V_BACK = 16'd33;
	parameter V_DISP = 16'd480;
	parameter H_POL = 1'b0;
	parameter V_POL = 1'b0;
`endif

	localparam H_TOTAL = H_FRONT + H_PULSE + H_BACK + H_DISP;
	localparam V_TOTAL = V_FRONT + V_PULSE + V_BACK + V_DISP;

	reg [15:0] pix_cnt;
	always @ (posedge pclk or negedge reset_n) begin
		if (!reset_n)
			pix_cnt <= 0;
		else if (pix_cnt < H_TOTAL - 1'b1)
			pix_cnt <= pix_cnt + 1'b1;
		else
			pix_cnt <= 0;
	end

	reg [15:0] line_cnt;
	always @ (posedge pclk or negedge reset_n) begin
		if (!reset_n)
			line_cnt <= 0;
		else if (pix_cnt == H_FRONT - 1'b1) begin
			if (line_cnt < V_TOTAL - 1'b1)
				line_cnt <= line_cnt + 1'b1;
			else
				line_cnt <= 0;
		end
		else
			line_cnt <= line_cnt;
	end

	reg [23:0] color_data;
	always @ (posedge pclk or negedge reset_n) begin
		if (!reset_n)
			color_data <= 0;
		else if (pix_cnt < H_FRONT + H_PULSE + H_BACK)
			color_data <= 0;
		else if (pix_cnt < H_FRONT + H_PULSE + H_BACK + H_DISP * 1 / 8)
			color_data <= 24'h00_00_00;
		else if (pix_cnt < H_FRONT + H_PULSE + H_BACK + H_DISP * 2 / 8)
			color_data <= 24'h00_00_ff;
		else if (pix_cnt < H_FRONT + H_PULSE + H_BACK + H_DISP * 3 / 8)
			color_data <= 24'h00_ff_00;
		else if (pix_cnt < H_FRONT + H_PULSE + H_BACK + H_DISP * 4 / 8)
			color_data <= 24'h00_ff_ff;
		else if (pix_cnt < H_FRONT + H_PULSE + H_BACK + H_DISP * 5 / 8)
			color_data <= 24'hff_00_00;
		else if (pix_cnt < H_FRONT + H_PULSE + H_BACK + H_DISP * 6 / 8)
			color_data <= 24'hff_00_ff;
		else if (pix_cnt < H_FRONT + H_PULSE + H_BACK + H_DISP * 7 / 8)
			color_data <= 24'hff_ff_00;
		else if (pix_cnt < H_FRONT + H_PULSE + H_BACK + H_DISP * 8 / 8)
			color_data <= 24'hff_ff_ff;
		else
			color_data <= 0;
	end

	always @(posedge pclk or negedge reset_n) begin
		if (!reset_n) begin
			lcd_de <= 0;
			lcd_hs <= ~H_POL;
			lcd_vs <= ~V_POL;
		end
		else begin
			lcd_de <= pix_cnt >= H_FRONT + H_PULSE + H_BACK && line_cnt >= V_FRONT + V_PULSE + V_BACK;
			lcd_hs <= (pix_cnt >= H_FRONT && pix_cnt < H_FRONT + H_PULSE) ? H_POL : ~H_POL;
			lcd_vs <= (line_cnt >= V_FRONT && line_cnt < V_FRONT + V_PULSE) ? V_POL : ~V_POL;
		end
	end

	assign lcd_dclk = ~pclk;
	assign {lcd_r,lcd_g,lcd_b} = lcd_de ? color_data : 24'd0;
endmodule
