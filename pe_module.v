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
// add cin - if mode bit - so we could check flag once
module pe_module(clk_i,rst_ni,a_i,b_i,c_i,start_i,mode_bit_i,a_o,b_o,res_o,overflow_o);//module ports
//-----------------------------ports----------------------------------------------//
input clk_i, rst_ni,a_i,b_i,start_i,mode_bit_i,c_i; // define inputs 
output a_o,b_o,res_o,overflow_o; // define outputs
//----------------------------parameters-----------------------------------------//
parameter DATA_WIDTH = 8; // parameter for data
parameter BUS_WIDTH = 16; // parameter for data
//----------------------------variables------------------------------------------//
wire clk_i, rst_ni,start_i,mode_bit_i; // define clk and rst
wire signed [DATA_WIDTH-1:0] a_i ,b_i; // value inputs
wire signed [BUS_WIDTH-1:0] c_i; // value inputs
reg  signed [DATA_WIDTH-1:0] a_o ,b_o; // value to move on to the next pe
reg  signed [BUS_WIDTH-1:0] res_o; // result of matrix index
reg overflowBit; // overflow bit out
wire [BUS_WIDTH-1:0] resultMul,resultCalc;
reg overflow_o;
reg firstAcc;

//----------------------------assign result comb----------------------------------------//
assign resultMul = a_i * b_i + (mode_bit_i && ~firstAcc ? c_i: 0);
assign resultCalc = resultMul + res_o;

//----------------------------always block---------------------------------------------//
always @(posedge clk_i or negedge rst_ni) // wake in rising edge of clock or falling edge of reset
begin : multiply_and_acc // start and init if needed
  if(~rst_ni) // in negative edge 
    begin
      a_o           <=  {(DATA_WIDTH){1'b0}}; // initialize A out
      b_o           <=  {(DATA_WIDTH){1'b0}}; // initialize B out
      res_o         <=  {(BUS_WIDTH){1'b0}}; // initialize result
	    overflow_o    <=  1'b0; // init overflow
	    firstAcc      <=  1'b0;
    end
  else if(!start_i) // if start_i == 0
    begin 
      a_o           <=  {(DATA_WIDTH){1'b0}}; // initialize A out
      b_o           <=  {(DATA_WIDTH){1'b0}}; // initialize B out
      res_o         <=  {(BUS_WIDTH){1'b0}}; // initialize result 
	    overflow_o    <=  1'b0; // init overflow
	    firstAcc      <=  1'b0;
    end
  else
    begin  
        {overflowBit,res_o}  <= resultCalc; // multiple the argument and add to result and overflow bit
	    overflow_o         <= (res_o[BUS_WIDTH-1] == resultMul[BUS_WIDTH-1]) && (resultMul[BUS_WIDTH-1]!=resultCalc[BUS_WIDTH-1]);  
	    a_o         	   <= a_i; // move A to next pe
        b_o         	   <= b_i; // move B to next pe
	    firstAcc           <= 1'b1;
    end
end
endmodule
