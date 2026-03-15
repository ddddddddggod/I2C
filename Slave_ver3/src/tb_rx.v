
`timescale 1ns / 1ps

module tb_rx ();

//******************************************************************
// Clock & Reset
//******************************************************************

reg clk;
reg reset_n;
reg [7:0] period;     // hold

initial clk = 0;
always #5 clk = ~clk;

initial begin
	reset_n = 1'b0;
	repeat(10) @(negedge clk);
	reset_n = 1'b1;
end //


//******************************************************************
// I2C Master Model
//******************************************************************
i2c_master_top u_i2c_master_top (
  .clk     (clk    ),
  .reset_n (reset_n),
  .scl     (scl    ),
  .sda     (sda    )
);

pullup(sda);
pullup(scl);


//******************************************************************
// Run an I2C master model
//******************************************************************
parameter [6:0] dev_adr = 7'h74;

reg [7:0] rxr;
reg [7:0] rdata;
initial begin
    period = 8'd0;
    #50; // mem[10] = 8'h15, mem[11] = 8'h0b

    // Write Data
    $display("\n[STEP 1] Write: Addr 0x0A -> F5, FB, 77, 88");
    u_i2c_master_top.start({dev_adr, 1'b0}); // (start with write)
    u_i2c_master_top.byte (8'h0a, 1'b0, 1'b0, rxr); // (write addr)
    u_i2c_master_top.byte (8'hf5, 1'b0, 1'b0, rxr); // (write data)
    u_i2c_master_top.byte (8'hfb, 1'b0, 1'b0, rxr); // (write data)
    u_i2c_master_top.byte (8'h77, 1'b0, 1'b0, rxr); // (write data)
    u_i2c_master_top.stop (8'h88, 1'b0, 1'b0, rxr); // (write data and stop)

    #10;
    if (dut.u_mem_buf.mem[8'h0a] === 8'hf5) $display("[PASS] Memory Write 0x0A: %h", dut.u_mem_buf.mem[8'h0a]);
    else $display("[FAIL] Memory Write 0x0A: Expected F5, Got %h", dut.u_mem_buf.mem[8'h0a]);

    #50;  // Set start address to read as 0xA
    $display("\n[STEP 2] Setting Address to 0x0A for Read Operation");
    u_i2c_master_top.start({dev_adr, 1'b0});  // (start with write)
    u_i2c_master_top.stop (8'h0a, 1'b0, 1'b0, rxr);  // (write addr and stop)

    // Read Data
    $display("\n[STEP 3] Read Data: Reading back from 0x0A...");
    u_i2c_master_top.start({dev_adr, 1'b1}); // (start with read)
    u_i2c_master_top.byte (8'h00, 1'b1, 1'b0, rdata); // (read data and ack)
    if (rdata === 8'hf5) $display("[PASS] I2C Read 1st (0x0A): %h", rdata);
    else                 $display("[FAIL] I2C Read 1st (0x0A): Expected F5, Got %fh", rdata);
    u_i2c_master_top.stop (8'h00, 1'b1, 1'b1, rdata); // (read data and nack)
    if (rdata === 8'hfb) $display("[PASS] I2C Read 2nd (0x0B): %h", rdata);
    else                 $display("[FAIL] I2C Read 2nd (0x0B): Expected FB, Got %h", rdata);

    // write again ...
    $display("\n[STEP 4] Write Again: Addr 0x02 -> 55, AA");
    u_i2c_master_top.start({dev_adr, 1'b0}        );  // (start with write)
    u_i2c_master_top.byte (8'h02, 1'b0, 1'b0, rxr );  // (write addr)
    u_i2c_master_top.byte (8'h55, 1'b0, 1'b0, rxr );  // (write data)
    u_i2c_master_top.stop (8'haa, 1'b0, 1'b0, rxr );  // (write data and stop)
    #10;
    if (dut.u_mem_buf.mem[8'h02] === 8'h55) $display("[PASS] Memory Write 0x02: %h", dut.u_mem_buf.mem[8'h02]);
    else $display("[FAIL] Memory Write 0x02: Expected 55, Got %h", dut.u_mem_buf.mem[8'h02]);

    #(100000)
    $display("\n[STEP 5] Final Write: Addr 0x05 -> 66, BB");
    u_i2c_master_top.start({dev_adr, 1'b0}        );  // (start with write)
    u_i2c_master_top.byte (8'h05, 1'b0, 1'b0, rxr );  // (write addr)
    u_i2c_master_top.byte (8'h66, 1'b0, 1'b0, rxr );  // (write data)
    u_i2c_master_top.stop (8'hbb, 1'b0, 1'b0, rxr );  // (write data and stop)
    #10;
    if (dut.u_mem_buf.mem[8'h05] === 8'h66) $display("[PASS] Memory Write 0x05: %h", dut.u_mem_buf.mem[8'h05]);
    else $display("[FAIL] Memory Write 0x05: Expected 66, Got %h", dut.u_mem_buf.mem[8'h05]);


    //Repeated Start
    #100;
    $display("\n[STEP 6] Repeated START: Set Addr 0x0C and Read immediately");
    u_i2c_master_top.start({dev_adr, 1'b0});  //(start with write)
    u_i2c_master_top.byte (8'h0c, 1'b0, 1'b0, rxr); // (write addr)
    u_i2c_master_top.start({dev_adr, 1'b1});  // (start with read)
    u_i2c_master_top.stop (8'h00, 1'b1, 1'b1, rdata); // (read data and stop)

    if (rdata === 8'h77) $display("[PASS] Repeated START Read (0x0C): %h", rdata);
    else $display("[FAIL] Repeated START Read (0x0C): Expected 77, Got %h", rdata);

    // Zero-length Write :  right action => st_idle
    #100;
    $display("\n[STEP 7] Zero-length Write: Address only, No data");
    u_i2c_master_top.start({dev_adr, 1'b0}); 
    u_i2c_master_top.stop(8'h00, 1'b0, 1'b0, rxr); // (write no data)

    #50;
    $display("[CHECK] Testing if slave is ready for next transaction...");
    u_i2c_master_top.start({dev_adr, 1'b0});  //(start with write)
    u_i2c_master_top.byte (8'h20, 1'b0, 1'b0, rxr);  //(write addr)
    u_i2c_master_top.stop (8'h55, 1'b0, 1'b0, rxr);  //(write data and stop)
    if (dut.u_mem_buf.mem[8'h20] === 8'h55) $display("[PASS] Slave recovered and wrote 0x55 successfully");
    else $display("[FAIL] Slave hang after zero-length write");


    // Address NACK
    #100;
    $display("\n[STEP 8] Address NACK: Calling non-existent slave (0x33)");
    u_i2c_master_top.start({7'h33, 1'b0}); // (unknown address)
    u_i2c_master_top.byte (8'hFF, 1'b0, 1'b0, rxr); //(write addr)
    if (rxr[0] === 1'b1) $display("[PASS] Received NACK as expected for address 0x33"); //NACK
    else $display("[FAIL] No NACK received for non-existent address!");
    u_i2c_master_top.stop (8'h00, 1'b0, 1'b0, rxr); //(write data and stop)


    //Memory Boundry overrun
    #100;
    $display("\n[STEP 9] Boundary Test: Writing beyond 128 bytes (Addr 0x7E -> 4 bytes)");
    // available adddress range :  0x00 ~ 0x7F (7'h7F) 
    u_i2c_master_top.start({dev_adr, 1'b0});
    u_i2c_master_top.byte (8'h7E, 1'b0, 1'b0, rxr); 
    u_i2c_master_top.byte (8'hAA, 1'b0, 1'b0, rxr); 
    u_i2c_master_top.byte (8'hBB, 1'b0, 1'b0, rxr); 
    u_i2c_master_top.byte (8'hCC, 1'b0, 1'b0, rxr); 
    u_i2c_master_top.stop (8'hDD, 1'b0, 1'b0, rxr); 
    #100;
    // normal range
    $display("[CHECK] Verifying Memory Boundary handling...");
    if (dut.u_mem_buf.mem[8'h7E] === 8'hAA && dut.u_mem_buf.mem[8'h7F] === 8'hBB) $display("[PASS] Normal range 0x7E-0x7F written successfully.");
    else $display("[FAIL] Boundary write failed at 0x7E-0x7F.");
    // overflow checking
    if (dut.u_mem_buf.mem[8'h00] === 8'hCC) $display("[INFO] Memory Rollover detected: 0x80 wrapped to 0x00"); //1.memory rollover
    //else if (dut.u_mem_buf.mem[8'h80] === 8'hCC) $display("[INFO] Memory extended: Design handles more than 128 bytes"); //2.memory extend
    else $display("[INFO] Overrun data ignored: Design saturated at 0x7F"); //3.data ignore
end
//******************************************************************
// Desing under Testing:  I2C Slave RTL
//******************************************************************
ass_i2c_slave #(.device_address(dev_adr)) dut (

.clk  (clk    ),
.rstb (reset_n),
.scl  (scl    ),
.sda  (sda    ),
.period(period),
.overflow_stop_en(overflow_stop_en)
);


endmodule
