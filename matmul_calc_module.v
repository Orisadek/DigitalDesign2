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
`define OPERAND_A 00100
`define OPERAND_B 01000
`define OPERAND_C 10000
module matmul_calc_module(clk_i,rst_ni,n_dim_i,k_dim_i,m_dim_i
,start_i,data_a_i,data_b_i,data_c_i,mode_i,read_target_i,write_target_i,
data_o,address_o,address_a_o,address_b_o,address_c_o,finish_mul_o,enable_w_o);
//-------------------ports----------------------------------------------//
input  clk_i,rst_ni,start_i,mode_i; // clock , reset , start bit from control , mode bit : if to add prev c
input  n_dim_i,k_dim_i,m_dim_i; // matrix A is NxK , matrix B KxM
output finish_mul_o,enable_w_o; // output matrix is actually long matrix 
//-----------------parameters-----------------------------------------
parameter DATA_WIDTH = 8; // data width
parameter BUS_WIDTH = 16; // bus width
parameter ADDR_WIDTH = 32; // addr width
localparam MAX_DIM = BUS_WIDTH/DATA_WIDTH; // max dim of the matrix
//-----------------variables------------------------------------------
wire clk_i,rst_ni,start_i,mode_i;// clock , reset , start bit from control
wire [2:0] n_dim_i,k_dim_i,m_dim_i; // matrix A is NxK , matrix B KxM
wire [2:0] read_target_i,write_target_i;
wire signed [(MAX_DIM*MAX_DIM*DATA_WIDTH)-1:0] a_matrix; // this matrix is actually  long register
wire signed [(MAX_DIM*MAX_DIM*DATA_WIDTH)-1:0] b_matrix; // this matrix is actually  long register
wire signed [(MAX_DIM*MAX_DIM*BUS_WIDTH)-1:0] c_bias; // output matrix is actually long matrix
wire [(MAX_DIM*MAX_DIM) -1:0]  flags_local; // flags for overflow
wire signed [BUS_WIDTH-1:0] data_a_i,data_b_i,data_c_i;
reg [ADDR_WIDTH-1:0] address_o,address_a_o,address_b_o,address_c_o;
reg signed [BUS_WIDTH-1:0] data_o;
reg enable_w_o;
reg finish_mul_o; // signals to enable write to sp and assert we ended the matmul
wire finishMulWire,finishWrite; // local variable for finishMulWire from the inside module
wire signed [(MAX_DIM*MAX_DIM*BUS_WIDTH)-1:0] cMatrixWire,cMatrixWireBias; // output matrix is actually long matrix

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
   .flags_o    (flags_local), // flags for overflow
   .finish_mul_o (finishMulWire) // write to start to de assert
   .finish_write_i(finishWrite)
); 
//---------------------------get a,b matrices----------------------------------//
genvar index_mat,index_mat_c; // b variable
generate  // grenerate the block
	for(index_mat = 0;index_mat<MAX_DIM;index_mat = index_mat+1)
		begin
			address_a_o[4:0] = OPERAND_A;
			address_a_o[5+:$clog2(MAX_DIM)] = index_mat;
			a_matrix[index_mat*MAX_DIM*DATA_WIDTH:+BUS_WIDTH] = data_a_i;
			address_b_o[4:0] = OPERAND_B;
			address_b_o[5+:$clog2(MAX_DIM)] = index_mat;
			b_matrix[index_mat*MAX_DIM*DATA_WIDTH:+BUS_WIDTH] = data_b_i;		
		end
endgenerate
//---------------------------get c bias----------------------------------//
generate  // grenerate the block
	for(index_mat_c = 0;index_mat_c < MAX_DIM*MAX_DIM;index_mat_c = index_mat_c + 1)
		begin
			if(mode_i)
				begin
					address_c_o[4:0] = OPERAND_C;
					address_c_o[5+:2*$clog2(MAX_DIM)] = index_mat_c;
					c_bias[index_mat_c*BUS_WIDTH:+BUS_WIDTH] = data_c_i;
				end
			else
				begin
					c_bias[index_mat_c*BUS_WIDTH:+BUS_WIDTH] = {(BUS_WIDTH){1'b0}};
				end		
		end
endgenerate
//--------------------------write data---------------------------------//
genvar b; // b variable
generate  // grenerate the block
	always @(posedge clk_i)// sensitivity list
		begin:write_out_matmul
			if(~rst)
				begin
					b = 0;
					data_o <= {(BUS_WIDTH){1'b0}};			
					finishWrite<=1'b0;			
				end
			else if(finishMulWire and b < MAX_DIM*MAX_DIM) //if we writing and in strobe and enabled
				begin
					address_o[4:0] = OPERAND_C;
					address_o[5+:2*$clog2(MAX_DIM)] = b;
					data_o     <= cMatrixWireBias[BUS_WIDTH*b-1:0];
					enable_w_o <= 1'b1;
					b = b + 1;
				end
			else if(finishMulWire and b == MAX_DIM*MAX_DIM)
				begin
					enable_w_o   <= 1'b0;
					finish_mul_o <= 1'b1;
					data_o       <= {(BUS_WIDTH){1'b0}};
					b = 0;
					finishWrite<=1'b1;	
				end
			else 
				begin
					enable_w_o   <= 1'b0;
					finish_mul_o <= 1'b0;
					data_o       <= {(BUS_WIDTH){1'bz}};
					address_o 	 <= {(ADDR_WIDTH){1'bz}};
					b = 0;
				end
	end
endgenerate

	
assign 	cMatrixWireBias = cMatrixWire + c_bias;