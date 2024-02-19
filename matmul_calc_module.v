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
,start_i,data_a_i,data_b_i,data_c_i,mode_i,
data_o,address_o,address_a_o,address_b_o,
address_c_o,flags_o,finish_mul_o,enable_w_o);
//-------------------ports----------------------------------------------//
input  clk_i,rst_ni,start_i,mode_i; // clock , reset , start bit from control , mode bit : if to add prev c
input  n_dim_i,k_dim_i,m_dim_i; // matrix A is NxK , matrix B KxM
input  data_c_i,data_b_i,data_a_i;
output finish_mul_o,enable_w_o; // output matrix is actually long matrix 
output data_o;
output address_o,address_a_o,address_b_o,address_c_o;
output flags_o;
//-----------------parameters-----------------------------------------
parameter DATA_WIDTH = 8; // data width
parameter BUS_WIDTH = 16; // bus width
parameter ADDR_WIDTH = 32; // addr width
localparam MAX_DIM = BUS_WIDTH/DATA_WIDTH; // max dim of the matrix
localparam  [4:0]   OPERAND_A = 5'b00100,
				    OPERAND_B = 5'b01000,
					OPERAND_C = 5'b10000;
//-----------------variables------------------------------------------
wire clk_i,rst_ni,start_i,mode_i;// clock , reset , start bit from control
wire [1:0] n_dim_i,k_dim_i,m_dim_i; // matrix A is NxK , matrix B KxM
wire signed [(MAX_DIM*MAX_DIM*DATA_WIDTH)-1:0] a_matrix; // this matrix is actually  long register
reg signed [(MAX_DIM*MAX_DIM*DATA_WIDTH)-1:0] a_matrix_local; // this matrix is actually  long register
wire signed [(MAX_DIM*MAX_DIM*DATA_WIDTH)-1:0] b_matrix; // this matrix is actually  long register
reg signed [(MAX_DIM*MAX_DIM*DATA_WIDTH)-1:0] b_matrix_local; // this matrix is actually  long register
reg [$clog2(MAX_DIM)-1:0] addr_log;
reg [2*$clog2(MAX_DIM)-1:0] addr_log_c;
wire signed [(MAX_DIM*MAX_DIM*BUS_WIDTH)-1:0] c_bias; // output matrix is actually long matrix
reg  signed [(MAX_DIM*MAX_DIM*BUS_WIDTH)-1:0] c_bias_local; // output matrix is actually long matrix
wire [(MAX_DIM*MAX_DIM) -1:0]  flags_local; // flags for overflow
wire signed [BUS_WIDTH-1:0] data_a_i,data_b_i,data_c_i;
reg [ADDR_WIDTH-1:0] address_o;
wire [ADDR_WIDTH-1:0]  address_a_o,address_b_o,address_c_o;
reg signed [BUS_WIDTH-1:0] data_o;
reg enable_w_o;
reg finish_mul_o; // signals to enable write to sp and assert we ended the matmul
wire finishMulWire;
reg  finishWrite; // local variable for finishMulWire from the inside module
wire signed [(MAX_DIM*MAX_DIM*BUS_WIDTH)-1:0] cMatrixWire,cMatrixWireBias; // output matrix is actually long matrix
wire [MAX_DIM*MAX_DIM-1:0] flags_o;
reg [MAX_DIM*MAX_DIM -1:0] index_byte;
reg overflow_bit,overflow_a_b_bit,overflow_c_bit;

//-----------------------------matmul unit-----------------------------------//
matrix_multiple_module #(.DATA_WIDTH(DATA_WIDTH),.BUS_WIDTH(BUS_WIDTH)) U_matmul(
   .clk_i      (clk_i), // clk
   .rst_ni     (rst_ni),// reset
   .n_dim_i    (n_dim_i), // n dim of the matrix
   .k_dim_i    (k_dim_i), // k dim of the matrix
   .m_dim_i    (m_dim_i), // m dim of the matrix
   .start_i    (start_i), // start bit from the control
   .a_matrix_i (a_matrix), // matrix a as long vector - input
   .b_matrix_i (b_matrix), // matrix b as long vector - input
   .c_matrix_o (cMatrixWire), // // matrix c as long vector - output
   .flags_o    (flags_local), // flags for overflow
   .finish_mul_o (finishMulWire), // write to start to de assert
   .finish_write_i(finishWrite)
); 
//---------------------------get a,b matrices----------------------------------//
genvar index_mat,index_mat_c; // b variable
generate  // grenerate the block
		assign address_a_o[4:0] = OPERAND_A;
		assign address_a_o[5+$clog2(MAX_DIM)-1:5] = 0;
		assign address_b_o[4:0] = OPERAND_B;
		assign address_b_o[5+$clog2(MAX_DIM)-1:5] = 0;
		assign address_b_o[ADDR_WIDTH-1:5+$clog2(MAX_DIM)] = 0;
		assign address_a_o[ADDR_WIDTH-1:5+$clog2(MAX_DIM)] = 0;
	for(index_mat = 0;index_mat < MAX_DIM;index_mat = index_mat+1)
		begin
			assign a_matrix[(index_mat+1)*BUS_WIDTH-1-:BUS_WIDTH] = a_matrix_local[(index_mat+1)*BUS_WIDTH-1-:BUS_WIDTH];
			assign b_matrix[(index_mat+1)*BUS_WIDTH-1-:BUS_WIDTH] = b_matrix_local[(index_mat+1)*BUS_WIDTH-1-:BUS_WIDTH];		
		end
