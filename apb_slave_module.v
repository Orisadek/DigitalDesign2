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
prdata_o,busy_o,bus_mem_o,strobe_o); // ports
//-------------------ports----------------------------------------------//
input clk_i,rst_ni,psel_i,penable_i,pwrite_i; // input ports
input pstrb_i,pwdata_i,paddr_i,bus_mem_i; // input ports
input start_bit_i; // input start bit
output pready_o,pslverr_o,prdata_o,busy_o,bus_mem_o,address_o; // output ports
output strobe_o; // output strobe
//-----------------parameters-----------------------------------------//
parameter DATA_WIDTH = 32; // data width
parameter BUS_WIDTH = 64; // bus width
parameter ADDR_WIDTH = 32; // address width
localparam MAX_DIM = BUS_WIDTH/DATA_WIDTH; // max dim of the matrix/ max dim of the matrix  NEVER USED
localparam [1:0] IDLE          = 2'b00, // idle state
			     ACCESS_READ   = 2'b01, // read state
			     ACCESS_WRITE  = 2'b10; // write state	
				 
localparam [4:0] SP    = 5'b10000,
				 FLAGS = 5'b01100;
//-----------------variables------------------------------------------//
wire clk_i, rst_ni; // define clk and rst
wire psel_i,penable_i,pwrite_i; // psel - choose the module (we only have one - matmul) , penable - enable to the APB ,pwrite - write mode or read mode
wire [MAX_DIM-1:0] pstrb_i; //for every byte there is a Pstrb[n]
wire [BUS_WIDTH-1:0] pwdata_i; // data in
wire [BUS_WIDTH-1:0] bus_mem_i; // mem bus in read
wire [ADDR_WIDTH-1:0] paddr_i; // address in
reg  [ADDR_WIDTH-1:0] address_o; // address out
reg  pready_o;    // ready out and next
reg  pslverr_o;   // error out and next
reg  busy_o; // busy line
reg  [BUS_WIDTH-1:0] prdata_o, prdata_next; // data out and next
wire [BUS_WIDTH-1:0] bus_mem_o; 
reg  [1:0] current_state,next_state;   // current state and next
wire start_bit_i;
reg  [ADDR_WIDTH-1:0] address_next;
reg  [MAX_DIM-1:0] strobe_o;
reg  writeEn;

