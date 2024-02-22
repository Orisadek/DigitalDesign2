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
    parameter string matrixC_File = ""
) (
    matmul_calc_intf.STIMULUS    intf,
    output logic matrix_done_o,
    output logic stim_done_o
);
    integer matrixA_fd,matrixB_fd,matrixC_fd;
    integer MatrixA_rows,MatrixA_colms;
    integer MatrixB_rows,MatrixB_colms;
    integer MatrixC_rows,MatrixC_colms;
	
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
	logic pstrb_o;
	logic pwdata_o;
	logic paddr_o;
	
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
        
       //-----------------MatrixC file------------    
       // if($fscanf(matrixB, "%d x %d\n", MatrixC_rows, MatrixC_colms) != 2)begin
      //      $fatal(1, "Failed to read the size line of MatrixB_FILE");
      //      $fclose(matrixB);
      //  end
	  
        // Sanity check for simple input
        if((MatrixA_rows != N) || (MatrixA_colms != K)) 
            $fatal(1, $sformatf("Bad Configs in Watermark and Matrix_A_file, got (%0d,%0d) and (%0d,%0d)",MatrixA_rows,MatrixA_colms,N,K));
        if((MatrixB_rows != K) || (MatrixB_colms != M)) 
            $fatal(1, $sformatf("Bad Configs in Watermark and Matrix_B_file, got (%0d,%0d) and (%0d,%0d)",MatrixB_rows,MatrixB_colms,K,M));
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
        wait( rst ); // Wait for reset to be asserted
        wait(!rst ); // Wait for reset to be deasserted
        // Reset done.
end endtask
	
initial begin : APB_MASTER
psel_o <= 1'b1;

//psel_i
//penable_i
//paddr_i
//pwrite
//so on
@(posedge clk)

end

 initial begin: INIT_STIM
        // Initial checks
        if(matrixA_File == "") $fatal(1, "matrixA_File is not set");
        if(matrixB_File == "") $fatal(1, "matrixB_File is not set");
       // if(matrixC_File == "") $fatal(1, "WATMK_FILE is not set");
        // Reset bus and wait for reset process to end
        do_reset();
        // Reset Done
        set_data(1'b1); // First must succeed
        // Start Image Stimulus
        while( stim_valid ) begin
            // Iterate over pixel matrix
            for(int i=0; i < pix_height; i=i+1) begin
                for(int j=0; j < pix_width; j=j+1) begin
                    // Read pixel data
                    read_pixels(i,j);
                    // Set enable with data
                    ena_o = 1'b1; 
                    @(posedge clk) ena_o = 1'b0;
                    // Increment counter
                    @(posedge clk) pix_cnt = pix_cnt + 1;
                end
                if( VERBOSE )
                    $display("[%7t] Finished Row %0d", $time, i);
            end
            set_metadata(1'b0);
            img_done_o = 1'b1;
            @(posedge clk) img_done_o = 1'b0;
        end
 end






endmodule
