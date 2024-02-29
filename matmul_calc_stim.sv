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
module matmul_calc_stim #(
    parameter string matrixA_File = "",
    parameter string matrixB_File = "",
    parameter string matrixC_File = "",
	localparam [4:0] CONTROL    = 5'b00000, // Control address
			         OPERAND_A  = 5'b00100, // Operand-A address
			         OPERAND_B  = 5'b01000, // Operand-B address
				     FLAGS	    = 5'b01100, // flags address
			         SP 		= 5'b10000 // SP address

) (
    matmul_calc_intf.STIMULUS    intf,
    output logic matrix_done_o,
    output logic stim_done_o
);
    integer matrixA_fd,matrixB_fd,matrixC_fd;
    integer MatrixA_rows,MatrixA_colms;
    integer MatrixB_rows,MatrixB_colms;
    integer MatrixC_rows,MatrixC_colms;
	
    logic [BUS_WIDTH-1-1:0] row_data_o;
    logic [BUS_WIDTH-1:0] col_data_o ;
	logic [DATA_WIDTH-1] row_data_cell;
	logic [DATA_WIDTH-1] col_data_cell;
    param_t        param_o;
    // Interface signals connect to internal decl'
    assign intf.ena         = ena_o;
    assign intf.im_pixel = im_pix_o;
    assign intf.w_pixel  = w_pix_o;
    assign intf.param     = param_o;
	
    wire  clk       = intf.clk;
    wire  rst_ni    = intf.rst_ni;
	logic pready_i  = intf.pready_o;
	logic pslverr_i = intf.pslverr_o;
	logic prdata_i  = intf.prdata_o;
	logic busy_i    = intf.busy_o;
    import matmul_calc_pkg::*;   
	
	logic psel_o;
	logic penable_o;
	logic pwrite_o;
	logic [MAX_DIM-1:0] pstrb_o;
	logic [BUS_WIDTH-1:0]  pwdata_o;
	logic [ADDR_WIDTH-1:0] paddr_o;
	
	assign intf.psel_i	  = psel_o;
	assign intf.penable_i = penable_o
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
    if($fscanf(matrixB_fd, "%d\n", col_data_cell) != 1)
            $fatal(1, $sformatf("Failed to read the %0dth data-line of WATMK_FILE", i*BUS_WIDTH+j+1));
end endtask

task read_data_A(input integer i, input integer j); begin
if($fscanf(matrixA_fd, "%d\n", row_data_cell) != 1) 
    $fatal(1, $sformatf("Failed to read the %0dth data-line of IMAGE_FILE", i*BUS_WIDTH+j+1));
     
end endtask



 task set_data(); 
  begin
       //check all 3 files headers of the matrices First line is Matrices dimensions in syntext format of N x K
        //-----------------MatrixA file------------
        if($fscanf(matrixA_fd, "%d x %d\n", MatrixA_rows, MatrixA_colms) != 2) begin  //if the first row is not 2 numbers and they are no
            $fatal(1, "Failed to read the size line of matrixA_FILE");
            $fclose(matrixA_fd);
        end
           
       //-----------------MatrixB file------------    
        if($fscanf(matrixB_fd, "%d x %d\n", MatrixB_rows, MatrixB_colms) != 2) begin
            $fatal(1, "Failed to read the size line of MatrixB_FILE");
            $fclose(matrixB_fd);
        end
        // Sanity check for simple input
        if((MatrixA_rows != N) || (MatrixA_colms != K)) 
            $fatal(1, $sformatf("Bad Configs in  Matrix_A_file, got (%0d,%0d) and (%0d,%0d)",MatrixA_rows,MatrixA_colms,N,K));
        if((MatrixB_rows != K) || (MatrixB_colms != M)) 
            $fatal(1, $sformatf("Bad Configs in  Matrix_B_file, got (%0d,%0d) and (%0d,%0d)",MatrixB_rows,MatrixB_colms,K,M));
       // if((MatrixC_rows != N) || (MatrixC_colms != M)) 
       //     $fatal(1, $sformatf("Bad Configs in Watermark and Matrix_C_file, got (%0d,%0d) and (%0d,%0d)",MatrixC_rows,MatrixC_colms,N,M));  
 end
   endtask

task do_reset; begin
        psel_o = 1'b0;;
		penable_o = 1'b0;
		pwrite_o = 1'b0;;
		pstrb_o  = 0;
		pwdata_o = 0;
		paddr_o  = 0;
        // Open Stimulus files
        open_files(1'b0); // Open all 3
        wait( rst_ni ); // Wait for reset to be asserted
        wait(!rst_ni ); // Wait for reset to be deasserted
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
	#1
	penable_o    = 1'b1;
	pstrb_o      = 
	#2
	psel_o       = 1'b0;
	pwrite_o     = 1'b0;  
end endtask

task apb_write; begin
	input [4:0] module_mem;
	input [5+:$clog2(MAX_DIM)] line;
	input [BUS_WIDTH-1:0] data;
    psel_o       = 1'b1;
	pwrite_o     = 1'b1;
	paddr_o[4:0] = module_mem; 
	paddr_o[5+:$clog2(MAX_DIM)] = line;
	pwdata_o = data;
	#1
	penable_o    = 1'b1;
	pstrb_o      = 
	#2
	psel_o       = 1'b0;
	pwrite_o     = 1'b0;  
end endtask

initial begin : APB_MASTER
    @(posedge clk)
	
	
end

 initial begin: INIT_STIM
        // Initial checks
        if(matrixA_File == "") $fatal(1, "matrixA_File is not set");
        if(matrixB_File == "") $fatal(1, "matrixB_File is not set");
        do_reset();
        // Reset Done
        set_data(1'b1); // First must succeed
        // Start Image Stimulus
        while( stim_valid ) begin
            for(int i=0; i < MatrixA_rows; i=i+1) begin
                for(int j=0; j < MatrixA_colms; j=j+1) begin
                    read_data_A(i,j);
					row_data_o[(DATA_WIDTH*j-1)-:DATA_WIDTH] =  row_data_cell;
                end
                if( VERBOSE )
                    $display("[%7t] Finished Row %0d", $time, i);
				apb_write(OPERAND_A,i,row_data_o)
            end
			
			for(int i=0; i < MatrixB_colms; i=i+1) begin
                for(int j=0; j < MatrixB_rows; j=j+1) begin
					read_data_B(i,j);
                    col_data_o[(DATA_WIDTH*j-1)-:DATA_WIDTH] =  col_data_cell;
                end
                if( VERBOSE )
                    $display("[%7t] Finished Row %0d", $time, i);
				apb_write(OPERAND_B,i,col_data_o)
            end
            set_data(1'b0);
            img_done_o = 1'b1;
            @(posedge clk) img_done_o = 1'b0;
        end
 end






endmodule
