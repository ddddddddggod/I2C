module ass_i2c_slave_rx_pkt_ctrl (
    input clk,
    input rstb,
    input init,
    input rxwe_addr,        
    input rxwe,             
    input read_req_flag,    
    input txfull,
    input [7:0] rf_rdata,
    input rxempty,
    output load_addr,       
    output we,              // rf write enable
    output txwe,
    output [7:0] txwdata,
    output inc_addr
);

    // ── FSM ──────────────────────────────────────────────
    localparam [1:0] pkt_idle = 2'd0; 
    localparam [1:0] pkt_addr = 2'd1;
    localparam [1:0] pkt_data = 2'd2; //rxwe 

    reg [1:0] pkt_state, pkt_state_n;

    always @(posedge clk or negedge rstb) begin
        if (!rstb) begin
            pkt_state <= pkt_idle;
        end else if (init) begin
            pkt_state <= pkt_idle;
        end else begin
            pkt_state <= pkt_state_n;
        end
    end

    always @(*) begin
        pkt_state_n = pkt_state;
        case (pkt_state)
            pkt_idle: if (rxwe_addr) begin pkt_state_n = pkt_addr; end //idle + slave address
            pkt_addr: if (rxwe) begin pkt_state_n = pkt_data; end//register address
            pkt_data: pkt_state_n = pkt_data; //read or write data
        endcase
    end

    // ── Output ───────────────────────────────────────────
    wire read_start = (pkt_state == pkt_idle) && read_req_flag;
    wire read_ing = (pkt_state == pkt_data) && (rxwe || read_req_flag);

    assign we = (pkt_state == pkt_data) && rxwe && !rxempty; //(rewe -> data)
    assign txwdata = rf_rdata; 
    assign txwe = (rxwe_addr || read_req_flag) && !txfull;

    assign load_addr = (pkt_state == pkt_addr) && rxwe; //(rxwe -> addr)
    assign inc_addr = read_start || read_ing;


endmodule