interface matmul_intf(input logic clk_i, input logic rst_ni);
	//------------------------------------------------ports------------------------------------------------------//
	import matmul_pkg::*;
    logic psel_i;
	logic penable_i;
	logic pwrite_i;
	logic [MAX_DIM-1:0] pstrb_i;
	logic [BUS_WIDTH-1:0] pwdata_i;
	logic [ADDR_WIDTH-1:0] paddr_i;
	logic pready_o;
	logic pslverr_o;
	logic [BUS_WIDTH-1:0] prdata_o;
	logic busy_o;
	//--------------------------------------modports---------------------------------------------------------------------------//
	modport DUT  (input clk_i,rst_ni,psel_i,penable_i,pwrite_i,pstrb_i,pwdata_i,paddr_i,output pready_o,pslverr_o,prdata_o,busy_o);
	modport STIMULUS(output psel_i,penable_i,pwrite_i,pstrb_i,pwdata_i,paddr_i,input clk_i,rst_ni,pready_o,pslverr_o,prdata_o,busy_o);
	modport CHECKCOV(input  clk_i,rst_ni,psel_i,penable_i,pwrite_i,pstrb_i,pwdata_i,paddr_i,output pready_o,pslverr_o,prdata_o,busy_o);
	modport GOLDEN(input clk_i,rst_ni);
endinterface

