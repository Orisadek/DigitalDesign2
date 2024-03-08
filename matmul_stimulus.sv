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
	parameter string modes_File = "",
	localparam [4:0] CONTROL    = 5'b00000, // Control address
					 OPERAND_A  = 5'b00100, // Operand-A address
					 OPERAND_B  = 5'b01000, // Operand-B address
					 FLAGS	    = 5'b01100, // flags address
					 SP0 		= 5'b10000, // SP address
					 SP1 		= 5'b10100, // SP address
					 SP2 		= 5'b11000, // SP address
					 SP3 		= 5'b11100 // SP address
) (
    matmul_intf.STIMULUS    intf,
	output logic stim_done_o,
	output logic [(matmul_pkg::BUS_WIDTH)*(matmul_pkg::MAX_DIM)*(matmul_pkg::MAX_DIM)-1:0] data_sp_o,
	input  logic golden_done_i
);
    import matmul_pkg::*;  
	//---------------------------------variables---------------------------------------// 
    integer matrixA_fd,matrixB_fd,matrixC_fd,modes_fd;
    integer MatrixA_rows,MatrixA_colms;
    integer MatrixB_rows,MatrixB_colms;
    integer MatrixC_rows,MatrixC_colms;
	reg  [BUS_WIDTH*MAX_DIM*MAX_DIM-1:0] dataTempSp;
    logic [BUS_WIDTH-1:0] rowData;
    logic [BUS_WIDTH-1:0] colData ;
	logic [DATA_WIDTH-1:0] row_data_cell;
	logic [DATA_WIDTH-1:0] col_data_cell;
	logic  modeBit;
	logic [1:0] writeTarget;
	logic [1:0] readTarget;
	reg stim_valid;
	string row_data_cell_str;
	string col_data_cell_str;
    //--------------------------------interface connection----------------------------//	
    wire clk_i     = intf.clk_i;
    wire rst_ni    = intf.rst_ni;
	wire pready_i  = intf.pready_o;
	wire pslverr_i = intf.pslverr_o;
	wire signed [BUS_WIDTH-1:0] prdata_i  = intf.prdata_o;
	
	wire busy_i    = intf.busy_o;
	logic psel_o;
	logic penable_o;
	logic pwrite_o;
	logic [MAX_DIM-1:0] pstrb_o;
	logic signed [BUS_WIDTH-1:0] pwdata_o;
	logic [ADDR_WIDTH-1:0] paddr_o;

	//----------------------------assign interface signals----------------------------//
	
	assign intf.psel_i	  = psel_o;
	assign intf.penable_i = penable_o;
	assign intf.pwrite_i  = pwrite_o;
    assign intf.pstrb_i   = pstrb_o;
    assign intf.pwdata_i  = pwdata_o;
    assign intf.paddr_i   = paddr_o;
	assign data_sp_o      = dataTempSp;

//-----------------------------tasks---------------------------------------------------//	
//-----------------------------open files----------------------------------------------//
 task open_files(); 
    begin
        matrixA_fd = $fopen(matrixA_File, "r");
        if(matrixA_fd == 0) $fatal(1, $sformatf("Failed to open %s", matrixA_File));
        matrixB_fd = $fopen(matrixB_File, "r");
        if(matrixB_fd == 0) $fatal(1, $sformatf("Failed to open %s", matrixB_File));
		 modes_fd = $fopen(modes_File, "r");
        if(modes_fd == 0) $fatal(1, $sformatf("Failed to open %s", modes_fd));
                          
    end 
 endtask
//--------------------------read matrix B cell --------------------------------------//
task read_data_B(input integer i, input integer j); begin
	logic [DATA_WIDTH-1:0] col_data_cell_temp;
    if($fscanf(matrixB_fd, "%s[^\n]", col_data_cell_str) != 1)
            $fatal(1, $sformatf("Failed to read the %0dth data-line of MatB", i*BUS_WIDTH+j+1));
	$sscanf(col_data_cell_str, "%0d", col_data_cell_temp);
	colData[((j+1)*DATA_WIDTH-1)-:DATA_WIDTH] = col_data_cell_temp;
