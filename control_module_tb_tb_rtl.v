//
// Test Bench Module Ori_Alon_Lab_1_lib.control_module_tb.control_module_tester
//
// Created:
//          by - orisad.UNKNOWN (TOMER)
//          at - 23:03:12 02/ 5/2024
//
// Generated by Mentor Graphics' HDL Designer(TM) 2019.2 (Build 5)
//
`resetall
`timescale 1ns/10ps

module control_module_tb;

localparam CONTROL_WIDTH = 16; // width of the control


// Internal signal declarations
wire clk_i; // clk
wire rst_ni;
wire start_bit_i;
wire write_enable_i;
wire mode_bit_o;
wire start_bit_o;
wire [CONTROL_WIDTH-1:0] data_i; // data in to all control
wire [CONTROL_WIDTH-1:0] data_o; // output data (control)
wire [1:0] write_target_o; // target to read from SP (only if mode bit =1)
wire [1:0] read_target_o; // target to write in SP
wire [1:0] N_o,K_o,M_o;  // N,K,M Dimension


control_module U_0(
   .clk_i          (clk_i),
   .rst_ni         (rst_ni),
   .start_bit_i    (start_bit_i),
   .write_enable_i (write_enable_i),
   .data_i         (data_i),
   .write_target_o (write_target_o),
   .read_target_o  (read_target_o),
   .N_o            (N_o),
   .K_o            (K_o),
   .M_o            (M_o),
   .mode_bit_o     (mode_bit_o),
   .start_bit_o    (start_bit_o),
   .data_o         (data_o)
);

control_module_tester U_1(
   .clk_i          (clk_i),
   .rst_ni         (rst_ni),
   .start_bit_i    (start_bit_i),
   .write_enable_i (write_enable_i),
   .data_i         (data_i),
   .write_target_o (write_target_o),
   .read_target_o  (read_target_o),
   .N_o            (N_o),
   .K_o            (K_o),
   .M_o            (M_o),
   .mode_bit_o     (mode_bit_o),
   .start_bit_o    (start_bit_o),
   .data_o         (data_o)
);

endmodule // control_module_tb


