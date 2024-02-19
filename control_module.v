//
// Verilog Module Ori_Alon_Lab_1_lib.control_module
//
// Created:
//          by - orisad.UNKNOWN (TOMER)
//          at - 22:20:26 02/ 5/2024
//
// using Mentor Graphics HDL Designer(TM) 2019.2 (Build 5)
//

`resetall
`timescale 1ns/10ps
module control_module(clk_i,rst_ni,start_bit_i,write_enable_i,data_i,write_target_o,
read_target_o,n_dim_o,k_dim_o,m_dim_o,mode_bit_o,start_bit_o,data_o); // ports
input clk_i,rst_ni; //reset and clk
input start_bit_i,write_enable_i; // start bit to de-asserted , write enable to whole control
input data_i; // data in to all control
output write_target_o,read_target_o; // target to write in SP , target to read from SP (only if mode bit = 1)
output n_dim_o,k_dim_o,m_dim_o; // N,K,M Dimension
output mode_bit_o,start_bit_o,data_o; // mode bit (bias add C),start bit for matmul calc, output data (control)
localparam CONTROL_WIDTH = 16; // width of the control

wire clk_i,rst_ni; // clk
wire start_bit_i,write_enable_i; // start bit de-asserted , write enable to whole control
wire [CONTROL_WIDTH-1:0] data_i; // data in to all control
wire [CONTROL_WIDTH-1:0] data_o; // output data (control)
wire [1:0] write_target_o; // target to read from SP (only if mode bit =1)
wire [1:0] read_target_o; // target to write in SP
wire  [1:0] n_dim_o,k_dim_o,m_dim_o;
wire mode_bit_o,start_bit_o; // mode bit (bias add C),start bit for matmul calc, output data (control)
reg  [CONTROL_WIDTH-1:0] controlRegister; // control register


assign data_o = write_enable_i ? 0 : controlRegister; // read data 
assign start_bit_o = controlRegister[0]; // read start bit
assign mode_bit_o = controlRegister[1];  // read mode bit
assign write_target_o = controlRegister[3:2]; // target to write in SP 
assign read_target_o = controlRegister[5:4]; // target to read from SP (only if mode bit = 1) 
assign n_dim_o = controlRegister[9:8];   // N -  1st dimension of matrix A and the 1st dimension of out matrix C
assign k_dim_o = controlRegister[11:10]; // K -  2nd dimension of matrix A and the 1st dimension of matrix B
assign m_dim_o = controlRegister[13:12]; // M -  2nd dimension of matrix B and the 2nd dimension of out matrix C

always @(posedge clk_i or negedge rst_ni) // clk edge and reset edge
	begin:write_to_control // write to control
		if(~rst_ni) // reset 
			begin
				controlRegister <=  {(CONTROL_WIDTH){1'b0}}; // init to 0
			end
		else if(write_enable_i) // if write enable 
		    begin
				controlRegister <= data_i; // write data
		    end 
		else if(start_bit_i) // if start bit needed to de-asserted - signal from matmul calc 
			begin
				controlRegister[0] <= 1'b0; // de-asserted start bit internally
			end
	end
	
endmodule
