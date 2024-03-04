`include "headers.vh"

module matmul_tester #(
    parameter string RESOURCE_BASE = ""
) (
    matmul_intf intf
);
// Local declarations
logic  stim_done, golden_done;

wire rst_ni = intf.rst_ni;
wire clk_i  = intf.clk_i;

matmul_stimulus #(
    .matrixA_File($sformatf("%sMatrixA.txt",RESOURCE_BASE)),
    .matrixB_File($sformatf("%sMatrixB.txt",RESOURCE_BASE))
) u_stim (
    .intf(intf)
	//.clk_i      (clk_i),
   // .rst_ni     (rst_ni)
    // TB Status
  
);

/*
// Functional Coverage
eqn_impl_coverage u_cover (
    .intf(intf)
);
*/
// Functional Checker
/*
eqn_impl_checker u_check (
    .intf    (intf)
);
*/
/*
// Golden-Model module
matmul_golden #(
    .MAX_IM_DIM(240),
    .OUTFILE($sformatf("%s/out/BGUTROLL",RESOURCE_BASE)),
	.GOLDENFILE($sformatf("%s/out/golden.raw",RESOURCE_BASE)),
    .VERBOSE(1'b1)
) u_golden (
    .intf    (intf),
    // TB Status
    .out_width_i(out_width),
    .out_height_i(out_height),
    .img_done_i(img_done),
    .stim_done_i(stim_done),
    .golden_done_o(golden_done)
);
*/

initial begin: TB_INIT
    wait(rst_ni); wait(!rst_ni);
    wait(stim_done);
    $display("[%0t] Stim Done.", $time);
   // wait(golden_done);
    $display("[%0t] Check Done.", $time);
    $finish;
end

endmodule // eqn_impl_tester


