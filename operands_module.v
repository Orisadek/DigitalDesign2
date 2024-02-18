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
module operands_module(clk_i,rst_ni,write_enable_i,address_i,data_i,strobe_i,data_o); 
input clk_i,rst_ni; // clk,reset
input write_enable_i; // enable writing to operands
input  address_i,strobe_i; // adress of writing (for line/col)
input data_i; //the data we ant to write
output data_o; // the data we read (line/col)

parameter DATA_WIDTH = 32; // data width
parameter BUS_WIDTH = 64; // bus width
//parameter ADDR_WIDTH = 32; // addr width
localparam MAX_DIM = (BUS_WIDTH / DATA_WIDTH); // max dim matrix
wire [5:+$clog2(MAX_DIM)] address_i; // adress of writing (for line/col)
wire [BUS_WIDTH-1:0] data_i; //the data we ant to write
wire [BUS_WIDTH-1:0] data_o; // the data we read (line/col)
wire [MAX_DIM-1:0] strobe_i; //for every byte there is a Pstrb[n]
    // Declare the registers
reg [BUS_WIDTH-1:0] registers [MAX_DIM-1:0]; // where we keep the operands
reg [MAX_DIM:0] index;  // Read and Write Logic

always @(negedge rst_ni)
 begin :memory_operands
    if (~rst_ni) // on negative edge
	begin
		for (index = 0; index < MAX_DIM; index = index[MAX_DIM-1:0] + 1) 
			begin
				registers[index] <= {(BUS_WIDTH){1'b0}}; // init to zero
			end
    end
end

genvar b; // b variable
generate  // grenerate the block
  for(b = 0 ; b < MAX_DIM ; b = b+1) // for loop
    begin:insert_byte
       always @(posedge clk_i)// sensitivity list
			begin:strobe_apb
				if(write_enable_i and rst_ni and strobe_i[b]) //if we writing and in strobe and enabled
					begin
						registers[address_i][(b+1)*DATA_WIDTH-1:b*DATA_WIDTH] = data_i[(b+1)*DATA_WIDTH-1:b*DATA_WIDTH]; // write data
					end
			end
    end 
endgenerate


    // Output assignment for read data
assign data_o = (write_enable_i == 1'b0) ? registers[address_i] : {(BUS_WIDTH){1'b0}}; // read the data async

endmodule
