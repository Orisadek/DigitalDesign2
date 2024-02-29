`include "headers.vh"

module matmul_calc_golden #(
    parameter string        GOLDENFILE = "",
    parameter string        OUTFILE = "" // Expected with no type (.raw added here)
)();

    // Only samples the bus -> uses the same type of interface as checker/coverage

import matmul_calc_pkg::matA,matB,matC,N,M,K; //IMPORT THE SIZES OF N,M,K AND THE MATRICES TYPES matA/B/C which are array of N by K / K by M / N x M arrays, where each element is a vector of width DATA_WIDTH

matA   matrixA;
matB   matrixB;
matC   matrixC;

integer out_fd;
integer out_cnt = 0;
string  filename;

always @(posedge clk or posedge rst) begin: CHECKER_SP_FF
    if(rst) begin
        matrixA      <= '{default: '0}; // Push 0 to all memory cells
        matrixB      <= '{default: '0};
        matrixC      <= '{default: '0};
        enable       <= 1'b0;
    end else begin
        enable       <=  intf.ena;
        if(enable) begin //IF WE WANT TO write to the SP
            mem[mem_addr] <=  intf.iw_pixel;
            mem_addr      <=  mem_addr + 1;
        end else if( img_done_i ) begin
            mem_addr <= '0;
        end

    end
end


task check_golden(input string golden_f_A,golden_f_B,golden_f_C);
  automatic int gfd, glog, golden_errors = 0;
	automatic string err_str;
	automatic real min_rng, max_rng;
begin
    gfdA = $fopen(golden_f_A, "r"); //read file A
    gfdB = $fopen(golden_f_B, "r"); //read file B
    gfdC = $fopen(golden_f_C, "r"); //read file C
    if(gfdA == 0)
        $fatal(1, $sformatf("Failed to open '%s' for reading.", golden_f_A));     //check that the matrices data were read.
    if(gfdB == 0)
        $fatal(1, $sformatf("Failed to open '%s' for reading.", golden_f_B));
    if(gfdC == 0)
        $fatal(1, $sformatf("Failed to open '%s' for reading.", golden_f_C));
    
    
            
    if(($fscanf(gfdA, "%d x %d\n", golden_marix_rows, golden_matrix_col) != 2) || ~(golden_marix_rows == N && golden_matrix_col == K)) //checks the size of A matrix is fine (the file start with N x K )
        $fatal(1, $sformatf("Bad golden dims : %d x %d in matrix A.", golden_marix_rows, golden_matrix_col));
    if(($fscanf(gfdB, "%d x %d\n", golden_marix_rows, golden_matrix_col) != 2) || ~(golden_marix_rows == K && golden_matrix_col == M)) //checks the size of B matrix is fine (the file start with K x M )
        $fatal(1, $sformatf("Bad golden dims : %d x %d. in matrix B", golden_marix_rows, golden_matrix_col));
    if(($fscanf(gfdC, "%d x %d\n", golden_marix_rows, golden_matrix_col) != 2) || ~(golden_marix_rows == N && golden_matrix_col == M)) //checks the size of A matrix is fine (the file start with N x M )
        $fatal(1, $sformatf("Bad golden dims : %d x %d. in matrix C", golden_marix_rows, golden_matrix_col));        
	
 
	
    for(int j = 0; j < mem_addr; j = j + 1) 
      begin
        if($fscanf(gfd, "%d\n", golden_dat) != 1)
                $fatal(1, $sformatf("Failed to read golden pixel at index : %d", j));
    		min_rng = real'(golden_dat)*(1.0 - golden_err);
    		max_rng = real'(golden_dat)*(1.0 + golden_err);
    		if(max_rng > 255.0) max_rng = 255.0;
    		// Check
    		
    		if(!(real'(mem[j]) inside {[min_rng : max_rng]}))
    		begin: WARN_GOLD_MODEL
    			err_str = $sformatf("Golden model error is not in accepted range at index %0d.\n\tExpected : [%3.3f:%3.3f] , Received : %d", j+1, min_rng, max_rng, mem[j]);
    			if(glog != 0) $fdisplay(glog, err_str);
    			else $warning("\n\t%s", err_str);
    			golden_errors += 1;
    		end
	end
	// Your mission, if you choose to accept it,
	// is to find the cause.
	if(golden_errors > 0) $warning("Total %0d golden model errors out of %0d pixels", golden_errors, golden_h*golden_w);
    $fclose(gfd);
	if(glog != 0) $fclose(glog);
end
endtask






initial begin: INIT_GOLDEN
    if(OUTFILE == "") //if there is no OUTFILE show fatal Error
        $fatal(1, "[GOLDEN] OUTFILE must be set!");
    golden_done_o = 1'b0;
    wait(rst);
    wait(!rst); // Reset done
    while(!stim_done_i) begin
        wait( img_done_i | stim_done_i );
        if( ~img_done_i & stim_done_i ) break;
      
        // String operation to create file name
        filename = $sformatf("%s_%0d.raw", OUTFILE, out_cnt);
		`ifndef VERILATOR
		// Mismatch between simulators ...
        #1
		`endif
        // Sanity check
        if(mem_addr != addr_t'(out_width_i*out_height_i))
            $fatal(1, $sformatf("Output dims not as expected.\nExpected : %0d x %0d = %0d\nGot (serialized) : %0d", out_width_i, out_height_i, out_width_i*out_height_i, mem_addr));
        else if( VERBOSE )
            $display("[%8t:GOLDEN] Writing output file :: %s\n\tSize : %0d[B]", $time, filename, mem_addr);
        
        // Compare
        if(GOLDENFILE == OUTFILE) begin
            // Multiple golden result files
            check_golden($sformatf("%s_golden%0d.raw", OUTFILE, out_cnt));
        end else if (GOLDENFILE != "") begin
            check_golden(GOLDENFILE);
        end

        // Write output file
        out_fd = $fopen(filename, "w"); // File creation
        if(out_fd == 0) 
            $fatal(1, $sformatf("Failed to open '%s' for writing.", filename));
        // Write data to file
        $fdisplay(out_fd, "%0d x %0d", out_width_i, out_height_i);
        for(int j = 0; j < mem_addr; j = j + 1)
            $fdisplay(out_fd, "%0d", mem[j]);
        $fclose(out_fd);
        out_cnt = out_cnt + 1;
        wait( !img_done_i | stim_done_i );
    end
    if( VERBOSE )
        $display("[%7t:GOLDEN] DONE", $time);
    golden_done_o = 1'b1;
end

endmodule

