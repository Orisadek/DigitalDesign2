//
// Verilog Module Ori_Alon_Lab_2_copy_lib.matmul_calc_stim
//
// Created:
//          by - vain.UNKNOWN (TOMER)
//          at - 10:11:33 02/19/2024
//
// using Mentor Graphics HDL Designer(TM) 2019.2 (Build 5)
//

`resetall
`timescale 1ns/10ps
module matmul_stimulus #(
    parameter string matrixA_File = "",
    parameter string matrixB_File = "",
    parameter string matrixC_File = "",
	localparam [4:0] CONTROL    = 5'b00000, // Control address
			         OPERAND_A  = 5'b00100, // Operand-A address
			         OPERAND_B  = 5'b01000, // Operand-B address
				     FLAGS	    = 5'b01100, // flags address
			         SP 		= 5'b10000 // SP address

) (
    matmul_intf.STIMULUS    intf
);
    import matmul_pkg::*;   
    integer matrixA_fd,matrixB_fd,matrixC_fd;
    integer MatrixA_rows,MatrixA_colms;
    integer MatrixB_rows,MatrixB_colms;
    integer MatrixC_rows,MatrixC_colms;
	
    logic [BUS_WIDTH-1-1:0] row_data_o;
    logic [BUS_WIDTH-1:0] col_data_o ;
	logic [DATA_WIDTH-1:0] row_data_cell;
	logic [DATA_WIDTH-1:0] col_data_cell;
	 
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
	logic [MAX_DIM-1:0] pstrb_o;
	logic [BUS_WIDTH-1:0]  pwdata_o;
	logic [ADDR_WIDTH-1:0] paddr_o;
	
	assign intf.psel_i	  = psel_o;
	assign intf.penable_i = penable_o;
	assign intf.pwrite_i  = pwrite_o;
    assign intf.pstrb_i   = pstrb_o;
    assign intf.pwdata_i  = pwdata_o;
    assign intf.paddr_i   = paddr_o;
	
	
 task open_files(); 
    begin
        matrixA_fd = $fopen(matrixA_File, "r");
        if(matrixA_fd == 0) $fatal(1, $sformatf("Failed to open %s", matrixA_File));
        matrixB_fd = $fopen(matrixB_File, "r");
        if(matrixB_fd == 0) $fatal(1, $sformatf("Failed to open %s", matrixB_File));
       // matrixC = $fopen(matrixC, "r");
      //  if(matrixA == 0) $fatal(1, $sformatf("Failed to open %s", matrixC_File));                       
    end 
 endtask


task read_data_B(input integer i, input integer j); begin
	logic [DATA_WIDTH-1:0] col_data_cell_temp;
	$display(i,j,"i,j read_data_B");
    if($fscanf(matrixB_fd, "%s[^\n]", col_data_cell_str) != 1)
            $fatal(1, $sformatf("Failed to read the %0dth data-line of MatB", i*BUS_WIDTH+j+1));
	 $sscanf(col_data_cell_str, "%0d", col_data_cell_temp);
	$display("col_data_cell_str",col_data_cell_str);
	$display("col_data_cell_temp %0b",col_data_cell_temp);
	col_data_o[((i+1)*DATA_WIDTH+DATA_WIDTH*MatrixB_rows*j-1)-:DATA_WIDTH] = col_data_cell_temp;
end endtask

task read_data_A(input integer i, input integer j); begin
	logic [DATA_WIDTH-1:0] row_data_cell_temp;
	if($fscanf(matrixA_fd, "%s[^\n]", row_data_cell_str) != 1) 
				$fatal(1, $sformatf("Failed to read the %0dth data-line of MatA", i*BUS_WIDTH+j+1)); 
	$sscanf(row_data_cell_str, "%0d", row_data_cell_temp);
	$display(row_data_cell_str,"row_data_cell");
	$display(row_data_cell_temp,"row_data_cell_temp");
	row_data_o[(DATA_WIDTH*(i+1)+DATA_WIDTH*MatrixA_colms*j-1)-:DATA_WIDTH] = row_data_cell_temp;
