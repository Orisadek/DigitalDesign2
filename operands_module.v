//
// Verilog Module Ori_Alon_Lab_1_lib.operands_module
//
// Created:
//          by - orisad.UNKNOWN (TOMER)
//          at - 00:35:28 02/ 2/2024
//
// using Mentor Graphics HDL Designer(TM) 2019.2 (Build 5)
//

`resetall
`timescale 1ns/10ps
module operands_module(clk_i,rst_ni,write_enable_i,address_i,data_i,strobe_i,start_send_i,data_o); 
//-----------------------------ports----------------------------------------------//
input clk_i,rst_ni; // clk,reset
input write_enable_i; // enable writing to operands
input  address_i,strobe_i,start_send_i; // adress of writing (for line/col)
input data_i; //the data we ant to write
output data_o; // the data we read (line/col)
//----------------------------parameters-----------------------------------------//
parameter DATA_WIDTH = 32; // data width
parameter BUS_WIDTH = 64; // bus width
//parameter ADDR_WIDTH = 32; // addr width
localparam MAX_DIM = (BUS_WIDTH / DATA_WIDTH); // max dim matrix
//----------------------------variables------------------------------------------//
wire [$clog2(MAX_DIM)-1:0] address_i; // adress of writing (for line/col)
wire [BUS_WIDTH-1:0] data_i; //the data we ant to write
wire [BUS_WIDTH-1:0] data_o; // the data we read (line/col)
wire [MAX_DIM-1:0] strobe_i; //for every byte there is a Pstrb[n]
    // Declare the registers
reg [BUS_WIDTH-1:0] registers [MAX_DIM-1:0]; // where we keep the operands
reg  [$clog2(MAX_DIM)+1:0] index;  // Read and Write Logic
reg  [$clog2(MAX_DIM)-1:0] addrSendOp;
wire [$clog2(MAX_DIM)-1:0] addrWireOut;
wire start_send_i;
reg overflowBit;


//------------------------------------generate block------------------------------------------------//
genvar b; // b variable
generate  // grenerate the block
    for(b = 0 ; b < MAX_DIM ; b = b+1) // for loop
		begin:insert_data_width
			always @(posedge clk_i or negedge rst_ni)// sensitivity list
				begin:strobe_operand
				if(~rst_ni) //if we writing and in strobe and enabled
					begin
					for(index = 0; index < MAX_DIM ; index = index+1)
						begin
						  registers[index][(b+1)*DATA_WIDTH-1-:DATA_WIDTH] <=  {(DATA_WIDTH){1'b0}}; // write data
						end
					end	
				 else if(strobe_i[b]) //if we writing and in strobe and enabled
					begin
						registers[address_i][(b+1)*DATA_WIDTH-1-:DATA_WIDTH] <=  data_i[(b+1)*DATA_WIDTH-1-:DATA_WIDTH]; // write data
					end
				end
		end 
endgenerate

//------------------------always block----------------------//
always@(posedge clk_i or negedge rst_ni)
	begin:send_address_a_b		
		if(~rst_ni)
			begin
				addrSendOp <= {($clog2(MAX_DIM)){1'b0}};
				overflowBit <= 1'b0;
			end
		else
			begin
				if(start_send_i && ~overflowBit){overflowBit,addrSendOp} <= addrSendOp + 1;	
				else if(~start_send_i)
					begin
						addrSendOp <= {($clog2(MAX_DIM)){1'b0}};
						overflowBit <= 1'b0;
					end
				else
					begin
						addrSendOp <= {($clog2(MAX_DIM)){1'b0}};
					end
			end
	end
	
assign addrWireOut = (start_send_i && ~overflowBit) ? addrSendOp : address_i;
    // Output assignment for read data
assign data_o  = (strobe_i == {(MAX_DIM){1'b0}}) ? registers[addrWireOut] : {(BUS_WIDTH){1'b0}}; // read the data async
endmodule

/*
overflowBit not used - bit used for acc only
*/