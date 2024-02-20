`include "headers.vh"

module matmul_checker (
   matmul_intf.CHECKCOV intf
);


property valid_address; //checks if the address is 1 of 5 addresses posible
    @(posedge intf.clk) disable iff(intf.rst)
        intf.penable_i |-> intf.paddr_i inside {5'b00000,5'b00100,5'b01000,5'b01100,5'b10000}; //expected value of the address are the addresses of the registers, must be after p_enable rise
endproperty

a_valid_adress: assert property(valid_address) else $error("\n\t Assertion valid_address failed! \n\t paddr_i : %0d", intf.paddr_i);
cover property(valid_address);


endmodule

