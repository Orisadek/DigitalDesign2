//
// Verilog Module Lab2AlonOri_lib.register_file_module
//
// Created:
//          by - orisad.UNKNOWN (TOMER)
//          at - 19:11:22 02/15/2024
//
// using Mentor Graphics HDL Designer(TM) 2019.2 (Build 5)
//

`resetall
`timescale 1ns/10ps
module register_file_module(clk_i,rst_ni,address_i,data_i,data_flags_i,write_enable_i,strobe_i,
sp_enable_i,write_target_o,address_a_i,address_b_i,address_c_i,start_bit_i,read_target_o,N_o,K_o,M_o,mode_bit_o,
start_bit_o,data_o,a_mat_o,b_mat_o,c_mat_o);
input clk_i,rst_ni,address_i;
input data_i,write_enable_i,data_flags_i,start_bit_i;
output write_target_o,read_target_o,N_o,K_o,M_o;
output mode_bit_o,start_bit_o,data_o;
output a_mat_o,b_mat_o,c_mat_o;
parameter DATA_WIDTH = 32; // data width
parameter BUS_WIDTH = 64; // bus width
parameter ADDR_WIDTH = 32; // addr width
localparam CONTROL_WIDTH = 16;
localparam MAX_DIM = (BUS_WIDTH / DATA_WIDTH); // max dim matrix
localparam [4:0] CONTROL    = 2'b00000, // idle state
			     OPERAND_A  = 2'b00100, // read state
			     OPERAND_B  = 2'b01100; // write state
				 FLAGS		= 2'b01000;
				 SP 		= 2'b10000;
				 
wire signed [BUS_WIDTH-1:0] dataOpA,dataOpB,dataFlags,dataSp,dataCtrl;
reg signed [BUS_WIDTH-1:0] a_mat_o,b_mat_o,c_mat_o;
wire wEnMatA,wEnMatB,wEnFlags,wEnCtrl;
wire [BUS_WIDTH-1:0] data_flags_i,data_i;
wire [ADDR_WIDTH-1] address_a_i,address_b_i,address_c_i,address_i;
wire [MAX_DIM-1:0] strobe_i;
wire start_bit_i,sp_enable_i,write_enable_i,rst_ni,clk_i;
reg [1:0] write_target_o,read_target_o;
reg [2:0] N_o,K_o,M_o;
reg mode_bit_o,start_bit_o;
reg signed [BUS_WIDTH-1] data_o;
 
case(address_i[4:0])  // current state
    CONTROL: // control
      	begin
			data_o = write_enable ? {(BUS_WIDTH){1'bz}} : dataCtrl;
			wEnCtrl = write_enable ? 1'b1 : 1'b0;
		end
	OPERAND_A: // operand A
      	begin
			data_o = write_enable ? {(BUS_WIDTH){1'bz}} : dataOpA;
			wEnMatA = write_enable ? 1'b1 : 1'b0;
		end
	OPERAND_B: // operand B
      	begin
			data_o = write_enable ? {(BUS_WIDTH){1'bz}} : dataOpB;
			wEnMatB = write_enable ? 1'b1 : 1'b0;
		end
	FLAGS: // flags
      	begin
			data_o  = sp_enable_i ? {(BUS_WIDTH){1'bz}} : dataFlags;
		end
	SP: // scrachpad
      	begin
			data_o = sp_enable_i ? {(BUS_WIDTH){1'bz}} : dataSp;
		end
endcase
	
operands_module#(.DATA_WIDTH(DATA_WIDTH),.BUS_WIDTH(BUS_WIDTH)) U_operandA(
.clk_i(clk_i),
.rst_ni(rst_ni),
.write_enable_i(wEnMatA),
.address_i(address_i[5:+$clog2(MAX_DIM)]),
.address_op_i(address_a_i)
.data_i(data_i),
.strobe_i(strobe_i),
.data_op_o(a_mat_o),
.data_o(dataOpA)
);

operands_module#(.DATA_WIDTH(DATA_WIDTH),.BUS_WIDTH(BUS_WIDTH)) U_operandB(
.clk_i(clk_i),
.rst_ni(rst_ni),
.write_enable_i(wEnMatB),
.address_i(address_i[5:+$clog2(MAX_DIM)]),
.address_op_i(address_b_i),
.data_i(data_i),
.strobe_i(strobe_i),
.data_op_o(b_mat_o),
.data_o(dataOpB)
);

flags_module#(.DATA_WIDTH(DATA_WIDTH),.BUS_WIDTH(BUS_WIDTH))U_flags(
.clk_i(clk_i),
.rst_ni(rst_ni),
.write_enable_i(sp_enable_i),
.data_i(data_flags_i),
.data_o(dataFlags)
);

control_module#(.DATA_WIDTH(DATA_WIDTH),.BUS_WIDTH(BUS_WIDTH)) U_control(
.clk_i(clk_i),
.rst_ni(rst_ni),
.start_bit_i(start_bit_i),
.write_enable_i(wEnCtrl),
.data_i(data_i[CONTROL_WIDTH-1:0]),
.write_target_o(write_target_o),
.N_o(N_o),
.K_o(K_o),
.M_o(M_o),
.mode_bit_o(mode_bit_o),
.start_bit_o(start_bit_o),
.data_o(data_control)
);

sp_module#(.SP_NTARGETS(SP_NTARGETS),.DATA_WIDTH(DATA_WIDTH),.BUS_WIDTH(BUS_WIDTH),.ADDR_WIDTH(ADDR_WIDTH)) U_sp (
.clk_i(clk_i),
.rst_ni(rst_ni),
.write_enable_i(sp_enable_i),
.address_i(address_i[5:+2*$clog2(MAX_DIM)]),
.address_sp_i(address_c_i),
.data_i(data_i),
.data_o(dataSp),
.data_sp_o(c_mat_o)
);

endmodule
