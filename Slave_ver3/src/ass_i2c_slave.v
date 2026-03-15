`timescale 1ns / 10ps

module ass_i2c_slave #(parameter [6:0] device_address = 7'h45) (
input clk,
input rstb,
input scl,
inout sda,
input [7:0] period,
.overflow_stop_en(overflow_stop_en)
);

    wire we;
    wire [6:0] addr;
    wire [7:0] wdata;
    wire [7:0] rdata;
    wire sda_oe;
    wire full;

    //open_drain
    assign sda = sda_oe ? 1'b0 : 1'bz;

    ass_i2c_slave_rx #(
        .SLAVE_ADDR(device_address)
    ) u_rx(
        .clk            (clk), 
        .rstb           (rstb),
        .sda            (sda),
        .scl            (scl),
        .rdata          (rdata),
        .period         (period),
        .overflow_stop_en(overflow_stop_en),
        .full           (full),
        .we             (we),
        .addr           (addr),
        .wdata          (wdata),
        .sda_oe         (sda_oe)
    );

    //Mem buffer
    ass_i2c_slave_rf u_mem_buf (
        .clk            (clk), 
        .rstb           (rstb),
        .we             (we),
        .addr           (addr), 
        .wdata          (wdata),
        .rdata          (rdata),
        .full           (full)
    );
endmodule
