//
// Test Bench Module Ori_Alon_Lab_1_lib.operands_module_tb.operands_module_tester
//
// Created:
//          by - orisad.UNKNOWN (TOMER)
//          at - 15:31:14 02/ 2/2024
//
// Generated by Mentor Graphics' HDL Designer(TM) 2019.2 (Build 5)
//
`resetall
`timescale 1ns/10ps

module operands_module_tb;

// Local declarations
parameter DATA_WIDTH = 32;
parameter BUS_WIDTH = 64;
parameter ADDR_WIDTH = 32;
localparam MAX_DIM = (BUS_WIDTH / DATA_WIDTH);

// Internal signal declarations
wire clk_i;
wire rst_ni;
wire write_enable_i;
wire [ADDR_WIDTH-1:0] address_i; // adress of writing (for line/col)
wire [BUS_WIDTH-1:0] write_data_i; //the data we ant to write
wire [BUS_WIDTH-1:0] read_data_o; // the data we read (line/col)

operands_module #(32,64,32) U_0(
   .clk_i          (clk_i),
   .rst_ni         (rst_ni),
   .write_enable_i (write_enable_i),
   .address_i      (address_i),
   .write_data_i   (write_data_i),
   .read_data_o    (read_data_o)
);

operands_module_tester #(32,64,32) U_1(
   .clk_i          (clk_i),
   .rst_ni         (rst_ni),
   .write_enable_i (write_enable_i),
   .address_i      (address_i),
   .write_data_i   (write_data_i),
   .read_data_o    (read_data_o)
);

endmodule // operands_module_tb


