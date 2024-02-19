//
// Verilog Module Ori_Alon_Lab_1_lib.apb_slave_module
//
// Created:
//          by - vain.UNKNOWN (TOMER)
//          at - 08:32:44 01/30/2024
//
// using Mentor Graphics HDL Designer(TM) 2019.2 (Build 5)
//

`resetall
`timescale 1ns/10ps

module apb_slave_module(clk_i,rst_ni,psel_i,penable_i,pwrite_i,pstrb_i,pwdata_i,
paddr_i,bus_mem_i,start_bit_i,address_o,pready_o,pslverr_o,
prdata_o,busy_o,bus_mem_o); // ports
input clk_i,rst_ni,psel_i,penable_i,pwrite_i; // input ports
input pstrb_i,pwdata_i,paddr_i,bus_mem_i; // input ports
input start_bit_i;
output pready_o,pslverr_o,prdata_o,busy_o,bus_mem_o,address_o; // output ports
parameter DATA_WIDTH = 32; // data width
parameter BUS_WIDTH = 64; // bus width
parameter ADDR_WIDTH = 32; // address width
localparam MAX_DIM = BUS_WIDTH/DATA_WIDTH; // max dim of the matrix/ max dim of the matrix  NEVER USED
localparam [1:0] IDLE          = 2'b00, // idle state
			     ACCESS_READ   = 2'b01, // read state
			     ACCESS_WRITE  = 2'b10; // write state			 
localparam [4:0] SP    = 5'b10000,
				 FLAGS = 5'b01100;
wire clk_i, rst_ni; // define clk and rst
wire psel_i,penable_i,pwrite_i; // psel - choose the module (we only have one - matmul) , penable - enable to the APB ,pwrite - write mode or read mode
wire [MAX_DIM-1:0] pstrb_i; //for every byte there is a Pstrb[n]
wire [BUS_WIDTH-1:0] pwdata_i; // data in
wire [BUS_WIDTH-1:0] bus_mem_i;
wire [ADDR_WIDTH-1:0] paddr_i; // address in
reg  [ADDR_WIDTH-1:0] address_o;
reg  pready_o,pready_next;    // ready out and next
reg  pslverr_o,pslverr_next;   // error out and next
reg  busy_o,next_busy;
reg  [BUS_WIDTH-1:0] prdata_o, prdata_next,bus_mem_o; // data out and next
reg  [1:0] current_state,next_state;   // current state and next
wire start_bit_i;
reg  [ADDR_WIDTH-1:0] address_next;

