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

    localparam st_idle    = 3'd0;
    localparam st_rx_byte = 3'd1;  
    localparam st_rx_ack  = 3'd2;  
    localparam st_tx_byte = 3'd3;  
    localparam st_tx_ack  = 3'd4;  

    reg [2:0] state, state_n;
    reg first_byte; 
    reg addr_done;  
    wire addr_match = (wdata[7:1] == SLAVE_ADDR); 

    reg rx_done;
    reg captured_ack;
    
    // ------------------------------------------
    // 1. Current State & Flags
    // ------------------------------------------
    always @(posedge clk or negedge rstb) begin
        if (!rstb) begin
            state        <= st_idle;
            first_byte   <= 1'b1;
            addr_done    <= 1'b0;
            rx_done      <= 1'b0;
            captured_ack <= 1'b1;
        end else begin
            if (start_det) begin  //start
                state        <= st_rx_byte; 
                first_byte   <= 1'b1;
                addr_done    <= 1'b0;
                rx_done      <= 1'b0;
                captured_ack <= 1'b1;
            end else if (stop_det) begin  //stp
                state        <= st_idle;
            end else begin
                state <= state_n;
                if (count_clr) 
                    rx_done <= 1'b0;
                else if (state == st_rx_byte && count_done && scl_rising) begin
                    rx_done <= 1'b1;
                end else if (state == st_tx_ack && scl_rising) begin
                    captured_ack <= sda_in;
                end else if (state == st_rx_ack && scl_falling) begin
                    if (first_byte) first_byte <= 1'b0;
                    else            addr_done  <= 1'b1;
                end
            end
        end
    end

    // ------------------------------------------
    // 2. Next State Logic
    // ------------------------------------------
    always @(*) begin
        state_n = state;
        case (state)
            st_idle: state_n = st_idle;
            st_rx_byte: state_n = (scl_falling && rx_done) ? st_rx_ack : st_rx_byte;
            st_rx_ack: begin
                if (scl_falling) begin
                    if (first_byte) begin 
                        if (addr_match) begin state_n = (wdata[0] == 1'b0) ? st_rx_byte : st_tx_byte; 
                        else            state_n = st_idle; 
                    end else begin
                        state_n = st_rx_byte; 
                    end
                end
            end
            st_tx_byte: state_n = (scl_falling && count_done) ? st_tx_ack : st_tx_byte;
            st_tx_ack: begin
                if (scl_falling) begin
                    state_n = (captured_ack == 1'b0) ? st_tx_byte : st_idle; 
                end 
            end
            default: state_n = st_idle;
        endcase
    end

    // ------------------------------------------
    // 3. Output Logic
    // ------------------------------------------
    wire rx_ack_fall = (state == st_rx_ack) && scl_falling; 
    wire tx_ack_fall_ack = (state == st_tx_ack) && scl_falling && (captured_ack == 1'b0); 

    assign shift_en  = ((state == st_rx_byte) && scl_rising) || ((state == st_tx_byte) && scl_falling);
    assign count_clr = rx_ack_fall || (state == st_tx_ack && scl_falling) || start_det || (state == st_idle); 
    assign load_addr = rx_ack_fall && ~first_byte && ~addr_done;
    assign we        = rx_ack_fall && ~first_byte &&  addr_done;
    assign inc_addr  = we || ((state == st_tx_byte) && scl_falling && count_done);
    assign load_data = (rx_ack_fall && first_byte && addr_match && wdata[0]) || tx_ack_fall_ack;

    // ------------------------------------------
    // 4. sda_oe
    // ------------------------------------------
    always @(*) begin
        if (state == st_rx_ack) begin
            sda_oe = (addr_match || !first_byte) ? 1'b1 : 1'b0;
        end else if (state == st_tx_byte) begin
            sda_oe = ~sda_out_bit; 
        end else begin
            sda_oe = 1'b0; 
        end
    end
endmodule
