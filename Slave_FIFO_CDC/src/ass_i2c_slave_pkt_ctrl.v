module ass_i2c_slave_pkt_ctrl (
    input        clk,
    input        rstb, 
    input        rxempty,  
    input        txfull,
    input        init_req,
    input        request_req,  

    output       we,        
    output       load_addr, 
    output       inc_addr,  
    output       rxre,      // RX FIFO pop
    output       txwe,       // TX FIFO push
    output       init_ack,
    output       request_ack
);

localparam [1:0] pkt_idle = 2'd0;
localparam [1:0] pkt_addr = 2'd1;
localparam [1:0] pkt_data = 2'd2;

reg [1:0] pkt_state, pkt_state_n;


//---------- CDC ack -----------------
reg [1:0] init_ack_r;
always @(posedge clk or negedge rstb) begin
    if(!rstb) begin
        init_ack_r <= 2'b00;
    end else begin
        init_ack_r <= {init_ack_r[0], init_req};
    end
end
wire init_clk2 = init_ack_r[0] & ~init_ack_r[1]; //edge detect
assign init_ack = init_ack_r[1];


reg [1:0] request_ack_r;
always @(posedge clk or negedge rstb) begin
    if(!rstb) begin
        request_ack_r <= 2'b00;
    end else begin
        request_ack_r <= {request_ack_r[0], request_req};
    end
end
wire request_clk2 = request_ack_r[0] & ~request_ack_r[1]; //edge detect
assign request_ack = request_ack_r[1];


//-----------rxre delay----------------
assign rxre = ~rxempty;
reg rxre_r;
always @(posedge clk or negedge rstb) begin
    if (!rstb || init_clk2) rxre_r <= 1'b0;
    else               rxre_r <= rxre;
end
// ------------------------------------------------------------------
// State register
// ------------------------------------------------------------------
always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        pkt_state <= pkt_idle;
    end else if (init_clk2) begin
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
            end else if (request_clk2) begin
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
    if (!rstb || init_clk2) request_d <= 1'b0;
    else               request_d <= request_clk2;
end

wire read_pulse = request_clk2 & ~request_d; // request rising edge

assign load_addr = (pkt_state == pkt_addr) && rxre_r;
assign we        = (pkt_state == pkt_data) && rxre_r;

// inc_addr:
assign inc_addr = ((pkt_state == pkt_data) && rxre_r)   // write sequential
                | ((pkt_state == pkt_idle) && request_clk2)   // read set
                | ((pkt_state == pkt_data) && request_clk2);  // read sequential

assign txwe = read_pulse & ~txfull;

endmodule