always @(*)	// combinatorical always
	begin: apb_comb
		 case(current_state)  // current state
      		IDLE: // idle
      			begin
      				if(psel_i) //if pslverr_o==1 then a reset is needed, can be changed if we want that pslverr_o	will not stop the APB			          				  
        				begin 
   				            pready_next  = 1'b0;  // not ready
        				    next_busy    = 1'b1;  // is busy
						    pslverr_next = 1'b0; // no error
          					if(pwrite_i) 	// if pwrite == 1
            					begin
									next_state = ACCESS_WRITE; // next state is write	
									address_next  = paddr_i;	
								 end
							 else
								 begin
									next_state = ACCESS_READ; // next state is read	
									address_next  = paddr_i;	
								 end	
							prdata_next  = {(BUS_WIDTH){1'b0}};
						end
					else
						begin
							pready_next  = 1'b0;  // not ready
        				    next_busy    = 1'b0;  // is busy
						    pslverr_next = 1'b0; // no error
          					next_state = IDLE; // next state is write	
							address_next  = {(ADDR_WIDTH){1'b0}};	
							prdata_next  = {(BUS_WIDTH){1'b0}};
						end
				end
	    
   		   ACCESS_READ: // read state
      			begin
					if(psel_i && ~pstrb_i && ~start_bit_i) // during READ all pstrob[n] must be low.
						begin
							pready_next  = penable_i ? 1'b1 : 1'b0;  // allow next op 
							prdata_next  = penable_i ? bus_mem_i : {(BUS_WIDTH){1'b0}}; //insert the data from ram to prdata_o bus.
							next_state   = penable_i ? IDLE : ACCESS_READ; // go to idle / stay
							next_busy    = penable_i ? 1'b0: 1'b1;  //  busy
							pslverr_next = 1'b0; // without an err
							address_next = {(ADDR_WIDTH){1'b0}};
						end // end if
					else
						begin //if the psel fall betwine clocks the transaction is an error
          				    next_state   = IDLE; // go to idle
          			   		pslverr_next = 1'b1; //either the sel fall during clocks or strob is not 0, transaction is not valid.
          			   		prdata_next  = {(BUS_WIDTH){1'b0}}; // data 0	
							pready_next  = 1'b0;  // not ready
							next_busy    = 1'b1;  // is busy
							address_next = {(ADDR_WIDTH){1'b0}};
  					    end // end else
      			end // end read
      			
      		ACCESS_WRITE: // write state
			    begin
					if(psel_i && ~start_bit_i) // if pasel == 1
						begin
							pready_next  = penable_i ? 1'b1 : 1'b0;  // allow next op
							next_state   = penable_i ? IDLE : ACCESS_WRITE; // go to idle / stay
							next_busy    = penable_i ? 1'b0: 1'b1;  //  busy
							pslverr_next = ~(paddr_i[4:0] == FLAGS || paddr_i[4:0] == SP) ? 1'b0 : 1'b1; // without an err
							prdata_next  = {(BUS_WIDTH){1'b0}}; // data 0	
							address_next = {(ADDR_WIDTH){1'b0}};
						end // end if
					else
						begin //if the psel fall during the transaction its an error
          					next_state   = IDLE; // go to idle
          					pslverr_next = 1'b1; // err
							prdata_next  = {(BUS_WIDTH){1'b0}}; // data 0	
							pready_next  = 1'b0;
							next_busy    = 1'b0;
							address_next = {(ADDR_WIDTH){1'b0}};
						end // end else
				end  // end write
          default:
			begin
                next_state = IDLE;  // move to idle
				pready_next  = 1'b0;  // allow next op 
				prdata_next  = {(BUS_WIDTH){1'b0}}; //insert the data from ram to prdata_o bus.
				next_busy    = 1'b0;  //  busy
				pslverr_next = 1'b1; // without an err
				address_next = {(ADDR_WIDTH){1'b0}};
			end
       endcase
    end	


genvar b; // b variable
generate  // grenerate the block
  for(b = 0 ; b < MAX_DIM ; b = b + 1) // for loop
    begin:insert_data_width
        always @(posedge clk_i or negedge rst_ni)// sensitivity list
			begin:strobe_apb
				if(~rst_ni)
					begin
						bus_mem_o[(b+1)*DATA_WIDTH-1-:DATA_WIDTH] <= {(DATA_WIDTH){1'b0}};
					end
				else if(pwrite_i && psel_i && penable_i && ~(paddr_i[4:0] == FLAGS || paddr_i[4:0] >= SP) && ~start_bit_i) //if we writing and in strobe and enabled
					begin
						bus_mem_o[(b+1)*DATA_WIDTH-1-:DATA_WIDTH] <= pstrb_i[b] ? pwdata_i[(b+1)*DATA_WIDTH-1-:DATA_WIDTH] : {(DATA_WIDTH){1'b0}}; // write data
					end
			end
    end 
endgenerate

always @(posedge clk_i or negedge rst_ni) // Asyncronise reset and clk
begin: apb_clk
		if(~rst_ni) //reset, go back to idle and reset all outputs.
    		begin
    			 current_state   <= IDLE; // state idle
    			 pready_o 	     <= 1'b1;   // ready 1
    			 pslverr_o	     <= 1'b0;   // err 0
    			 prdata_o 	     <= {(BUS_WIDTH){1'b0}};   // out data 0
    			 busy_o          <= 1'b0;	// busy 0
				 address_o       <= {(ADDR_WIDTH){1'b0}};
    		end
	  else 
			 begin
			   current_state   <= next_state; // move to next state
  			   pready_o 	   <= pready_next; // move to next ready
    		   pslverr_o	   <= pslverr_next; // move to next pslverr
    		   prdata_o 	   <= prdata_next; // move to next out data
  			   busy_o          <= next_busy; // move to next busy
			   address_o 	   <= address_next;
			end
end
endmodule


