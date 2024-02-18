//
// Verilog Module Ori_Alon_Lab_1_lib.matmul_calc_module
//
// Created:
//          by - orisad.UNKNOWN (TOMER)
//          at - 20:43:53 01/31/2024
//
// using Mentor Graphics HDL Designer(TM) 2019.2 (Build 5)
//

`resetall
`timescale 1ns/10ps
module matmul_calc_module(clk_i,rst_ni,n_dim_i,k_dim_i,m_dim_i
,start_i,a_matrix_i,b_matrix_i,c_bias_i,mode_i,c_matrix_o,flags_o,finish_mul_o,enable_w_o);
//-------------------ports----------------------------------------------
input  clk_i,rst_ni,start_i,mode_i; // clock , reset , start bit from control , mode bit : if to add prev c
input  a_matrix_i,b_matrix_i,c_bias_i; // the matrices are actually two long registers
input  n_dim_i,k_dim_i,m_dim_i; // matrix A is NxK , matrix B KxM
output c_matrix_o,flags_o;
output finish_mul_o,enable_w_o,data_flags; // output matrix is actually long matrix 
//-----------------parameters-----------------------------------------
parameter DATA_WIDTH = 8; // data width
parameter BUS_WIDTH = 16; // bus width
localparam MAX_DIM = BUS_WIDTH/DATA_WIDTH; // max dim of the matrix
//-----------------variables------------------------------------------
wire clk_i,rst_ni,start_i,mode_i;// clock , reset , start bit from control
wire [2:0] n_dim_i,k_dim_i,m_dim_i; // matrix A is NxK , matrix B KxM
wire signed [(MAX_DIM*MAX_DIM*DATA_WIDTH)-1:0] a_matrix_i; // this matrix is actually  long register
wire signed [(MAX_DIM*MAX_DIM*DATA_WIDTH)-1:0] b_matrix_i; // this matrix is actually  long register
wire signed [(MAX_DIM*MAX_DIM*2*(DATA_WIDTH))-1:0] c_bias_i; // output matrix is actually long matrix
reg signed  [(MAX_DIM*MAX_DIM*2*(DATA_WIDTH))-1:0] c_matrix_o; // output matrix is actually long matrix
wire [(MAX_DIM*MAX_DIM) -1:0]  flags_o; // flags for overflow
reg enable_w_o;
reg finish_mul_o; // signals to enable write to sp and assert we ended the matmul
wire finishMulWire; // local variable for finishMulWire from the inside module
wire signed [(MAX_DIM*MAX_DIM*2*(DATA_WIDTH))-1:0] cMatrixWire; // output matrix is actually long matrix

//-----------------------------matmul unit-----------------------------------//
matrix_multiple_module #(.DATA_WIDTH(DATA_WIDTH),.BUS_WIDTH(BUS_WIDTH)) U_matmul(
   .clk_i      (clk_i), // clk
   .rst_ni     (rst_ni),// reset
   .n_dim_i    (n_dim_i), // n dim of the matrix
   .k_dim_i    (k_dim_i), // k dim of the matrix
   .m_dim_i    (m_dim_i), // m dim of the matrix
   .start_i    (start_i), // start bit from the control
   .a_matrix_i (a_matrix_i), // matrix a as long vector - input
   .b_matrix_i (b_matrix_i), // matrix b as long vector - input
   .c_matrix_o (cMatrixWire), // // matrix c as long vector - output
   .flags_o    (flags_o), // flags for overflow
   .finish_mul_o (finishMulWire) // write to start to de assert
); 
always @(negedge rst_ni or posedge clk_i)
	begin : enable_w_finish
		if(~rst_ni)
			begin
				c_matrix_o   <= {(MAX_DIM*MAX_DIM*2*(DATA_WIDTH)){1'b0}}; // check if return with bias c or without
				enable_w_o   <= 1'b0; // disable write to sp
				finish_mul_o <= 1'b0; // do keep the value of start as is
			end 
		else if(finishMulWire)
			begin
				c_matrix_o   <= cMatrixWire +( mode_i ?  c_bias_i : 0); // check if return with bias c or without
				enable_w_o   <= 1'b1; // enable write to sp
				finish_mul_o <= 1'b1; // signal to change start bit to 0
			end
		else
			begin
				c_matrix_o   <= {(MAX_DIM*MAX_DIM*2*(DATA_WIDTH)){1'b0}}; // check if return with bias c or without
				enable_w_o   <= 1'b0; // disable write to sp
				finish_mul_o <= 1'b0; // do keep the value of start as is
			end 
	end
endmodule
