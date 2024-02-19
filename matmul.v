//
// Verilog Module Lab2AlonOri_lib.matmul
//
// Created:
//          by - orisad.UNKNOWN (TOMER)
//          at - 19:03:27 02/15/2024
//
// using Mentor Graphics HDL Designer(TM) 2019.2 (Build 5)
//

`resetall
`timescale 1ns/10ps
module matmul(clk_i,rst_ni,psel_i,penable_i,pwrite_i,pstrb_i,pwdata_i,paddr_i,pready_o,pslverr_o,prdata_o,busy_o);
input  clk_i,rst_ni,psel_i,penable_i;
input  pwrite_i,pstrb_i,pwdata_i,paddr_i;
output pready_o,pslverr_o,prdata_o,busy_o;
parameter DATA_WIDTH = 8; // data width
parameter BUS_WIDTH = 16; // bus width
parameter ADDR_WIDTH = 32; // addr width
parameter  SP_NTARGETS = 4; //The number of addressable targets in sp
localparam MAX_DIM = (BUS_WIDTH / DATA_WIDTH); // max dim matrix

wire rst_ni,clk_i;

wire [1:0] nDim,kDim,mDim;
wire startBit,modeBit;
wire [MAX_DIM*MAX_DIM-1:0] flagsData;
wire finishMul,enableWriteSp;
wire signed [BUS_WIDTH-1:0] matA,matB,matC;
wire psel_i,penable_i,pwrite_i;
wire [MAX_DIM-1:0] pstrb_i;
wire [BUS_WIDTH-1:0] pwdata_i;
wire [ADDR_WIDTH-1:0] paddr_i;
wire pready_o,pslverr_o,busy_o;
wire  [BUS_WIDTH-1:0] prdata_o;
wire [ADDR_WIDTH-1:0] addressApb,addressMatmul,addressMem;
wire [ADDR_WIDTH-1:0] addressReadA,addressReadB,addressReadC;
wire [BUS_WIDTH-1:0] readDataMem,writeDataMem;
wire [BUS_WIDTH-1:0] writeDataApb,writeDataMatmul;
wire writeEnable;
assign addressMem   = startBit ? addressMatmul : addressApb;
assign writeDataMem = startBit ? writeDataMatmul : writeDataApb;
assign writeEnable  =  startBit ? pwrite_i : 1'b0;

matmul_calc_module#(.DATA_WIDTH(DATA_WIDTH),.BUS_WIDTH(BUS_WIDTH),.ADDR_WIDTH(ADDR_WIDTH)) U_matmul_calc(
.clk_i(clk_i),
.rst_ni(rst_ni),
.n_dim_i(nDim),
.k_dim_i(kDim),
.m_dim_i(mDim),
.start_i(startBit),
.data_a_i(matA),
.data_b_i(matB),
.data_c_i(matC),
.mode_i(modeBit),
.data_o(writeDataMatmul),
.address_o(addressMatmul),
.address_a_o(addressReadA),
.address_b_o(addressReadB),
.address_c_o(addressReadC),
.flags_o(flagsData),
.finish_mul_o(finishMul),
.enable_w_o(enableWriteSp)
);

apb_slave_module#(.DATA_WIDTH(DATA_WIDTH),.BUS_WIDTH(BUS_WIDTH),.ADDR_WIDTH(ADDR_WIDTH)) U_apb(
.clk_i(clk_i),
.rst_ni(rst_ni),
.psel_i(psel_i),
.penable_i(penable_i),
.pwrite_i(pwrite_i),
.pstrb_i(pstrb_i),
.pwdata_i(pwdata_i),
.paddr_i(paddr_i),
.bus_mem_i(readDataMem),
.start_bit_i(startBit),
.address_o(addressApb),
.pready_o(pready_o),
.pslverr_o(pslverr_o),
.prdata_o(prdata_o),
.busy_o(busy_o),
.bus_mem_o(writeDataApb)
);

register_file_module#(.DATA_WIDTH(DATA_WIDTH),.BUS_WIDTH(BUS_WIDTH),.ADDR_WIDTH(ADDR_WIDTH),.SP_NTARGETS(SP_NTARGETS))(
.clk_i(clk_i),
.rst_ni(rst_ni),
.address_i(addressMem),
.data_i(writeDataMem),
.data_flags_i(flagsData),
.write_enable_i(writeEnable),
.strobe_i(strobe_i),
.sp_enable_i(enableWriteSp),
.address_a_i(addressReadA),
.address_b_i(addressReadB),
.address_c_i(addressReadC),
.start_bit_i(finishMul),
.n_dim_o(nDim),
.k_dim_o(kDim),
.m_dim_o(mDim),
.mode_bit_o(modeBit),
.start_bit_o(startBit),
.data_o(readDataMem),
.a_mat_o(matA),
.b_mat_o(matB),
.c_mat_o(matC)
);
endmodule
