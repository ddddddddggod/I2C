
`timescale 1ns / 1ps

module tb_rx ();

//******************************************************************
// Clock & Reset
//******************************************************************

reg clk;
reg reset_n;

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
    #50; 
    $display("\n==================================================");
    $display("       I2C SLAVE SIMULATION START");
    $display("==================================================");

    // ---------------------------------------------------------
    // 1. Write Data (Burst Write)
    // ---------------------------------------------------------
    $display("\n[STEP 1] Burst Write: Addr 0x0A -> F5, FB, 77, 88");
    u_i2c_master_top.start({dev_adr, 1'b0}         ); 
    u_i2c_master_top.byte (8'h0a, 1'b0, 1'b0, rxr  ); // Reg Address
    u_i2c_master_top.byte (8'hf5, 1'b0, 1'b0, rxr  ); // Data to 0x0A
    u_i2c_master_top.byte (8'hfb, 1'b0, 1'b0, rxr  ); // Data to 0x0B
    u_i2c_master_top.byte (8'h77, 1'b0, 1'b0, rxr  ); // Data to 0x0C
    u_i2c_master_top.stop (8'h88, 1'b0, 1'b0, rxr  ); // Data to 0x0D & Stop

    #10;
    if (dut.u_mem_buf.mem[8'h0a] === 8'hf5) $display("[PASS] Memory Write 0x0A: %h", dut.u_mem_buf.mem[8'h0a]);
    else $display("[FAIL] Memory Write 0x0A: Expected F5, Got %h", dut.u_mem_buf.mem[8'h0a]);

    // ---------------------------------------------------------
    // 2. Set start address to read as 0xA
    // ---------------------------------------------------------
    #50; 
    $display("\n[STEP 2] Setting Address to 0x0A for Read Operation");
    u_i2c_master_top.start({dev_adr, 1'b0}         ); 
    u_i2c_master_top.stop (8'h0a, 1'b0, 1'b0, rxr  ); 

    // ---------------------------------------------------------
    // 3. Read Data (Compare with Step 1)
    // ---------------------------------------------------------
    $display("\n[STEP 3] Read Data: Reading back from 0x0A...");
    u_i2c_master_top.start({dev_adr, 1'b1}         ); 
    u_i2c_master_top.byte (8'h00, 1'b1, 1'b0, rdata); // Read 1st byte (Expected F5)
    
    if (rdata === 8'hf5) $display("[PASS] I2C Read 1st (0x0A): %h", rdata);
    else                 $display("[FAIL] I2C Read 1st (0x0A): Expected F5, Got %h", rdata);

    u_i2c_master_top.stop (8'h00, 1'b1, 1'b1, rdata); // Read 2nd byte (Expected FB)
    
    if (rdata === 8'hfb) $display("[PASS] I2C Read 2nd (0x0B): %h", rdata);
    else                 $display("[FAIL] I2C Read 2nd (0x0B): Expected FB, Got %h", rdata);

    // ---------------------------------------------------------
    // 4. Write Again (0x02 -> 55, AA)
    // ---------------------------------------------------------
    $display("\n[STEP 4] Write Again: Addr 0x02 -> 55, AA");
    u_i2c_master_top.start({dev_adr, 1'b0}         ); 
    u_i2c_master_top.byte (8'h02, 1'b0, 1'b0, rxr  ); 
    u_i2c_master_top.byte (8'h55, 1'b0, 1'b0, rxr  ); 
    u_i2c_master_top.stop (8'haa, 1'b0, 1'b0, rxr  ); 

    #10;
    if (dut.u_mem_buf.mem[8'h02] === 8'h55) $display("[PASS] Memory Write 0x02: %h", dut.u_mem_buf.mem[8'h02]);
    else $display("[FAIL] Memory Write 0x02: Expected 55, Got %h", dut.u_mem_buf.mem[8'h02]);

    // ---------------------------------------------------------
    // 5. Final Write (0x05 -> 66, BB)
    // ---------------------------------------------------------
    #(100000)
    $display("\n[STEP 5] Final Write: Addr 0x05 -> 66, BB");
    u_i2c_master_top.start({dev_adr, 1'b0}         ); 
    u_i2c_master_top.byte (8'h05, 1'b0, 1'b0, rxr  ); 
    u_i2c_master_top.byte (8'h66, 1'b0, 1'b0, rxr  ); 
    u_i2c_master_top.stop (8'hbb, 1'b0, 1'b0, rxr  ); 

    #10;
    if (dut.u_mem_buf.mem[8'h05] === 8'h66) $display("[PASS] Memory Write 0x05: %h", dut.u_mem_buf.mem[8'h05]);
    else $display("[FAIL] Memory Write 0x05: Expected 66, Got %h", dut.u_mem_buf.mem[8'h05]);


// ---------------------------------------------------------
    // [STEP 6] Repeated START Verification
    // ---------------------------------------------------------
    #100;
    $display("\n[STEP 6] Repeated START: Set Addr 0x0C and Read immediately");
    u_i2c_master_top.start({dev_adr, 1'b0}); 
    u_i2c_master_top.byte (8'h0c, 1'b0, 1'b0, rxr); 
    u_i2c_master_top.start({dev_adr, 1'b1}); 
    u_i2c_master_top.stop (8'h00, 1'b1, 1'b1, rdata); 

    if (rdata === 8'h77) 
        $display("[PASS] Repeated START Read (0x0C): %h", rdata);
    else 
        $display("[FAIL] Repeated START Read (0x0C): Expected 77, Got %h", rdata);

end
//******************************************************************
// Desing under Testing:  I2C Slave RTL
//******************************************************************
ass_i2c_slave #(.device_address(dev_adr)) dut (

.clk  (clk    ),
.rstb (reset_n),

.scl  (scl    ),
.sda  (sda    )
);


endmodule
