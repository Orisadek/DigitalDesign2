//
// Verilog Module Ori_Alon_Lab_1_lib.pe_module
//
// Created:
//          by - orisad.UNKNOWN (TOMER)
//          at - 20:17:33 01/18/2024
//
// using Mentor Graphics HDL Designer(TM) 2019.2 (Build 5)
//

`resetall
`timescale 1ns/10ps
module pe_module(clk_i,rst_ni,a_i,b_i,start_i,a_o,b_o,res_o,overflow_o);//module ports
input clk_i, rst_ni,a_i,b_i,start_i; // define inputs 
output a_o,b_o,res_o,overflow_o; // define outputs
parameter DATA_WIDTH = 8; // parameter for data
parameter BUS_WIDTH = 16; // parameter for data
wire clk_i, rst_ni,start_i; // define clk and rst
wire signed [DATA_WIDTH-1:0] a_i ,b_i; // value inputs
reg  signed [DATA_WIDTH-1:0] a_o ,b_o; // value to move on to the next pe
reg  signed [BUS_WIDTH-1:0] res_o; // result of matrix index
reg overflow_o; // overflow bit out

always @(posedge clk_i or negedge rst_ni) // wake in rising edge of clock or falling edge of reset
begin : multiply_and_acc // start and init if needed
  if(~rst_ni) // in negative edge 
    begin
      a_o           <=  {(DATA_WIDTH){1'b0}}; // initialize A out
      b_o           <=  {(DATA_WIDTH){1'b0}}; // initialize B out
      res_o         <=  {(BUS_WIDTH){1'b0}}; // initialize result
	  overflow_o    <=  1'b0; // init overflow
    end
  else if(!start_i) // if start_i == 0
    begin 
      a_o           <=  {(DATA_WIDTH){1'b0}}; // initialize A out
      b_o           <=  {(DATA_WIDTH){1'b0}}; // initialize B out
      res_o         <=  {(BUS_WIDTH){1'b0}}; // initialize result 
	  overflow_o    <=  1'b0; // init overflow
    end
  else
    begin  
      {overflow_o,res_o}  <= res_o + a_i * b_i; // multiple the argument and add to result and overflow bit
      a_o         	      <= a_i; // move A to next pe
      b_o         		  <= b_i; // move B to next pe
    end
end
endmodule
