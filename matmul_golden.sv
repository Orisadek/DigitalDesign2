`include "headers.vh"

module matmul_golden #(
    parameter string matrixC_File = "",
	localparam [4:0] CONTROL    = 5'b00000, // Control address
			         OPERAND_A  = 5'b00100, // Operand-A address
			         OPERAND_B  = 5'b01000, // Operand-B address
				     FLAGS	    = 5'b01100, // flags address
			         SP 		= 5'b10000 // SP address

) (
    matmul_intf.GOLDEN    intf,
	input wire stim_done_i,
	input wire [(matmul_pkg::BUS_WIDTH)*(matmul_pkg::MAX_DIM)*(matmul_pkg::MAX_DIM)-1:0] data_sp_i,
    output logic golden_done_o,
	output logic golden_done_iteration_o
);
	import matmul_pkg::*;   
    integer matrixC_fd;
    integer MatrixC_rows,MatrixC_colms;
	logic signed [BUS_WIDTH-1:0] dataSpCell;
	logic [BUS_WIDTH-1:0] MatC_rows_o ;
	
    // Interface signals connect to internal decl'	
	//wire [BUS_WIDTH-1:0] data_i [MAX_DIM-1:0][MAX_DIM-1:0] = intf.dataSp;
    wire clk_i     = intf.clk_i;
    wire rst_ni    = intf.rst_ni;
	 
 task open_files(); 
    begin
		matrixC_fd = $fopen(matrixC_File, "r");
        if(matrixC_fd == 0) $fatal(1, $sformatf("Failed to open %s", matrixC_File));                       
    end 
 endtask

task do_reset; begin
        open_files(); // Open only C file
		// Reset done.
end endtask


initial begin:GOLDEN_MODEL
    int rows, cols;
	int errors;
    bit signed  [BUS_WIDTH-1:0] matrixC [][]; // Declare dynamic array for matrix each element is BUS_WIDTH bits
	if(matrixC_File == "") $fatal(1, "matrixC_File is not set");
    // Open the file for reading
    do_reset();
	// Loop until end of file
	while (!$feof(matrixC_fd)) 
		begin
		wait(stim_done_i == 1'b0);
		golden_done_iteration_o = 0;
		wait(stim_done_i == 1'b1);
      // Read dimensions of the matrix from the file
			if ($fscanf(matrixC_fd, "%d x %d", rows, cols) != 2) 
				begin
					$display("Error reading dimensions.");
					$fclose(matrixC_fd);
					break;
				end
      // Allocate memory for the matrix based on dimensions
			matrixC = new[rows];
			foreach(matrixC[k])
				matrixC[k] = new[cols];
      // Read each number from the file into the matrix
			for (int i = 0; i < rows; i++) begin
				for (int j = 0; j < cols; j++) begin
					string matCTemp;
					if ($fscanf(matrixC_fd, "%s[^/n]", matCTemp) != 1) begin
						$fatal(1, $sformatf("failed to read data from matrixC_File in index %d x %d.", i+1, j+1));
						$fclose(matrixC_fd);
						end
					$sscanf(matCTemp, "%0d", matrixC[i][j]);
				end
			end
			errors = 0;
			for (int i = 0; i < rows; i++)
				begin
					for (int j = 0; j < cols; j++)
						begin
						//bringing the C result from the SP.
						//compare MATLAB matrixC[i][j] to our intf.
							if(data_sp_i[i*BUS_WIDTH*MAX_DIM + j*MAX_DIM+BUS_WIDTH-1])
								begin
									if(signed'(data_sp_i[i*BUS_WIDTH*MAX_DIM + j*BUS_WIDTH+:BUS_WIDTH]) != matrixC[i][j])
										begin
											errors++;
											$display("Error, the number in GOLDEN does not match the number in Sp, epected to read %d and instead read %d",matrixC[i][j],signed'(data_sp_i[i*BUS_WIDTH*MAX_DIM + j*MAX_DIM+:BUS_WIDTH]));
										end
								end
							else
								begin
									if(data_sp_i[i*BUS_WIDTH*MAX_DIM+j*BUS_WIDTH+:BUS_WIDTH] != matrixC[i][j])
										begin
											errors++;
											$display("Error, the number in GOLDEN does not match the number in Sp, epected to read %d and instead read %d",matrixC[i][j],data_sp_i[i*BUS_WIDTH*MAX_DIM + j*MAX_DIM+:BUS_WIDTH]);
										end
								end
						end
				end
			$display("There are %d errors",errors);
			golden_done_iteration_o = 1'b1;
		end
	$fclose(matrixC_fd);
	golden_done_o = 1;
	end
endmodule



