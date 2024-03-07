`include "headers.vh"

module matmul_tester #(
    parameter string RESOURCE_BASE = ""
) (
    matmul_intf intf
);
// Local declarations
import matmul_pkg::*;
logic  stim_done, golden_done;
wire rst_ni = intf.rst_ni;
wire clk_i  = intf.clk_i;

matmul_stimulus #(
    .matrixA_File($sformatf("%sMatrixA.txt",RESOURCE_BASE)),
    .matrixB_File($sformatf("%sMatrixB.txt",RESOURCE_BASE))
) u_stim (
    .intf(intf),
	.stim_done_o(stim_done)
    // TB Status
);

// Golden-Model module
matmul_golden #(
 .matrixC_File($sformatf("%sMatrixA.txt",RESOURCE_BASE))
) u_golden (
    .intf    (intf),
    // TB Status
    .stim_done_i(stim_done),
    .golden_done_o(golden_done)
);


initial begin: TB_INIT
    wait(rst_ni); wait(!rst_ni);
    wait(stim_done);
    $display("[%0t] Stim Done.", $time);
    wait(golden_done);
    $display("[%0t] Check Done.", $time);
    $finish;
end

endmodule // eqn_impl_tester