end endtask



 task set_data(); 
  begin
       //check all 3 files headers of the matrices First line is Matrices dimensions in syntext format of N x K
        //-----------------MatrixA file------------
	    $display("set_data");
		if($fscanf(matrixA_fd, "%d x %d\n", MatrixA_rows, MatrixA_colms) != 2) begin  //if the first row is not 2 numbers and they are no
            $fatal(1, "Failed to read the size line of matrixA_FILE");
            $fclose(matrixA_fd);
        end
		  $display(MatrixA_rows,"MatrixA_rows");
       //-----------------MatrixB file------------    
        if($fscanf(matrixB_fd, "%d x %d\n", MatrixB_rows, MatrixB_colms) != 2) begin
            $fatal(1, "Failed to read the size line of MatrixB_FILE");
            $fclose(matrixB_fd);
        end
		/*
        // Sanity check for simple input
        if((MatrixA_rows != N) || (MatrixA_colms != K)) 
            $fatal(1, $sformatf("Bad Configs in  Matrix_A_file, got (%0d,%0d) and (%0d,%0d)",MatrixA_rows,MatrixA_colms,N,K));
        if((MatrixB_rows != K) || (MatrixB_colms != M)) 
            $fatal(1, $sformatf("Bad Configs in  Matrix_B_file, got (%0d,%0d) and (%0d,%0d)",MatrixB_rows,MatrixB_colms,K,M));
       // if((MatrixC_rows != N) || (MatrixC_colms != M)) 
       //     $fatal(1, $sformatf("Bad Configs in Watermark and Matrix_C_file, got (%0d,%0d) and (%0d,%0d)",MatrixC_rows,MatrixC_colms,N,M)); 
		*/	   
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
        open_files(); // Open all 3
        // Reset done.
end endtask
	
task apb_write_control; begin
    psel_o       = 1'b1;
	pwrite_o     = 1'b1;
	paddr_o[4:0] = CONTROL; 
	pwdata_o[3:2]= 2'b00;
	pwdata_o[5:4]= 2'b00;
	pwdata_o[9:8]= 2'b01;
	pwdata_o[11:10]= 2'b01;
	pwdata_o[13:12]= 2'b01;
	#2
	penable_o    = 1'b1;
	pstrb_o      = 4'b1111;
	#2
	psel_o       = 1'b0;
	pwrite_o     = 1'b0;  
end endtask

task apb_write(input bit [4:0] module_mem,input bit [$clog2(MAX_DIM):0] line,input bit [BUS_WIDTH-1:0] data);
	begin
		psel_o       = 1'b1;
		pwrite_o     = 1'b1;
		paddr_o[4:0] = module_mem; 
		paddr_o[5+:$clog2(MAX_DIM)] = line;
		pwdata_o     = data;
		@(posedge clk_i)
		penable_o    = 1'b1;
		pstrb_o      = 4'b1111;
		@(posedge clk_i)
		psel_o       = 1'b0;
		pwrite_o     = 1'b0;  
end endtask

/*
initial begin : APB_MASTER
    @(posedge clk)
	
	
end
*/

// stim_valid init 1 in rst , 0 in EOF
// bind - try to use 
 initial begin: INIT_STIM
        // Initial checks
        if(matrixA_File == "") $fatal(1, "matrixA_File is not set");
        if(matrixB_File == "") $fatal(1, "matrixB_File is not set");

		wait (rst_ni == 1'b0);
	    do_reset();
        // Reset Done
		$display("INIT_STIM");
		
		wait (rst_ni == 1'b1);
		
	    
        set_data(); // First must succeed
        // Start Image Stimulus
      //  while( stim_valid ) begin
		//	wait(!rst_ni );
            for(int i=0; i < MatrixA_rows; i=i+1) begin
                for(int j=0; j < MatrixA_colms; j=j+1) begin
					logic [DATA_WIDTH-1:0] temp;
					read_data_A(i,j);
                end
              //  if( VERBOSE )
                 $display("Finished Row %0d", i);
				@(posedge clk_i)apb_write(OPERAND_A,i,row_data_o);
            end
			
			for(int i=0; i < MatrixB_colms; i=i+1) begin
                for(int j=0; j < MatrixB_rows; j=j+1) begin
                   read_data_B(i,j);
                end
             //   if( VERBOSE )
               //     $display("[%7t] Finished Row %0d", $time, i);
				@(posedge clk_i)apb_write(OPERAND_B,i,col_data_o);
            end
           // set_data();
         //   img_done_o = 1'b1;
         //   @(posedge clk) img_done_o = 1'b0;
      //  end
 end






endmodule
