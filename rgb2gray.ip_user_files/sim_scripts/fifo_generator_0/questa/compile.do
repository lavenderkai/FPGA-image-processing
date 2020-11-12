vlib work
vlib msim

vlib msim/xil_defaultlib

vmap xil_defaultlib msim/xil_defaultlib

vlog -work xil_defaultlib -64 \
"../../../ip/fifo_generator_0/fifo_generator_0_sim_netlist.v" \


vlog -work xil_defaultlib "glbl.v"

