module ass_i2c_slave_rx_ctrl_period (
	input clk,
	input rstb,
	input scl_falling,
	input [7:0] period,
	output wait_done
);

reg [7:0] wait_cnt;
reg wait_en;

always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        wait_en  <= 1'b0;
    end else if (scl_falling) begin
        wait_en  <= 1'b1;
    end else if (wait_cnt == period) begin
        wait_en <= 1'b0; 
    end
end
 
always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        wait_cnt <= 8'd0;
    end else if (scl_falling) begin
        wait_cnt <= 8'd0;
    end else if (wait_en) begin
        wait_cnt <= wait_cnt + 1'b1;
    end else begin
        wait_cnt <= 8'd0;
    end
end

assign wait_done = (period == 8'd0) ? scl_falling : (wait_en && (wait_cnt == period)); //0: same as before , else : hold margin

endmodule