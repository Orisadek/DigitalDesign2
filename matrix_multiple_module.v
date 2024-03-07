//
// Verilog Module Ori_Alon_Lab_1_lib.matmul_matrix_module
//
// Created:
//          by - orisad.UNKNOWN (TOMER)
//          at - 19:01:29 01/21/2024
//
// using Mentor Graphics HDL Designer(TM) 2019.2 (Build 5)
//

`resetall
`timescale 1ns/10ps
module matrix_multiple_module(clk_i,rst_ni,n_dim_i,k_dim_i,m_dim_i
,start_i,a_matrix_i,b_matrix_i,c_matrix_i,finish_write_i,mode_bit_i,c_matrix_o,flags_o,finish_mul_o);  // inputs
//-----------------------------ports----------------------------------------------//
input  clk_i,rst_ni,start_i,mode_bit_i; // clock , reset , start bit from control
input  a_matrix_i,b_matrix_i,c_matrix_i; // the matrices are actually two long registers
input  n_dim_i,k_dim_i,m_dim_i,finish_write_i; // matrix A is NxK , matrix B KxM
output c_matrix_o,flags_o,finish_mul_o; // output matrix is actually long matrix 
//----------------------------parameters-----------------------------------------//
parameter DATA_WIDTH = 8; // data width
parameter BUS_WIDTH = 16; // bus width
localparam MAX_DIM = BUS_WIDTH/DATA_WIDTH; // max dim of the matrix
localparam MATRIX_WORD = MAX_DIM*DATA_WIDTH; // matrix word, so we know how to move to the next line
//----------------------------variables------------------------------------------//
wire clk_i,rst_ni,start_i,mode_bit_i;// clock , reset , start bit from control
wire finish_write_i;
wire [1:0] n_dim_i,k_dim_i,m_dim_i; // matrix A is NxK , matrix B KxM
wire signed [(MAX_DIM*MAX_DIM*DATA_WIDTH)-1:0] a_matrix_i; // this matrix is actually  long register
wire signed [(MAX_DIM*MAX_DIM*DATA_WIDTH)-1:0] b_matrix_i; // this matrix is actually  long register
wire signed [(MAX_DIM*MAX_DIM*BUS_WIDTH)-1:0] c_matrix_i; // this matrix is actually  long register
wire  signed [(MAX_DIM*MAX_DIM*(BUS_WIDTH))-1:0] c_matrix_o; // output matrix is actually long matrix
wire [(MAX_DIM*MAX_DIM) -1:0] flags_o; 					// flags for overflow in pe
reg finish_mul_o; // write out when finished
wire signed [DATA_WIDTH-1:0] matA [MAX_DIM-1:0][MAX_DIM:0]; // wires for pe's rows
wire signed [DATA_WIDTH-1:0] matB [MAX_DIM:0][MAX_DIM-1:0]; // wires for pe's cols
wire signed [BUS_WIDTH-1:0]  matC [MAX_DIM-1:0][MAX_DIM-1:0]; // wires for pe's results
reg  signed [DATA_WIDTH-1:0] regMatA[MAX_DIM-1:0]; // wires for pe's rows
reg  signed [DATA_WIDTH-1:0] regMatB[MAX_DIM-1:0]; // wires for pe's rows
reg  signed [2*MAX_DIM+1 :0] index_a,index_b; // counter for clock and index for each matrix
reg  signed [2*MAX_DIM :0] counter;


genvar  i,j; // generated variables
generate
//-----------------------general connction (without last row and col)----------------------------//
  for (i = 0; i < MAX_DIM; i = i+1)
   begin : rows 
      for (j = 0; j < MAX_DIM; j = j+1) // here we create the structure of pe we want
         begin : columns  
            pe_module #(.DATA_WIDTH(DATA_WIDTH),.BUS_WIDTH(BUS_WIDTH)) U_pe ( // single pe
             .clk_i(clk_i), //clk
             .rst_ni(rst_ni), // reset
             .a_i(matA[i][j]), // a element in
             .b_i(matB[i][j]), // b element in
			 .c_i(c_matrix_i[(j*(BUS_WIDTH)*MAX_DIM+(i+1)*(BUS_WIDTH))-1-:BUS_WIDTH]),
             .a_o(matA[i][j+1]), // a element out
             .b_o(matB[i+1][j]), // b element out
             .res_o(matC[i][j]), // result out 
             .start_i(start_i), //start bit from control
			 .mode_bit_i(mode_bit_i),
		     .overflow_o(flags_o[i+j*MAX_DIM]) // flag for overflow
           );
    end 
  end
endgenerate

//-------------------assign result----------------------------------------//
generate
  for (j = 0; j < MAX_DIM; j = j +1) begin : rows_assign // connect rows output and matC
	   for (i = 0; i < MAX_DIM; i = i +1) begin : cols_assign // connect cols output and matC
		     assign c_matrix_o[(j*(BUS_WIDTH)*MAX_DIM+(i+1)*(BUS_WIDTH))-1-:BUS_WIDTH] = matC[j][i]; // conect the wires
	   end // end for i
  end // end for j
 endgenerate  
