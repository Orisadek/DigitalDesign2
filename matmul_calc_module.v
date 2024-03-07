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
,data_a_i,data_b_i,data_c_i,start_i,mode_i,
data_o,address_o,flags_o,finish_mul_o,enable_w_o);
//-------------------ports----------------------------------------------//
input  clk_i,rst_ni,start_i,mode_i; // clock , reset , start bit from control , mode bit : if to add prev c
input  n_dim_i,k_dim_i,m_dim_i; // matrix A is NxK , matrix B KxM
input  data_a_i,data_b_i,data_c_i;
output finish_mul_o,enable_w_o; // output matrix is actually long matrix 
output data_o;
output address_o;
output flags_o;
//-----------------parameters-----------------------------------------//
parameter DATA_WIDTH = 8; // data width
parameter BUS_WIDTH = 16; // bus width
parameter ADDR_WIDTH = 32; // addr width
localparam MAX_DIM = BUS_WIDTH/DATA_WIDTH; // max dim of the matrix
localparam  [4:0]   OPERAND_A = 5'b00100,
				    OPERAND_B = 5'b01000,
					OPERAND_C = 5'b10000;
//-----------------variables------------------------------------------//
wire clk_i,rst_ni,start_i,mode_i;// clock , reset , start bit from control
wire [1:0] n_dim_i,k_dim_i,m_dim_i; // matrix A is NxK , matrix B KxM
wire signed [BUS_WIDTH-1:0] data_a_i,data_b_i,data_c_i;
wire signed [(MAX_DIM*MAX_DIM*DATA_WIDTH)-1:0] a_matrix; // this matrix is actually  long register
reg signed [(MAX_DIM*MAX_DIM*DATA_WIDTH)-1:0] a_matrix_local; // this matrix is actually  long register
wire signed [(MAX_DIM*MAX_DIM*DATA_WIDTH)-1:0] b_matrix; // this matrix is actually  long register
reg signed [(MAX_DIM*MAX_DIM*DATA_WIDTH)-1:0] b_matrix_local; // this matrix is actually  long register
reg [$clog2(MAX_DIM):0] addrLogA,addrLogB;
reg [2*$clog2(MAX_DIM):0] addrLogC;
wire signed [(MAX_DIM*MAX_DIM*BUS_WIDTH)-1:0] c_bias; // output matrix is actually long matrix
reg  signed [(MAX_DIM*MAX_DIM*BUS_WIDTH)-1:0] c_bias_local; // output matrix is actually long matrix
wire [(MAX_DIM*MAX_DIM) -1:0]  flagsLocal; // flags for overflow
reg [ADDR_WIDTH-1:0] address_o;
reg signed [BUS_WIDTH-1:0] data_o;
reg enable_w_o;
reg finish_mul_o; // signals to enable write to sp and assert we ended the matmul
wire finishMulWire;
reg  finishWrite; // local variable for finishMulWire from the inside module
wire signed [(MAX_DIM*MAX_DIM*BUS_WIDTH)-1:0] cMatrixWire; // output matrix is actually long matrix
wire [BUS_WIDTH-1:0] flags_o;
reg [2*$clog2(MAX_DIM):0] indexByte;
reg overflowBit;
wire startBit;
reg startBitA,startBitB,startBitC;
//-----------------------------matmul unit-----------------------------------//
matrix_multiple_module #(.DATA_WIDTH(DATA_WIDTH),.BUS_WIDTH(BUS_WIDTH)) U_matmul(
   .clk_i        (clk_i), // clk
   .rst_ni       (rst_ni),// reset
   .n_dim_i      (n_dim_i), // n dim of the matrix
   .k_dim_i      (k_dim_i), // k dim of the matrix
   .m_dim_i      (m_dim_i), // m dim of the matrix
   .start_i      (startBit), // start bit from the control
   .a_matrix_i   (a_matrix), // matrix a as long vector - input
   .b_matrix_i   (b_matrix), // matrix b as long vector - input
   .c_matrix_i   (c_bias),  // c bias matrix
   .mode_bit_i   (mode_i),  // mode bit - with add or without
   .c_matrix_o   (cMatrixWire), // // matrix c as long vector - output
   .flags_o      (flagsLocal), // flags for overflow
   .finish_mul_o (finishMulWire), // write to start to de assert
   .finish_write_i(finishWrite) // finish writing C to SP
); 


