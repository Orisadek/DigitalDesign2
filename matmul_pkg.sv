//
// Verilog Module Ori_Alon_Lab_2_copy_lib.matmul_calc_pkg
//
// Created:
//          by - vain.UNKNOWN (TOMER)
//          at - 10:15:02 02/18/2024
//
// using Mentor Graphics HDL Designer(TM) 2019.2 (Build 5)
//

package matmul_pkg;
	// DUT Params
  parameter int unsigned DATA_WIDTH = 16; // data width
  parameter int unsigned BUS_WIDTH = 64; // bus width
  parameter int unsigned ADDR_WIDTH = 32; // address width
  localparam unsigned    MAX_DIM = BUS_WIDTH/DATA_WIDTH;
  parameter int unsigned SP_NTARGETS = 4;
 
  typedef logic [DATA_WIDTH-1:0] matA [MAX_DIM-1:0][MAX_DIM-1:0];
  typedef logic [DATA_WIDTH-1:0] matB [MAX_DIM-1:0][MAX_DIM-1:0];
  typedef logic [BUS_WIDTH-1:0]  matc [MAX_DIM-1:0][MAX_DIM-1:0];
  
  
	// TB Params
  localparam int unsigned CLK_NS = 10;
	localparam int unsigned RST_CYC = 3;

endpackage
