######################################################################
#
# File name : rgb2gray_tb_simulate.do
# Created on: Thu Nov 12 20:25:08 +0800 2020
#
# Auto generated by Vivado for 'behavioral' simulation
#
######################################################################
vsim -voptargs="+acc" -t 1ps -L unisims_ver -L unimacro_ver -L secureip -L xil_defaultlib -lib xil_defaultlib xil_defaultlib.rgb2gray_tb xil_defaultlib.glbl

do {rgb2gray_tb_wave.do}

view wave
view structure
view signals

do {rgb2gray_tb.udo}

run 1000ns
