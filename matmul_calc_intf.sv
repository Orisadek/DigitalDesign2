interface matmul_calc_intf(input logic clk, input logic rst_ni);
	import matmul_calc_pkg::*;
  
  logic enable;

  
  matA matrix_A;
  matB matrix_B;
	matC matrix_C; 
  






	
	modport DEVICE(output ena, im_pixel, w_pixel, param, input clk, rst);
	modport STIMULUS(output enable, matrixC input clk, rst_ni, N, K, M);
	modport CHECKCOV(output ena, im_pixel, w_pixel, param, input clk, rst);
  
endinterface

