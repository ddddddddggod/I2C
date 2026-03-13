quit -sim
vlib work
vmap work work


vlog +incdir+../rtl +incdir+../tb ../tb/i2c_master/i2c_master_bit_ctrl.v
vlog +incdir+../rtl +incdir+../tb ../tb/i2c_master/i2c_master_byte_ctrl.v
vlog +incdir+../rtl +incdir+../tb ../tb/i2c_master/i2c_master_top.v
vlog +incdir+../rtl +incdir+../tb ../rtl/ass_i2c_slave.v
vlog +incdir+../rtl +incdir+../tb ../rtl/ass_i2c_slave_rx_ctrl.v
vlog +incdir+../rtl +incdir+../tb ../rtl/ass_i2c_slave_rx_pkt_ctrl.v
vlog +incdir+../rtl +incdir+../tb ../rtl/ass_i2c_slave_rx_deserializer.v
vlog +incdir+../rtl +incdir+../tb ../rtl/ass_i2c_slave_bit_counter.v
vlog +incdir+../rtl +incdir+../tb ../rtl/ass_i2c_slave_rf.v
vlog +incdir+../rtl +incdir+../tb ../rtl/ass_i2c_slave_rx.v
vlog +incdir+../rtl +incdir+../tb ../rtl/ass_i2c_slave_rx_sync.v
vlog +incdir+../rtl +incdir+../tb ../tb/tb_rx.v

vsim -voptargs=+acc work.tb_rx


add wave /tb_rx/dut/* 
add wave sim:/tb_rx/dut/u_rx/u_sync/scl_in
add wave sim:/tb_rx/dut/u_rx/u_sync/sda_in
add wave sim:/tb_rx/dut/u_rx/u_sync/start_det
add wave sim:/tb_rx/dut/u_rx/u_ctrl/stop_det
add wave sim:/tb_rx/dut/u_rx/u_ctrl/state
add wave sim:/tb_rx/dut/u_rx/u_pkt_ctrl/pkt_state
add wave sim:/tb_rx/dut/u_rx/u_ctrl/shift_en
add wave sim:/tb_rx/dut/u_rx/u_ctrl/first_byte
add wave sim:/tb_rx/dut/u_rx/u_ctrl/count_clr
add wave sim:/tb_rx/dut/u_rx/u_ctrl/count_done
add wave sim:/tb_rx/dut/u_rx/u_ctrl/rx_done
add wave sim:/tb_rx/dut/u_rx/u_ctrl/init
add wave sim:/tb_rx/dut/u_rx/u_ctrl/rdy
add wave sim:/tb_rx/dut/u_rx/u_ctrl/request
add wave sim:/tb_rx/dut/u_rx/u_pkt_ctrl/load_addr
add wave sim:/tb_rx/dut/u_rx/u_pkt_ctrl/we
add wave sim:/tb_rx/dut/u_rx/u_pkt_ctrl/load_data



run 600us;