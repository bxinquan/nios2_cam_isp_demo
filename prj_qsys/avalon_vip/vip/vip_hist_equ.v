/*************************************************************************
    > File Name: vip_hist_equ.v
    > Author: bxq
    > Mail: 544177215@qq.com
    > Created Time: Thu 21 Jan 2021 21:50:04 GMT
 ************************************************************************/

//histogram equalization 
module vip_hist_equ
#(
	parameter BITS = 8,
	parameter WIDTH = 640,
	parameter HEIGHT = 480
)
(
	input pclk,
	input rst_n,

	input in_href,
	input in_vsync,
	input [BITS-1:0] in_data,

	output out_href,
	output out_vsync,
	output [BITS-1:0] out_data
);

	localparam PIX_TOTAL = WIDTH * HEIGHT;
	localparam HIST_BITS = clogb2(PIX_TOTAL);

	reg prev_vsync;
	always @ (posedge pclk or negedge rst_n) begin
		if (!rst_n)
			prev_vsync <= 0;
		else
			prev_vsync <= in_vsync;
	end

	reg hist_sum_done;
	reg [BITS-1:0] hist_addr;
	always @ (posedge pclk or negedge rst_n) begin
		if (!rst_n) begin
			hist_sum_done <= 0;
			hist_addr <= 0;
		end
		else if (in_vsync & ~prev_vsync) begin
			hist_sum_done <= 0;
			hist_addr <= 0;
		end
		else if (!hist_sum_done) begin
			hist_addr <= hist_addr + 1'b1;
			if (hist_addr == {BITS{1'b1}})
				hist_sum_done <= 1'b1;
			else
				hist_sum_done <= hist_sum_done;
		end
		else begin
			hist_sum_done <= hist_sum_done;
			hist_addr <= hist_addr;
		end
	end

	wire [HIST_BITS-1:0] hist_data;
	hist_ram #(BITS, HIST_BITS) hist_ram_data (
			.in_clk(pclk),
			.in_rst_n(rst_n),
			.in_valid(in_href),
			.in_flip_trigger(in_vsync),
			.in_addr(in_data),
			.out_clk(pclk),
			.out_en(~hist_sum_done),
			.out_addr(hist_addr),
			.out_data(hist_data)
		);

	reg hist_sum_runn_0;
	reg [BITS-1:0] hist_sum_addr_0;
	always @ (posedge pclk or negedge rst_n) begin
		if (!rst_n) begin
			hist_sum_runn_0 <= 0;
			hist_sum_addr_0 <= 0;
		end
		else if (hist_sum_done) begin
			hist_sum_runn_0 <= 0;
			hist_sum_addr_0 <= 0;
		end
		else begin
			hist_sum_runn_0 <= 1;
			hist_sum_addr_0 <= hist_addr;
		end
	end

	reg hist_sum_runn_1;
	reg [BITS-1:0] hist_sum_addr_1;
	reg [HIST_BITS-1:0] hist_sum_data_1;
	always @ (posedge pclk or negedge rst_n) begin
		if (!rst_n) begin
			hist_sum_runn_1 <= 0;
			hist_sum_addr_1 <= 0;
			hist_sum_data_1 <= 0;
		end
		else begin
			hist_sum_runn_1 <= hist_sum_runn_0;
			hist_sum_addr_1 <= hist_sum_addr_0;
			if (hist_sum_runn_0)
				hist_sum_data_1 <= hist_sum_data_1 + hist_data;
			else
				hist_sum_data_1 <= 0;
		end
	end

	reg hist_sum_runn_2;
	reg [BITS-1:0] hist_sum_addr_2;
	reg [HIST_BITS+BITS-1:0] hist_sum_data_2;
	always @ (posedge pclk or negedge rst_n) begin
		if (!rst_n) begin
			hist_sum_runn_2 <= 0;
			hist_sum_addr_2 <= 0;
			hist_sum_data_2 <= 0;
		end
		else begin
			hist_sum_runn_2 <= hist_sum_runn_1;
			hist_sum_addr_2 <= hist_sum_addr_1;
			hist_sum_data_2 <= hist_sum_data_1 * {BITS{1'b1}};
		end
	end

	reg hist_sum_runn_3;
	reg [BITS-1:0] hist_sum_addr_3;
	reg [HIST_BITS+BITS-1:0] hist_sum_data_3;
	always @ (posedge pclk or negedge rst_n) begin
		if (!rst_n) begin
			hist_sum_runn_3 <= 0;
			hist_sum_addr_3 <= 0;
			hist_sum_data_3 <= 0;
		end
		else begin
			hist_sum_runn_3 <= hist_sum_runn_2;
			hist_sum_addr_3 <= hist_sum_addr_2;
			hist_sum_data_3 <= hist_sum_data_2 / PIX_TOTAL[HIST_BITS-1:0];
		end
	end

	wire [BITS-1:0] hist_q;
	simple_dp_ram #(BITS, BITS) hist_map_ram (
			.clk(pclk),
			.wren(hist_sum_runn_3),
			.wraddr(hist_sum_addr_3),
			.data(hist_sum_data_3[BITS-1:0]),
			.rden(in_href),
			.rdaddr(in_data),
			.q(hist_q)
		);

	reg href_r, vsync_r;
	always @ (posedge pclk) {href_r, vsync_r} <= {in_href, in_vsync};
	assign {out_href, out_vsync} = {href_r, vsync_r};
	assign out_data = out_href ? hist_q : {BITS{1'b0}};

	function integer clogb2;
	input integer depth;
	begin
		for (clogb2 = 0; depth > 0; clogb2 = clogb2 + 1)
			depth = depth >> 1;
	end
	endfunction
endmodule
