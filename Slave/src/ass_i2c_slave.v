`timescale 1ns / 10ps

module ass_i2c_slave #(parameter [6:0] device_address = 7'h45) (
input clk,
input rstb,
input scl,
inout sda
);

    //Shift reg 
    wire we;
    wire [6:0] addr;
    wire [7:0] wdata;
    ass_i2c_slave_rx #(
        .SLAVE_ADDR(device_address)
    ) u_rx(
        .clk            (clk), 
        .rstb           (rstb),
        .sda            (sda),
        .scl            (scl),
        .we             (we),
        .addr           (addr),
        .wdata          (wdata)
    );

    //Mem buffer
    ass_i2c_slave_rf u_mem_buf (
        .clk            (clk), 
        .rstb           (rstb),
        .we             (we),
        .addr           (addr), 
        .wdata          (wdata),
        .rdata          (rdata)
    );
endmodule
