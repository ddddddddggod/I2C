module ass_i2c_slave_rx #(
    parameter [6:0] SLAVE_ADDR = 7'h74
)(
    input        clk,
    input        rstb,
    input        scl,
    input        sda,
    input  [7:0] rdata,
    output       we,
    output [6:0] addr,
    output [7:0] wdata,
    output       sda_oe
);


    //---------SDA,SCL Synchronization---------
    wire scl_rising, scl_falling, start_det, stop_det, sda_in;

    ass_i2c_slave_rx_sync u_sync (
        .clk        (clk),
        .rstb       (rstb),
        .scl        (scl),
        .sda        (sda),
        .scl_rising (scl_rising),
        .scl_falling(scl_falling),
        .sda_in     (sda_in),
        .start_det  (start_det),
        .stop_det   (stop_det)
    );

    //--------FSM---------------------
    wire rxempty, rxfull;
    wire txempty, txfull;

    wire count_clr, count_done;
    wire shift_rx_en, shift_tx_en;
    wire sda_out_bit;
    wire request, init;
    wire rxwe, txre;
    wire [7:0] rxwdata;
    wire load_data;

    ass_i2c_slave_rx_ctrl #(
        .SLAVE_ADDR(SLAVE_ADDR)
    ) u_ctrl (
        .clk        (clk),
        .rstb       (rstb),
        .start_det  (start_det),
        .stop_det   (stop_det),
        .scl_rising (scl_rising),
        .scl_falling(scl_falling),
        .count_done (count_done),
        .sda_in     (sda_in),
        .wdata      (rxwdata),
        .sda_out_bit(sda_out_bit),
        .rxfull     (rxfull),
        .txempty    (txempty),

        .sda_oe     (sda_oe),
        .count_clr  (count_clr),
        .shift_rx_en   (shift_rx_en),
        .shift_tx_en(shift_tx_en),
        .request    (request),
        .init       (init),
        .rxwe       (rxwe),
        .txre       (txre),
        .load_data  (load_data)
    );

    //------RX FIFO---------------
    wire [7:0] rxrdata;
    wire       rxre;

    generic_fifo_dc #(
        .dw(8),
        .aw(1)
    ) u_rx_fifo (
        .wr_clk (clk),
        .rd_clk (clk),
        .rst    (rstb),
        .clr    (1'b0),
        .din    (rxwdata),
        .we     (rxwe),
        .dout   (rxrdata),
        .re     (rxre),
        .empty  (rxempty),
        .full   (rxfull),
        .full_n (),
        .empty_n(),
        .level  ()
    );

    //--------TX FIFO---------------
    wire [7:0] txrdata;
    wire       txwe;

    generic_fifo_dc #(
        .dw(8),
        .aw(1)
    ) u_tx_fifo (
        .wr_clk (clk),
        .rd_clk (clk),
        .rst    (rstb),
        .clr    (1'b0),
        .din    (rdata), //txwdata
        .we     (txwe),
        .dout   (txrdata),
        .re     (txre),
        .empty  (txempty),
        .full   (txfull),
        .full_n (),
        .empty_n(),
        .level  ()
    );

    //----------bit counter------------------
    ass_i2c_slave_bit_counter u_cnt (
        .clk        (clk),
        .rstb       (rstb),
        .count_clr  (count_clr),
        .shift_rx_en(shift_rx_en),
        .shift_tx_en(shift_tx_en),
        .count_done (count_done)
    );

    //--------Deserializer------------------------
    //RX
    ass_i2c_slave_rx_deserializer u_rx_deserial (
        .clk        (clk),
        .rstb       (rstb),
        .sda_in     (sda_in),
        .shift_rx_en(shift_rx_en),
        .wdata      (rxwdata)
    );

    //TX
    ass_i2c_slave_tx_deserializer u_tx_deserial (
        .clk        (clk),
        .rstb       (rstb),
        .shift_tx_en(shift_tx_en),
        .load_data  (load_data),
        .txrdata    (txrdata),
        .sda_out_bit(sda_out_bit)
    );

    //-------------Addr register---------------------
    wire load_addr, inc_addr;

    ass_i2c_slave_rx_addr u_addr (
        .clk      (clk),
        .rstb     (rstb),
        .load_addr(load_addr),
        .inc_addr (inc_addr),
        .rdata    (rxrdata[6:0]),
        .addr     (addr)
    );

    //-----------Packet FSM--------------------------
    ass_i2c_slave_pkt_ctrl u_pkt_ctrl (
        .clk    (clk),
        .rstb   (rstb),
        .rxempty    (rxempty),
        .txfull     (txfull),
        .init       (init),
        .request    (request),
        
        .we         (we),
        .load_addr  (load_addr),
        .inc_addr   (inc_addr),
        .rxre       (rxre),
        .txwe       (txwe)
    );

    assign wdata = rxrdata;

endmodule