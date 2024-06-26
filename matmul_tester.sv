`include "headers.vh"

module matmul_tester #(
    parameter string RESOURCE_BASE = ""
) (
    matmul_intf intf
);
// Local declarations
import matmul_pkg::*;
wire  stim_done, golden_done_iteration;
wire rst_ni = intf.rst_ni;
wire clk_i  = intf.clk_i;
wire [MAX_DIM*MAX_DIM*BUS_WIDTH-1:0] dataSP;
wire [BUS_WIDTH-1:0] flags;
//----------------------------Units----------------------------------//
matmul_stimulus #(
    .matrixA_File($sformatf("%sMatrixA.txt",RESOURCE_BASE)),
    .matrixB_File($sformatf("%sMatrixB.txt",RESOURCE_BASE)),
	.modes_File($sformatf("%sModFile.txt",RESOURCE_BASE))
) u_stim (
    .intf(intf),
	.stim_done_o(stim_done),
	.golden_done_i(golden_done_iteration),
	.flags_o(flags),
	.data_sp_o(dataSP)
    // TB Status
);

// Golden-Model module
matmul_golden #(
 .matrixC_File($sformatf("%sMatrixC.txt",RESOURCE_BASE)),
 .errors_File($sformatf("%serrors.txt",RESOURCE_BASE))
) u_golden (
    .intf    (intf),
    // TB Status
    .stim_done_i(stim_done),
	.flags_i(flags),
    .golden_done_o(golden_done),
	.golden_done_iteration_o(golden_done_iteration),
	.data_sp_i(dataSP)
);


initial begin: TB_INIT
    wait(rst_ni); wait(!rst_ni);
	while(golden_done !=1)
		begin
			wait(stim_done);
			$display("[%0t] Stim Done.", $time);
		end
    wait(golden_done);
    $display("[%0t] Check Done.", $time);
    $finish;
end

endmodule // eqn_impl_tester


