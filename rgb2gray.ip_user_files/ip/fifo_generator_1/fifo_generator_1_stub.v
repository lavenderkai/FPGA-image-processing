// Copyright 1986-2015 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2015.4 (win64) Build 1412921 Wed Nov 18 09:43:45 MST 2015
// Date        : Thu Nov 12 19:51:15 2020
// Host        : DESKTOP-2SF23LR running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               D:/Desktop/FPGA/vivado_prj/rgb2gray/rgb2gray.runs/fifo_generator_1_synth_1/fifo_generator_1_stub.v
// Design      : fifo_generator_1
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7z020clg400-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "fifo_generator_v13_0_1,Vivado 2015.4" *)
module fifo_generator_1(clk, srst, din, wr_en, rd_en, dout, full, empty)
/* synthesis syn_black_box black_box_pad_pin="clk,srst,din[23:0],wr_en,rd_en,dout[23:0],full,empty" */;
  input clk;
  input srst;
  input [23:0]din;
  input wr_en;
  input rd_en;
  output [23:0]dout;
  output full;
  output empty;
endmodule
