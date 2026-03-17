module ass_i2c_slave_rx_deserializer (
    input clk,
    input rstb,
    input sda_in,
    input shift_rx_en,   
    input shift_tx_en,   
    input load_data,     
    input [7:0] txrdata, 
    output [7:0] wdata,  
    output sda_out_bit   
);

    reg [7:0] rx_shift_reg; 
    reg [7:0] tx_shift_reg;

    //RX register
    always @(posedge clk or negedge rstb) begin
        if (!rstb) begin
            rx_shift_reg <= 8'h00;
        end else if (shift_rx_en) begin
            rx_shift_reg <= {rx_shift_reg[6:0], sda_in};
        end
    end

    //TX register
    always @(posedge clk or negedge rstb) begin
        if (!rstb) begin
            tx_shift_reg <= 8'h00;
        end else if (load_data) begin
            tx_shift_reg <= txrdata; 
        end else if (shift_tx_en) begin
            tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
        end
    end

    assign wdata = rx_shift_reg;         
    assign sda_out_bit = tx_shift_reg[7];

endmodule