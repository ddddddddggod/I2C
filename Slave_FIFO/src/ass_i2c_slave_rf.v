module ass_i2c_slave_rf (
    input clk,
    input rstb, 
    input we,
    input [6:0] addr,
    input [7:0] rf_wdata,
    input init,
    output [7:0] rf_rdata,
    output rf_full
);
    reg [7:0] mem [0:127]; // 128x8

    reg full_reg;  
    always @(posedge clk or negedge rstb) begin
        if (!rstb) begin
            full_reg <= 1'b0;
        end else if (init) begin
            full_reg <= 1'b0;
        end else if (we && (addr == 7'd127)) begin
            full_reg <= 1'b1;
        end
    end
    assign rf_full = full_reg;

    //Write
    integer i;
    always @(posedge clk or negedge rstb) begin
        if (!rstb) begin
            for (i=0; i<128; i=i+1) mem[i] <= 8'h00;
        end else if (we) begin  //we=1 
            mem[addr] <= rf_wdata;
        end
    end

    //Read
    assign rf_rdata = mem[addr];


endmodule