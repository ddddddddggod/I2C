module ass_i2c_slave_rx_ctrl #(parameter [6:0] SLAVE_ADDR = 7'h74) (
    input clk,
    input rstb,
    input start_det,
    input stop_det,
    input scl_rising,
    input scl_falling,
    input count_done,
    input sda_in,
    input [7:0] wdata,
    input sda_out_bit,
    input [7:0] period,
    input full,               // [ADDED]
    input overflow_stop_en,  // [ADDED]
    output reg sda_oe,
    output count_clr,
    output shift_en,
    output rdy,
    output request,
    output init
);

localparam [2:0] st_idle = 3'd0;
localparam [2:0] st_rx = 3'd1;
localparam [2:0] st_rx_ack = 3'd2;
localparam [2:0] st_tx = 3'd3;
localparam [2:0] st_tx_ack = 3'd4;

reg [2:0] state, state_n;
reg first_byte, rx_done; 

//------------------------------------------
// Hold time margin
//------------------------------------------
    ass_i2c_slave_rx_ctrl_period u_period (
        .clk        (clk),
        .rstb       (rstb),
        .scl_falling(scl_falling),
        .period     (period),
        .wait_done  (wait_done)
        );

//-------------------
//wire
//-------------------
wire addr_match = (wdata[7:1] == SLAVE_ADDR);
wire rx_ack_fall = (state == st_rx_ack && wait_done);
wire tx_ack_fall = (state == st_tx_ack && wait_done);
wire rx_rise = (state == st_rx && scl_rising);
wire rx_fall = (state == st_rx && wait_done);
wire tx_fall = (state == st_tx && wait_done);
wire write_valid = first_byte ? (addr_match && !wdata[0]) : (!(overflow_stop_en && full)); //[Modified]
wire read_req = (rx_ack_fall && first_byte && addr_match && wdata[0]); 
wire seq_read_req = (tx_ack_fall && sda_in == 1'b0);
 
// ----------------------------
// Current State & flag
//-----------------------------
always @(posedge clk or negedge rstb) begin
    if (!rstb) begin 
        state <= st_idle;
    end else if (stop_det) begin
        state <= st_idle;
    end else if (start_det) begin
        state <= st_rx;
    end else begin
        state <= state_n;
    end
end

//flag : first_byte
always @(posedge clk or negedge rstb) begin
    if (!rstb) begin 
        first_byte <= 1'b1;
    end else if (init) begin
        first_byte <= 1'b1;
    end else if (rx_ack_fall) begin
        first_byte <= 1'b0;
    end
end

// flag : rx_done 
always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        rx_done <= 1'b0;
    end else if (count_clr) begin
        rx_done <= 1'b0;
    end else if (rx_rise && count_done) begin
        rx_done <= 1'b1;
    end
end

//------------------------------------------
// Next State Logic
//------------------------------------------
wire [2:0] ack_next_state = (first_byte && wdata[0]) ? st_tx : st_rx; //read or write
wire valid_phase = first_byte ? addr_match : !(overflow_stop_en && full); //[Modified]

always @(*) begin
    state_n = state;
    case (state)
        st_idle: state_n = st_idle;
        st_rx:     state_n = (wait_done && rx_done) ? st_rx_ack : st_rx; 
        st_rx_ack: state_n = (wait_done) ? (valid_phase ? ack_next_state : st_idle) : st_rx_ack; 
        st_tx:     state_n = (wait_done && count_done) ? st_tx_ack : st_tx;
        st_tx_ack: state_n = (wait_done) ? ( (sda_in == 1'b0) ? st_tx : st_idle) : st_tx_ack;
    endcase
end

// -----------------------------------------
// Output Logic 
//------------------------------------------
assign rdy = (rx_fall && rx_done && write_valid); //write ready
assign request = read_req || seq_read_req; //read ready
assign shift_en = rx_rise || tx_fall;
assign count_clr = rx_ack_fall || tx_ack_fall || (state == st_idle) || init;
assign init = start_det || stop_det;

// 5. sda_oe
always @(*) begin
    if (state == st_rx_ack) begin
        sda_oe = valid_phase;  //[Modified sda_oe = valid_phase; 
    end else if (state == st_tx) begin
        sda_oe = ~sda_out_bit;
    end else begin
        sda_oe = 1'b0;
    end
end

endmodule
