interface matmul_calc_intf(input logic clk, input logic rst_ni);
	import matmul_calc_pkg::*;



	//modport DEVICE  (input clk_i,rst_ni,psel_i,penable_i,pwrite_i,pstrb_i,pwdata_i,paddr_i,output pready_o,pslverr_o,prdata_o,busy_o);
	modport STIMULUS(output clk_i,rst_ni,psel_i,penable_i,pwrite_i,pstrb_i,pwdata_i,paddr_i,input pready_o,pslverr_o,prdata_o,busy_o);
	modport CHECKCOV(input  clk_i,rst_ni,psel_i,penable_i,pwrite_i,pstrb_i,pwdata_i,paddr_i,output pready_o,pslverr_o,prdata_o,busy_o);
  
endinterface

