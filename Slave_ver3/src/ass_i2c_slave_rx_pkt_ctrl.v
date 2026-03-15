module ass_i2c_slave_rx_pkt_ctrl (
    input clk, 
    input rstb,
    input init,
    input rdy,
    input request,
    output we,
    output load_addr,
    output inc_addr,
    output load_data
);

localparam [1:0] pkt_idle = 2'd0;
localparam [1:0] pkt_addr = 2'd1;
localparam [1:0] pkt_data = 2'd2;

reg [1:0] pkt_state, pkt_state_n;

//next state
always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        pkt_state <= pkt_idle;
    end else if (init) begin
        pkt_state <= pkt_idle;
    end else begin           
        pkt_state <= pkt_state_n;
    end
end

//current state
always @(*) begin
    pkt_state_n = pkt_state;
    case (pkt_state)
        pkt_idle: begin
            if (rdy) begin
                pkt_state_n = pkt_addr;
            end else if (request) begin
                pkt_state_n = pkt_data;
            end
        end
        pkt_addr: if (rdy) pkt_state_n = pkt_data;
        pkt_data: pkt_state_n = pkt_data;
    endcase
end

//output logic
assign load_addr = (pkt_state == pkt_addr) && rdy;
assign we        = (pkt_state == pkt_data) && rdy;
assign load_data = ((pkt_state == pkt_idle) && request) || ((pkt_state == pkt_data) && request);
assign inc_addr  = ((pkt_state == pkt_idle) && request) || ((pkt_state == pkt_data) && (rdy || request));

endmodule
