////////////////////////////////////////////////////////////////
// Module name:		ram
// Description: 	
// Originator:  	Kostochkin
// Rev:		Rev1.0 
// Date:	25_01_2023
//////////////////////////////////////////////////////////////// 
//XILINX RAM
////////////////////////////////////////////////////////////////

`timescale 1 ns / 100 ps

module ram #(
     parameter WIDTH     = 32,
     parameter ADDRWIDTH = 8)
   (
    input  logic 					clkA,   			
    input  logic 					clkB,   			 
    input  logic 					enA,   			 
    input  logic 					enB,   			
    input  logic 					weA,   			
    input  logic 					weB,    			
    input  logic [(ADDRWIDTH-1):0] 	addrA,  			
    input  logic [(ADDRWIDTH-1):0] 	addrB,  			
    input  logic [(WIDTH-1):0] 		diA,   		    
    input  logic [(WIDTH-1):0] 		diB,   		    
    output logic [(WIDTH-1):0] 		doA,   		    
    output logic [(WIDTH-1):0] 		doB);

	(* RAM_STYLE = "BLOCK" *) logic [(WIDTH-1):0] ram [(2**ADDRWIDTH-1):0];

	logic [(WIDTH-1):0] r_readA;
 	logic [(WIDTH-1):0] r_readB;

	always_ff @(posedge clkA) begin
	  	if (enA) begin
	    	if (weA) ram[addrA] <= diA;		
	    	else r_readA <= ram[addrA];				
	  	end
	end

	always_ff @(posedge clkB) begin
	  	if (enB) begin	
	  	    //if (weB) ram[addrB] <= diB;
	    	//else r_readB <= ram[addrB];
			r_readB <= ram[addrB];	
	  	end
	end

  	assign doA = r_readA;
  	assign doB = r_readB;

endmodule
