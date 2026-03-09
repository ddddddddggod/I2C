module ass_i2c_slave_rx_ctrl #(parameter [6:0] SLAVE_ADDR = 7'h74) (
    input clk,
    input rstb,
    input start_det,
    input stop_det,
    input scl_rising,
    input scl_falling,
    input count_done,
    input [7:0] wdata,
    input sda_out_bit,
    input sda_in,
    output reg sda_oe,
    output reg count_inc,
    output reg count_clr,
    output reg we,
    output reg shift_rx_en,
    output reg shift_tx_en,
    output reg load_addr,
    output reg inc_addr,
    output reg load_data
);
    localparam st_idle = 4'd0;
    localparam st_addr = 4'd1;
    localparam st_addr_ack = 4'd2;
    localparam st_reg = 4'd3;
    localparam st_reg_ack = 4'd4;
    localparam st_wr_data  = 4'd5;
    localparam st_wr_ack   = 4'd6;
    localparam st_rd_load  = 4'd7;
    localparam st_rd_data  = 4'd8;
    localparam st_rd_ack   = 4'd9;

    reg [3:0] state, state_n;

    // 1. Current state (Sequential)
    always @(posedge clk or negedge rstb) begin
        if (!rstb) begin
            state <= st_idle;
        end else if (start_det) begin
            state <= st_addr;
        end else if (stop_det) begin
            state <= st_idle;
        end else begin
            state <= state_n;
        end
    end

    //2. Next state
    always @(*) begin
        state_n = state;
        case (state)
            st_idle: begin state_n = st_idle; end
            st_addr: state_n = (scl_rising && count_done) ? st_addr_ack : st_addr;
            st_addr_ack: begin
                if (scl_falling) begin
                    if (wdata[7:1] == SLAVE_ADDR) begin
                        if (wdata[0] == 1'b0)
                            state_n = st_reg;      // write mode
                        else
                            state_n = st_rd_load;  // read mode
                    end else begin
                        state_n = st_idle;
                    end
                end
            end
            st_reg: state_n = (scl_rising && count_done) ? st_reg_ack : st_reg;
            st_reg_ack: state_n = (scl_falling) ? st_wr_data : st_reg_ack;
            st_wr_data: state_n = (scl_rising && count_done) ? st_wr_ack : st_wr_data;
            st_wr_ack: state_n = (scl_falling) ? st_wr_data : st_wr_ack;
            st_rd_load: begin state_n = st_rd_data; end
            st_rd_data: state_n = (scl_falling && count_done) ? st_rd_ack : st_rd_data;
            st_rd_ack: begin
                if (scl_rising) begin
                    if (sda_in == 1'b0)
                        state_n = st_rd_load; // master ACK
                    else
                        state_n = st_idle;    // master NACK
                end
            end
        endcase
    end

    // 3. Control Signals 
    always @(*) begin
    count_inc = (((state == st_addr) || (state == st_reg) || (state == st_wr_data)) && scl_rising) || ((state == st_rd_data) && scl_falling);
    count_clr = (((state == st_addr_ack) || (state == st_reg_ack) || (state == st_wr_ack)) && scl_falling) || ((state == st_rd_ack) && scl_rising && (sda_in == 1'b0));
    shift_rx_en = (((state == st_addr) || (state == st_reg) || (state == st_wr_data)) && scl_rising);
    shift_tx_en =((state == st_rd_data) && scl_falling);
    load_data = ((state == st_addr_ack) && (wdata[7:1] == SLAVE_ADDR) && (wdata[0] == 1'b1) && scl_falling) || (state == st_rd_load);
    we = (state == st_wr_ack) && scl_falling;
    load_addr = (state == st_reg_ack) && scl_falling;
    inc_addr = ((state == st_wr_ack) && scl_falling) || ((state == st_rd_ack) && scl_rising && (sda_in == 1'b0));
    // SDA OE 
    if ((state == st_addr_ack && (wdata[7:1] == SLAVE_ADDR)) || (state == st_reg_ack) || (state == st_wr_ack)) begin
        sda_oe = 1'b1; // slave ACK
    end else if (state == st_rd_data) begin
        sda_oe = ~sda_out_bit; // read data transmit
    end else begin
        sda_oe = 1'b0; // release SDA
    end

    end
endmodule