endgenerate


always@(posedge clk_i or negedge rst_ni)
	begin:get_data_a_b
		if(~rst_ni)
			begin
				a_matrix_local   <= 0;
				b_matrix_local   <= 0;
				addr_log 		 <= 0;
				overflow_a_b_bit <= 0;
			end
		else
			begin
				a_matrix_local[(addr_log+1)*MAX_DIM*DATA_WIDTH-1-:BUS_WIDTH] <= data_a_i;
				b_matrix_local[(addr_log+1)*MAX_DIM*DATA_WIDTH-1-:BUS_WIDTH] <= data_b_i;
				if(addr_log == MAX_DIM-1) addr_log<=0;
				else {overflow_a_b_bit,addr_log} <= addr_log + 1;	
					
			end
	end
//---------------------------get c bias----------------------------------//
generate  // grenerate the block
	for(index_mat_c = 0;index_mat_c < MAX_DIM*MAX_DIM;index_mat_c = index_mat_c + 1)
		begin
			assign address_c_o[4:0] = OPERAND_C;
			assign address_c_o[5+2*$clog2(MAX_DIM)-1:5] = 0;
			assign address_c_o[ADDR_WIDTH-1:5+2*$clog2(MAX_DIM)] = 0;
			assign c_bias[(index_mat_c+1)*BUS_WIDTH-1-:BUS_WIDTH] = c_bias_local[(index_mat_c+1)*BUS_WIDTH-1-:BUS_WIDTH];
		end
endgenerate

always@(posedge clk_i or negedge rst_ni)
	begin:get_data_c
		if(~rst_ni)
			begin
				c_bias_local <= 0;
				addr_log_c   <= 0;
				overflow_c_bit <= 0;
			end
		else
			begin
				c_bias_local[(addr_log_c+1)*BUS_WIDTH-1-:BUS_WIDTH] <= mode_i ? data_c_i : {(BUS_WIDTH){1'b0}};
				if(addr_log_c == MAX_DIM*MAX_DIM-1) addr_log_c <= 0;
				else {overflow_c_bit,addr_log_c} <= addr_log_c + 1;
			end
	end
//--------------------------write data---------------------------------//

always @(posedge clk_i or negedge rst_ni)// sensitivity list
	begin:write_out_matmul
		if(~rst_ni)
			begin
				data_o       <= {(BUS_WIDTH){1'b0}};			
				finishWrite  <= 1'b0;	
				index_byte   <= {(MAX_DIM*MAX_DIM){1'b0}};		
				overflow_bit <= 0;
				enable_w_o   <= 0;
				finish_mul_o <= 1'b0;
			end
		else if(finishMulWire && index_byte < MAX_DIM*MAX_DIM) //if we writing and in strobe and enabled
			begin
				address_o[4:0] 					<= OPERAND_C;
				address_o[5+2*$clog2(MAX_DIM)-1:5] <= index_byte;
				data_o     						<= cMatrixWireBias[BUS_WIDTH*(index_byte+1)-1-:BUS_WIDTH];
				enable_w_o 						<= 1'b1;
				{overflow_bit,index_byte} <= index_byte + 1;
			end
		else if(finishMulWire && index_byte == MAX_DIM*MAX_DIM)
			begin
				enable_w_o   <= 1'b0;
				finish_mul_o <= 1'b1;
				data_o       <= {(BUS_WIDTH){1'bz}};
				finishWrite  <= 1'b1;	
				index_byte   <= {(MAX_DIM*MAX_DIM){1'b0}};
			end
		else 
			begin
				enable_w_o   <= 1'b0;
				finish_mul_o <= 1'b0;
				finishWrite  <= 1'b0;
				data_o       <= {(BUS_WIDTH){1'bz}};
				address_o 	 <= {(ADDR_WIDTH){1'bz}};
			end
	end



assign flags_o = {{(BUS_WIDTH-MAX_DIM*MAX_DIM){1'b0}},flags_local};
assign 	cMatrixWireBias = cMatrixWire + c_bias;

endmodule