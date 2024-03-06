`include "headers.vh"

module matmul_golden #(
    parameter string matrixC_File = "",
	localparam [4:0] CONTROL    = 5'b00000, // Control address
			         OPERAND_A  = 5'b00100, // Operand-A address
			         OPERAND_B  = 5'b01000, // Operand-B address
				     FLAGS	    = 5'b01100, // flags address
			         SP 		= 5'b10000 // SP address

) (
    matmul_intf.GOLDEN    intf
);

	import matmul_pkg::*;   
    integer matrixC_fd;
    integer MatrixC_rows,MatrixC_colms;

	logic [BUS_WIDTH-1:0] MatC_rows_o ;
    logic [BUS_WIDTH-1:0] C_temp;
	
	
    // Interface signals connect to internal decl'	
	
    wire clk_i     = intf.clk_i;
    wire rst_ni    = intf.rst_ni;
	
	wire pready_i  = intf.pready_o;
	wire pslverr_i = intf.pslverr_o;
	wire prdata_i  = intf.prdata_o;
	wire busy_i    = intf.busy_o;
  
 
	string row_data_cell_str;
	string col_data_cell_str;
	 
	logic psel_o;
	logic penable_o;
	logic pwrite_o;
	logic [MAX_DIM-1:0]    pstrb_o;
	logic [BUS_WIDTH-1:0]  pwdata_o;
	logic [ADDR_WIDTH-1:0] paddr_o;
	
	assign intf.psel_i	  = psel_o;
	assign intf.penable_i = penable_o;
	assign intf.pwrite_i  = pwrite_o;
    assign intf.pstrb_i   = pstrb_o;
    assign intf.pwdata_i  = pwdata_o;
    assign intf.paddr_i   = paddr_o;
	
	
string  filename;



 task open_files(); 
    begin
        /*matrixA_fd = $fopen(matrixA_File, "r");
        if(matrixA_fd == 0) $fatal(1, $sformatf("Failed to open %s", matrixA_File));
        matrixB_fd = $fopen(matrixB_File, "r");
        if(matrixB_fd == 0) $fatal(1, $sformatf("Failed to open %s", matrixB_File));
        */
		matrixC_fd = $fopen(matrixC_File, "r");
        if(matrixC_fd == 0) $fatal(1, $sformatf("Failed to open %s", matrixC_File));                       
    end 
 endtask




task do_reset; begin
        psel_o = 1'b0;;
		penable_o = 1'b0;
		pwrite_o = 1'b0;;
		pstrb_o  = 0;
		pwdata_o = 0;
		paddr_o  = 0;
		row_data_o = 0;
		col_data_o = 0;
        // Open Stimulus files
        open_files(); // Open only C file
        // Reset done.
end endtask



task apb_READ(input bit [4:0] module_mem,input bit [$clog2(MAX_DIM):0] line);
	begin
		psel_o       = 1'b1;
		pwrite_o     = 1'b0;
		paddr_o[4:0] = module_mem; 
		paddr_o[5+:$clog2(MAX_DIM)] = line;
		@(posedge clk_i)
		penable_o    = 1'b1;
		@(posedge clk_i)
		psel_o       = 1'b0;  
end endtask


	
module test;
  initial begin
  
    if(matrixA_File == "") $fatal(1, "matrixA_File is not set");
    if(matrixB_File == "") $fatal(1, "matrixB_File is not set");
	if(matrixC_File == "") $fatal(1, "matrixC_File is not set");
	
	first = 1;
	
    int rows, cols;
    signed [BUS_WIDTH-1:0] matrixC [][]; // Declare dynamic array for matrix each element is BUS_WIDTH bits
    
    // Open the file for reading
    open_files();
    
	
	
	
	// Loop until end of file
	while (!$feof(matrixC_fd)) begin
	  int error = 0;
      // Read dimensions of the matrix from the file
      if ($fscanf(matrixC_fd, "%d x %d", rows, cols) != 2) begin
        if(first) begin
			$fatal(1, $sformatf("FILE IS EMPTY")); 	 //if the file is empty display fatal error
		end
		else begin
		$display("Error reading dimensions.");
		$fclose(matrixC_fd);
		return;
		end
      end
      
      // Allocate memory for the matrix based on dimensions
      matrixC = new[rows][cols];
      
      // Read each number from the file into the matrix
      for (int i = 0; i < rows; i++) begin
        for (int j = 0; j < cols; j++) begin
          if ($fscanf(matrixC_fd, "%d", matrixC[i][j]) != 1) begin
            $fatal(1, $sformatf("failed to read data from matrixC_File in index %d x %d.", i+1, j+1));
			//$display("Error reading file.");
			//$fclose(file);
            //return;
          end
        end
      end
	  
	  //bringing the C result from the SP.
	  apb_READ(SP,i);
	  C_temp = prdata_i;
	  
	  //compare MATLAB matrixC[i][j] to our intf.
	  if(C_temp != matrixC[i][j])begin
		error = error + 1;
		$display("Error, the number in GOLDEN does not match the number in Sp, epected to read %d and instead read %d",matrixC[i][j],C_temp);
		end

		
    
    // Close the file
    $fclose(file);
  end
endmodule

endmodule

