module ass_i2c_slave_rx #(parameter [6:0] SLAVE_ADDR = 7'h74)(
	input clk,
	input rstb,
	input scl,
	input sda,
	input [7:0] rdata,
	input [7:0] period,
	output we,
	output [6:0] addr,
	output [7:0] wdata,
	output sda_oe
);
	//--------------SDA, SCL Synchronization-------------
	wire scl_rising, scl_falling, start_det, stop_det;
	wire sda_in;
  
	ass_i2c_slave_rx_sync u_sync (
		.clk 		(clk),
		.rstb 		(rstb),
		.scl  		(scl),
		.sda 		(sda),
		.scl_rising	(scl_rising),
		.scl_falling(scl_falling),
		.sda_in 	(sda_in),
		.start_det 	(start_det),
		.stop_det 	(stop_det)
		);

    //----------Rx Ctrl (FSM)--------------
    wire shift_en, count_clr, count_done;
    wire load_addr, inc_addr, load_data;
    wire sda_out_bit;
    wire rdy, request, init;

    ass_i2c_slave_rx_ctrl #(
    	.SLAVE_ADDR(SLAVE_ADDR)
    ) u_ctrl (
    	.clk 		(clk),
    	.rstb  		(rstb),
    	.start_det  (start_det),
    	.stop_det 	(stop_det),
    	.scl_rising (scl_rising),
    	.scl_falling(scl_falling),
    	.count_done (count_done),
    	.sda_in		(sda_in),
    	.wdata 		(wdata),
    	.sda_out_bit(sda_out_bit),
    	.period     (period),
    	.sda_oe 	(sda_oe),
    	.count_clr 	(count_clr),
    	.shift_en 	(shift_en),
    	.rdy 		(rdy),
    	.request 	(request),
    	.init 		(init)
    );


    ass_i2c_slave_rx_pkt_ctrl u_pkt_ctrl (
    	.clk 		(clk),
    	.rstb  		(rstb),
    	.init		(init),
    	.rdy 		(rdy),
    	.request 	(request),
    	.load_addr 	(load_addr),
    	.we 		(we),
    	.inc_addr 	(inc_addr),
    	.load_data 	(load_data)
    );


    //---------Sda bit counter ------------
    ass_i2c_slave_bit_counter u_cnt (
    	.clk 		(clk),
    	.rstb 		(rstb),
    	.count_clr  (count_clr),
    	.shift_en   (shift_en),
    	.count_done (count_done)
    );

    //---------De-serializer---------------
    ass_i2c_slave_rx_deserializer u_deserial (
    	.clk 		(clk),
    	.rstb 		(rstb),
    	.sda_in 	(sda_in),
    	.shift_en 	(shift_en),
    	.load_data  (load_data),
    	.load_addr  (load_addr),
    	.inc_addr	(inc_addr),
    	.rdata 		(rdata),
    	.wdata 		(wdata),
    	.addr 		(addr),
    	.sda_out_bit(sda_out_bit)
    );

endmodule
