module ass_i2c_slave_rx_deserializer (
    input clk,
    input rstb,
    input sda_in,
    input shift_en,
    input load_data,
    input load_addr,
    input inc_addr,
    input [7:0] rdata,
    output [7:0] wdata,
    output reg [6:0] addr,
    output sda_out_bit
);
    reg [7:0] shift_reg;

    // 1. Shift Register
    always @(posedge clk or negedge rstb) begin
        if (!rstb) begin
            shift_reg <= 8'h00;
        end else if (load_data) begin //read
            shift_reg <= rdata;
        end else if (shift_en) begin //write
            shift_reg <= {shift_reg[6:0], sda_in};
        end
    end

    assign wdata = shift_reg;
    assign sda_out_bit = shift_reg[7];

    // 2. Address
    always @(posedge clk or negedge rstb) begin
        if (!rstb) begin
            addr <= 7'd0;
        end else if (load_addr) begin
            addr <= shift_reg[6:0];
        end else if (inc_addr) begin
            addr <= addr + 1'b1;
        end
    end

endmodule