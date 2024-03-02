interface matmul_intf(input logic clk, input logic rst_ni);
	import matmul_calc_pkg::*;
    logic psel_i,
	logic penable_i,
	logic pwrite_i,
	logic pstrb_i,
	logic pwdata_i,
	logic paddr_i,
	logic pready_o,
	logic pslverr_o,
	logic prdata_o,
	logic busy_o
	modport matmul  (input clk_i,rst_ni,psel_i,penable_i,pwrite_i,pstrb_i,pwdata_i,paddr_i,output pready_o,pslverr_o,prdata_o,busy_o);
	modport STIMULUS(output psel_i,penable_i,pwrite_i,pstrb_i,pwdata_i,paddr_i,input clk_i,rst_ni,pready_o,pslverr_o,prdata_o,busy_o);
	modport CHECKCOV(input  clk_i,rst_ni,psel_i,penable_i,pwrite_i,pstrb_i,pwdata_i,paddr_i,output pready_o,pslverr_o,prdata_o,busy_o);
  
endinterface

