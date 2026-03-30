module ass_i2c_slave_pkt_ctrl #(parameter [3:0] depth = 4'd1) (
    input        clk,
    input        rstb, 
    input        rxempty,
    input        rx_empty_n,
    input        txfull,  
    input        init_req,
    input        request_req,

    output       we,        
    output       load_addr, 
    output       inc_addr,  
    output       rxre,
    output       txwe,
    output       init_ack,
    output       request_ack
    );

localparam [1:0] pkt_idle = 2'd0;
localparam [1:0] pkt_addr = 2'd1;
localparam [1:0] pkt_data = 2'd2;

reg [1:0] pkt_state, pkt_state_n;

//---------- CDC request -----------------
reg [1:0] init_req_r;
always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        init_req_r <= 2'b00;
    end else begin
        init_req_r <= {init_req_r[0], init_req};
    end
end
assign init_ack  = init_req_r[1];
assign init_clk2 = init_req_r[0] & ~init_req_r[1]; //edge detect


reg [1:0] request_req_r;
always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        request_req_r <= 2'b00;
    end else begin
        request_req_r <= {request_req_r[0], request_req};
    end
end
assign request_ack  = request_req_r[1];
assign request_clk2 = request_req_r[0] && ~request_req_r[1]; //edge detect

//-----------rxre logic (depth version)----------------
reg rxfifo_out;
always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        rxfifo_out <= 1'b0;
    end else if (rxempty) begin
        rxfifo_out <= 1'b0;
    end else if (~rx_empty_n) begin
        rxfifo_out <= 1'b1;
    end else if (init_clk2) begin //if data is smaller than depth
        rxfifo_out <= 1'b1;
    end
end
assign rxre = rxfifo_out && ~rxempty; 


//rxre_delay
reg rxre_r;
always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        rxre_r <= 1'b0;
    end else if (init_clk2 && rxempty) begin
        rxre_r <= 1'b0;
    end else begin
        rxre_r <= rxre;
    end           
end

// ------------------------------------------------------------------
// State register
// ------------------------------------------------------------------
always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        pkt_state <= pkt_idle;
    end else if (init_clk2 && rxempty) begin
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
        pkt_idle: begin
            if (rxre_r) begin //addr
                pkt_state_n = pkt_addr;
            end else if (request_clk2) begin //read 
                pkt_state_n = pkt_data;
            end
        end
        pkt_addr: if (rxre_r) begin pkt_state_n = pkt_data; end
        pkt_data: pkt_state_n = pkt_data;
    endcase
end

// ------------------------------------------------------------------
// Output logic
// ------------------------------------------------------------------
assign load_addr = (pkt_state == pkt_addr) && rxre_r;
assign we        = (pkt_state == pkt_data) && rxre_r;


assign inc_addr = ((pkt_state == pkt_data) && rxre_r) //write seq
                | txwe;                                //read prefetch seq (read 요청이 들어왔다는 순간이 아니라 실제로 TX FIFO에 한 바이트를 넣는 순간 증가)

//prefetch data to fifo 
reg read_prefetch_init;
reg [3:0] prefetch_cnt;
always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        read_prefetch_init <= 1'b0;
    end else if (init_clk2) begin
        read_prefetch_init <= 1'b0;    
    end else if (request_clk2 && !read_prefetch_init) begin
        read_prefetch_init <= 1'b1;
    end
end

always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        prefetch_cnt <= 4'd0;
    end else if (init_clk2) begin
        prefetch_cnt <= 4'd0;         
    end else if (request_clk2 && !read_prefetch_init) begin
        prefetch_cnt <= depth; 
    end else if (request_clk2 && ~txfull && prefetch_cnt == 0) begin
        prefetch_cnt <= 4'd1;   
    end else if (prefetch_cnt > 0 && ~txfull) begin
        prefetch_cnt <= prefetch_cnt - 1;
    end
end
assign txwe = (prefetch_cnt > 0) && ~txfull;

endmodule
