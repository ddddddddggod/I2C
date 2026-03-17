`timescale 1ns / 10ps

module ass_i2c_slave #(parameter [6:0] device_address = 7'h45) (
    input clk,
    input rstb,
    input scl,
    inout sda,
    input [7:0] period,
    input overflow_stop_en
);

    wire we;
    wire [6:0] addr;
    wire [7:0] rf_wdata;
    wire [7:0] rf_rdata;
    wire sda_oe;
    wire rf_full;
    wire init;

    assign sda = sda_oe ? 1'b0 : 1'bz;

    ass_i2c_slave_rx #(
        .SLAVE_ADDR(device_address)
    ) u_rx (
        .clk             (clk), 
        .rstb            (rstb),
        .sda             (sda),
        .scl             (scl),
        .rf_rdata        (rf_rdata),
        .period          (period),
        .overflow_stop_en(overflow_stop_en),
        .rf_full         (rf_full),
        .we               (we),
        .addr            (addr),
        .rf_wdata        (rf_wdata),
        .sda_oe          (sda_oe),
        .init            (init)
    );

    ass_i2c_slave_rf u_mem_buf (
        .clk             (clk), 
        .rstb            (rstb),
        .we              (we),
        .addr            (addr), 
        .rf_wdata           (rf_wdata),
        .init            (init),
        .rf_rdata           (rf_rdata),
        .rf_full            (rf_full)
    );

endmodule
