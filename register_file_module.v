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
module register_file_module(clk_i,rst_ni,address_i,data_i,data_flags_i,
write_enable_i,strobe_i,sp_enable_i,write_target_o,address_a_i,
address_b_i,address_c_i,start_bit_i,read_target_o,n_dim_o,k_dim_o,m_dim_o,
mode_bit_o,start_bit_o,data_o,a_mat_o,b_mat_o,c_mat_o);

input clk_i,rst_ni,address_i;
input data_i,write_enable_i,data_flags_i,start_bit_i;
input address_c_i,address_b_i,address_a_i;
input sp_enable_i,strobe_i;
output write_target_o,read_target_o,n_dim_o,k_dim_o,m_dim_o;
output mode_bit_o,start_bit_o,data_o;
output a_mat_o,b_mat_o,c_mat_o;
parameter  DATA_WIDTH = 32; // data width
parameter  BUS_WIDTH = 64; // bus width
parameter  ADDR_WIDTH = 32; // addr width
parameter  SP_NTARGETS = 4; //The number of addressable targets in sp

localparam CONTROL_WIDTH = 16;
localparam MAX_DIM = (BUS_WIDTH / DATA_WIDTH); // max dim matrix
localparam [4:0] CONTROL    = 5'b00000, // idle state
			     OPERAND_A  = 5'b00100, // read state
			     OPERAND_B  = 5'b01100, // write state
				 FLAGS		= 5'b01000,
				 SP 		= 5'b10000;
				 
wire signed [BUS_WIDTH-1:0] dataOpA,dataOpB,dataSp;
wire [BUS_WIDTH-1:0] dataFlags;
wire [CONTROL_WIDTH-1:0] dataCtrl;
wire signed [BUS_WIDTH-1:0] a_mat_o,b_mat_o,c_mat_o;
reg wEnMatA,wEnMatB,wEnCtrl;
wire [BUS_WIDTH-1:0] data_flags_i,data_i;
wire [ADDR_WIDTH-1:0] address_a_i,address_b_i,address_c_i,address_i;
wire [MAX_DIM-1:0] strobe_i;
wire start_bit_i,sp_enable_i,write_enable_i,rst_ni,clk_i;
wire [1:0] write_target_o,read_target_o;
wire [1:0] n_dim_o,k_dim_o,m_dim_o;
wire mode_bit_o,start_bit_o;
reg signed [BUS_WIDTH-1:0] data_o;
 
always@(*)
begin:begin_switch_case
	case(address_i[4:0])  // current state
		CONTROL: // control
			begin
				data_o  = write_enable_i ? {(BUS_WIDTH){1'bz}} : {{(BUS_WIDTH-CONTROL_WIDTH){1'b0}},dataCtrl};
				wEnCtrl = write_enable_i ? 1'b1 : 1'b0;
				wEnMatA = 0;
				wEnMatB = 0;
			end
		OPERAND_A: // operand A
			begin
				data_o  = write_enable_i ? {(BUS_WIDTH){1'bz}} : dataOpA;
				wEnMatA = write_enable_i ? 1'b1 : 1'b0;
				wEnCtrl = 0;
				wEnMatB = 0;
			end
		OPERAND_B: // operand B
			begin
				data_o  = write_enable_i ? {(BUS_WIDTH){1'bz}} : dataOpB;
				wEnMatB = write_enable_i ? 1'b1 : 1'b0;
				wEnCtrl = 0;
				wEnMatA = 0;
			end
		FLAGS: // flags
			begin
				data_o  = sp_enable_i ? {(BUS_WIDTH){1'bz}} : dataFlags;
				wEnCtrl = 0;
				wEnMatA = 0;
				wEnMatB = 0;
			end
		SP: // scrachpad
			begin
				data_o = sp_enable_i ? {(BUS_WIDTH){1'bz}} : dataSp;
				wEnCtrl = 0;
				wEnMatA = 0;
				wEnMatB = 0;
			end
		default:
				begin
					data_o = {(BUS_WIDTH){1'bz}};
					wEnCtrl = 0;
					wEnMatA = 0;
					wEnMatB = 0;
				end
	endcase
end
	
operands_module#(.DATA_WIDTH(DATA_WIDTH),.BUS_WIDTH(BUS_WIDTH)) U_operandA(
.clk_i(clk_i),
.rst_ni(rst_ni),
.write_enable_i(wEnMatA),
.address_i(address_i[5+$clog2(MAX_DIM)-1:5]),
.address_op_i(address_a_i[5+$clog2(MAX_DIM)-1:5]),
.data_i(data_i),
.strobe_i(strobe_i),
.start_i(start_bit_o),
.data_op_o(a_mat_o),
.data_o(dataOpA)
);

operands_module#(.DATA_WIDTH(DATA_WIDTH),.BUS_WIDTH(BUS_WIDTH)) U_operandB(
.clk_i(clk_i),
.rst_ni(rst_ni),
.write_enable_i(wEnMatB),
.address_i(address_i[5+$clog2(MAX_DIM)-1:5]),
.address_op_i(address_b_i[5+$clog2(MAX_DIM)-1:5]),
.data_i(data_i),
.strobe_i(strobe_i),
.start_i(start_bit_o),
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

control_module U_control(
.clk_i(clk_i),
.rst_ni(rst_ni),
.start_bit_i(start_bit_i),
.write_enable_i(wEnCtrl),
.data_i(data_i[CONTROL_WIDTH-1:0]),
.write_target_o(write_target_o),
.read_target_o(read_target_o),
.n_dim_o(n_dim_o),
.k_dim_o(k_dim_o),
.m_dim_o(m_dim_o),
.mode_bit_o(mode_bit_o),
.start_bit_o(start_bit_o),
.data_o(dataCtrl)
);

sp_module#(.SP_NTARGETS(SP_NTARGETS),.DATA_WIDTH(DATA_WIDTH),.BUS_WIDTH(BUS_WIDTH),.ADDR_WIDTH(ADDR_WIDTH)) U_sp (
.clk_i(clk_i),
.rst_ni(rst_ni),
.write_enable_i(sp_enable_i),
.address_i(address_i[5+2*$clog2(MAX_DIM):5]),
.address_sp_i(address_c_i[5+2*$clog2(MAX_DIM):5]),
.mode_i(mode_bit_o),
.write_target_i(write_target_o),
.read_target_i(read_target_o),
.data_i(data_i),
.data_o(dataSp),
.data_sp_o(c_mat_o)
);

endmodule


/*

Net 'address_i[31:7]' is unused.   - only need untill 6 , that's because we only need 5+:2*$clog2(MAX_DIM) and 4:0
Net 'address_a_i[31:6]' is unused. -  only need 5+:$clog2(MAX_DIM) for choosing lines
Net 'address_b_i[4:0]' is unused.  - only need 5+:$clog2(MAX_DIM) for choosing lines
Net 'address_b_i[31:6]' is unused. - only need 5+:$clog2(MAX_DIM) for choosing lines
Net 'address_a_i[4:0]' is unused.  - only need 5+:$clog2(MAX_DIM) for choosing lines
Net 'address_c_i[31:7]' is unused. - only need 5+:2*$clog2(MAX_DIM) for choosing element
Net 'address_c_i[4:0]' is unused.  - only need 5+:2*$clog2(MAX_DIM) for choosing element

*/