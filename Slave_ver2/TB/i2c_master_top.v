

`timescale 1ns / 1ps


module i2c_master_top(
clk     ,
reset_n ,
scl     ,
sda
);

input        clk;     // master clock input
input        reset_n;    // asynchronous reset

inout   scl;
inout   sda;

reg sta         ;  // STA, generate (repeated) start condition
reg sto         ;  // STO, generate stop condition
reg rd          ;  // RD, read from slave (SDA high impedence)
reg wr          ;  // WR, write to slave
reg ack         ;  // when tx is a receiver, send ack (0) or send nack (1)
reg iack        ;  // Interrupt acknowledge. When set, clears a pending interrupt

wire irxack     ;  // ¡®1¡¯ = No acknowledge received ¡®0¡¯ = Acknowledge received
wire i2c_busy   ;  // bus busy (start signal detected)
wire i2c_al     ;  // i2c bus arbitration lost

wire byte_done  ;  // done signal: command completed, clear command register
reg   [ 7:0] txr;  // transmit data
wire  [ 7:0] rxr;  // received data

wire core_en    ;  // i2c master enable
wire [15:0] prer;  // presacler


// scl
wire scl_pad_i;       // SCL-line input
wire scl_pad_o;       // SCL-line output (always 1'b0)
wire scl_padoen_o;    // SCL-line output enable (active low)

// sda
wire  sda_pad_i;       // SDA-line input
wire  sda_pad_o;       // SDA-line output (always 1'b0)
wire  sda_padoen_o;    // SDA-line output enable (active low)


// hookup byte controller block
i2c_master_byte_ctrl byte_controller (
	.clk      ( clk          ),
	.rst      ( 1'b0         ),
	.nReset   ( reset_n      ),
	.ena      ( core_en      ),
	.clk_cnt  ( prer         ),
	.start    ( sta          ),
	.stop     ( sto          ),
	.read     ( rd           ),
	.write    ( wr           ),
	.ack_in   ( ack          ),
	.din      ( txr          ),
	.cmd_ack  ( byte_done    ),
	.ack_out  ( irxack       ),
	.dout     ( rxr          ),
	.i2c_busy ( i2c_busy     ),
	.i2c_al   ( i2c_al       ),
	.scl_i    ( scl_pad_i    ),
	.scl_o    ( scl_pad_o    ),
	.scl_oen  ( scl_padoen_o ),
	.sda_i    ( sda_pad_i    ),
	.sda_o    ( sda_pad_o    ),
	.sda_oen  ( sda_padoen_o )
);

// control value
assign core_en = 1'b1;
assign prer    = 16'h00_17;

assign sda = (sda_padoen_o == 1'b0) ? sda_pad_o : 1'bz;
assign sda_pad_i = sda;

assign scl = (scl_padoen_o == 1'b0) ? scl_pad_o : 1'bz;
assign scl_pad_i = scl;

initial
begin
	sta = 1'b0;
	sto = 1'b0;
	rd  = 1'b0;
	wr  = 1'b0;
	ack = 1'b0;
	iack = 1'b0;
end // initial

// tasks
task start;
	input [7:0] din; // {slave_addr[7:1], RW}
begin
	sta  = 1'b1;  // start
	wr   = 1'b1;  // write
	txr  = din;
	@(posedge byte_done);
	sta  = 1'b0;
	wr   = 1'b0;
end
endtask

task byte;
	input [7:0] din;
	input rw;
	input nack;
	output [7:0] dout;
begin
	wr   = ~rw;
	rd   =  rw;
	ack  = nack;
	txr  = din;

	@(posedge byte_done);
	wr  = 1'b0;
	rd  = 1'b0;
	ack = 1'b0;
	dout = rxr;
end
endtask

task stop;
	input [7:0] din;
	input rw;
	input nack;
	output [7:0] dout;
begin
	sto  = 1'b1;
	wr   = ~rw;
	rd   =  rw;
	ack  = nack;
	txr  = din;
	@(posedge byte_done);
	sto  = 1'b0;
	wr   = 1'b0;
	rd   = 1'b0;
	ack  = 1'b0;
	dout = rxr ;
end
endtask



endmodule
