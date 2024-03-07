
`include "headers.vh"

module matmul_tb;

import matmul_pkg::CLK_NS;
import matmul_pkg::RST_CYC;
import matmul_pkg::DATA_WIDTH;
import matmul_pkg::BUS_WIDTH;
import matmul_pkg::ADDR_WIDTH;
import matmul_pkg::SP_NTARGETS;
// Internal signal declarations
logic clk_i = 1'b0;
logic rst_ni;
// Interface instantiation
matmul_intf intf(
	.clk_i(clk_i), .rst_ni(rst_ni)
);
// Init clock process
initial forever 
	#(CLK_NS/2) clk_i = ~clk_i;
	//#(5) clk_i = ~clk_i;
// Init reset process
initial begin: TOP_RST
	rst_ni = 1'b1; // Assert reset
	// Reset for RST_CYC cycles
	repeat(1) @(posedge clk_i);
	rst_ni = 1'b0; // Deassert reset
	repeat(RST_CYC) @(posedge clk_i);
	rst_ni = 1'b1; // assert reset
end
// DUT //
matmul #(
   .DATA_WIDTH(DATA_WIDTH),
   .BUS_WIDTH(BUS_WIDTH),
   .ADDR_WIDTH(ADDR_WIDTH),
   .SP_NTARGETS(SP_NTARGETS)
) u_dut (
   .clk_i     (clk_i),
   .rst_ni    (rst_ni),
   .psel_i    (intf.psel_i),
   .penable_i (intf.penable_i),
   .pwrite_i  (intf.pwrite_i),
   .pstrb_i   (intf.pstrb_i),
   .pwdata_i  (intf.pwdata_i),
   .paddr_i   (intf.paddr_i),
   .pready_o  (intf.pready_o),
   .pslverr_o (intf.pslverr_o),
   .prdata_o  (intf.prdata_o),
   .busy_o    (intf.busy_o)
   
);

matmul_tester #(
	.RESOURCE_BASE("C:/Users/orisa/OneDrive - post.bgu.ac.il/bguStudy/fourth_year/semester_a/logical_design_verilog/LAB2/DigitalDesign2/matmul_golden_Matlab/")
) u_tester (
   .intf(intf)
);

endmodule 