assign startBit = startBitA && startBitB && startBitC; // start matmul -after get A,B,C
	
//----------------------------------------get MatA----------------------------------------------------//
always@(posedge clk_i or negedge rst_ni) 
	begin:get_data_matA
		if(~rst_ni) // reset - init variables
			begin
				addrLogA       <= {($clog2(MAX_DIM)+1){1'b0}};
				startBitA      <= 1'b0;
				a_matrix_local <= {(MAX_DIM*MAX_DIM*DATA_WIDTH){1'b0}}; 
			end
		else
			begin
				if(start_i) // if start bit is up
					begin
						if(addrLogA == n_dim_i) // in the last read
							begin
								a_matrix_local[((addrLogA+1)*MAX_DIM*DATA_WIDTH-1)-:BUS_WIDTH] <= data_a_i;  // insert data in
								addrLogA  <= addrLogA + 1; // inc addr
								startBitA <= 1'b1; // finish to read A
							end
						else if (addrLogA < n_dim_i) // read to addr addrLogA
							begin
								a_matrix_local[((addrLogA+1)*MAX_DIM*DATA_WIDTH-1)-:BUS_WIDTH] <= data_a_i;  // insert data in
								addrLogA <= addrLogA + 1;  // inc addr
							end
					end						
				else // reset variables after start = 0
					begin // start bit = 0
						startBitA      <= 1'b0;
						addrLogA       <= 0;
						a_matrix_local <= 0;
					end
						
			end
	end

//----------------------------------------get MatB----------------------------------------------------//

always@(posedge clk_i or negedge rst_ni)
	begin:get_data_matB
		if(~rst_ni) // reset - init variables
			begin
				addrLogB       <= {($clog2(MAX_DIM)+1){1'b0}};
				startBitB      <= 1'b0;
				b_matrix_local <= {(MAX_DIM*MAX_DIM*DATA_WIDTH){1'b0}};
			end
		else
			begin
				if(start_i)// if start bit is up
					begin
						if(addrLogB == m_dim_i)// in the last read
							begin
								b_matrix_local[((addrLogB+1)*MAX_DIM*DATA_WIDTH-1)-:BUS_WIDTH] <= data_b_i;  // insert data in
								addrLogB <= addrLogB + 1;  // inc addr
								startBitB <= 1'b1;  // finish to read B
							end
						else if(addrLogB < m_dim_i) // read to addr addrLogB
							begin
								b_matrix_local[((addrLogB+1)*MAX_DIM*DATA_WIDTH-1)-:BUS_WIDTH] <= data_b_i;  // insert data in
								addrLogB <= addrLogB + 1; // inc addr
							end
					end						
				else
					begin // reset variables after start = 0
						startBitB      <= 1'b0;
						addrLogB       <= 0;
						b_matrix_local <= 0;
					end
						
			end
	end
	
//----------------------------------------get MatC----------------------------------------------------//

always@(posedge clk_i or negedge rst_ni)
	begin:get_data_matC
		if(~rst_ni) // reset - init variables
			begin
				addrLogC     <= {(2*$clog2(MAX_DIM)+1){1'b0}};
				startBitC    <= 1'b0;
				c_bias_local <= {(MAX_DIM*MAX_DIM*BUS_WIDTH){1'b0}};
			end
		else
			begin
				if(start_i) // if start bit is up
					begin
						if(addrLogC == (n_dim_i+1)*(m_dim_i+1)-1)// in the last read
							begin
								c_bias_local[((addrLogC+1)*BUS_WIDTH-1)-:BUS_WIDTH] <= data_c_i; // insert data in
								startBitC <= 1'b1; // finish to read C
								addrLogC <= addrLogC + 1;  // inc addr
							end
						else if(addrLogC < (n_dim_i+1)*(m_dim_i+1)-1) // read to addr addrLogC
							begin
								c_bias_local[((addrLogC+1)*BUS_WIDTH-1)-:BUS_WIDTH] <= data_c_i;  // insert data in
								addrLogC <= addrLogC + 1; // inc addr
							end
					end						
				else
					begin // reset variables after start = 0
						startBitC    <= 1'b0;
						addrLogC     <= 0;
						c_bias_local <= 0 ;
					end
						
			end
	end

//---------------------------assign a,b matrices----------------------------------//

genvar indexMat,indexMatCGen; // b variable
generate  // grenerate the block
		
	for(indexMat = 0;indexMat < MAX_DIM;indexMat = indexMat+1)
		begin
			assign a_matrix[(indexMat+1)*BUS_WIDTH-1-:BUS_WIDTH] = a_matrix_local[(indexMat+1)*BUS_WIDTH-1-:BUS_WIDTH];
			assign b_matrix[(indexMat+1)*BUS_WIDTH-1-:BUS_WIDTH] = b_matrix_local[(indexMat+1)*BUS_WIDTH-1-:BUS_WIDTH];		
		end
endgenerate

//---------------------------assign c bias----------------------------------//
generate  // grenerate the block
	for(indexMatCGen = 0;indexMatCGen < MAX_DIM*MAX_DIM;indexMatCGen = indexMatCGen + 1)
		begin
			assign c_bias[((indexMatCGen+1)*BUS_WIDTH-1)-:BUS_WIDTH] = c_bias_local[((indexMatCGen+1)*BUS_WIDTH-1)-:BUS_WIDTH];
		end
endgenerate

//--------------------------write data C ---------------------------------//

always @(posedge clk_i or negedge rst_ni)// sensitivity list
	begin:write_out_matmul
		if(~rst_ni)
			begin
				data_o       <= {(BUS_WIDTH){1'b0}};			
				finishWrite  <= 1'b0;	
				indexByte   <= {(2*$clog2(MAX_DIM)+1){1'b0}};	
				enable_w_o   <= 1'b0;
				finish_mul_o <= 1'b0;
				address_o 	 <= {(ADDR_WIDTH){1'b0}};
			end
		else if(finishMulWire && indexByte < MAX_DIM*MAX_DIM) //if we writing and in strobe and enabled
			begin
				address_o[4:0] 				       <= OPERAND_C;
				address_o[5+2*$clog2(MAX_DIM)-1:5] <= indexByte[2*$clog2(MAX_DIM)-1:0];
				data_o     						   <= cMatrixWire[BUS_WIDTH*(indexByte+1)-1-:BUS_WIDTH];
				enable_w_o 						   <= 1'b1;
				{overflowBit,indexByte} <= indexByte + 1;
			end
		else if(finishMulWire && indexByte == MAX_DIM*MAX_DIM)
			begin
				enable_w_o   <= 1'b0;
				finish_mul_o <= 1'b1;
				data_o       <= {(BUS_WIDTH){1'b0}};
				finishWrite  <= 1'b1;	
			end
		else 
			begin
				enable_w_o   <= 1'b0;
				finish_mul_o <= 1'b0;
				finishWrite  <= 1'b0;
				data_o       <= {(BUS_WIDTH){1'b0}};
				address_o 	 <= {(ADDR_WIDTH){1'b0}};
				indexByte   <= {(2*$clog2(MAX_DIM)+1){1'b0}};
			end
	end

assign flags_o = {{(BUS_WIDTH-MAX_DIM*MAX_DIM){1'b0}},flagsLocal};

endmodule

/*
State bit(s) 'address_o[31:7]' has/have a stuck-at-0 fault. - not needed values
State bit(s) 'address_o[3:0]' has/have a stuck-at-0 fault.  - OPERAND_C or zero , that okay
*/