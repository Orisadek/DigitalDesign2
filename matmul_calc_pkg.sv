//
// Verilog Module Ori_Alon_Lab_2_copy_lib.matmul_calc_pkg
//
// Created:
//          by - vain.UNKNOWN (TOMER)
//          at - 10:15:02 02/18/2024
//
// using Mentor Graphics HDL Designer(TM) 2019.2 (Build 5)
//

package matmul_calc_pkg;
	// DUT Params
	parameter int unsigned DATA_WIDTH = 32; // data width
  parameter int unsigned BUS_WIDTH = 64; // bus width
  parameter int unsigned ADDR_WIDTH = 32; // address width
  localparam unsigned    MAX_DIM = BUS_WIDTH/DATA_WIDTH;
 	parameter int unsigned N = 4; // the rows on matrix A
  parameter int unsigned K = 2; // the colms of matrix A and the Rows of matrix B
  parameter int unsigned M = 1; // the colms of matrix B
  
  typedef logic [DATA_WIDTH-1:0] matA [N-1:0][K-1:0];
  typedef logic [DATA_WIDTH-1:0] matB [K-1:0][M-1:0];
  typedef logic [BUS_WIDTH-1:0]  matc [N-1:0][K-1:0];
  
  
	// TB Params
	localparam time CLK_NS = 10ns;
	localparam int unsigned RST_CYC = 3;

endpackage
