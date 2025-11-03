////////////////////////////////////////////////////////////////
// Module name:		monitor_test
// Description: 	
// Originator:  	Kostochkin
// Rev:		Rev1.0 
// Date:	25_01_2023
//////////////////////////////////////////////////////////////// 
//MONITOR SEARCH
////////////////////////////////////////////////////////////////

`timescale 1 ns / 100 ps

module monitor_test	 	
#( 
	parameter C_NUM_TABLE       = 4,    // Number of block ram, value: 1,2,4,8 or 16
	parameter C_RULE_WIDTH      = 24,	// Bit width of rules
	parameter C_MEM_DATA_WIDTH  = 56,	// Bit width of data in ram
	parameter C_MEM_ADDR_WIDTH  = 8	    // Bit width of addres in ram
( 	
	input  logic 				 						clk_i,        // Input clock
	input  logic 				 						rstn_i,		  // Input asynchronous reset, active '0'

	input  logic										search_i,	  // Strob signal, start rule search for key, active '1'
	input  logic [(C_RULE_WIDTH-1):0]					key_i,		  // Rule, whitch search in ram 

	input  logic [(C_NUM_TABLE-1):0]    				ready_i,	  // Signal from each block ram, then it ready for load rules, active '1' 
	input  logic [(C_NUM_TABLE-1):0]    				busy_i,	      // Signal from each block ram, then it busy for load rules, active '1' 

	input  logic 										hit_vd_i,	  // Strob, search finished, active '1'
	input  logic 										hit_i,		  // Strob, '1' - search was successful, '0' - search failed
	input  logic [3:0]                                  hit_tab_i,     // Output number table, addres in that was found rule
	input  logic [(C_MEM_ADDR_WIDTH-1):0]               hit_addr_i,   // Output addres, addres in that was found rule
	input  logic [(C_MEM_DATA_WIDTH-C_RULE_WIDTH-1):0]	hit_data_i);  // Output data, data that was found in ram by rule						
		

	always_ff @(posedge clk_i) begin
		if (~rstn) begin

		end
		else begin
		
		end
	end	
	
	always_comb begin
	
	end

	
endmodule