//------------------ combinatorical FSM ---------------------------//
always @(*)	// combinatorical always
	begin: apb_comb
		 case(current_state)  // current state
      		IDLE: // idle
      			begin
      				if(psel_i) //if pslverr_o==1  pslverr_o will not stop the APB			          				  
        				begin 
   				            pready_o  = 1'b0;  // not ready
        				    busy_o    = 1'b1;  // is busy
						    pslverr_o = 1'b0; // no error
							writeEn   = 1'b0;
          					if(pwrite_i) 	// if pwrite == 1
            					begin
									next_state    = ACCESS_WRITE; // next state is write	
									address_next  = paddr_i;	
									strobe_o      = {(MAX_DIM){1'b0}};
								 end
							 else
								 begin
									next_state    = ACCESS_READ; // next state is read	
									address_next  = paddr_i;	
									strobe_o   = {(MAX_DIM){1'b0}};
								 end	
							prdata_next  = {(BUS_WIDTH){1'b0}};
						end
					else
						begin
							writeEn   = 1'b0;
							pready_o  = 1'b0;  // not ready
        				    busy_o    = 1'b0;  // is not busy
						    pslverr_o = 1'b0; // no error
          					next_state = IDLE; // next state is idle	
							address_next  = {(ADDR_WIDTH){1'b0}};	
							prdata_next  = {(BUS_WIDTH){1'b0}};
							strobe_o = {(MAX_DIM){1'b0}};
						end
				end
	    
   		   ACCESS_READ: // read state
      			begin
					if(psel_i && ~pstrb_i && ~start_bit_i) // during READ all pstrob[n] must be low.
						begin
							pready_o     = penable_i ? 1'b1 : 1'b0;  // allow next op 
							prdata_next  = penable_i ? bus_mem_i : {(BUS_WIDTH){1'b0}}; //insert the data from ram to prdata_o bus.
							next_state   = penable_i ? IDLE : ACCESS_READ; // go to idle / stay
							busy_o       = penable_i ? 1'b0: 1'b1;  //  busy
							pslverr_o = 1'b0; // without an err
							address_next = {(ADDR_WIDTH){1'b0}};
							strobe_o = {(MAX_DIM){1'b0}};
							writeEn   = 1'b0;
						end // end if
					else
						begin //if the psel fall betwine clocks the transaction is an error
          				    next_state   = IDLE; // go to idle
          			   		pslverr_o = 1'b1; //either the sel fall during clocks or strob is not 0, transaction is not valid.
          			   		prdata_next  = {(BUS_WIDTH){1'b0}}; // data 0	
							pready_o  = 1'b0;  // not ready
							busy_o    = 1'b1;  // is busy
							address_next = {(ADDR_WIDTH){1'b0}};
							strobe_o = {(MAX_DIM){1'b0}};
							writeEn   = 1'b0;
  					    end // end else
      			end // end read
      			
      		ACCESS_WRITE: // write state
			    begin
					if(psel_i && ~start_bit_i) // if pasel == 1
						begin
							writeEn      = (penable_i && ~(paddr_i[4:0] == FLAGS || paddr_i[4:0] >= SP)) ? 1'b1 : 1'b0;
							pready_o     = penable_i ? 1'b1 : 1'b0;  // allow next op
							next_state   = penable_i ? IDLE : ACCESS_WRITE; // go to idle / stay
							busy_o       =  1'b1;  //  busy
							pslverr_o    = (paddr_i[4:0] == FLAGS || paddr_i[4:0] >= SP); // without an err
							prdata_next  = {(BUS_WIDTH){1'b0}}; // data 0	
							address_next = {(ADDR_WIDTH){1'b0}};
							strobe_o     = (penable_i && ~(paddr_i[4:0] == FLAGS || paddr_i[4:0] >=SP)) ? pstrb_i : 0;
						end // end if
					else
						begin //if the psel fall during the transaction its an error
          					next_state   = IDLE; // go to idle
          					pslverr_o = 1'b1; // err
							prdata_next  = {(BUS_WIDTH){1'b0}}; // data 0	
							pready_o  = 1'b0;
							busy_o    = 1'b0;
							address_next = {(ADDR_WIDTH){1'b0}};
							writeEn   = 1'b0;
							strobe_o     =  0;
						end // end else
				end  // end write
          default:
			begin
                next_state = IDLE;  // move to idle
				pready_o  = 1'b0;  // allow next op 
				prdata_next  = {(BUS_WIDTH){1'b0}}; //insert the data from ram to prdata_o bus.
				busy_o    = 1'b0;  //  not busy
				pslverr_o = 1'b1; // with an err
				writeEn   = 1'b0;
				address_next = {(ADDR_WIDTH){1'b0}};
				strobe_o     =  0;
			end
       endcase
    end	

// assign bus data mem as pwdata_i
assign bus_mem_o = writeEn && ~start_bit_i ? pwdata_i : {(BUS_WIDTH){1'b0}};

//-----------------------Sync part------------------------------------//
always @(posedge clk_i or negedge rst_ni) // Asyncronise reset and clk
begin: apb_clk
		if(~rst_ni) //reset, go back to idle and reset all outputs.
    		begin
    			 current_state   <= IDLE; // state idle
    			 prdata_o 	     <= {(BUS_WIDTH){1'b0}};   // out data 0
				 address_o       <= {(ADDR_WIDTH){1'b0}}; // default address
    		end
	  else 
			 begin
			   current_state   <= next_state; // move to next state
    		   prdata_o 	   <= prdata_next; // move to next out data
			   address_o 	   <= address_next; // next address
			end
end
endmodule