//-------------------assign inputs----------------------------------------
generate
  for (i = 0; i < MAX_DIM; i = i +1) begin : Left_assign // insert in the left side of the matrix
     assign  matA[i][0] = regMatA[i]; // connect the start wires of A to the reg
  end
 endgenerate
 
 generate
  for (j = 0; j < MAX_DIM; j = j +1) begin : Top_assign // insert in the top of the matrix
     assign  matB[0][j] = regMatB[j]; // connect the start wires of B to the reg
  end
 endgenerate

//---------------------------------operations with clock----------------------------------------------------//

//-----------------counter-------------------------------//
always @(posedge clk_i or negedge rst_ni)
  begin: acc_counter
  if(~rst_ni) // on negative edge
		begin
			counter  <= {(2*MAX_DIM+1){1'b0}}; // init counter
		end
  else if(start_i) // if start bit
		begin
			if(counter < (k_dim_i+m_dim_i+n_dim_i+1) || counter == (k_dim_i+m_dim_i+n_dim_i+1)) 
				counter <= counter[2*MAX_DIM-1:0]+1; //  count up with clk
		end
  else // if posedge clk and start != 1 -> initialize counter
		begin
			counter <= {(2*MAX_DIM+1){1'b0}}; // clock init
		end
  end
 
 //-----------------insert values for matrix A-------------------------------//

always @(posedge clk_i or negedge rst_ni) 
  begin: insert_vector_a
    if(~rst_ni)  // on negative edge
     begin
        for (index_a = 0; index_a < MAX_DIM; index_a = index_a[2*MAX_DIM:0]+1) // loop with index_a
          begin : reset_a
			       regMatA[index_a] <= {DATA_WIDTH{1'b0}}; // init to 0
		      end
	   end
   else if(start_i && counter <(k_dim_i+m_dim_i+n_dim_i-2+3))  // make sure not to happen if we finished
		begin
			for (index_a = 0; index_a < MAX_DIM; index_a = index_a[2*MAX_DIM:0]+1) // loop with index_a 
				begin : Left  // start insert to reg the values
				    regMatA[index_a] <= (counter-index_a>=0 && counter-index_a<{{(2*MAX_DIM){1'b0}},k_dim_i+1} 
					&& index_a < {{(2*MAX_DIM-1){1'b0}},n_dim_i+1})
					?  // if the condition is true insert value 
					a_matrix_i[((index_a*MATRIX_WORD)+((counter-index_a+1)*DATA_WIDTH)-1)-:DATA_WIDTH]
					: {DATA_WIDTH{1'b0}};                                      // else insert zero (MUX)
				end
		end
 end

 //-----------------insert values for matrix B-------------------------------//

always @(posedge clk_i or negedge rst_ni) 
 begin: insert_vector_b
   if(~rst_ni)  // on negative edge
     begin
        for (index_b = 0; index_b < MAX_DIM; index_b = index_b[2*MAX_DIM:0]+1) // loop with index_b
          begin : reset_b
			       regMatB[index_b] <= {DATA_WIDTH{1'b0}};  // init to 0
		      end // end for
	    end // end if
    else if(start_i && counter<(k_dim_i+m_dim_i+n_dim_i-2+3)) // make sure not to happen if we finished
		begin
			for (index_b = 0; index_b < MAX_DIM; index_b = index_b[2*MAX_DIM:0] +1) // loop with index_a 
				begin : Top  // start insert to reg the values
					regMatB[index_b] <= (counter-index_b>=0 && counter-index_b<{{(2*MAX_DIM){1'b0}},k_dim_i+1} 
					&& index_b < {{(2*MAX_DIM-1){1'b0}},m_dim_i+1})
					? // if the condition is true insert value 
					b_matrix_i[((index_b*MATRIX_WORD)+((counter-index_b+1)*DATA_WIDTH)-1)-:DATA_WIDTH]
					:
					{DATA_WIDTH{1'b0}};									   // else insert zero (MUX)
				end // end for
		end	 // end else if
end // end always

//---------------------to remove start bit--------------------//
always @(posedge clk_i or negedge rst_ni) 
 begin: change_start_o
	if(~rst_ni)
		begin
			finish_mul_o <= 1'b0; // init to 0
		end
    else if(start_i && (counter>=(k_dim_i+m_dim_i+n_dim_i-2+3))) // make sure not to happen if we finished
		begin
			finish_mul_o <= 1'b1; // sign that we finish the operation
		end	 // end  if
	else 
		begin
			finish_mul_o <= 1'b0; // sign that we didnt finish the operation
		end	 // end  if
end // end always


endmodule

/*


Net 'matB[2]' is unused. - the garbage values - bout in the last outputs
Net 'matA[0][2]' is unused. - the garbage values - aout in the last outputs
Net 'matA[1][2]' is unused. - the garbage values - aout in the last outputs


Net 'overflow_bit' is unused. - only used for the acc (bit range diff)
Net 'overflow_c_bit' is unused. - only used for the acc (bit range diff)
Net 'overflow_a_b_bit' is unused. - only used for the acc (bit range diff)


*/