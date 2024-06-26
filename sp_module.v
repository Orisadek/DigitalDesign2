//
// Verilog Module Ori_Alon_Lab_1_lib.sp_module
//
// Created:
//          by - vain.UNKNOWN (TOMER)
//          at - 19:17:45 02/ 7/2024
//
// using Mentor Graphics HDL Designer(TM) 2019.2 (Build 5)
//

`resetall
`timescale 1ns/10ps
module sp_module (clk_i,rst_ni,write_enable_i,address_i,data_i,mode_i,start_send_i,write_target_i,
read_target_i,mat_num_i,data_o); //descripition for all inputs\outputs
//-----------------------------ports----------------------------------------------//
input clk_i,rst_ni,mat_num_i; // clk,reset
input write_enable_i,mode_i; // enable writing to operands
input address_i; // adress of writing (for line/col)
input data_i,start_send_i; //the data we want to write
input read_target_i,write_target_i; // matrix index for read and write 
output data_o; // the data we read (line/col)
//----------------------------parameters-----------------------------------------//
parameter  SP_NTARGETS = 4; //The number of addressable targets in sp
parameter  DATA_WIDTH  = 32; // data width
parameter  BUS_WIDTH   = 64; // bus width
parameter  ADDR_WIDTH  = 32; // addr width
localparam MAX_DIM     = (BUS_WIDTH / DATA_WIDTH); // max dim matrix

//--------------------Wires-------------------//
wire write_enable_i; //enabler to write the data
wire clk_i,rst_ni; // clk and rst
wire [2*$clog2(MAX_DIM)-1:0] address_i; // adress of writing (for line/col)
wire [BUS_WIDTH-1:0] data_i; //the input result matrix we need to save
wire mode_i;
wire [1:0] write_target_i,read_target_i;
wire start_send_i;
wire [BUS_WIDTH-1:0] data_o; // the data we read (line/col)
reg   overflowBit; // overflow bit 
reg  [BUS_WIDTH-1:0] mem [SP_NTARGETS*MAX_DIM*MAX_DIM-1:0]; // where we keep the resulte matries. 
reg  [$clog2(MAX_DIM*MAX_DIM*SP_NTARGETS)+1:0]index_insert_sp;
reg  [2*$clog2(MAX_DIM)-1:0] addrSendSp; 
wire [2*$clog2(MAX_DIM)-1:0] addrWireOut;
wire [1:0] addrWireMatOut;
wire [1:0] mat_num_i; // num of matrix from SPN
//-------------------------------insert data---------------------------------------//
always @(posedge clk_i or negedge rst_ni) 
	begin: writing_to_sp // we want it to activate during clk or rst
		if (~rst_ni) //add reset
			begin
				for (index_insert_sp = 0; index_insert_sp < MAX_DIM*MAX_DIM*SP_NTARGETS; index_insert_sp = index_insert_sp[$clog2(MAX_DIM*MAX_DIM*SP_NTARGETS):0] + 1) 
					begin
						mem[index_insert_sp] <=  {(BUS_WIDTH){1'b0}}; //implement 0 insted.
					end
			end 
	else if(write_enable_i) //if enable 
		begin
			mem[write_target_i*MAX_DIM*MAX_DIM + address_i] <= data_i; // sub addressing 
		end
end

//--------------------------------read data ----------------------------------------//
always@(posedge clk_i or negedge rst_ni)
	begin:send_address_sp		
		if(~rst_ni) // init to 0
			begin
				addrSendSp <= {(2*$clog2(MAX_DIM)){1'b0}};
				overflowBit <= 1'b0;
			end
		else
			begin
				if(start_send_i && ~overflowBit){overflowBit,addrSendSp} <= addrSendSp + 1;	 // inc addrSendSp
				else if(~start_send_i)
					begin
						addrSendSp <= {(2*$clog2(MAX_DIM)){1'b0}}; // reset to 0
						overflowBit <= 1'b0; // reset to 0
					end
				else
					begin
						addrSendSp <= {(2*$clog2(MAX_DIM)){1'b0}}; // reset to 0
					end
			end
	end
	
assign addrWireOut = (start_send_i && ~overflowBit) ? addrSendSp : address_i; //  if passed all the values
assign addrWireMatOut = (start_send_i && mode_i) ? read_target_i : mat_num_i; // start bit and mode_i - c_bias is needed
    // Output assignment for read data
assign data_o    = (write_enable_i == 1'b0) ? mem[addrWireMatOut*MAX_DIM*MAX_DIM+addrWireOut]:{(BUS_WIDTH){1'b0}}; //read data is when not on write mod


endmodule

