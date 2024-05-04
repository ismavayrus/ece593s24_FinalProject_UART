vlib work.top
vlog uart_tb.sv -lint
vlog uart_top.sv -lint
vlog uart_single.sv -lint
vsim work.tb_top 
run -all