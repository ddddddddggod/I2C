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
    output count_clr,
    output we,
    output shift_en,
    output load_addr,
    output inc_addr,
    output load_data
);

localparam [3:0] st_idle    = 3'd0;
localparam [3:0] st_rx_byte = 3'd1;  
localparam [3:0] st_rx_ack  = 3'd2;  
localparam [3:0] st_tx_byte = 3'd3;  
localparam [3:0] st_tx_ack  = 3'd4;  

reg [2:0] state, state_n;
reg first_byte; 
reg addr_done; 
reg rx_done; 

wire addr_match = (wdata[7:1] == SLAVE_ADDR);
wire rx_ack_fall = (state == st_rx_ack) && scl_falling;
wire tx_ack_fall = (state == st_tx_ack) && scl_falling;
wire rx_byte_rise =  (state == st_rx_byte) && scl_rising;
wire tx_byte_fall = (state == st_tx_byte) && scl_falling;

// ------------------------------------------
// 1. Current State & Flags
// ------------------------------------------
always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        state <= st_idle;
    end else begin
        if (stop_det) begin
            state <= st_idle;
        end else if (start_det) begin
            state <= st_rx_byte; 
        end else begin
            state <= state_n;
        end
    end
end

//flag : first byte
wire init = stop_det || start_det;
    always @(posedge clk or negedge rstb) begin
        if (!rstb) begin
            first_byte <= 1'b1;
        end else if (init) begin
            first_byte <= 1'b1;
        end else if(rx_ack_fall) begin  
            first_byte <= 1'b0;
        end
    end

//flag : addr_done
    always @(posedge clk or negedge rstb) begin
        if (!rstb) begin
            addr_done <= 1'b0;
        end else if (init)begin
            addr_done <= 1'b0;
        end else if (rx_ack_fall && ~first_byte) begin            
            addr_done  <= 1'b1;     
        end
    end

//flag : rx_done
wire init_x = init || count_clr;
always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        rx_done <= 1'b0;
    end else if (init_x)begin
        rx_done <= 1'b0;
    end else if (rx_byte_rise && count_done) begin
        rx_done <= 1'b1;
    end
end
// ------------------------------------------
// 2. Next State Logic
// ------------------------------------------
wire [2:0] next_tx_ack_val = (sda_in == 1'b0) ? st_tx_byte : st_idle; 
wire [2:0] rw_next_state = (wdata[0] == 1'b0) ? st_rx_byte : st_tx_byte; //0:write, 1:read
wire [2:0] addr_phase_next = (addr_match) ? rw_next_state : st_idle; // address matching
wire [2:0] phase_next      = (first_byte) ? addr_phase_next : st_rx_byte; //address stage or data stage


always @(*) begin
    state_n = state;
    case (state)
        st_idle: state_n = st_idle;
        st_rx_byte: state_n = (scl_falling && rx_done) ? st_rx_ack : st_rx_byte;
        st_rx_ack: state_n = (scl_falling) ? phase_next : st_rx_ack;
        st_tx_byte: state_n = (scl_falling && count_done) ? st_tx_ack : st_tx_byte;
        st_tx_ack: state_n = (scl_falling) ? next_tx_ack_val : st_tx_ack;
    endcase
end

// ------------------------------------------
// 3. Output Logic
// -----------------------------------------

assign shift_en  = rx_byte_rise || tx_byte_fall;
assign count_clr = rx_ack_fall || tx_ack_fall || (state == st_idle) || start_det; 
assign load_addr = rx_ack_fall && ~first_byte && ~addr_done;
assign we        = rx_ack_fall && ~first_byte &&  addr_done;
assign inc_addr  = we || (tx_byte_fall) && count_done;
assign load_data = (rx_ack_fall && first_byte && addr_match && wdata[0]) || tx_ack_fall; //read set (address) or next read data preparing.

// ------------------------------------------
// 4. sda_oe
// ------------------------------------------
always @(*) begin
    if (state == st_rx_ack) begin
        sda_oe = (addr_match || !first_byte); 
    end else if (state == st_tx_byte) begin
        sda_oe = ~sda_out_bit; 
    end else begin
        sda_oe = 1'b0; 
    end
end

endmodule