end endtask

//--------------------------read matrix A cell --------------------------------------//
task read_data_A(input integer i, input integer j); begin
	logic signed [DATA_WIDTH-1:0] row_data_cell_temp;
	if($fscanf(matrixA_fd, "%s[^\n]", row_data_cell_str) != 1) 
				$fatal(1, $sformatf("Failed to read the %0dth data-line of MatA", i*BUS_WIDTH+j+1)); 
	$sscanf(row_data_cell_str, "%0d", row_data_cell_temp);
	rowData[(DATA_WIDTH*(j+1)-1)-:DATA_WIDTH] = row_data_cell_temp;
end endtask

//------------------------set data variables ----------------------------------------//
 task set_data(); 
  begin
       //check all 3 files headers of the matrices First line is Matrices dimensions in syntext format of N x K
        //-----------------MatrixA file------------//
		if($fscanf(matrixA_fd, "%d x %d\n", MatrixA_rows, MatrixA_colms) != 2) begin  //if the first row is not 2 numbers and they are no
			$fatal(1, "Failed to read the size line of matrixA_FILE");
            $fclose(matrixA_fd);
        end
		  $display(MatrixA_rows,"MatrixA_rows");
       //-----------------MatrixB file------------ //  
        if($fscanf(matrixB_fd, "%d x %d\n", MatrixB_rows, MatrixB_colms) != 2) begin
            $fatal(1, "Failed to read the size line of MatrixB_FILE");
            $fclose(matrixB_fd);
        end  
       //-----------------Modes file------------ //  
		if($fscanf(modes_fd, "modbit = %d, write target %d, read target %d \n", modeBit, writeTarget,readTarget) != 3) begin
            $fatal(1, "Failed to read the size line of Mode_FILE");
            $fclose(modes_fd);
        end  
		
 end
   endtask

