module ass_i2c_slave_rx #(parameter [6:0] SLAVE_ADDR = 7'h74)(
    input clk,
    input rstb,
    input scl,
    input sda,
    input [7:0] rf_rdata,
    input [7:0] period,
    input overflow_stop_en,
    input rf_full,
    output we,
    output [6:0] addr,
    output [7:0] rf_wdata,
    output sda_oe,
    output init
);

    wire scl_rising, scl_falling, start_det, stop_det, sda_in;
    wire count_clr, shift_rx_en,shift_tx_en, count_done, sda_out_bit;
    wire read_req_flag;
    wire rxwe_addr, rxwe;
    wire txfull, txempty, txre;
    wire rxfull,rxempty; 
    wire [7:0] rxwdata, rxrdata, txwdata, txrdata;
    wire load_data, load_addr, inc_addr;

    ass_i2c_slave_rx_sync u_sync (
        .clk            (clk), 
        .rstb           (rstb), 
        .scl            (scl), 
        .sda            (sda),
        .scl_rising     (scl_rising), 
        .scl_falling    (scl_falling),
        .sda_in         (sda_in), 
        .start_det      (start_det), 
        .stop_det       (stop_det)
    );

    ass_i2c_slave_bit_counter u_cnt (
        .clk            (clk), 
        .rstb           (rstb),
        .count_clr      (count_clr), 
        .shift_rx_en       (shift_rx_en),
        .shift_tx_en(shift_tx_en), 
        .count_done     (count_done)
    );

    ass_i2c_slave_rx_ctrl #(.SLAVE_ADDR(SLAVE_ADDR)) u_ctrl (
        .clk            (clk),              
        .rstb           (rstb),
        .start_det      (start_det),  
        .stop_det       (stop_det),
        .scl_rising     (scl_rising),
        .scl_falling    (scl_falling),
        .count_done     (count_done),
        .sda_in         (sda_in),
        .sda_out_bit    (sda_out_bit), 
        .period         (period),
        .rxfull         (rxfull),        
        .txempty        (txempty),
        .overflow_stop_en(overflow_stop_en), 
        .rf_full        (rf_full),
        .wdata          (rxwdata),        
        .sda_oe         (sda_oe),
        .count_clr      (count_clr),  
        .shift_rx_en       (shift_rx_en),
        .shift_tx_en    (shift_tx_en),
        .rxwe_addr      (rxwe_addr),  
        .rxwe           (rxwe),
        .txre           (txre),            
        .init           (init),            
        .read_req_flag  (read_req_flag)
    );

    ass_i2c_slave_rx_pkt_ctrl u_pkt_ctrl (
        .clk            (clk),              
        .rstb           (rstb),
        .init           (init),
        .rxwe_addr      (rxwe_addr),  
        .rxwe           (rxwe),
        .read_req_flag  (read_req_flag),
        .txfull         (txfull),        
        .rf_rdata       (rf_rdata),
        .rxempty        (rxempty),
        .load_addr      (load_addr),
        .we             (we),
        .txwe           (txwe),            
        .txwdata        (txwdata),
        .inc_addr       (inc_addr)
    );


    // RX FIFO: rxfull
    generic_fifo_dc #(.dw(8), .aw(8)) u_rxfifo (
        .rd_clk         (clk), 
        .wr_clk         (clk),
        .rst            (rstb),   
        .clr            (init),
        .din            (rxwdata), 
        .we             (rxwe),
        .dout           (rxrdata), 
        .re             (we), //we
        .full           (rxfull), 
        .empty          (rxempty),
        .full_n         (), 
        .empty_n        (), 
        .level          ()
    );
    // rf_wdata
    assign rf_wdata = rxwdata;
    // TX FIFO
    generic_fifo_dc #(.dw(8), .aw(8)) u_txfifo (
        .rd_clk         (clk), 
        .wr_clk         (clk),
        .rst            (rstb),   
        .clr            (init),
        .din            (txwdata), 
        .we             (txwe),
        .dout           (txrdata), 
        .re             (txre),
        .full           (txfull), 
        .empty          (txempty),
        .full_n         (), 
        .empty_n        (), 
        .level          ()
    );

    ass_i2c_slave_rx_deserializer u_deserial (
        .clk            (clk), 
        .rstb           (rstb),
        .sda_in         (sda_in), 
        .shift_rx_en    (shift_rx_en),
        .shift_tx_en    (shift_tx_en),
        .load_data      (read_req_flag),
        .txrdata        (txwdata),
        .wdata          (rxwdata), 
        .sda_out_bit    (sda_out_bit)
    );

    // Addr Register
    ass_i2c_slave_rx_addr u_addr (
        .clk            (clk),          
        .rstb           (rstb),
        .load_addr      (load_addr),
        .inc_addr       (inc_addr),
        .rdata          (rxwdata[6:0]),
        .addr           (addr)
    );

endmodule