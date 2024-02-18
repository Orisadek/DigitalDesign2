//
// Test Bench Module Ori_Alon_Lab_1_lib.matmul_calc_module_tester.matmul_calc_module_tester
//
// Created:
//          by - orisad.UNKNOWN (TOMER)
//          at - 00:55:19 02/ 1/2024
//
// Generated by Mentor Graphics' HDL Designer(TM) 2019.2 (Build 5)
//
`resetall
`timescale 1ns/10ps
module matmul_calc_module_tester (clk_i,
                                  rst_ni,
                                  n_dim_i,
                                  k_dim_i,
                                  m_dim_i,
                                  start_i,
                                  a_matrix_i,
                                  b_matrix_i,
                                  c_bias_i,
                                  mode_i,
                                  c_matrix_o,
                                  flags_o,
                                  finish_mul_o,
                                  enable_w_o
                                 );

// Local declarations

parameter DATA_WIDTH = 8;
parameter BUS_WIDTH = 16;
localparam MAX_DIM = BUS_WIDTH/DATA_WIDTH; // max dim of the matrix

output clk_i;
output rst_ni;
output n_dim_i;
output k_dim_i;
output m_dim_i;
output start_i;
output a_matrix_i;
output b_matrix_i;
output c_bias_i;
output mode_i;
input  c_matrix_o;
input  flags_o;
input  finish_mul_o;
input  enable_w_o;


reg clk_i;
reg rst_ni;
reg [2:0] n_dim_i;
reg [2:0] k_dim_i;
reg [2:0] m_dim_i;
reg start_i;
reg  [(MAX_DIM*MAX_DIM*DATA_WIDTH)-1:0] a_matrix_i;
reg  [(MAX_DIM*MAX_DIM*DATA_WIDTH)-1:0] b_matrix_i;
reg  [(MAX_DIM*MAX_DIM*2*(DATA_WIDTH))-1:0] c_bias_i;
reg  mode_i;
wire [(MAX_DIM*MAX_DIM*2*(DATA_WIDTH))-1:0] c_matrix_o;
wire [(MAX_DIM*MAX_DIM) -1:0] flags_o;
wire finish_mul_o;
wire enable_w_o;

reg [DATA_WIDTH-1:0] val_a1,val_a2,val_a3,val_a4;
reg [DATA_WIDTH-1:0] val_b1,val_b2,val_b3,val_b4;

initial begin: setup_clk
  clk_i = 1'b0;
  forever #1 clk_i = ~clk_i;
end

initial begin: setup_rst
  rst_ni = 1'b0;
  #10 rst_ni = 1'b1;
end

initial begin: mode_bit
  mode_i = 1'b0;
  c_bias_i = 0;
end

initial begin: setup_matrices
  // wait (rst_ni == 1'b1);
   #11
	n_dim_i = 2;
	k_dim_i = 2;
	m_dim_i = 2;
	val_a1=2;
	val_a2=3;
	val_a3=4;
	val_a4=5;
	
	val_b1=1;
	val_b2=3;
	val_b3=1;
	val_b4=10;
	a_matrix_i = {val_a1,val_a2,val_a3,val_a4};
	b_matrix_i = {val_b1,val_b2,val_b3,val_b4};

end

initial begin: setup_start_i
  start_i = 1'b0;
//  wait (rst_ni == 1'b1);
  #15 start_i = 1'b1;
	
end


endmodule // matmul_calc_module_tester