//----------------------------------do reset --------------------------------------------------//
task do_reset; begin
        psel_o     = 1'b0;
		penable_o  = 1'b0;
		pwrite_o   = 1'b0;
		pstrb_o    = {(MAX_DIM){1'b0}};
		pwdata_o   = {(BUS_WIDTH){1'b0}};
		paddr_o    = {(ADDR_WIDTH){1'b0}};
		rowData    = {(BUS_WIDTH){1'b0}};
		colData    = {(BUS_WIDTH){1'b0}};
		dataTempSp   = 0;
		stim_valid = 1'b1;
		stim_done_o = 1'b0;
        // Open Stimulus files
        open_files(); // Open all 3
        // Reset done.
end endtask

//---------------------------------read data----------------------------------------------------//
task apb_read(input bit [4:0] module_mem,input bit [2*$clog2(MAX_DIM):0] line,output  bit signed [BUS_WIDTH-1:0] data);
	begin
		$display("apb_read %d ",module_mem);
		psel_o       = 1'b1;
		pwrite_o     = 1'b0;
		paddr_o[4:0] = module_mem; 
		paddr_o[5+:2*$clog2(MAX_DIM)] = line;
		@(posedge clk_i)
		penable_o    = 1'b1;
		pstrb_o      = 4'b0000;
		//wait(pready_i==1);
		@(posedge clk_i)
		data = prdata_i;		
		#1
		penable_o    = 1'b0;
		psel_o       = 1'b0;
		pwrite_o     = 1'b0; 		
end endtask	

//---------------------------------write data------------------------------------------------------//
task apb_write(input bit [4:0] module_mem,input bit [$clog2(MAX_DIM)-1:0] line,input bit [BUS_WIDTH-1:0] data);
	begin
		wait(pslverr_i == 1'b0);
		psel_o       = 1'b1;
		pwrite_o     = 1'b1;
		paddr_o[4:0] = module_mem; 
		paddr_o[5+:$clog2(MAX_DIM)] = line;
		pwdata_o     = data;
		@(posedge clk_i)
		penable_o    = 1'b1;
		pstrb_o      = 4'b1111;
		wait(pready_i==1);
		@(posedge clk_i)
		#1
		penable_o    = 1'b0;
		psel_o       = 1'b0;
		pwrite_o     = 1'b0;  
		pstrb_o      = 4'b0000;
end endtask

//--------------------------------write to control-----------------------------------------------------//
task control_write(input bit start_bit,input bit mode_bit ,input bit [1:0] write_target,input bit [1:0] read_target,
					input bit [1:0] n,input bit [1:0] k,input bit [1:0] m);
	begin
			bit [15:0] control_bit;  
			control_bit[0] = start_bit;
			control_bit[1] = mode_bit;
			control_bit[3:2]= write_target-1;
			if(read_target == 0)
				control_bit[5:4]= read_target;
			else
				control_bit[5:4]= read_target -1;
			control_bit[9:8]= n;
			control_bit[11:10]= k;
			control_bit[13:12]= m;
			@(posedge clk_i)apb_write(CONTROL,{($clog2(MAX_DIM)){1'b0}},control_bit);
end endtask

//----------------------------------Init block------------------------------------------------------//

 initial begin: INIT_STIM
        // Initial checks
		logic [4:0] spIdx;
        if(matrixA_File == "") $fatal(1, "matrixA_File is not set");
        if(matrixB_File == "") $fatal(1, "matrixB_File is not set");
		if(modes_File == "") $fatal(1, "modes_File is not set");
		wait (rst_ni == 1'b0);
	    do_reset();
        // Reset Done
		wait (rst_ni == 1'b1);
        // Start Image Stimulus
        while(stim_valid == 1 && $feof(matrixB_fd) == 0 && $feof(matrixA_fd)== 0) begin
		
			set_data(); // First must succeed
            for(int i=0; i < MatrixA_rows; i=i+1) begin
                for(int j=0; j < MatrixA_colms; j=j+1) begin
					read_data_A(i,j);
                end
              //  if( VERBOSE )
          //       $display("Finished Row %0d", i);
				@(posedge clk_i)apb_write(OPERAND_A,i,rowData);
            end
			
			for(int i=0; i < MatrixB_colms; i=i+1) begin
                for(int j = 0; j < MatrixB_rows; j=j+1) begin
                   read_data_B(i,j);
                end
            //    $display("Finished Col %0d", i);
				@(posedge clk_i)apb_write(OPERAND_B,i,colData);
            end
			 control_write(1'b1,modeBit ,writeTarget,readTarget,
					MatrixA_rows-1,MatrixA_colms-1,MatrixB_colms-1);
			wait(busy_i == 1'b0);
			rowData   = {(BUS_WIDTH){1'b0}};
			colData   = {(BUS_WIDTH){1'b0}};
			
			case(writeTarget) 
				2'b00:    spIdx = SP0;
				2'b01:    spIdx = SP1;
				2'b10:    spIdx = SP2;
				2'b11:    spIdx = SP3;
				default : spIdx = SP0;
			endcase
			
			for(int i = 0 ; i <MAX_DIM;i = i+1)
				begin
					for(int j = 0 ; j < MAX_DIM;j = j+1)
						begin
							@(posedge clk_i) apb_read(spIdx,i*MAX_DIM+j,dataTempSp[i*BUS_WIDTH*MAX_DIM + j*BUS_WIDTH+:BUS_WIDTH]);
						end
				end
			stim_done_o = 1'b1;
			wait(golden_done_i == 1'b1);
			stim_done_o = 1'b0;
        end
		$fclose(matrixA_fd);
		$fclose(matrixB_fd);
 end


// change busy_i - so when matmul busy_i=1
// add wait until not bust
// change, when err stay until Reset
// add when EOF get out of file



endmodule
