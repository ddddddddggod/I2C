module ass_i2c_slave_pkt_ctrl (
    input        clk,
    input        rstb,
    input        init,
    input        rdy,      
    input        request,   
    input        rxempty,  
    input        txfull,   
    output       we,        
    output       load_addr, 
    output       inc_addr,  
    output       rxre,      // RX FIFO pop
    output       txwe       // TX FIFO push
);

localparam [1:0] pkt_idle = 2'd0;
localparam [1:0] pkt_addr = 2'd1;
localparam [1:0] pkt_data = 2'd2;

reg [1:0] pkt_state, pkt_state_n;

//rxre delay
assign rxre = ~rxempty;
reg rxre_r;
always @(posedge clk or negedge rstb) begin
    if (!rstb || init) rxre_r <= 1'b0;
    else               rxre_r <= rxre;
end
// ------------------------------------------------------------------
// State register
// ------------------------------------------------------------------
always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        pkt_state <= pkt_idle;
    end else if (init) begin
        pkt_state <= pkt_idle;
    end else begin
        pkt_state <= pkt_state_n;
    end
end

// ------------------------------------------------------------------
// Next state
// ------------------------------------------------------------------
always @(*) begin
    pkt_state_n = pkt_state;
    case (pkt_state)
        pkt_idle: begin //idle + slave address
            if (rxre_r) begin
                pkt_state_n = pkt_addr; // write: rxrdata valid
            end else if (request) begin
                pkt_state_n = pkt_data; // read
            end
        end
        pkt_addr: if (rxre_r) begin pkt_state_n = pkt_data; end 
        pkt_data: pkt_state_n = pkt_data;
    endcase
end

// ------------------------------------------------------------------
// Output logic
// -----------------------------------------------------------------
reg request_d;
always @(posedge clk or negedge rstb) begin
    if (!rstb || init) request_d <= 1'b0;
    else               request_d <= request;
end

wire read_pulse = request & ~request_d; // request rising edge

assign load_addr = (pkt_state == pkt_addr) && rxre_r;
assign we        = (pkt_state == pkt_data) && rxre_r;

// inc_addr:
assign inc_addr = ((pkt_state == pkt_data) && rxre_r)   // write sequential
                | ((pkt_state == pkt_idle) && request)   // read set
                | ((pkt_state == pkt_data) && request);  // read sequential

assign txwe = read_pulse & ~txfull;

endmodule